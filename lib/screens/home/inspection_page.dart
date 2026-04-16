// lib/screens/home/inspection_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'inspection_page/components/inspection_app_bar_title.dart';
import 'inspection_page/components/inspection_bottom_actions.dart';
import 'inspection_page/components/inspection_progress_header.dart';
import 'inspection_page/components/inspection_sections_drawer.dart';
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

class _InspectionScreenState extends State<InspectionScreen>
    with WidgetsBindingObserver {
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
  Set<String> _uploadingImages = {};
  String? _verifyingRegNoUniqueId;
  final Map<String, String> _regNoVerifyMessage = {};
  final Map<String, bool> _regNoVerifyIsError = {};

  // Dynamic inspection template from API
  InspectionInitializationResponse? _inspectionTemplate;
  bool _useDynamicTemplate = false;
  bool _isLoadingTemplate = true; // Track if template is still loading

  /// Server inspection id: from route, Hive snapshot, or refetch when resuming.
  int? _sessionInspectionId;

  int? get _effectiveInspectionId =>
      _sessionInspectionId ?? widget.inspectionId;

  static const String INSPECTION_BOX = HiveConstants.INSPECTION_BOX;
  Box<InspectionStorageModel>? _inspectionBox;

  final RewardedInterstitialAdManager _rewardedAdManager =
      RewardedInterstitialAdManager();

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
    WidgetsBinding.instance.addObserver(this);
    _isScrollable = false;
    _showButton = false;
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initHive();

      _sessionInspectionId = widget.inspectionId;

      // Set vehicle details from widget
      vehicleDetails = widget.vehicleDetails;

      // If continuing a previous inspection, load template from storage first
      if (!widget.isNewInspection) {
        await _loadTemplateFromStorage();
        _sessionInspectionId ??= _inspectionBox
            ?.get(HiveConstants.CURRENT_INSPECTION_KEY)
            ?.inspectionId;
      }

      // Check if we have a dynamic inspection template from API
      if (widget.inspectionTemplate != null) {
        _inspectionTemplate = widget.inspectionTemplate;
        _useDynamicTemplate = true;
      } else if (_inspectionTemplate == null &&
          vehicleDetails != null &&
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

      // Hive may lack template JSON (older saves / failed serialization). Refetch.
      if (!widget.isNewInspection) {
        await _fetchInspectionTemplateIfMissing();
      }

      if (widget.isNewInspection) {
        await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);
        _initializeValues();
        _initializeControllers();
      } else {
        await _loadDataFromStorage();
        // Persist refetched template + restored answers together for next offline resume.
        if (_inspectionTemplate != null && mounted) {
          await _saveDataLocally();
        }
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
        vehicleDetails: vehicleDetails,
        inspectionTemplate: _inspectionTemplate?.toJson(),
        inspectionId: _effectiveInspectionId,
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
          multiImages: currentData.typedMultiImages,
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

  Future<void> _flushPendingAutoSave() async {
    if (_saveDebouncer?.isActive ?? false) {
      _saveDebouncer?.cancel();
    }

    try {
      await _saveDataLocally();
    } catch (e) {
      print('Error flushing auto save: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _flushPendingAutoSave();
    }
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

  // Load template and vehicle details from storage before building sections
  Future<void> _loadTemplateFromStorage() async {
    try {
      final storedData =
          _inspectionBox?.get(HiveConstants.CURRENT_INSPECTION_KEY);

      if (storedData != null) {
        // Load vehicle details if not already set
        if (vehicleDetails == null && storedData.typedVehicleDetails != null) {
          vehicleDetails = storedData.typedVehicleDetails;
        }

        // Load inspection template if not already set
        if (_inspectionTemplate == null &&
            storedData.typedInspectionTemplate != null) {
          try {
            _inspectionTemplate = InspectionInitializationResponse.fromJson(
              storedData.typedInspectionTemplate!,
            );
            _useDynamicTemplate = true;
          } catch (e) {
            print('Error parsing stored inspection template: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading template from storage: $e');
    }
  }

  /// When continuing an inspection, [Hive] may not contain serialized template
  /// (legacy data or first save before template was in memory). Re-initialize
  /// from API using stored [vehicleDetails] brand/model.
  Future<void> _fetchInspectionTemplateIfMissing() async {
    if (_inspectionTemplate != null) {
      _useDynamicTemplate = true;
      return;
    }

    final vd = vehicleDetails;
    if (vd == null) {
      log('Resume: no vehicle details — cannot refetch inspection template');
      return;
    }

    final brandRaw = vd['brand_id'];
    final modelRaw = vd['model_id'];
    final brandId =
        brandRaw is int ? brandRaw : int.tryParse(brandRaw?.toString() ?? '');
    final modelId =
        modelRaw is int ? modelRaw : int.tryParse(modelRaw?.toString() ?? '');

    if (brandId == null || modelId == null) {
      log('Resume: missing brand_id/model_id — cannot refetch template');
      return;
    }

    final online = await ConnectivityChecker.hasInternetConnection();
    if (!online) {
      log('Resume: offline — cannot refetch inspection template');
      return;
    }

    try {
      final result = await ApiService.initializeInspection(
        vehicleBrandId: brandId,
        vehicleModelId: modelId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        InspectionInitializationResponse? parsed;
        if (data is InspectionInitializationResponse) {
          parsed = data;
        } else if (data is Map<String, dynamic>) {
          try {
            parsed = InspectionInitializationResponse.fromJson(data);
          } catch (e) {
            log('Error parsing refetched inspection template: $e');
          }
        }

        if (parsed != null) {
          _inspectionTemplate = parsed;
          _useDynamicTemplate = true;
        }

        final apiId = result['inspection_id'];
        if (_sessionInspectionId == null && apiId != null) {
          _sessionInspectionId =
              apiId is int ? apiId : int.tryParse(apiId.toString());
        }
      } else {
        log('initializeInspection on resume failed: ${result['message']}');
      }
    } catch (e, st) {
      log('initializeInspection exception on resume: $e', stackTrace: st);
    }
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

  bool _isRegNoField(dynamic item) {
    final field = _getItemFieldId(item).toLowerCase();
    final uid = _getItemUniqueId(item).toLowerCase();
    return field == 'regno' || uid == 'regno';
  }

  bool _regNoResponseHasUsableData(dynamic data) {
    if (data is Map && data.isEmpty) return false;
    if (data is List && data.isEmpty) return false;
    return true;
  }

  Future<void> _verifyRegNo(String uniqueId) async {
    final raw = textFieldControllers[uniqueId]?.text.trim() ?? '';
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a registration number to verify'),
        ),
      );
      return;
    }

    setState(() => _verifyingRegNoUniqueId = uniqueId);

    final result = await ApiService.getVehicleDetails(vehicleNumber: raw);

    if (!mounted) return;

    final success = result['success'] == true;
    final data = result['data'];
    final message = (result['message'] ?? '').toString();

    setState(() {
      _verifyingRegNoUniqueId = null;
      if (success && data != null && _regNoResponseHasUsableData(data)) {
        final String display;
        if (data is Map || data is List) {
          display = const JsonEncoder.withIndent('  ').convert(data);
        } else {
          display = data.toString();
        }
        _regNoVerifyMessage[uniqueId] = display;
        _regNoVerifyIsError[uniqueId] = false;
      } else {
        _regNoVerifyMessage[uniqueId] = message.isNotEmpty
            ? message
            : 'Could not verify registration number';
        _regNoVerifyIsError[uniqueId] = true;
      }
    });
  }

  Widget _buildRegNoVerifyResultCard(String uniqueId) {
    final text = _regNoVerifyMessage[uniqueId];
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final isError = _regNoVerifyIsError[uniqueId] ?? false;
    final theme = Theme.of(context);
    final Color accent =
        isError ? theme.colorScheme.error : const Color(0xFF2E7D32);
    final Color bg = isError
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.45)
        : theme.brightness == Brightness.dark
            ? accent.withValues(alpha: 0.14)
            : accent.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isError ? Icons.error_outline : Icons.verified_outlined,
                      size: 20,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isError
                            ? 'Verification failed'
                            : 'Verified — RC details',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: theme.iconTheme.color?.withValues(alpha: 0.65),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _regNoVerifyMessage.remove(uniqueId);
                          _regNoVerifyIsError.remove(uniqueId);
                        });
                      },
                      tooltip: 'Dismiss',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

    return _buildSingleItemContainer(item, title);
  }

  Widget _buildItemNavigationBar(List<dynamic> items) {
    final canGoPrevious =
        !_isSubmitting && (_currentItemIndex > 0 || _currentSection > 0);
    final canGoNext = !_isSubmitting && items.isNotEmpty;

    final previousLabel = _currentItemIndex == 0 && _currentSection > 0
        ? 'Previous section'
        : 'Previous';

    final String nextLabel;
    if (items.isEmpty) {
      nextLabel = 'Next';
    } else if (_currentItemIndex < items.length - 1) {
      nextLabel = 'Next';
    } else if (_currentSection < _sections.length - 1) {
      nextLabel = 'Next section';
    } else {
      nextLabel = 'Finish';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: canGoPrevious ? _previousItem : null,
            icon: const Icon(Icons.arrow_back),
            label: Text(previousLabel),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: canGoNext ? _nextItem : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(nextLabel),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
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
                    if ((allowImage && !_isImageFieldType(item)) ||
                        allowMultiImage)
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
                    if ((item is Map ? (item['fieldType'] as String?) : null)
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
              ReferenceMediaSectionView(
                mediaList: referenceMedia,
                imageHeight: 110,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InspectionInfoButton(
                  fieldId: uniqueId,
                  referenceMedia: referenceMedia,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_isImageFieldType(item) && itemImages[uniqueId] == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCameraCard(
                    height: 220,
                    borderRadius: BorderRadius.circular(12),
                    instructionText: 'Take a clear photo of: $title',
                    onPickFromGallery: () => _pickImage(
                      ImageSource.gallery,
                      uniqueId,
                      _getItemFieldId(item),
                    ),
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
                          inspectionId: _effectiveInspectionId,
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
                        color: Colors.grey.shade200,
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
                            color: Colors.grey.shade200,
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

    final inputDecoration = InputDecoration(
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
        borderSide:
            BorderSide(color: Theme.of(context).dividerColor.withAlpha(128)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (useTextField && _isRegNoField(item))
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: textFieldControllers[uniqueId],
                  textCapitalization: TextCapitalization.characters,
                  decoration: inputDecoration,
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  onChanged: (value) {
                    setState(() {
                      itemValues[uniqueId] = value;
                      _regNoVerifyMessage.remove(uniqueId);
                      _regNoVerifyIsError.remove(uniqueId);
                    });
                    _autoSave();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _verifyingRegNoUniqueId == uniqueId
                    ? SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => _verifyRegNo(uniqueId),
                        child: const Text('Verify'),
                      ),
              ),
            ],
          ),
        if (useTextField && _isRegNoField(item))
          _buildRegNoVerifyResultCard(uniqueId),
        if (useTextField && !_isRegNoField(item))
          TextField(
            controller: textFieldControllers[uniqueId],
            decoration: inputDecoration,
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
                      child:
                          Text((opt['label'] ?? opt['value'] ?? '').toString()),
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

  Future<bool> _ensureMediaPermission(
    Permission permission, {
    required String permissionName,
  }) async {
    if (!Platform.isIOS) return true;

    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showPermissionDeniedSnackBar(permissionName, openSettings: true);
      return false;
    }

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    _showPermissionDeniedSnackBar(
      permissionName,
      openSettings: status.isPermanentlyDenied || status.isRestricted,
    );
    return false;
  }

  void _showPermissionDeniedSnackBar(
    String permissionName, {
    bool openSettings = false,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$permissionName permission is required to continue.'),
        action: openSettings
            ? SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  openAppSettings();
                },
              )
            : null,
      ),
    );
  }

  Future<void> _pickImage(
      ImageSource source, String uniqueId, String fieldId) async {
    try {
      final hasPermission = source == ImageSource.camera
          ? await _ensureMediaPermission(
              Permission.camera,
              permissionName: 'Camera',
            )
          : await _ensureMediaPermission(
              Permission.photos,
              permissionName: 'Gallery',
            );
      if (!hasPermission) return;

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
            inspectionId: _effectiveInspectionId,
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
      final hasGalleryPermission = await _ensureMediaPermission(
        Permission.photos,
        permissionName: 'Gallery',
      );
      if (!hasGalleryPermission) return;

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
                inspectionId: _effectiveInspectionId,
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
      final hasPhotosPermission = await _ensureMediaPermission(
        Permission.photos,
        permissionName: 'File upload',
      );
      if (!hasPhotosPermission) return;

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
      final hasMicrophonePermission = await _ensureMediaPermission(
        Permission.microphone,
        permissionName: 'Microphone',
      );
      if (!hasMicrophonePermission) return;

      final hasMediaLibraryPermission = await _ensureMediaPermission(
        Permission.mediaLibrary,
        permissionName: 'Media library',
      );
      if (!hasMediaLibraryPermission) return;

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
                leading:
                    const Icon(Icons.video_library, color: Colors.deepPurple),
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
      final hasVideoPermission = source == ImageSource.camera
          ? await _ensureMediaPermission(
              Permission.camera,
              permissionName: 'Camera',
            )
          : await _ensureMediaPermission(
              Permission.photos,
              permissionName: 'Gallery',
            );
      if (!hasVideoPermission) return;

      if (source == ImageSource.camera) {
        final hasMicrophonePermission = await _ensureMediaPermission(
          Permission.microphone,
          permissionName: 'Microphone',
        );
        if (!hasMicrophonePermission) return;
      }

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
        fit: BoxFit.contain,
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
        fit: BoxFit.contain,
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
    if (items.isEmpty) return;
    if (_currentItemIndex < items.length - 1) {
      setState(() {
        _currentItemIndex++;
      });
      _autoSave();
    } else {
      _nextSection();
    }
  }

  void _previousItem() {
    if (_currentItemIndex > 0) {
      setState(() {
        _currentItemIndex--;
      });
      _autoSave();
      return;
    }
    if (_currentSection <= 0) return;

    final prevItems = _sections[_currentSection - 1]['items'] as List<dynamic>;
    final lastIdx = prevItems.isEmpty ? 0 : prevItems.length - 1;

    setState(() {
      _currentSection--;
      _currentItemIndex = lastIdx;
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
          if (_scrollController.hasClients) {
            _isScrollable = _scrollController.position.maxScrollExtent > 0;
            _showButton = !_isScrollable;
          }
        });
      }
    });
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
        Map<String, String?> finalItemVideos = Map.from(itemVideos);
        Map<String, String?> finalItemAudios = Map.from(itemAudios);
        Map<String, String?> finalItemFiles = Map.from(itemFiles);
        // Filter out null values from multiImages
        Map<String, List<String>> finalMultiImages = {};
        itemMultiImages.forEach((key, value) {
          if (value != null && value.isNotEmpty) {
            finalMultiImages[key] = value;
          }
        });
        final body = _buildSubmissionBody();

        await LocalStorageService.saveInspection(
          data: body,
          images: finalItemImages,
          status: 'pending',
          videos: finalItemVideos,
          audios: finalItemAudios,
          files: finalItemFiles,
          multiImages: finalMultiImages,
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
          Map<String, String?> finalItemVideos = Map.from(itemVideos);
          Map<String, String?> finalItemAudios = Map.from(itemAudios);
          Map<String, String?> finalItemFiles = Map.from(itemFiles);
          // Filter out null values from multiImages
          Map<String, List<String>> finalMultiImages = {};
          itemMultiImages.forEach((key, value) {
            if (value != null && value.isNotEmpty) {
              finalMultiImages[key] = value;
            }
          });
          await LocalStorageService.saveInspection(
            data: _buildSubmissionBody(),
            images: finalItemImages,
            status: 'pending',
            videos: finalItemVideos,
            audios: finalItemAudios,
            files: finalItemFiles,
            multiImages: finalMultiImages,
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
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load inspection form',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connect to the internet and try again, or go back and start a new inspection. '
                    'If you were resuming a saved inspection, your answers stay on this device once the form loads.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      setState(() => _isLoadingTemplate = true);
                      await _fetchInspectionTemplateIfMissing();
                      if (!mounted) return;
                      if (_inspectionTemplate != null) {
                        await _loadDataFromStorage();
                        await _saveDataLocally();
                      }
                      setState(() => _isLoadingTemplate = false);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
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
          toolbarHeight: 60,
          title: InspectionAppBarTitle(
            sectionTitle: _sections[_currentSection]['title'] as String,
            itemCount:
                (_sections[_currentSection]['items'] as List<dynamic>).length,
            currentItemIndex: _currentItemIndex,
            sectionIcon:
                _getSectionIcon(_sections[_currentSection]['title'] as String),
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
          automaticallyImplyLeading: false,
        ),
        endDrawer: _buildDrawer(),
        body: Column(
          children: [
            InspectionProgressHeader(
              currentSection: _currentSection,
              totalSections: _sections.length,
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
                ],
              ),
            ),
            InspectionBottomActions(
              isSubmitting: _isSubmitting,
              isLastSection: _currentSection == _sections.length - 1,
              onSubmitInspection: _nextSection,
              itemNavigationBar: _buildItemNavigationBar(
                currentSection['items'] as List<dynamic>,
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
    return InspectionSectionsDrawer(
      sections: _sections,
      currentSection: _currentSection,
      isSectionComplete: _isSectionComplete,
      getSectionIcon: _getSectionIcon,
      onSelectSection: (index) {
        setState(() {
          _currentSection = index;
          _currentItemIndex = 0;
          _isScrollable = false;
          _showButton = true;
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            _isScrollable = _scrollController.position.maxScrollExtent > 0;
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
    WidgetsBinding.instance.removeObserver(this);
    _saveDebouncer?.cancel();
    _flushPendingAutoSave();
    _scrollController.dispose();
    _cleanupControllers();
    _isSubmitting = false;
    _rewardedAdManager.dispose();
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
