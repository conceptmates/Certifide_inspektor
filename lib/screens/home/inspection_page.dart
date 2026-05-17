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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../constants/hive_constants.dart';
import '../../data/inspection_storage_model.dart';
import '../../models/inspection_item.dart';
import '../../models/inspection_template_model.dart';
import '../../providers/inspection_provider.dart';
import '../../providers/inspection_session_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_services.dart';
import '../../services/local_storage_services.dart';
import '../../services/reports_cache_service.dart';
import '../../utils/connectivity_checker.dart';
import '../../widgets/inspection_field_info_sheet.dart';
import '../../widgets/section_camera_card.dart';
import '../../widgets/section_video_camera_card.dart';
import '../main_screen.dart';
import 'inspection_page/components/inspection_flag_issues_sheet.dart';
import 'inspection_page/components/inspection_image_review.dart';
import 'inspection_page/components/inspection_video_review.dart';
import 'inspection_page/components/inspection_reference_fullscreen.dart';
import 'inspection_page/components/inspection_sections_drawer.dart';
import 'inspection_page/components/inspection_video_player.dart';
import 'inspection_success_page.dart';
import '../../utils/ads manager/rewarded_interstitial_ad.dart';

class InspectionScreen extends ConsumerStatefulWidget {
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
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen>
    with WidgetsBindingObserver {
  // Survives navigation — keyed by "${brandId}_${modelId}"
  static final Map<String, InspectionInitializationResponse> _templateCache =
      {};

  // Set true on successful submit so dispose() doesn't snapshot a dead session.
  bool _sessionCompleted = false;

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
  final Set<String> _uploadingImages = {};
  String? _verifyingRegNoUniqueId;
  final Map<String, String> _regNoVerifyMessage = {};
  final Map<String, bool> _regNoVerifyIsError = {};
  Map<String, List<String>> itemFlaggedIssues = {};
  XFile? _pendingCapturedXFile;
  String? _pendingCapturedUniqueId;
  bool _isReviewingCapture = false;
  XFile? _pendingCapturedVideoFile;
  String? _pendingCapturedVideoUniqueId;
  bool _isReviewingVideo = false;
  String? _pendingCapturedAudioPath;
  String? _pendingCapturedAudioUniqueId;
  bool _isReviewingAudio = false;
  String _currentCaptureMode = 'PHOTO';
  // Bound to SectionCameraCard when showControls:false; resets on item change.
  VoidCallback? _triggerPhotoCapture;
  VoidCallback? _triggerEnlarge;
  VoidCallback? _triggerVideoToggle;
  bool _isVideoRecording = false;
  AudioRecorder? _audioRecorder;
  bool _isRecordingAudio = false;
  Timer? _audioTimer;
  Duration _audioElapsed = Duration.zero;
  bool _highlightFlagIssues = false;

  // Dynamic inspection template from API
  InspectionInitializationResponse? _inspectionTemplate;
  bool _useDynamicTemplate = false;
  bool _isLoadingTemplate = true; // Track if template is still loading

  /// Server inspection id: from route, Hive snapshot, or refetch when resuming.
  int? _sessionInspectionId;

  int? get _effectiveInspectionId =>
      _sessionInspectionId ?? widget.inspectionId;

  int get _totalFields =>
      _sections.fold(0, (sum, s) => sum + (s['items'] as List).length);

  int get _processedFields {
    int count = 0;
    for (int i = 0; i < _currentSection; i++) {
      count += (_sections[i]['items'] as List).length;
    }
    return count + _currentItemIndex + 1;
  }

  int get _progressPercent {
    if (_totalFields == 0) return 0;
    return ((_processedFields / _totalFields) * 100).round();
  }

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

      if (!mounted) return;

      _sessionInspectionId = widget.inspectionId;

      // Set vehicle details from widget
      vehicleDetails = widget.vehicleDetails;

      if (widget.isNewInspection) {
        // Fresh start — discard any leftover session from a previous run.
        ref.read(inspectionSessionNotifierProvider.notifier).clearSession();
        await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);
        if (!mounted) return;
        // Load the API template (with sections, fields, and options) for new inspections.
        if (widget.inspectionTemplate != null) {
          _inspectionTemplate = widget.inspectionTemplate;
          _useDynamicTemplate = true;
        }
        _initializeValues();
        _initializeControllers();
      } else {
        // Resume path: prefer in-memory snapshot over Hive to avoid I/O.
        final snap = ref.read(inspectionSessionNotifierProvider);
        if (snap != null) {
          _restoreFromSnapshot(snap);
        } else {
          // If continuing a previous inspection, load template from storage first
          await _loadTemplateFromStorage();
          _sessionInspectionId ??= _inspectionBox
              ?.get(HiveConstants.CURRENT_INSPECTION_KEY)
              ?.inspectionId;

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
                  _inspectionTemplate =
                      InspectionInitializationResponse.fromJson(
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
          final hadTemplate = _inspectionTemplate != null;
          await _fetchInspectionTemplateIfMissing();
          final templateWasRefetched =
              !hadTemplate && _inspectionTemplate != null;

          await _loadDataFromStorage();
          // Only re-save when a new template was fetched so future offline resumes
          // find template + answers together in Hive.
          if (templateWasRefetched && mounted) {
            await _saveDataLocally();
          }
        }
      }

      // Load rewarded interstitial ad
      _rewardedAdManager.loadRewardedInterstitialAd();

      // Request camera + mic permissions while the loading screen is still
      // shown so the camera card renders with permissions already resolved.
      await _requestInspectionPermissions();

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

  /// Requests camera and microphone permissions while the loading screen is
  /// shown so the camera card never races with a permission dialog.
  Future<void> _requestInspectionPermissions() async {
    if (!Platform.isIOS) return;
    final camStatus = await Permission.camera.status;
    if (!camStatus.isGranted &&
        !camStatus.isPermanentlyDenied &&
        !camStatus.isRestricted) {
      await Permission.camera.request();
    }
    if (!mounted) return;
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted &&
        !micStatus.isPermanentlyDenied &&
        !micStatus.isRestricted) {
      await Permission.microphone.request();
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

    final cacheKey = '${brandId}_$modelId';
    final cached = _templateCache[cacheKey];
    if (cached != null) {
      _inspectionTemplate = cached;
      _useDynamicTemplate = true;
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
          _templateCache[cacheKey] = parsed;
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

  void _restoreFromSnapshot(InspectionSessionSnapshot snap) {
    _inspectionTemplate = snap.inspectionTemplate;
    _useDynamicTemplate = snap.useDynamicTemplate;
    _sessionInspectionId = snap.sessionInspectionId;
    vehicleDetails ??= snap.vehicleDetails;
    setState(() {
      itemValues = Map.from(snap.itemValues);
      itemImages = Map.from(snap.itemImages);
      itemVideos = Map.from(snap.itemVideos);
      itemAudios = Map.from(snap.itemAudios);
      itemFiles = Map.from(snap.itemFiles);
      itemRemarks = Map.from(snap.itemRemarks);
      itemMultiImages = Map.from(snap.itemMultiImages);
      itemFlaggedIssues = Map.from(snap.itemFlaggedIssues);
      _currentSection = snap.currentSection;
      _currentItemIndex = snap.currentItemIndex;
    });
    _initializeControllers();
  }

  Future<void> _loadDataFromStorage() async {
    try {
      final storedData =
          _inspectionBox?.get(HiveConstants.CURRENT_INSPECTION_KEY);

      if (storedData != null) {
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
        _initializeControllers();
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
      _sessionCompleted = true;
      ref.read(inspectionSessionNotifierProvider.notifier).clearSession();

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

  String _defaultCaptureModeForItem(dynamic item) {
    final refMedia = _getItemReferenceMedia(item);
    if (refMedia.isNotEmpty) {
      final refType =
          (refMedia.first['mediaType'] as String? ?? '').toLowerCase();
      if (refType == 'image') return 'PHOTO';
      if (refType == 'video') return 'VIDEO';
    }
    if (_itemHasImage(item)) return 'PHOTO';
    if (_itemHasVideo(item)) return 'VIDEO';
    if (_itemHasFile(item)) return 'FILE';
    return 'PHOTO';
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

  String _getItemFieldType(dynamic item) {
    if (item is Map) {
      return (item['fieldType'] as String?)?.toLowerCase() ?? 'text';
    }
    return 'text';
  }

  static IconData _fieldTypeIcon(dynamic item) {
    final type = item is Map
        ? (item['fieldType'] as String?)?.toLowerCase() ?? 'text'
        : 'text';
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'dropdown':
        return Icons.arrow_drop_down_circle_outlined;
      case 'file':
        return Icons.attach_file_outlined;
      case 'audio':
        return Icons.audiotrack_outlined;
      default:
        return Icons.text_fields_outlined;
    }
  }

  static Color _fieldTypeColor(dynamic item) {
    final type = item is Map
        ? (item['fieldType'] as String?)?.toLowerCase() ?? 'text'
        : 'text';
    switch (type) {
      case 'image':
        return const Color(0xFF4D9EFF);
      case 'video':
        return const Color(0xFFA855F7);
      case 'dropdown':
        return const Color(0xFFF97316);
      case 'file':
        return const Color(0xFF22C55E);
      case 'audio':
        return const Color(0xFFEC4899);
      default:
        return Colors.grey;
    }
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

  Widget _buildSingleItemContainer(dynamic item, String sectionTitle) {
    final uniqueId = _getItemUniqueId(item);
    final title = _getItemTitle(item);
    final allowImage = _itemHasImage(item);
    final allowMultiImage = _itemHasMultiImage(item);
    final isRequired = _itemIsRequired(item);
    final referenceMedia = _getItemReferenceMedia(item);
    final flaggedIssues = itemFlaggedIssues[uniqueId] ?? [];
    final hasFlaggableOptions = _itemHasOptions(item) &&
        !_itemHasImage(item) &&
        !_itemHasVideo(item);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isRequired
              ? Colors.orange.withValues(alpha: 0.5)
              : const Color(0xFFE4E7EB),
          width: isRequired ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _fieldTypeColor(item).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _fieldTypeIcon(item),
                    color: _fieldTypeColor(item),
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
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
                      const SizedBox(height: 2),
                      Text(
                        _getItemFieldType(item),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
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
                        color: const Color(0xFF4D9EFF),
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
                        color: const Color(0xFFA855F7),
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
                        color: const Color(0xFF22C55E),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _showFilePickerOptions(item),
                      ),
                    if ((item is Map ? (item['fieldType'] as String?) : null)
                            ?.toLowerCase() ==
                        'audio')
                      IconButton(
                        icon: const Icon(Icons.audio_file, size: 22),
                        color: const Color(0xFFF97316),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _showAudioPickerOptions(item),
                      ),
                    if (hasFlaggableOptions)
                      IconButton(
                        icon: Icon(
                          flaggedIssues.isNotEmpty
                              ? Icons.flag
                              : Icons.flag_outlined,
                          size: 22,
                        ),
                        color: flaggedIssues.isNotEmpty
                            ? Colors.orange
                            : Colors.grey[500],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _showFlagIssuesSheet(item),
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
                maxItems: 1,
                trailing: InspectionInfoButton(
                  fieldId: uniqueId,
                  referenceMedia: referenceMedia,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_itemHasImage(item) && itemImages[uniqueId] == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCameraCard(
                    key: ValueKey('camera_$uniqueId'),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 120,
                          maxHeight: 400,
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          child: _buildImageWidget(itemImages[uniqueId]!),
                        ),
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
                                  child: _buildImageWidget(imagePath,
                                      fit: BoxFit.cover),
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
            if (_itemHasVideo(item) && itemVideos[uniqueId] == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionVideoCameraCard(
                    key: ValueKey('video_$uniqueId'),
                    height: 220,
                    borderRadius: BorderRadius.circular(12),
                    instructionText: 'Record a video of: $title',
                    onPickFromGallery: () =>
                        _pickVideo(item, ImageSource.gallery),
                    onCapture: (XFile file) {
                      setState(() {
                        _pendingCapturedVideoFile = file;
                        _pendingCapturedVideoUniqueId = uniqueId;
                        _isReviewingVideo = true;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
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
            if (hasFlaggableOptions && flaggedIssues.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: flaggedIssues.map((issue) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag,
                            size: 11, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          issue,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
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
            initialValue:
                itemValues[uniqueId] == 'N/A' ? null : itemValues[uniqueId],
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

  String _formatAudioDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startAudioRecording(dynamic item) async {
    final uniqueId = _getItemUniqueId(item);
    final hasMicPerm = await _ensureMediaPermission(
      Permission.microphone,
      permissionName: 'Microphone',
    );
    if (!hasMicPerm) return;
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/audio_${uniqueId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _audioRecorder ??= AudioRecorder();
      await _audioRecorder!.start(const RecordConfig(), path: path);
      _audioElapsed = Duration.zero;
      _audioTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _audioElapsed += const Duration(seconds: 1));
        }
      });
      if (mounted) setState(() => _isRecordingAudio = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopAudioRecording(dynamic item) async {
    final uniqueId = _getItemUniqueId(item);
    _audioTimer?.cancel();
    _audioTimer = null;
    try {
      final path = await _audioRecorder?.stop();
      if (mounted) {
        setState(() {
          _isRecordingAudio = false;
          if (path != null) {
            _pendingCapturedAudioPath = path;
            _pendingCapturedAudioUniqueId = uniqueId;
            _isReviewingAudio = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecordingAudio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
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
          _pendingCapturedAudioPath = result.files.single.path!;
          _pendingCapturedAudioUniqueId = uniqueId;
          _isReviewingAudio = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick audio: $e')),
        );
      }
    }
  }

  Future<void> _discardAllMedia(dynamic item) async {
    final uniqueId = _getItemUniqueId(item);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard all media?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
          'This will remove the photo, video, audio, and any attached file for this item.',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard',
                style: TextStyle(
                    color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        itemImages[uniqueId] = null;
        itemVideos[uniqueId] = null;
        itemAudios[uniqueId] = null;
        itemFiles[uniqueId] = null;
        itemMultiImages[uniqueId] = [];
      });
      _autoSave();
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

  void _showAudioPickerOptions(dynamic item) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.mic, color: Color(0xFFF97316)),
                title: const Text('Record Audio'),
                onTap: () {
                  Navigator.pop(context);
                  _startAudioRecording(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.audio_file, color: Color(0xFFF97316)),
                title: const Text('Browse Audio Files'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAudio(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilePickerOptions(dynamic item) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.attach_file, color: Color(0xFF22C55E)),
                title: const Text('Browse Files'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(item);
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
          _pendingCapturedVideoFile = video;
          _pendingCapturedVideoUniqueId = uniqueId;
          _isReviewingVideo = true;
        });
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

  Widget _buildImageWidget(String imagePath, {BoxFit fit = BoxFit.fitWidth}) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: fit,
        width: double.infinity,
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
        fit: fit,
        width: double.infinity,
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

  Future<void> _acceptCapturedImage() async {
    final file = _pendingCapturedXFile;
    final uniqueId = _pendingCapturedUniqueId;
    if (file == null || uniqueId == null) return;

    setState(() {
      _isReviewingCapture = false;
      _pendingCapturedXFile = null;
      _pendingCapturedUniqueId = null;
    });

    final item = (_sections[_currentSection]['items']
        as List<dynamic>)[_currentItemIndex];
    final fieldId = _getItemFieldId(item);
    final sectionTitle = _sections[_currentSection]['title'] as String;
    final savedPath = await LocalStorageService.saveImage(file.path);

    setState(() {
      itemImages[uniqueId] = savedPath;
      _uploadingImages.add(uniqueId);
    });
    await _saveDataLocally();

    final bool hasInternet = await ConnectivityChecker.hasInternetConnection();
    if (hasInternet) {
      final result = await ApiService.uploadImage(
        savedPath,
        inspectionId: _effectiveInspectionId,
        section: sectionTitle,
        itemId: fieldId,
      );
      if (mounted) {
        setState(() => _uploadingImages.remove(uniqueId));
        if (result['success']) {
          setState(() => itemImages[uniqueId] = result['url'] as String);
          await _saveDataLocally();
        }
      }
    } else {
      if (mounted) setState(() => _uploadingImages.remove(uniqueId));
    }
  }

  Future<void> _acceptCapturedVideo() async {
    final file = _pendingCapturedVideoFile;
    final uniqueId = _pendingCapturedVideoUniqueId;
    if (file == null || uniqueId == null) return;

    String sectionTitle = '';
    String fieldId = '';
    for (final section in _sections) {
      for (final item in section['items'] as List<dynamic>) {
        if (_getItemUniqueId(item) == uniqueId) {
          sectionTitle = section['title'] as String;
          fieldId = _getItemFieldId(item);
          break;
        }
      }
      if (sectionTitle.isNotEmpty) break;
    }

    setState(() {
      _isReviewingVideo = false;
      _pendingCapturedVideoFile = null;
      _pendingCapturedVideoUniqueId = null;
      itemVideos[uniqueId] = file.path;
      _uploadingImages.add(uniqueId);
    });

    await _saveDataLocally();

    final bool hasInternet = await ConnectivityChecker.hasInternetConnection();
    if (hasInternet && sectionTitle.isNotEmpty) {
      final result = await ApiService.uploadImage(
        file.path,
        inspectionId: _effectiveInspectionId,
        section: sectionTitle,
        itemId: fieldId,
        fieldName: 'image',
      );
      if (mounted) {
        setState(() => _uploadingImages.remove(uniqueId));
        if (result['success']) {
          setState(() => itemVideos[uniqueId] = result['url'] as String);
          await _saveDataLocally();
        }
      }
    } else {
      if (mounted) setState(() => _uploadingImages.remove(uniqueId));
    }
  }

  Future<void> _acceptCapturedAudio() async {
    final path = _pendingCapturedAudioPath;
    final uniqueId = _pendingCapturedAudioUniqueId;
    if (path == null || uniqueId == null) return;

    String sectionTitle = '';
    String fieldId = '';
    for (final section in _sections) {
      for (final item in section['items'] as List<dynamic>) {
        if (_getItemUniqueId(item) == uniqueId) {
          sectionTitle = section['title'] as String;
          fieldId = _getItemFieldId(item);
          break;
        }
      }
      if (sectionTitle.isNotEmpty) break;
    }

    setState(() {
      _isReviewingAudio = false;
      _pendingCapturedAudioPath = null;
      _pendingCapturedAudioUniqueId = null;
      itemAudios[uniqueId] = path;
      _uploadingImages.add(uniqueId);
    });

    await _saveDataLocally();

    final bool hasInternet = await ConnectivityChecker.hasInternetConnection();
    if (hasInternet && sectionTitle.isNotEmpty) {
      final result = await ApiService.uploadImage(
        path,
        inspectionId: _effectiveInspectionId,
        section: sectionTitle,
        itemId: fieldId,
        fieldName: 'image',
      );
      if (mounted) {
        setState(() => _uploadingImages.remove(uniqueId));
        if (result['success']) {
          setState(() => itemAudios[uniqueId] = result['url'] as String);
          await _saveDataLocally();
        }
      }
    } else {
      if (mounted) setState(() => _uploadingImages.remove(uniqueId));
    }
  }

  bool _checkCurrentItemFlagIssue() {
    final currentSection = _sections[_currentSection];
    final items = currentSection['items'] as List<dynamic>;
    if (items.isEmpty) return true;

    final currentItem = items[_currentItemIndex];
    if (!(_itemHasImage(currentItem) || _itemHasVideo(currentItem))) return true;

    final uniqueId = _getItemUniqueId(currentItem);
    final hasMedia = (itemImages[uniqueId] != null) ||
        (itemVideos[uniqueId] != null) ||
        (itemFiles[uniqueId] != null) ||
        (itemAudios[uniqueId] != null);
    if (!hasMedia) return true;

    final conditionValue = itemValues[uniqueId] ?? '';
    final issueMarked =
        conditionValue == 'no_issues' || conditionValue == 'flagged';
    if (!issueMarked) {
      setState(() => _highlightFlagIssues = true);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please flag an issue or mark as no issues before proceeding'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }

  void _nextItem() {
    if (_isReviewingCapture) {
      setState(() {
        _isReviewingCapture = false;
        _pendingCapturedXFile = null;
        _pendingCapturedUniqueId = null;
      });
      return;
    }
    if (_isReviewingVideo) {
      setState(() {
        _isReviewingVideo = false;
        _pendingCapturedVideoFile = null;
        _pendingCapturedVideoUniqueId = null;
      });
      return;
    }
    if (_isReviewingAudio) {
      setState(() {
        _isReviewingAudio = false;
        _pendingCapturedAudioPath = null;
        _pendingCapturedAudioUniqueId = null;
      });
      return;
    }
    if (!_checkCurrentItemFlagIssue()) return;
    setState(() => _highlightFlagIssues = false);
    final currentSection = _sections[_currentSection];
    final items = currentSection['items'] as List<dynamic>;
    if (items.isEmpty) return;
    if (_currentItemIndex < items.length - 1) {
      _audioTimer?.cancel();
      _audioTimer = null;
      _audioRecorder?.stop();
      final nextItem = items[_currentItemIndex + 1];
      setState(() {
        _currentItemIndex++;
        _currentCaptureMode = _defaultCaptureModeForItem(nextItem);
        _triggerPhotoCapture = null;
        _triggerEnlarge = null;
        _triggerVideoToggle = null;
        _isVideoRecording = false;
        _isRecordingAudio = false;
        _audioElapsed = Duration.zero;
      });
      _autoSave();
    } else {
      _nextSection();
    }
  }

  void _previousItem() {
    if (_isReviewingCapture) {
      setState(() {
        _isReviewingCapture = false;
        _pendingCapturedXFile = null;
        _pendingCapturedUniqueId = null;
      });
      return;
    }
    if (_isReviewingVideo) {
      setState(() {
        _isReviewingVideo = false;
        _pendingCapturedVideoFile = null;
        _pendingCapturedVideoUniqueId = null;
      });
      return;
    }
    if (_isReviewingAudio) {
      setState(() {
        _isReviewingAudio = false;
        _pendingCapturedAudioPath = null;
        _pendingCapturedAudioUniqueId = null;
      });
      return;
    }
    if (_currentItemIndex > 0) {
      _audioTimer?.cancel();
      _audioTimer = null;
      _audioRecorder?.stop();
      final currentItems = _sections[_currentSection]['items'] as List<dynamic>;
      final prevItem = currentItems[_currentItemIndex - 1];
      setState(() {
        _currentItemIndex--;
        _currentCaptureMode = _defaultCaptureModeForItem(prevItem);
        _triggerPhotoCapture = null;
        _triggerEnlarge = null;
        _triggerVideoToggle = null;
        _isVideoRecording = false;
        _isRecordingAudio = false;
        _audioElapsed = Duration.zero;
        _highlightFlagIssues = false;
      });
      _autoSave();
      return;
    }
    if (_currentSection <= 0) return;

    final prevItems = _sections[_currentSection - 1]['items'] as List<dynamic>;
    final lastIdx = prevItems.isEmpty ? 0 : prevItems.length - 1;
    final lastItem = prevItems.isNotEmpty ? prevItems[lastIdx] : null;

    setState(() {
      _currentSection--;
      _currentItemIndex = lastIdx;
      _showButton = false;
      _isScrollable = false;
      if (lastItem != null)
        _currentCaptureMode = _defaultCaptureModeForItem(lastItem);
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
    if (!_checkCurrentItemFlagIssue()) return;
    setState(() => _highlightFlagIssues = false);
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
      _audioTimer?.cancel();
      _audioTimer = null;
      _audioRecorder?.stop();
      final nextSectionItems =
          _sections[_currentSection + 1]['items'] as List<dynamic>;
      final firstNextItem =
          nextSectionItems.isNotEmpty ? nextSectionItems.first : null;
      setState(() {
        _currentSection++;
        _currentItemIndex = 0;
        _showButton = false;
        _isScrollable = false;
        _currentCaptureMode = firstNextItem != null
            ? _defaultCaptureModeForItem(firstNextItem)
            : 'PHOTO';
        _triggerPhotoCapture = null;
        _triggerEnlarge = null;
        _triggerVideoToggle = null;
        _isVideoRecording = false;
        _isRecordingAudio = false;
        _audioElapsed = Duration.zero;
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
            } else {
              _isScrollable = false;
            }
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

  /// Uploads any images that are still local paths (capture-time upload failed).
  /// Runs before submission so the backend always receives URLs, not local paths.
  Future<void> _uploadRemainingImages() async {
    for (var section in _sections) {
      final sectionTitle = section['title'] as String;
      for (var item in section['items'] as List<dynamic>) {
        final uniqueId = _getItemUniqueId(item);
        final fieldId = _getItemFieldId(item);

        final imagePath = itemImages[uniqueId];
        if (imagePath != null && !imagePath.startsWith('http')) {
          if (mounted) setState(() => _uploadingImages.add(uniqueId));
          final result = await ApiService.uploadImage(
            imagePath,
            inspectionId: _effectiveInspectionId,
            section: sectionTitle,
            itemId: fieldId,
          );
          if (mounted) {
            setState(() {
              _uploadingImages.remove(uniqueId);
              if (result['success'] == true) {
                itemImages[uniqueId] = result['url'] as String;
              }
            });
          }
        }

        final multiImages = itemMultiImages[uniqueId];
        if (multiImages != null && multiImages.isNotEmpty) {
          final List<String> updated = [];
          for (final path in multiImages) {
            if (!path.startsWith('http')) {
              final result = await ApiService.uploadImage(
                path,
                inspectionId: _effectiveInspectionId,
                section: sectionTitle,
                itemId: fieldId,
              );
              updated.add(
                result['success'] == true ? result['url'] as String : path,
              );
            } else {
              updated.add(path);
            }
          }
          if (mounted) setState(() => itemMultiImages[uniqueId] = updated);
        }

        final videoPath = itemVideos[uniqueId];
        if (videoPath != null && !videoPath.startsWith('http')) {
          if (mounted) setState(() => _uploadingImages.add(uniqueId));
          final result = await ApiService.uploadImage(
            videoPath,
            inspectionId: _effectiveInspectionId,
            section: sectionTitle,
            itemId: fieldId,
            fieldName: 'image',
          );
          if (mounted) {
            setState(() {
              _uploadingImages.remove(uniqueId);
              if (result['success'] == true) {
                itemVideos[uniqueId] = result['url'] as String;
              }
            });
          }
        }

        final audioPath = itemAudios[uniqueId];
        if (audioPath != null && !audioPath.startsWith('http')) {
          if (mounted) setState(() => _uploadingImages.add(uniqueId));
          final result = await ApiService.uploadImage(
            audioPath,
            inspectionId: _effectiveInspectionId,
            section: sectionTitle,
            itemId: fieldId,
            fieldName: 'image',
          );
          if (mounted) {
            setState(() {
              _uploadingImages.remove(uniqueId);
              if (result['success'] == true) {
                itemAudios[uniqueId] = result['url'] as String;
              }
            });
          }
        }
      }
    }
    await _saveDataLocally();
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
        if (mounted) {
          ref.read(inspectionNotifierProvider.notifier).markDirty();
        }

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
        await _uploadRemainingImages();
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
            ref.read(inspectionNotifierProvider.notifier).markDirty();
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
          initialIndex: ref.read(userNotifierProvider).isAdmin() ? 3 : 2,
        ),
      ),
    );
  }

  void _showFlagIssuesSheet(dynamic item) {
    final uniqueId = _getItemUniqueId(item);
    final sectionTitle = _sections[_currentSection]['title'] as String;
    final currentIssues = itemFlaggedIssues[uniqueId] ?? [];
    final currentNotes = itemRemarks[uniqueId] ?? '';

    // For fields that are pure dropdowns (have options, no image/video capture),
    // don't overwrite the dropdown's selected value when flagging issues.
    final isPureDropdownField = _itemHasOptions(item) &&
        !_itemHasImage(item) &&
        !_itemHasVideo(item);

    final List<String> availableIssues = [];
    final Map<String, Color> issueColors = {};
    if (item is Map) {
      final opts = item['options'] as List?;
      if (opts != null) {
        for (final opt in opts) {
          final lbl = opt['label']?.toString() ?? '';
          final val = opt['value']?.toString() ?? '';
          final label = lbl.isNotEmpty ? lbl : val;
          if (label.isNotEmpty) {
            availableIssues.add(label);
            final colorCode = opt['colorCode']?.toString() ?? '';
            if (colorCode.isNotEmpty) {
              try {
                final hex =
                    colorCode.startsWith('#') ? colorCode.substring(1) : colorCode;
                issueColors[label] =
                    Color(int.parse('FF$hex', radix: 16));
              } catch (_) {}
            }
          }
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: InspectionFlagIssuesSheet(
          sectionTitle: sectionTitle,
          selectedIssues: currentIssues,
          notes: currentNotes,
          availableIssues: availableIssues,
          issueColors: issueColors.isEmpty ? null : issueColors,
          onConfirm: (issues, notes, markedNoIssues) {
            setState(() {
              _highlightFlagIssues = false;
              if (markedNoIssues) {
                itemFlaggedIssues[uniqueId] = [];
                if (!isPureDropdownField) itemValues[uniqueId] = 'no_issues';
              } else {
                itemFlaggedIssues[uniqueId] = issues;
                if (!isPureDropdownField) {
                  itemValues[uniqueId] = issues.isEmpty ? '' : 'flagged';
                }
              }
              if (notes.isNotEmpty) {
                remarksControllers[uniqueId]?.text = notes;
                itemRemarks[uniqueId] = notes;
              }
            });
            _autoSave();
          },
        ),
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  PreferredSizeWidget _buildDarkAppBar(Map<String, dynamic> currentSection) {
    final sectionTitle = currentSection['title'] as String;
    final items = currentSection['items'] as List<dynamic>;
    final itemTitle = (items.isNotEmpty && _currentItemIndex < items.length)
        ? (items[_currentItemIndex]['title'] as String? ?? sectionTitle)
        : sectionTitle;
    final subtitle =
        'Field ${_currentItemIndex + 1} out ${items.length} • Section ${_currentSection + 1}/${_sections.length}';

    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              '$_progressPercent% Complete',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Stop Inspection?'),
                  content: const Text(
                    'Your progress will be saved and you can continue later.',
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
          icon: const Icon(Icons.close, color: Colors.white60, size: 22),
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white60, size: 22),
          onPressed: _openDrawer,
        ),
      ],
    );
  }

  Widget _buildDarkNavBar(List<dynamic> items) {
    final canGoPrevious =
        !_isSubmitting && (_currentItemIndex > 0 || _currentSection > 0);
    final canGoNext = !_isSubmitting && items.isNotEmpty;

    final bool isLast = _currentItemIndex == items.length - 1 &&
        _currentSection == _sections.length - 1;

    return Container(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canGoPrevious ? _previousItem : null,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white30,
                    side: BorderSide(
                      color: canGoPrevious ? Colors.white30 : Colors.white12,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      canGoNext ? (isLast ? _nextSection : _nextItem) : null,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(isLast ? 'Finish' : 'Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF448AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullscreenReferenceImage(
      List<Map<String, dynamic>> referenceMedia, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => InspectionReferenceFullscreen(
        mediaList: referenceMedia,
        initialIndex: initialIndex,
      ),
    );
  }

  Widget _buildImageFieldView(dynamic item) {
    final uniqueId = _getItemUniqueId(item);
    final title = _getItemTitle(item);
    final referenceMedia = _getItemReferenceMedia(item);
    final fieldId = _getItemFieldId(item);
    final hasCapturedPhoto = itemImages[uniqueId] != null;
    final hasCapturedVideo = itemVideos[uniqueId] != null;
    final hasAttachedFile = itemFiles[uniqueId] != null;
    final hasRecordedAudio = itemAudios[uniqueId] != null;
    final flaggedIssues = itemFlaggedIssues[uniqueId] ?? [];
    final conditionValue = itemValues[uniqueId] ?? '';
    final isUploading = _uploadingImages.contains(uniqueId);
    final refUrl = referenceMedia.isNotEmpty
        ? (referenceMedia.first['url'] as String? ?? '')
        : '';
    final refMediaType = referenceMedia.isNotEmpty
        ? (referenceMedia.first['mediaType'] as String? ?? 'image')
        : 'image';

    // Build the main capture area based on current mode
    Widget captureArea;
    if (_currentCaptureMode == 'PHOTO') {
      if (hasCapturedPhoto) {
        captureArea = GestureDetector(
          onTap: () => _showImagePreview(itemImages[uniqueId]!),
          child: _buildImageWidget(itemImages[uniqueId]!, fit: BoxFit.cover),
        );
      } else {
        captureArea = LayoutBuilder(
          builder: (ctx, constraints) => SectionCameraCard(
            key: ValueKey('cam_$uniqueId'),
            height: constraints.maxHeight,
            borderRadius: BorderRadius.zero,
            showControls: false,
            onCaptureReady: (fn) => setState(() => _triggerPhotoCapture = fn),
            onEnlargeReady: (fn) => setState(() => _triggerEnlarge = fn),
            onPickFromGallery: () =>
                _pickImage(ImageSource.gallery, uniqueId, fieldId),
            onCapture: (XFile file) {
              setState(() {
                _pendingCapturedXFile = file;
                _pendingCapturedUniqueId = uniqueId;
                _isReviewingCapture = true;
              });
            },
          ),
        );
      }
    } else if (_currentCaptureMode == 'VIDEO') {
      if (hasCapturedVideo) {
        captureArea = InspectionVideoPlayer(
          key: ValueKey('vplay_$uniqueId'),
          videoPath: itemVideos[uniqueId]!,
          onReRecord: () => _showVideoPickerOptions(item),
          onDiscard: () => _discardAllMedia(item),
        );
      } else {
        captureArea = LayoutBuilder(
          builder: (ctx, constraints) => SectionVideoCameraCard(
            key: ValueKey('vid_$uniqueId'),
            height: constraints.maxHeight,
            borderRadius: BorderRadius.zero,
            showControls: false,
            onRecordingToggleReady: (fn) =>
                setState(() => _triggerVideoToggle = fn),
            onRecordingChanged: (recording) =>
                setState(() => _isVideoRecording = recording),
            onPickFromGallery: () => _pickVideo(item, ImageSource.gallery),
            onCapture: (XFile file) {
              setState(() {
                _pendingCapturedVideoFile = file;
                _pendingCapturedVideoUniqueId = uniqueId;
                _isReviewingVideo = true;
                _isVideoRecording = false;
              });
            },
          ),
        );
      }
    } else if (_currentCaptureMode == 'FILE') {
      if (hasAttachedFile) {
        // File attached — show info on dark background
        captureArea = Container(
          color: const Color(0xFF111111),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insert_drive_file,
                      color: Color(0xFF4D9EFF), size: 64),
                  const SizedBox(height: 14),
                  Text(
                    _extractFileName(itemFiles[uniqueId]!),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // No file — clean dark bg with faint icon; action button is in panel
        captureArea = Container(
          color: const Color(0xFF111111),
          child: Center(
            child: Icon(Icons.attach_file,
                color: Colors.white.withValues(alpha: 0.06), size: 120),
          ),
        );
      }
    } else {
      // AUDIO mode
      if (hasRecordedAudio) {
        captureArea = InspectionVideoPlayer(
          key: ValueKey('aplay_$uniqueId'),
          videoPath: itemAudios[uniqueId]!,
          onReRecord: () {
            setState(() => itemAudios[uniqueId] = null);
            _showAudioPickerOptions(item);
          },
          onDiscard: () => _discardAllMedia(item),
        );
      } else if (_isRecordingAudio) {
        captureArea = Container(
          color: const Color(0xFF111111),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: const Icon(Icons.mic, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 8),
                    const SizedBox(width: 8),
                    Text(
                      _formatAudioDuration(_audioElapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Recording...',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        );
      } else {
        // No audio — faint bg + browse button
        captureArea = Container(
          color: const Color(0xFF111111),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_outlined,
                    color: Colors.white.withValues(alpha: 0.06), size: 120),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _pickAudio(item),
                  icon: const Icon(Icons.folder_open_outlined, size: 16),
                  label: const Text('Browse audio files'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Show action row for any mode that has no media yet
    final bool showCameraRow =
        (_currentCaptureMode == 'PHOTO' && !hasCapturedPhoto) ||
            (_currentCaptureMode == 'VIDEO' && !hasCapturedVideo) ||
            (_currentCaptureMode == 'FILE' && !hasAttachedFile) ||
            (_currentCaptureMode == 'AUDIO' && !hasRecordedAudio);

    // Condition chip colours
    final Color condColor = conditionValue == 'no_issues'
        ? Colors.green
        : conditionValue == 'flagged'
            ? Colors.red
            : Colors.white54;
    final IconData condIcon = conditionValue == 'no_issues'
        ? Icons.check_circle_outline
        : conditionValue == 'flagged'
            ? Icons.flag_outlined
            : Icons.radio_button_unchecked;
    final String condLabel = conditionValue == 'flagged'
        ? '${flaggedIssues.length} issue${flaggedIssues.length == 1 ? '' : 's'} flagged'
        : 'No issues — looks good';

    return Column(
      children: [
        // ── Capture area ──────────────────────────────────────────
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              captureArea,

              // Reference thumbnail (PHOTO / VIDEO only, top-left)
              if (refUrl.isNotEmpty &&
                  _currentCaptureMode != 'FILE' &&
                  _currentCaptureMode != 'AUDIO')
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () =>
                        _showFullscreenReferenceImage(referenceMedia, 0),
                    child: Container(
                      width: 100,
                      height: 75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (refMediaType == 'video')
                              Container(
                                color: Colors.black87,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.white70,
                                    size: 32,
                                  ),
                                ),
                              )
                            else
                              Image.network(
                                refUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey[900]),
                              ),
                            Positioned(
                              bottom: 2,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: const Text(
                                  'REF',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Recording indicator (VIDEO recording, top-right)
              if (_currentCaptureMode == 'VIDEO' && _isVideoRecording)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.red, size: 8),
                        SizedBox(width: 5),
                        Text('REC',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),

              // Retake badge (PHOTO captured, top-right)
              if (hasCapturedPhoto && _currentCaptureMode == 'PHOTO')
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _showImagePickerOptions(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUploading) ...[
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            const Text('Uploading',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ] else ...[
                            const Icon(Icons.refresh,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            const Text('Retake',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // Replace badge (FILE attached, top-right)
              if (hasAttachedFile && _currentCaptureMode == 'FILE')
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _showFilePickerOptions(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Replace',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),

              // Condition chip overlay (bottom of capture area)
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showFlagIssuesSheet(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: condColor.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(condIcon, size: 13, color: condColor),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  condLabel,
                                  style: TextStyle(
                                    color: condColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _highlightFlagIssues = false);
                        _showFlagIssuesSheet(item);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _highlightFlagIssues
                              ? Colors.orange.withValues(alpha: 0.2)
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _highlightFlagIssues
                                  ? Colors.orange
                                  : Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag_outlined,
                                size: 13,
                                color: _highlightFlagIssues
                                    ? Colors.orange
                                    : Colors.white70),
                            const SizedBox(width: 4),
                            Text('Flag Issue',
                                style: TextStyle(
                                    color: _highlightFlagIssues
                                        ? Colors.orange
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Bottom control panel ───────────────────────────────────
        Container(
          color: const Color(0xFF0D0D0D),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instruction text
                Text(
                  _currentCaptureMode == 'VIDEO'
                      ? 'Record a video of: $title'
                      : _currentCaptureMode == 'FILE'
                          ? 'Attach a document for: $title'
                          : _currentCaptureMode == 'AUDIO'
                              ? 'Add an audio note for: $title'
                              : 'Take a clear photo of: $title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Mode tabs — text + underline only
                Row(
                  children: ['FILE', 'PHOTO', 'VIDEO', 'AUDIO'].map((mode) {
                    final isSelected = mode == _currentCaptureMode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isSelected) {
                            _audioTimer?.cancel();
                            _audioTimer = null;
                            _audioRecorder?.stop();
                            setState(() {
                              _currentCaptureMode = mode;
                              _triggerPhotoCapture = null;
                              _triggerEnlarge = null;
                              _triggerVideoToggle = null;
                              _isVideoRecording = false;
                              _isRecordingAudio = false;
                              _audioElapsed = Duration.zero;
                            });
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mode,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.white38,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 2,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4D9EFF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Action row — shown for all modes when no media captured yet
                if (showCameraRow) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left slot: gallery (PHOTO/VIDEO) or spacer (FILE/AUDIO)
                      if (_currentCaptureMode == 'PHOTO' ||
                          _currentCaptureMode == 'VIDEO')
                        GestureDetector(
                          onTap: () => _currentCaptureMode == 'VIDEO'
                              ? _pickVideo(item, ImageSource.gallery)
                              : _pickImage(
                                  ImageSource.gallery, uniqueId, fieldId),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Icon(
                              _currentCaptureMode == 'VIDEO'
                                  ? Icons.video_library_outlined
                                  : Icons.photo_library_outlined,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 46, height: 46),

                      // Centre: main action button for each mode
                      if (_currentCaptureMode == 'PHOTO')
                        // Shutter ring
                        GestureDetector(
                          onTap: _triggerPhotoCapture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _triggerPhotoCapture != null
                                      ? Colors.white
                                      : Colors.white38,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (_currentCaptureMode == 'VIDEO')
                        // Record ring → square stop
                        GestureDetector(
                          onTap: _triggerVideoToggle,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isVideoRecording
                                    ? Colors.red
                                    : Colors.white,
                                width: 3,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: _isVideoRecording
                                      ? Colors.red
                                      : (_triggerVideoToggle != null
                                          ? Colors.white
                                          : Colors.white38),
                                  borderRadius: BorderRadius.circular(
                                      _isVideoRecording ? 4 : 40),
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (_currentCaptureMode == 'FILE')
                        // Attach button
                        GestureDetector(
                          onTap: () => _showFilePickerOptions(item),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4D9EFF)
                                  .withValues(alpha: 0.15),
                              border: Border.all(
                                  color: const Color(0xFF4D9EFF), width: 2.5),
                            ),
                            child: const Icon(Icons.attach_file,
                                color: Color(0xFF4D9EFF), size: 30),
                          ),
                        )
                      else
                        // AUDIO: toggle recording
                        GestureDetector(
                          onTap: () => _isRecordingAudio
                              ? _stopAudioRecording(item)
                              : _startAudioRecording(item),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecordingAudio
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : const Color(0xFFEC4899)
                                      .withValues(alpha: 0.15),
                              border: Border.all(
                                color: _isRecordingAudio
                                    ? Colors.red
                                    : const Color(0xFFEC4899),
                                width: 2.5,
                              ),
                            ),
                            child: Icon(
                              _isRecordingAudio ? Icons.stop : Icons.mic,
                              color: _isRecordingAudio
                                  ? Colors.red
                                  : const Color(0xFFEC4899),
                              size: 30,
                            ),
                          ),
                        ),

                      // Right slot: enlarge (PHOTO) or spacer
                      if (_currentCaptureMode == 'PHOTO')
                        GestureDetector(
                          onTap: _triggerEnlarge,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Icon(
                              Icons.open_in_full,
                              color: _triggerEnlarge != null
                                  ? Colors.white70
                                  : Colors.white24,
                              size: 20,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 46, height: 46),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ],
    );
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
    final items = currentSection['items'] as List<dynamic>;
    final currentItem = items.isNotEmpty ? items[_currentItemIndex] : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
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
        backgroundColor: Colors.black,
        appBar: _buildDarkAppBar(currentSection),
        endDrawer: _buildDrawer(),
        body: Column(
          children: [
            // Thin progress bar
            LinearProgressIndicator(
              value: _totalFields > 0 ? _processedFields / _totalFields : 0.0,
              minHeight: 3,
              backgroundColor: Colors.white12,
              color: const Color(0xFF448AFF),
            ),
            Expanded(
              child: _isReviewingVideo && _pendingCapturedVideoFile != null
                  ? InspectionVideoReview(
                      capturedMediaPath: _pendingCapturedVideoFile!.path,
                      fieldTitle:
                          currentItem != null ? _getItemTitle(currentItem) : '',
                      mediaLabel: 'Video',
                      onRetake: () {
                        setState(() {
                          _isReviewingVideo = false;
                          _pendingCapturedVideoFile = null;
                          _pendingCapturedVideoUniqueId = null;
                        });
                      },
                      onUseMedia: _acceptCapturedVideo,
                    )
                  : _isReviewingAudio && _pendingCapturedAudioPath != null
                      ? InspectionVideoReview(
                          capturedMediaPath: _pendingCapturedAudioPath!,
                          fieldTitle: currentItem != null
                              ? _getItemTitle(currentItem)
                              : '',
                          mediaLabel: 'Audio',
                          onRetake: () {
                            setState(() {
                              _isReviewingAudio = false;
                              _pendingCapturedAudioPath = null;
                              _pendingCapturedAudioUniqueId = null;
                            });
                          },
                          onUseMedia: _acceptCapturedAudio,
                        )
                      : _isReviewingCapture && _pendingCapturedXFile != null
                          ? InspectionImageReview(
                              capturedImagePath: _pendingCapturedXFile!.path,
                              fieldTitle: currentItem != null
                                  ? _getItemTitle(currentItem)
                                  : '',
                              referenceMedia: currentItem != null
                                  ? _getItemReferenceMedia(currentItem)
                                  : [],
                              onRetake: () {
                                setState(() {
                                  _isReviewingCapture = false;
                                  _pendingCapturedXFile = null;
                                  _pendingCapturedUniqueId = null;
                                });
                              },
                              onUsePhoto: _acceptCapturedImage,
                            )
                          : currentItem != null &&
                                  (_itemHasImage(currentItem) ||
                                      _itemHasVideo(currentItem))
                              ? _buildImageFieldView(currentItem)
                              : ListView(
                          key: PageStorageKey<int>(_currentSection),
                          controller: _scrollController,
                          children: [
                            _buildInspectionSection(
                              currentSection['title'],
                              items,
                            ),
                          ],
                        ),
            ),
            _buildDarkNavBar(items),
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
      onSelectSection: (index) => _navigateToField(index, 0),
      onSelectField: (sectionIndex, fieldIndex) =>
          _navigateToField(sectionIndex, fieldIndex),
    );
  }

  void _navigateToField(int sectionIndex, int fieldIndex) {
    final sectionItems = _sections[sectionIndex]['items'] as List<dynamic>;
    final clampedField = fieldIndex.clamp(0, sectionItems.length - 1);
    final targetItem =
        sectionItems.isNotEmpty ? sectionItems[clampedField] : null;
    setState(() {
      _currentSection = sectionIndex;
      _currentItemIndex = clampedField;
      _isScrollable = false;
      _showButton = true;
      _isVideoRecording = false;
      _isRecordingAudio = false;
      _triggerPhotoCapture = null;
      _triggerEnlarge = null;
      _triggerVideoToggle = null;
      if (targetItem != null) {
        _currentCaptureMode = _defaultCaptureModeForItem(targetItem);
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        if (_scrollController.hasClients) {
          _isScrollable = _scrollController.position.maxScrollExtent > 0;
        } else {
          _isScrollable = false;
        }
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
    if (!_sessionCompleted) {
      // ref is not guaranteed to be valid during dispose() in Riverpod — guard it.
      try {
        ref.read(inspectionSessionNotifierProvider.notifier).saveSnapshot(
          InspectionSessionSnapshot(
            itemImages: Map.from(itemImages),
            itemVideos: Map.from(itemVideos),
            itemAudios: Map.from(itemAudios),
            itemFiles: Map.from(itemFiles),
            itemRemarks: Map.from(itemRemarks),
            itemValues: Map.from(itemValues),
            itemMultiImages: Map.from(itemMultiImages),
            itemFlaggedIssues: Map.from(itemFlaggedIssues),
            currentSection: _currentSection,
            currentItemIndex: _currentItemIndex,
            vehicleDetails: vehicleDetails,
            inspectionTemplate: _inspectionTemplate,
            useDynamicTemplate: _useDynamicTemplate,
            sessionInspectionId: _sessionInspectionId,
          ),
        );
      } catch (_) {
        // ref was already invalidated; session data persisted to Hive via _flushPendingAutoSave.
      }
    }
    _scrollController.dispose();
    _cleanupControllers();
    _isSubmitting = false;
    _rewardedAdManager.dispose();
    _audioTimer?.cancel();
    _audioRecorder?.dispose();
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
