// lib/screens/home/inspection_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../constants/hive_constants.dart';
import '../../data/inspection_storage_model.dart';
import '../../models/inspection_item.dart';
import '../../models/inspection_template_model.dart';
import '../../providers/user_provider.dart';
import '../../services/api_services.dart';
import '../../services/local_storage_services.dart';
import '../../services/reports_cache_service.dart';
import '../../utils/connectivity_checker.dart';
import '../../widgets/inspection_field_info_sheet.dart';
import '../../widgets/section_camera_card.dart';
import '../main_screen.dart';
import 'inspection_success_page.dart';
import '../../utils/ads manager/rewarded_interstitial_ad.dart';

class InspectionScreen extends StatefulWidget {
  final bool isNewInspection;
  final Map<String, dynamic>? vehicleDetails;
  final int? inspectionId;
  final InspectionInitializationResponse? inspectionTemplate;

  const InspectionScreen({
    super.key,
    this.isNewInspection = false,
    this.vehicleDetails,
    this.inspectionId,
    this.inspectionTemplate,
  });

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  Timer? _saveDebouncer;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  int _currentSection = 0;
  int _currentItemIndex = 0;
  Map<String, String?> itemImages = {};
  Map<String, String?> itemVideos = {};
  Map<String, String?> itemAudios = {};
  Map<String, String?> itemFiles = {};
  Map<String, String> itemRemarks = {};
  Map<String, String> itemValues = {};
  Map<String, List<String>?> itemMultiImages = {};
  Map<String, TextEditingController> remarksControllers = {};
  Map<String, TextEditingController> numberRemarkControllers = {};
  Map<String, TextEditingController> textFieldControllers = {};
  Map<String, dynamic>? vehicleDetails;
  bool _showButton = true;
  bool _isScrollable = false;
  bool _isSubmitting = false;
  bool _showSectionTitle = false;
  Set<String> _uploadingImages = {};

  // Dynamic inspection template from API
  InspectionInitializationResponse? _inspectionTemplate;
  bool _useDynamicTemplate = false;
  bool _isLoadingTemplate = true; // Track if template is still loading

  static const String INSPECTION_BOX = HiveConstants.INSPECTION_BOX;
  Box<InspectionStorageModel>? _inspectionBox;

  final RewardedInterstitialAdManager _rewardedAdManager =
      RewardedInterstitialAdManager();

  // // Fallback sections for when API template is not available
  // final List<Map<String, dynamic>> _defaultSections = [
  //   {
  //     'title': 'Documents',
  //     'items': documents as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Body Panel',
  //     'items': bodyPanel as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Flood Affected Signs',
  //     'items': floodAffectedSigns as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Data Set - I',
  //     'items': dataSet1 as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Data Set - II',
  //     'items': dataSet2 as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Battery',
  //     'items': battery as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Coolant',
  //     'items': coolant as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Under Hood',
  //     'items': underHood as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Brake Fluid',
  //     'items': brakeFluid as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Tire',
  //     'items': tire as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Exterior',
  //     'items': exterior as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'A/C',
  //     'items': ac as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Interior',
  //     'items': interior as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Dicky',
  //     'items': dicky as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Test Drive',
  //     'items': testDrive as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'After WarmUp',
  //     'items': afterWarmUp as List<InspectionItem>,
  //   },
  //   {
  //     'title': 'Summary / Remarks',
  //     'items': summary as List<InspectionItem>,
  //   }
  // ];

  // Get sections - either from dynamic template or default
  List<Map<String, dynamic>> get _sections {
    if (_useDynamicTemplate && _inspectionTemplate != null) {
      final sections = _inspectionTemplate!.structure.sections;
      // Sort sections by order
      sections.sort((a, b) => a.order.compareTo(b.order));
      return sections.map((section) {
        // Sort fields by order
        final sortedFields = List<InspectionField>.from(section.fields);
        sortedFields.sort((a, b) => a.order.compareTo(b.order));

        return {
          'title': section.title,
          'name': section.name,
          'id': section.id,
          'order': section.order,
          'items': sortedFields.map((field) {
            return _createDynamicItem(field);
          }).toList(),
        };
      }).toList();
    }
    // return _defaultSections;
    return [];
  }

  // Create a dynamic item from API field
  dynamic _createDynamicItem(InspectionField field) {
    final fieldType = field.fieldType.toLowerCase();

    // Check if this is an image field type or has hasImage flag
    final isImageField = fieldType == 'image' || field.hasImage;

    return {
      'id': field.fieldId,
      'title': field.title,
      'fieldId': field.fieldId,
      'fieldType': fieldType,
      'isRequired': field.isRequired,
      'hasRemarks': field.hasRemarks,
      'hasImage':
          isImageField, // Override hasImage based on field_type or hasImage flag
      'hasVideo': field.hasVideo,
      'hasFile': field.hasFile,
      'useTextField': fieldType == 'text' || fieldType == 'date',
      'options': field.options
          .map((opt) => {
                'id': opt.id,
                'value': opt.value,
                'label': opt.label,
                'colorName': opt.colorName,
                'colorCode': opt.colorCode,
                'order': opt.order,
              })
          .toList(),
      'order': field.order,
      'metadata': field.metadata,
      'referenceMedia': field.referenceMedia
          .map((m) => {
                'id': m.id,
                'mediaType': m.mediaType,
                'filePath': m.filePath,
                'url': m.url,
                'description': m.description,
                'order': m.order,
              })
          .toList(),
    };
  }

  @override
  void initState() {
    super.initState();
    _isScrollable = false;
    _showButton = false;
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initHive();

      // Set vehicle details from widget
      vehicleDetails = widget.vehicleDetails;

      // Check if we have a dynamic inspection template from API
      if (widget.inspectionTemplate != null) {
        _inspectionTemplate = widget.inspectionTemplate;
        _useDynamicTemplate = true;
      } else if (vehicleDetails != null &&
          vehicleDetails!.containsKey('inspectionTemplate')) {
        final templateData = vehicleDetails!['inspectionTemplate'];
        if (templateData != null) {
          if (templateData is InspectionInitializationResponse) {
            _inspectionTemplate = templateData;
          } else {
            try {
              _inspectionTemplate = InspectionInitializationResponse.fromJson(
                templateData is Map<String, dynamic>
                    ? templateData
                    : templateData as Map<String, dynamic>,
              );
            } catch (e) {
              log('Error parsing inspection template: $e');
            }
          }
          _useDynamicTemplate = _inspectionTemplate != null;
        }
      }

      if (widget.isNewInspection) {
        await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);
        _initializeValues();
        _initializeControllers();
      } else {
        await _loadDataFromStorage();
      }

      // Load rewarded interstitial ad
      _rewardedAdManager.loadRewardedInterstitialAd();

      if (mounted) {
        setState(() {
          _isLoadingTemplate = false;
        });
      }
    });
  }

  Future<void> _initHive() async {
    try {
      if (!Hive.isBoxOpen(INSPECTION_BOX)) {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(appDocumentDir.path);

        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(InspectionStorageModelAdapter());
        }

        _inspectionBox =
            await Hive.openBox<InspectionStorageModel>(INSPECTION_BOX);
      } else {
        _inspectionBox = Hive.box<InspectionStorageModel>(INSPECTION_BOX);
      }
    } catch (e) {
      print('Error initializing Hive: $e');
      await Hive.deleteBoxFromDisk(INSPECTION_BOX);
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
      _inspectionBox =
          await Hive.openBox<InspectionStorageModel>(INSPECTION_BOX);
    }
  }

  Future<void> _saveDataLocally() async {
    if (_inspectionBox == null) {
      await _initHive();
    }

    try {
      Map<String, String> currentRemarks = {};
      remarksControllers.forEach((key, controller) {
        currentRemarks[key] = controller.text;
      });

      Map<String, List<String>> currentMultiImages = {};
      itemMultiImages.forEach((key, images) {
        if (images != null && images.isNotEmpty) {
          currentMultiImages[key] = images;
        }
      });

      final storageModel = InspectionStorageModel(
        itemValues: Map<String, String>.from(itemValues),
        itemImages: Map<String, String?>.from(itemImages),
        itemVideos: Map<String, String?>.from(itemVideos),
        itemAudios: Map<String, String?>.from(itemAudios),
        itemFiles: Map<String, String?>.from(itemFiles),
        itemRemarks: currentRemarks,
        currentSection: _currentSection,
        textFieldValues: Map<String, String>.from(
          Map.fromEntries(
            textFieldControllers.entries.map(
              (e) => MapEntry(e.key, e.value.text),
            ),
          ),
        ),
        multiImages: currentMultiImages,
      );

      await _inspectionBox?.put(
        HiveConstants.CURRENT_INSPECTION_KEY,
        storageModel,
      );

      print('Data saved locally');
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> _completeInspection() async {
    try {
      if (!(_inspectionBox?.isOpen ?? false)) {
        await _initHive();
      }

      final currentData =
          _inspectionBox?.get(HiveConstants.CURRENT_INSPECTION_KEY);
      if (currentData != null) {
        final completedInspection = InspectionStorageModel(
          itemValues: Map<String, String>.from(currentData.itemValues),
          itemImages: Map<String, String?>.from(currentData.itemImages),
          itemVideos: Map<String, String?>.from(currentData.itemVideos),
          itemAudios: Map<String, String?>.from(currentData.itemAudios),
          itemFiles: Map<String, String?>.from(currentData.itemFiles),
          itemRemarks: Map<String, String>.from(currentData.itemRemarks),
          currentSection: currentData.currentSection,
          textFieldValues:
              Map<String, String>.from(currentData.textFieldValues),
          isCompleted: true,
          timestamp: DateTime.now(),
          status: 'submitted',
        );

        final historyBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_HISTORY_BOX,
        );

        await historyBox.add(completedInspection);
        await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);
        await historyBox.close();
      }
    } catch (e) {
      print('Error completing inspection: $e');
      rethrow;
    }
  }

  void _autoSave() {
    if (_saveDebouncer?.isActive ?? false) _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        try {
          await _saveDataLocally();
        } catch (e) {
          print('Error in auto save: $e');
        }
      }
    });
  }

  IconData _getSectionIcon(String sectionTitle) {
    final title =
        sectionTitle.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');

    // Handle API section names (like documents, body_panel, dataset1, etc.)
    switch (title) {
      case 'documents':
        return Icons.description;
      case 'body_panel':
        return Icons.directions_car;
      case 'flood_affected':
        return Icons.water_damage;
      case 'dataset1':
      case 'data_set_1':
        return Icons.analytics;
      case 'dataset2':
      case 'data_set_2':
        return Icons.analytics;
      case 'battery':
        return Icons.battery_full;
      case 'coolant':
        return Icons.opacity;
      case 'under_hood':
        return Icons.car_repair;
      case 'brake_fluid':
        return Icons.speed;
      case 'tire':
        return Icons.tire_repair;
      case 'exterior':
        return Icons.directions_car_filled;
      case 'a_c':
        return Icons.ac_unit;
      case 'interior':
        return Icons.airline_seat_recline_normal;
      case 'dicky':
        return Icons.luggage;
      case 'test_drive':
        return Icons.drive_eta;
      case 'after_warmup':
        return Icons.local_fire_department;
      // Fallback to original titles
      case 'body panel':
        return Icons.directions_car;
      case 'flood affected signs':
        return Icons.water_damage;
      case 'data set - i':
      case 'data set - ii':
        return Icons.analytics;
      case 'under hood':
        return Icons.car_repair;
      case 'brake fluid':
        return Icons.speed;
      case 'a/c':
        return Icons.ac_unit;
      case 'test drive':
        return Icons.drive_eta;
      case 'after warmup':
        return Icons.local_fire_department;
      case 'summary / remarks':
        return Icons.summarize;
      default:
        return Icons.checklist;
    }
  }

  String _getPlaceholderText(String itemTitle, String sectionTitle) {
    final title = itemTitle.toLowerCase();

    if (title.contains('registration') ||
        title.contains('number') ||
        title.contains('plate')) {
      return 'e.g. MH12AB1234';
    }
    if (title.contains('chassis') || title.contains('vin')) {
      return 'e.g. MA1234567890123456';
    }
    if (title.contains('engine number')) {
      return 'e.g. G4FC123456';
    }

    return 'Enter details...';
  }

  Future<void> _loadDataFromStorage() async {
    try {
      final storedData =
          _inspectionBox?.get(HiveConstants.CURRENT_INSPECTION_KEY);

      if (storedData != null) {
        _cleanupControllers();

        setState(() {
          itemValues = storedData.typedItemValues;
          itemImages = storedData.typedItemImages;
          itemVideos = storedData.typedItemVideos;
          itemAudios = storedData.typedItemAudios;
          itemFiles = storedData.typedItemFiles;
          itemRemarks = storedData.typedItemRemarks;
          _currentSection = storedData.currentSection;
          itemMultiImages = storedData.typedMultiImages;
        });

        for (var section in _sections) {
          final items = section['items'] as List<dynamic>;
          for (var item in items) {
            final uniqueId = _getItemUniqueId(item);

            if (_itemHasRemarks(item)) {
              remarksControllers[uniqueId] = TextEditingController(
                text: storedData.typedItemRemarks[uniqueId] ?? '',
              );
            }

            if (_itemUsesTextField(item)) {
              textFieldControllers[uniqueId] = TextEditingController(
                text: storedData.typedItemValues[uniqueId] ?? '',
              );
            }
          }
        }
      } else {
        _initializeValues();
        _initializeControllers();
      }
    } catch (e) {
      print('Error loading data: $e');
      _initializeValues();
      _initializeControllers();
    }
  }

  void _onScroll() {
    if (!_isScrollable) return;

    bool shouldShowSectionTitle = _scrollController.position.pixels > 100;

    if (shouldShowSectionTitle != _showSectionTitle) {
      setState(() {
        _showSectionTitle = shouldShowSectionTitle;
      });
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_showButton) {
        setState(() {
          _showButton = true;
        });
      }
    } else {
      if (_showButton) {
        setState(() {
          _showButton = false;
        });
      }
    }
  }

  Future<void> _cleanupCurrentInspection() async {
    try {
      if (_inspectionBox?.isOpen ?? false) {
        await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);
      }

      if (mounted) {
        setState(() {
          itemValues.clear();
          itemImages.clear();
          itemVideos.clear();
          itemAudios.clear();
          itemFiles.clear();
          itemRemarks.clear();
        });
      }
    } catch (e) {
      print('Error cleaning up current inspection: $e');
    }
  }

  void _initializeControllers() {
    _cleanupControllers();
    remarksControllers.clear();
    textFieldControllers.clear();
    numberRemarkControllers.clear();

    for (var section in _sections) {
      final items = section['items'] as List<dynamic>;
      for (var item in items) {
        final uniqueId = _getItemUniqueId(item);

        if (_itemHasRemarks(item)) {
          remarksControllers[uniqueId] = TextEditingController(
            text: itemRemarks[uniqueId] ?? '',
          );
          remarksControllers[uniqueId]?.addListener(() {
            itemRemarks[uniqueId] = remarksControllers[uniqueId]?.text ?? '';
          });
        }

        if (_itemUsesTextField(item)) {
          textFieldControllers[uniqueId] = TextEditingController(
            text: itemValues[uniqueId] ?? '',
          );
          textFieldControllers[uniqueId]?.addListener(() {
            itemValues[uniqueId] = textFieldControllers[uniqueId]?.text ?? '';
          });
        }
      }
    }
  }

  void _initializeValues() {
    itemValues = {};
    itemRemarks = {};
    itemMultiImages = {};
    itemVideos = {};
    itemAudios = {};
    itemFiles = {};

    for (var section in _sections) {
      final items = section['items'] as List<dynamic>;
      for (var item in items) {
        final uniqueId = _getItemUniqueId(item);

        if (_itemUsesTextField(item)) {
          itemValues[uniqueId] = '';
        } else if (_itemHasOptions(item)) {
          itemValues[uniqueId] = 'N/A';
        }

        if (_itemHasRemarks(item)) {
          itemRemarks[uniqueId] = '';
        }
      }
    }
  }

  // Helper methods for handling both dynamic and regular items
  String _getItemUniqueId(dynamic item) {
    if (item is InspectionItem) {
      return item.uniqueId;
    } else if (item is Map) {
      return item['fieldId'] ?? item['id'] ?? '';
    }
    return '';
  }

  String _getItemTitle(dynamic item) {
    if (item is InspectionItem) {
      return item.title;
    } else if (item is Map) {
      return item['title'] ?? '';
    }
    return '';
  }

  bool _itemHasImage(dynamic item) {
    if (item is InspectionItem) {
      return item.allowImage;
    } else if (item is Map) {
      return item['hasImage'] ?? false;
    }
    return false;
  }

  bool _itemHasMultiImage(dynamic item) {
    if (item is InspectionItem) {
      return item.allowMultiImage;
    } else if (item is Map) {
      return item['allowMultiImage'] ?? false;
    }
    return false;
  }

  bool _itemUsesTextField(dynamic item) {
    if (item is InspectionItem) {
      return item.useTextField;
    } else if (item is Map) {
      return item['useTextField'] ?? false;
    }
    return false;
  }

  bool _itemHasRemarks(dynamic item) {
    if (item is InspectionItem) {
      return item.allowRemarks;
    } else if (item is Map) {
      return item['hasRemarks'] ?? false;
    }
    return false;
  }

  bool _itemIsRequired(dynamic item) {
    if (item is InspectionItem) {
      // InspectionItem doesn't have isRequired, default to false
      return false;
    } else if (item is Map) {
      return item['isRequired'] ?? false;
    }
    return false;
  }

  bool _itemHasVideo(dynamic item) {
    if (item is InspectionItem) {
      // InspectionItem doesn't have allowVideo, default to false
      return false;
    } else if (item is Map) {
      return item['hasVideo'] ?? false;
    }
    return false;
  }

  bool _itemHasFile(dynamic item) {
    if (item is InspectionItem) {
      // InspectionItem doesn't have allowFile, default to false
      return false;
    } else if (item is Map) {
      return item['hasFile'] ?? false;
    }
    return false;
  }

  List<Map<String, dynamic>> _getItemReferenceMedia(dynamic item) {
    if (item is Map) {
      final media = item['referenceMedia'];
      if (media is List && media.isNotEmpty) {
        return media.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  bool _itemHasOptions(dynamic item) {
    if (item is InspectionItem) {
      return item.options != null && item.options!.isNotEmpty;
    } else if (item is Map) {
      return item['options'] != null && (item['options'] as List).isNotEmpty;
    }
    return false;
  }

  String _getItemFieldId(dynamic item) {
    if (item is InspectionItem) {
      return item.id;
    } else if (item is Map) {
      return item['fieldId'] ?? item['id'] ?? '';
    }
    return '';
  }

  bool _isImageFieldType(dynamic item) {
    if (item is Map) {
      return (item['fieldType'] as String?)?.toLowerCase() == 'image';
    }
    return false;
  }

  Widget _buildInspectionSection(String title, List<dynamic> items) {
    if (_currentItemIndex >= items.length) {
      _currentItemIndex = 0;
    }
    if (_currentItemIndex < 0) {
      _currentItemIndex = 0;
    }

    final item = items[_currentItemIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withAlpha(76),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSectionIcon(title),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Item ${_currentItemIndex + 1} of ${items.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(204),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildSingleItemContainer(item, title),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _currentItemIndex > 0 ? _previousItem : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    _currentItemIndex < items.length - 1 ? _nextItem : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleItemContainer(dynamic item, String sectionTitle) {
    final uniqueId = _getItemUniqueId(item);
    final title = _getItemTitle(item);
    final allowImage = _itemHasImage(item);
    final allowMultiImage = _itemHasMultiImage(item);
    final isRequired = _itemIsRequired(item);
    final referenceMedia = _getItemReferenceMedia(item);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isRequired
              ? Colors.orange.withAlpha(128)
              : Theme.of(context).dividerColor.withAlpha(51),
          width: isRequired ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      if (isRequired)
                        const Text(
                          ' *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((allowImage && !_isImageFieldType(item)) || allowMultiImage)
                      IconButton(
                        icon: const Icon(Icons.camera_alt, size: 22),
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () {
                          if (allowMultiImage) {
                            _pickMultiImages(item);
                          } else {
                            _showImagePickerOptions(item);
                          }
                        },
                      ),
                    if (_itemHasVideo(item))
                      IconButton(
                        icon: const Icon(Icons.videocam, size: 22),
                        color: Colors.deepPurple,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _showVideoPickerOptions(item),
                      ),
                    if (_itemHasFile(item))
                      IconButton(
                        icon: const Icon(Icons.attach_file, size: 22),
                        color: Colors.teal,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _pickFile(item),
                      ),
                    if ((item is Map
                            ? (item['fieldType'] as String?)
                            : null)
                        ?.toLowerCase() ==
                        'audio')
                      IconButton(
                        icon: const Icon(Icons.audio_file, size: 22),
                        color: Colors.orange,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _pickAudio(item),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (referenceMedia.isNotEmpty) ...[
              ReferenceMediaSection(mediaList: referenceMedia),
              const SizedBox(height: 10),
            ],
            if (_isImageFieldType(item) && itemImages[uniqueId] == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCameraCard(
                    height: 220,
                    borderRadius: BorderRadius.circular(12),
                    onCapture: (XFile file) async {
                      final fieldId = _getItemFieldId(item);
                      final String sectionTitle =
                          _sections[_currentSection]['title'] as String;
                      final savedPath =
                          await LocalStorageService.saveImage(file.path);

                      setState(() {
                        itemImages[uniqueId] = savedPath;
                        _uploadingImages.add(uniqueId);
                      });

                      await _saveDataLocally();

                      final bool hasInternet =
                          await ConnectivityChecker.hasInternetConnection();

                      if (hasInternet) {
                        final result = await ApiService.uploadImage(
                          savedPath,
                          inspectionId: widget.inspectionId,
                          section: sectionTitle,
                          itemId: fieldId,
                        );

                        if (mounted) {
                          setState(() {
                            _uploadingImages.remove(uniqueId);
                          });

                          if (result['success']) {
                            setState(() {
                              itemImages[uniqueId] = result['url'] as String;
                            });
                            await _saveDataLocally();
                          }
                        }
                      } else {
                        if (mounted) {
                          setState(() {
                            _uploadingImages.remove(uniqueId);
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _pickImage(
                        ImageSource.gallery,
                        uniqueId,
                        _getItemFieldId(item),
                      ),
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Gallery', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            if (allowImage && itemImages[uniqueId] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Captured Image:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      if (_uploadingImages.contains(uniqueId)) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Uploading...',
                          style: TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showImagePreview(itemImages[uniqueId]!),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(itemImages[uniqueId]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (allowMultiImage &&
                itemMultiImages[uniqueId] != null &&
                itemMultiImages[uniqueId]!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Captured Images:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: itemMultiImages[uniqueId]!.length,
                      itemBuilder: (context, imgIndex) {
                        final imagePath = itemMultiImages[uniqueId]![imgIndex];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: _buildImageWidget(imagePath),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    final updatedPaths = List<String>.from(
                                        itemMultiImages[uniqueId]!)
                                      ..removeAt(imgIndex);
                                    setState(() {
                                      itemMultiImages[uniqueId] =
                                          updatedPaths.isEmpty
                                              ? null
                                              : updatedPaths;
                                    });
                                    _autoSave();
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.cancel,
                                        size: 18, color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (itemVideos[uniqueId] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Video selected: ${itemVideos[uniqueId]!.split('/').last}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (itemAudios[uniqueId] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Audio selected: ${itemAudios[uniqueId]!.split('/').last}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (itemFiles[uniqueId] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'File attached: ${_extractFileName(itemFiles[uniqueId]!)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            _buildItemControls(item, sectionTitle),
          ],
        ),
      ),
    );
  }

  Widget _buildItemControls(dynamic item, String sectionTitle) {
    final uniqueId = _getItemUniqueId(item);
    final useTextField = _itemUsesTextField(item);
    final title = _getItemTitle(item);
    final referenceMedia = _getItemReferenceMedia(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (useTextField)
          TextField(
            controller: textFieldControllers[uniqueId],
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[50],
              hintText: _getPlaceholderText(title, sectionTitle),
              hintStyle: TextStyle(
                color: Theme.of(context).hintColor.withAlpha(153),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Theme.of(context).dividerColor.withAlpha(128)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.multiline,
            onChanged: (value) {
              setState(() {
                itemValues[uniqueId] = value;
              });
              _autoSave();
            },
          ),
        if (!useTextField && _itemHasOptions(item))
          DropdownButtonFormField<String>(
            value: itemValues[uniqueId] == 'N/A' ? null : itemValues[uniqueId],
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[50],
              hintText: 'Select an option',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Theme.of(context).dividerColor.withAlpha(128)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            items: ((item['options'] as List?) ?? [])
                .map((opt) => DropdownMenuItem<String>(
                      value: (opt['value'] ?? '').toString(),
                      child: Text((opt['label'] ?? opt['value'] ?? '').toString()),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                itemValues[uniqueId] = value;
              });
              _autoSave();
            },
          ),
        const SizedBox(height: 12),
        InspectionInfoButton(
          fieldId: uniqueId,
          referenceMedia: referenceMedia,
        ),
      ],
    );
  }

  void _showImagePickerOptions(dynamic item) {
    final uniqueId = _getItemUniqueId(item);
    final fieldId = _getItemFieldId(item);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, uniqueId, fieldId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, uniqueId, fieldId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
      ImageSource source, String uniqueId, String fieldId) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final String sectionTitle =
            _sections[_currentSection]['title'] as String;
        final savedPath = await LocalStorageService.saveImage(image.path);

        setState(() {
          itemImages[uniqueId] = savedPath;
          _uploadingImages.add(uniqueId);
        });

        await _saveDataLocally();

        final bool hasInternet =
            await ConnectivityChecker.hasInternetConnection();

        if (hasInternet) {
          final result = await ApiService.uploadImage(
            savedPath,
            inspectionId: widget.inspectionId,
            section: sectionTitle,
            itemId: fieldId,
          );

          if (mounted) {
            setState(() {
              _uploadingImages.remove(uniqueId);
            });

            if (result['success']) {
              setState(() {
                itemImages[uniqueId] = result['url'] as String;
              });
              await _saveDataLocally();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Image saved locally. Will upload when online.')),
              );
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _uploadingImages.remove(uniqueId);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Image saved locally. Will upload when online.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingImages.remove(uniqueId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickMultiImages(dynamic item) async {
    final uniqueId = _getItemUniqueId(item);
    final fieldId = _getItemFieldId(item);

    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty && mounted) {
        final String sectionTitle =
            _sections[_currentSection]['title'] as String;
        final currentImages = itemMultiImages[uniqueId] ?? [];
        final List<String> savedPaths = [];

        for (var image in images) {
          final savedPath = await LocalStorageService.saveImage(image.path);
          savedPaths.add(savedPath);
        }

        final updatedPaths =
            [...currentImages, ...savedPaths].take(11).toList();

        setState(() {
          itemMultiImages[uniqueId] = updatedPaths;
          _uploadingImages.add(uniqueId);
        });

        await _saveDataLocally();

        final bool hasInternet =
            await ConnectivityChecker.hasInternetConnection();

        if (hasInternet) {
          final List<String> uploadedUrls = [];

          for (int i = 0; i < updatedPaths.length; i++) {
            final path = updatedPaths[i];
            if (!path.startsWith('http')) {
              final result = await ApiService.uploadImage(
                path,
                inspectionId: widget.inspectionId,
                section: sectionTitle,
                itemId: fieldId,
              );

              if (result['success']) {
                uploadedUrls.add(result['url'] as String);
              } else {
                uploadedUrls.add(path);
              }
            } else {
              uploadedUrls.add(path);
            }
          }

          if (mounted) {
            setState(() {
              _uploadingImages.remove(uniqueId);
              itemMultiImages[uniqueId] = uploadedUrls;
            });
            await _saveDataLocally();
          }
        } else {
          if (mounted) {
            setState(() {
              _uploadingImages.remove(uniqueId);
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingImages.remove(uniqueId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  Future<void> _pickFile(dynamic item) async {
    final uniqueId = _getItemUniqueId(item);
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result != null && result.files.single.path != null && mounted) {
        final file = result.files.single;
        final payload = json.encode({
          'filePath': file.path,
          'fileName': file.name,
          'fileType': file.extension?.toLowerCase() ?? '',
        });
        setState(() {
          itemFiles[uniqueId] = payload;
        });
        _autoSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _pickAudio(dynamic item) async {
    final uniqueId = _getItemUniqueId(item);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null && mounted) {
        setState(() {
          itemAudios[uniqueId] = result.files.single.path!;
        });
        _autoSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick audio: $e')),
        );
      }
    }
  }

  void _showVideoPickerOptions(dynamic item) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.deepPurple),
                title: const Text('Record Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(item, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.deepPurple),
                title: const Text('Choose Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(item, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickVideo(dynamic item, ImageSource source) async {
    final uniqueId = _getItemUniqueId(item);
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: source);
      if (video != null && mounted) {
        setState(() {
          itemVideos[uniqueId] = video.path;
        });
        _autoSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    }
  }

  String _extractFileName(String filePayload) {
    try {
      final parsed = json.decode(filePayload) as Map<String, dynamic>;
      return (parsed['fileName'] ?? 'attached_file').toString();
    } catch (_) {
      return filePayload.split('/').last;
    }
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      );
    }
  }

  void _showImagePreview(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        final items = _sections[_currentSection]['items']
                            as List<dynamic>;
                        final currentItem = items[_currentItemIndex];
                        final uniqueId = _getItemUniqueId(currentItem);
                        setState(() {
                          itemImages[uniqueId] = null;
                        });
                        _autoSave();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Flexible(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4,
                    child: imagePath.startsWith('http')
                        ? Image.network(imagePath, fit: BoxFit.contain)
                        : Image.file(File(imagePath), fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _nextItem() {
    final currentSection = _sections[_currentSection];
    final items = currentSection['items'] as List<dynamic>;
    if (_currentItemIndex < items.length - 1) {
      setState(() {
        _currentItemIndex++;
      });
      _autoSave();
    }
  }

  void _previousItem() {
    if (_currentItemIndex > 0) {
      setState(() {
        _currentItemIndex--;
      });
      _autoSave();
    }
  }

  List<String> _getRequiredFieldErrors() {
    final section = _sections[_currentSection];
    final items = section['items'] as List<dynamic>;
    final errors = <String>[];

    for (var item in items) {
      if (!_itemIsRequired(item)) continue;

      final uniqueId = _getItemUniqueId(item);
      final title = _getItemTitle(item);

      if (_itemUsesTextField(item)) {
        final value = itemValues[uniqueId]?.trim() ?? '';
        if (value.isEmpty) {
          errors.add(title);
        }
      } else if (_itemHasOptions(item)) {
        final value = itemValues[uniqueId] ?? 'N/A';
        if (value == 'N/A' || value.isEmpty) {
          errors.add(title);
        }
      }

      if (_itemHasImage(item)) {
        if (itemImages[uniqueId] == null || itemImages[uniqueId]!.isEmpty) {
          errors.add('$title (image)');
        }
      }
      if (_itemHasVideo(item)) {
        if (itemVideos[uniqueId] == null || itemVideos[uniqueId]!.isEmpty) {
          errors.add('$title (video)');
        }
      }
      if (_itemHasFile(item)) {
        if (itemFiles[uniqueId] == null || itemFiles[uniqueId]!.isEmpty) {
          errors.add('$title (file)');
        }
      }
    }

    return errors;
  }

  void _nextSection() {
    final errors = _getRequiredFieldErrors();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Required fields missing: ${errors.join(", ")}'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_currentSection < _sections.length - 1) {
      setState(() {
        _currentSection++;
        _currentItemIndex = 0;
        _showButton = false;
        _isScrollable = false;
      });

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _autoSave();
          setState(() {
            _isScrollable = _scrollController.position.maxScrollExtent > 0;
            _showButton = !_isScrollable;
          });
        }
      });
    } else {
      if (_isSubmitting) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Submit Inspection'),
            content: const Text(
                'Are you sure you want to submit the inspection data?'),
            actions: [
              TextButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _showRewardedAdAndSubmit();
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _showRewardedAdAndSubmit() async {
    try {
      await _rewardedAdManager.showRewardedInterstitialAd(
        onUserEarnedReward: (ad, rewardItem) {
          _handleSubmission();
        },
        onAdClosed: () {
          _handleSubmission();
        },
        onAdFailedToShow: () {
          _handleSubmission();
        },
      );
    } catch (e) {
      _handleSubmission();
    }
  }

  Map<String, dynamic> _buildSubmissionBody() {
    Map<String, dynamic> inspectionData = {};

    for (var section in _sections) {
      final sectionName = section['name'] ??
          (section['title'] as String).toLowerCase().replaceAll(' ', '_');
      List<Map<String, dynamic>> sectionItems = [];

      for (var item in section['items'] as List<dynamic>) {
        final uniqueId = _getItemUniqueId(item);
        final title = _getItemTitle(item);
        final value = itemValues[uniqueId] ?? '';
        final remarks = itemRemarks[uniqueId];
        final imagePath = itemImages[uniqueId];
        final multiImages = itemMultiImages[uniqueId];
        final videoPath = itemVideos[uniqueId];
        final audioPath = itemAudios[uniqueId];
        final filePath = itemFiles[uniqueId];

        sectionItems.add({
          'id': uniqueId,
          'fieldId': _getItemFieldId(item),
          'fieldType': item is Map ? (item['fieldType'] ?? '').toString() : '',
          'title': title,
          'value': value,
          'remarks': (remarks != null && remarks.isNotEmpty) ? remarks : null,
          'imagePath': imagePath,
          'multiImages': multiImages,
          'videoPath': videoPath,
          'audioPath': audioPath,
          'filePath': filePath,
        });
      }

      inspectionData[sectionName] = {
        'title': section['title'],
        'items': sectionItems,
      };
    }

    // Prefer 'regno' (Documents field id) then any registration-like key
    String registrationNumber = '';
    final regnoValue = (itemValues['regno'] ?? '').trim();
    if (regnoValue.isNotEmpty && regnoValue != 'N/A') {
      registrationNumber = regnoValue;
    } else {
      for (var key in itemValues.keys) {
        final k = key.toLowerCase();
        if (k.contains('registration') ||
            k.contains('regnumber') ||
            k.contains('reg_number') ||
            k.contains('regno')) {
          final value = (itemValues[key] ?? '').trim();
          if (value.isNotEmpty && value != 'N/A') {
            registrationNumber = value;
            break;
          }
        }
      }
    }

    return {
      'template_type': 'default',
      'vehicle_brand_id': vehicleDetails?['brand_id'],
      'vehicle_model_id': vehicleDetails?['model_id'],
      'registration_number': registrationNumber,
      'inspection_data': inspectionData,
    };
  }

  Future<void> _handleSubmission() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      bool hasInternet = await ConnectivityChecker.hasInternetConnection();

      if (!hasInternet) {
        Map<String, String?> finalItemImages = Map.from(itemImages);
        final body = _buildSubmissionBody();

        await LocalStorageService.saveInspection(
          data: body,
          images: finalItemImages,
          status: 'pending',
        );

        await _completeInspection();
        await _cleanupCurrentInspection();
        _navigateToLocalInspections(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'No internet connection. Inspection saved to pending.')),
          );
        }
        return;
      }

      try {
        final body = _buildSubmissionBody();
        final result = await ApiService.submitInspection(body);
        log(body.toString());
        log(result.toString());

        if (result['success']) {
          await _completeInspection();
          await _cleanupCurrentInspection();

          if (mounted) {
            final data = result['data'] as Map<String, dynamic>;
            final redirectUrl = data['redirect_url'] as String? ?? '';
            final inspectionId = data['inspection_id'] as int? ?? 0;
            if (redirectUrl.isNotEmpty) {
              await ReportsCacheService.addReport(
                redirectUrl: redirectUrl,
                inspectionId: inspectionId,
              );
            }
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => InspectionSuccessPage(
                  redirectUrl: redirectUrl,
                  inspectionId: inspectionId,
                  uuid: data['uuid'] ?? '',
                ),
              ),
              (route) => false,
            );
          }
        } else {
          Map<String, String?> finalItemImages = Map.from(itemImages);
          await LocalStorageService.saveInspection(
            data: _buildSubmissionBody(),
            images: finalItemImages,
            status: 'pending',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to submit: ${result['message']}')),
            );
          }
        }
      } catch (apiError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission error: $apiError')),
          );
        }
      }
    } catch (e) {
      print('Error in submission process: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving inspection: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _navigateToLocalInspections(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialIndex: context.read<UserProvider>().isAdmin() ? 3 : 2,
        ),
      ),
    );
  }

  void _previousSection() async {
    await _saveDataLocally();
    if (_currentSection > 0) {
      setState(() {
        _currentSection--;
        _currentItemIndex = 0;
        _showButton = false;
        _isScrollable = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while template is being initialized
    if (_isLoadingTemplate) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator.adaptive(),
              SizedBox(height: 16),
              Text('Loading inspection template...'),
            ],
          ),
        ),
      );
    }

    // Handle empty sections case
    if (_sections.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'No inspection template loaded',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Debug: _useDynamicTemplate = $_useDynamicTemplate',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Debug: _inspectionTemplate = ${_inspectionTemplate != null ? "loaded" : "null"}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Debug: widget.inspectionTemplate = ${widget.inspectionTemplate != null ? "loaded" : "null"}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentSection = _sections[_currentSection];

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final bool shouldClose = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Stop Inspection?'),
                  content: const Text(
                    'Your progress will be saved and you can continue later. Do you want to stop?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Stop'),
                    ),
                  ],
                );
              },
            ) ??
            false;

        if (shouldClose) {
          await _saveDataLocally();
          if (!mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          toolbarHeight: 70,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showSectionTitle
                ? Row(
                    key: const ValueKey('sectionTitle'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getSectionIcon(_sections[_currentSection]['title']),
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _sections[_currentSection]['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Certifide',
                    key: ValueKey('appTitle'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Stop Inspection?'),
                      content: const Text(
                        'Your progress will be saved and you can continue later. Do you want to stop?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: _handleClose,
                          child: const Text('Stop'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.close),
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: _openDrawer,
            ),
          ],
          leading: _currentSection > 0
              ? IconButton(
                  icon: const Icon(CupertinoIcons.back),
                  onPressed: _previousSection,
                )
              : null,
          automaticallyImplyLeading: false,
        ),
        endDrawer: _buildDrawer(),
        body: Column(
          children: [
            Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width *
                        ((_currentSection + 1) / _sections.length) *
                        0.87,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Section ${_currentSection + 1} of ${_sections.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${((_currentSection + 1) / _sections.length * 100).round()}% Complete',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: PageStorageKey<int>(_currentSection),
                controller: _scrollController,
                children: [
                  _buildInspectionSection(
                    currentSection['title'],
                    currentSection['items'] as List<dynamic>,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _currentSection == _sections.length - 1
                              ? const LinearGradient(colors: [
                                  Color(0xFF11998e),
                                  Color(0xFF38ef7d)
                                ])
                              : const LinearGradient(colors: [
                                  Color(0xFF667eea),
                                  Color(0xFF764ba2)
                                ]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (_currentSection == _sections.length - 1
                                      ? const Color(0xFF11998e)
                                      : const Color(0xFF667eea))
                                  .withAlpha(102),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _nextSection,
                          child: _isSubmitting &&
                                  _currentSection == _sections.length - 1
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentSection == _sections.length - 1
                                          ? 'FINISH INSPECTION'
                                          : 'NEXT SECTION',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _currentSection == _sections.length - 1
                                          ? Icons.check_circle_outline
                                          : Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSectionComplete(int sectionIndex) {
    if (sectionIndex >= _sections.length) return false;

    final section = _sections[sectionIndex];
    final items = section['items'] as List<dynamic>;

    for (var item in items) {
      final uniqueId = _getItemUniqueId(item);

      if (_itemHasImage(item)) {
        if (itemImages[uniqueId] == null || itemImages[uniqueId]!.isEmpty) {
          return false;
        }
      }

      if (_itemUsesTextField(item)) {
        final value = itemValues[uniqueId] ?? '';
        if (value.trim().isEmpty) {
          return false;
        }
      }

      if (_itemHasOptions(item)) {
        final value = itemValues[uniqueId] ?? 'N/A';
        if (value == 'N/A' || value.isEmpty) {
          return false;
        }
      }
    }

    return true;
  }

  Widget _buildDrawer() {
    return Drawer(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.checklist_rtl,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Inspection Sections',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_sections.length} sections available',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    final isSelected = _currentSection == index;
                    final isCompleted = _isSectionComplete(index);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              )
                            : null,
                        color: isSelected ? null : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Theme.of(context).dividerColor.withAlpha(51),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF667eea).withAlpha(76),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withAlpha(25)
                                : isSelected
                                    ? Colors.white.withAlpha(51)
                                    : Theme.of(context)
                                        .dividerColor
                                        .withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : _getSectionIcon(section['title']),
                            size: 20,
                            color: isCompleted
                                ? Colors.green
                                : isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .iconTheme
                                        .color
                                        ?.withAlpha(153),
                          ),
                        ),
                        trailing: isCompleted
                            ? const Icon(Icons.check_circle,
                                color: Colors.green, size: 20)
                            : isSelected
                                ? Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.white)
                                : null,
                        title: Text(
                          section['title'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        subtitle: Text(
                          '${(section['items'] as List).length} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white.withAlpha(204)
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withAlpha(153),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _currentSection = index;
                            _currentItemIndex = 0;
                            _isScrollable = false;
                            _showButton = true;
                          });

                          Future.delayed(const Duration(milliseconds: 100), () {
                            setState(() {
                              _isScrollable =
                                  _scrollController.position.maxScrollExtent >
                                      0;
                              _showButton = !_isScrollable;
                            });

                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });

                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cleanupControllers() {
    for (var controller in remarksControllers.values) {
      controller.dispose();
    }
    for (var controller in textFieldControllers.values) {
      controller.dispose();
    }
    remarksControllers.clear();
    textFieldControllers.clear();
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    _scrollController.dispose();
    _cleanupControllers();
    _isSubmitting = false;
    _rewardedAdManager.dispose();

    if (_inspectionBox?.isOpen ?? false) {
      _inspectionBox?.close();
    }
    super.dispose();
  }

  void _handleClose() async {
    try {
      await _saveDataLocally();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      print('Error handling close: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving data')),
      );
    }
  }
}
