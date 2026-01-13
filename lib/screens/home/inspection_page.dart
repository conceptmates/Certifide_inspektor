import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../constants/hive_constants.dart';
import '../../data/inspection_item.dart';
import '../../data/inspection_storage_model.dart';
import '../../models/inspection_item.dart';
import '../../providers/user_provider.dart';
import '../../services/api_services.dart';
import '../../services/local_storage_services.dart';
import '../../utils/connectivity_checker.dart';
import '../../utils/data_formatter.dart';
import '../../widgets/inspection_field_info_sheet.dart';
import '../main_screen.dart';
import '../../utils/ads manager/rewarded_interstitial_ad.dart';

class InspectionScreen extends StatefulWidget {
  final bool isNewInspection;
  final Map<String, dynamic>? vehicleDetails;
  const InspectionScreen({
    super.key,
    this.isNewInspection = false,
    this.vehicleDetails,
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

  static const String INSPECTION_BOX = HiveConstants.INSPECTION_BOX;
  Box<InspectionStorageModel>? _inspectionBox;

  final RewardedInterstitialAdManager _rewardedAdManager =
      RewardedInterstitialAdManager();

  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'Documents',
      'items': documents as List<InspectionItem>,
    },
    {
      'title': 'Body Panel',
      'items': bodyPanel as List<InspectionItem>,
    },
    {
      'title': 'Flood Affected Signs',
      'items': floodAffectedSigns as List<InspectionItem>,
    },
    {
      'title': 'Data Set - I',
      'items': dataSet1 as List<InspectionItem>,
    },
    {
      'title': 'Data Set - II',
      'items': dataSet2 as List<InspectionItem>,
    },
    {
      'title': 'Battery',
      'items': battery as List<InspectionItem>,
    },
    {
      'title': 'Coolant',
      'items': coolant as List<InspectionItem>,
    },
    {
      'title': 'Under Hood',
      'items': underHood as List<InspectionItem>,
    },
    {
      'title': 'Brake Fluid',
      'items': brakeFluid as List<InspectionItem>,
    },
    {
      'title': 'Tire',
      'items': tire as List<InspectionItem>,
    },
    {
      'title': 'Exterior',
      'items': exterior as List<InspectionItem>,
    },
    {
      'title': 'A/C',
      'items': ac as List<InspectionItem>,
    },
    // {
    //   'title': 'ECU Scan',
    //   'items': ecuScan as List<InspectionItem>,
    // },
    {
      'title': 'Interior',
      'items': interior as List<InspectionItem>,
    },
    {
      'title': 'Dicky',
      'items': dicky as List<InspectionItem>,
    },
    {
      'title': 'Test Drive',
      'items': testDrive as List<InspectionItem>,
    },
    {
      'title': 'After WarmUp',
      'items': afterWarmUp as List<InspectionItem>,
    },
    {
      'title': 'Summary / Remarks',
      'items': summary as List<InspectionItem>,
    }
  ];

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
        setState(() {});
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
      // If there's an error, try to delete the box and recreate it
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
      // Collect current remarks from controllers
      Map<String, String> currentRemarks = {};
      remarksControllers.forEach((key, controller) {
        currentRemarks[key] = controller.text;
      });

      // Prepare multi-images map
      Map<String, List<String>> currentMultiImages = {};
      itemMultiImages.forEach((key, images) {
        if (images != null && images.isNotEmpty) {
          currentMultiImages[key] = images;
        }
      });

      final storageModel = InspectionStorageModel(
        itemValues: Map<String, String>.from(itemValues),
        itemImages: Map<String, String?>.from(itemImages),
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

      print('Data saved locally: ${storageModel.itemValues}');
      print('Images saved: ${storageModel.itemImages}');
      print('Multi-Images saved: ${storageModel.multiImages}');
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> _completeInspection() async {
    try {
      // Ensure inspection box is open
      if (!(_inspectionBox?.isOpen ?? false)) {
        await _initHive();
      }

      final currentData =
          _inspectionBox?.get(HiveConstants.CURRENT_INSPECTION_KEY);
      if (currentData != null) {
        // Create a new completed inspection
        final completedInspection = InspectionStorageModel(
          itemValues: Map<String, String>.from(currentData.itemValues),
          itemImages: Map<String, String?>.from(currentData.itemImages),
          itemRemarks: Map<String, String>.from(currentData.itemRemarks),
          currentSection: currentData.currentSection,
          textFieldValues:
              Map<String, String>.from(currentData.textFieldValues),
          isCompleted: true,
          timestamp: DateTime.now(),
          status: 'submitted', // Set status to submitted
        );

        // Open history box
        final historyBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_HISTORY_BOX,
        );

        // Add to history
        await historyBox.add(completedInspection);

        // Delete current inspection
        await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);

        // Close history box
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
    switch (sectionTitle.toLowerCase()) {
      case 'documents':
        return Icons.description;
      case 'body panel':
        return Icons.directions_car;
      case 'flood affected signs':
        return Icons.water_damage;
      case 'data set - i':
      case 'data set - ii':
        return Icons.analytics;
      case 'battery':
        return Icons.battery_full;
      case 'coolant':
        return Icons.opacity;
      case 'under hood':
        return Icons.car_repair;
      case 'brake fluid':
        return Icons.speed;
      case 'tire':
        return Icons.tire_repair;
      case 'exterior':
        return Icons.directions_car_filled;
      case 'a/c':
        return Icons.ac_unit;
      case 'interior':
        return Icons.airline_seat_recline_normal;
      case 'dicky':
        return Icons.luggage;
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
    final section = sectionTitle.toLowerCase();

    // Numeric placeholders
    if (title.contains('battery voltage') || title.contains('voltage')) {
      return 'e.g. 12.4V';
    }
    if (title.contains('specific gravity') || title.contains('sg')) {
      return 'e.g. 1.265';
    }
    if (title.contains('tyre pressure') || title.contains('pressure')) {
      return 'e.g. 32 PSI';
    }
    if (title.contains('tread depth') || title.contains('depth')) {
      return 'e.g. 4.5mm';
    }
    if (title.contains('odometer') || title.contains('mileage')) {
      return 'e.g. 45,678 km';
    }
    if (title.contains('engine rpm') || title.contains('rpm')) {
      return 'e.g. 850 RPM';
    }
    if (title.contains('temperature') || title.contains('temp')) {
      return 'e.g. 85°C';
    }

    // Text/description placeholders
    if (title.contains('registration') ||
        title.contains('number') ||
        title.contains('plate')) {
      return 'e.g. MH12AB1234';
    }
    if (title.contains('chassis') || title.contains('vin')) {
      return 'e.g. MA1234567890123456';
    }
    if (title.contains('engine number') || title.contains('engine no')) {
      return 'e.g. G4FC123456';
    }
    if (title.contains('model') || title.contains('variant')) {
      return 'e.g. Verna SX 1.6L';
    }
    if (title.contains('year') || title.contains('manufacture')) {
      return 'e.g. 2019';
    }
    if (title.contains('color') || title.contains('colour')) {
      return 'e.g. Pearl White';
    }

    // Condition-based placeholders
    if (title.contains('scratch') || title.contains('dent')) {
      return 'e.g. Minor scratch on door';
    }
    if (title.contains('noise') || title.contains('sound')) {
      return 'e.g. Slight grinding noise';
    }
    if (title.contains('leak') || title.contains('fluid')) {
      return 'e.g. No leakage observed';
    }

    // Section-specific placeholders
    switch (section) {
      case 'documents':
        return 'Enter document details...';
      case 'test drive':
        return 'Describe driving performance...';
      case 'summary / remarks':
        return 'Overall condition summary...';
      default:
        return 'Enter inspection details...';
    }
  }

  Future<void> _loadDataFromStorage() async {
    try {
      final storedData =
          _inspectionBox?.get(HiveConstants.CURRENT_INSPECTION_KEY);

      if (storedData != null) {
        // Clean up existing controllers
        _cleanupControllers();

        // Update state with stored data
        setState(() {
          // Load item values
          itemValues = storedData.typedItemValues;

          // Load images
          itemImages = storedData.typedItemImages;

          // Load remarks
          itemRemarks = storedData.typedItemRemarks;

          // Load current section
          _currentSection = storedData.currentSection;

          // Load multi-images
          itemMultiImages = storedData.typedMultiImages;
        });

        // Initialize controllers for each section
        for (var section in _sections) {
          for (var item in section['items'] as List<InspectionItem>) {
            // Handle remarks controllers
            if (item.allowRemarks || item.id == 'summary') {
              remarksControllers[item.uniqueId] = TextEditingController(
                text: storedData.typedItemRemarks[item.uniqueId] ?? '',
              );
            }

            // Handle text field controllers
            if (item.useTextField) {
              textFieldControllers[item.uniqueId] = TextEditingController(
                text: storedData.typedItemValues[item.uniqueId] ?? '',
              );
            }
          }
        }

        // Debug print to verify loaded data
        print('Loaded Item Values: $itemValues');
        print('Loaded Images: $itemImages');
        print('Loaded Multi-Images: $itemMultiImages');
      } else {
        // If no stored data, initialize values and controllers
        _initializeValues();
        _initializeControllers();
      }
    } catch (e) {
      print('Error loading data: $e');

      // Fallback to initialization if loading fails
      _initializeValues();
      _initializeControllers();
    }
  }

  void _onScroll() {
    if (!_isScrollable) return;

    // Check if we should show section title in app bar (when scrolled past header)
    bool shouldShowSectionTitle = _scrollController.position.pixels > 100;

    if (shouldShowSectionTitle != _showSectionTitle) {
      setState(() {
        _showSectionTitle = shouldShowSectionTitle;
      });
    }

    // Check if we should show bottom button
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
          itemRemarks.clear();
        });
      }
    } catch (e) {
      print('Error cleaning up current inspection: $e');
    }
  }

  void _initializeControllers() {
    // First, clean up any existing controllers to prevent memory leaks
    _cleanupControllers();

    // Reset controller maps
    remarksControllers.clear();
    textFieldControllers.clear();
    numberRemarkControllers.clear();

    // Iterate through all sections and items
    for (var section in _sections) {
      for (var item in section['items'] as List<InspectionItem>) {
        try {
          // Handle Remarks Controllers
          if (item.allowRemarks || item.id == 'summary') {
            // Initialize remarks controller
            final initialRemarks = itemRemarks[item.uniqueId] ?? '';

            remarksControllers[item.uniqueId] = TextEditingController(
              text: initialRemarks,
            );

            // Add listener to update itemRemarks in real-time
            remarksControllers[item.uniqueId]?.addListener(() {
              final currentText = remarksControllers[item.uniqueId]?.text ?? '';

              // Update itemRemarks map
              itemRemarks[item.uniqueId] = currentText;
            });
          }

          // Handle Text Field Controllers
          if (item.useTextField) {
            // Determine initial value
            final initialValue = itemValues[item.uniqueId] ?? '';

            textFieldControllers[item.uniqueId] = TextEditingController(
              text: initialValue,
            );

            // Add listener to update itemValues in real-time
            textFieldControllers[item.uniqueId]?.addListener(() {
              final currentText =
                  textFieldControllers[item.uniqueId]?.text ?? '';

              // Update itemValues map
              itemValues[item.uniqueId] = currentText;
            });
          }

          // Optional: Handle Number Remark Controllers (if you have specific number input fields)
          if (item.id.contains('number_remark')) {
            numberRemarkControllers[item.uniqueId] = TextEditingController(
              text: itemValues[item.uniqueId] ?? '',
            );

            numberRemarkControllers[item.uniqueId]?.addListener(() {
              final currentText =
                  numberRemarkControllers[item.uniqueId]?.text ?? '';

              // Update itemValues map
              itemValues[item.uniqueId] = currentText;
            });
          }
        } catch (e) {
          // Minimal error handling
          print('Error initializing controllers for item ${item.uniqueId}');
        }
      }
    }
  }

  void _initializeValues() {
    itemValues = {};
    itemRemarks = {};
    itemMultiImages = {};

    for (var section in _sections) {
      for (var item in section['items'] as List<InspectionItem>) {
        if (item.useTextField) {
          itemValues[item.uniqueId] = '';
        } else if (item.options != null && item.options!.isNotEmpty) {
          // Set default value to 'N/A' for dropdowns
          itemValues[item.uniqueId] = 'N/A';
        }

        if (item.allowRemarks || item.id == 'summary') {
          // Include summary item
          itemRemarks[item.uniqueId] = '';
        }
      }
    }
  }

  _buildInspectionSection(String title, List<InspectionItem<String>> items) {
    // Ensure current item index is within bounds
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
        // Navigation buttons
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

  Widget _buildSingleItemContainer(
      InspectionItem<String> item, String sectionTitle) {
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
          color: Theme.of(context).dividerColor.withAlpha(51),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Item name + Camera button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ),
                if (item.allowImage || item.allowMultiImage)
                  IconButton(
                    icon: const Icon(Icons.camera_alt, size: 28),
                    color: Colors.blue,
                    onPressed: () {
                      if (item.allowMultiImage) {
                        _pickMultiImages(item);
                      } else {
                        _showImagePickerOptions(item);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Captured image preview (if exists)
            if (item.allowImage && itemImages[item.uniqueId] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Captured Image:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showImagePreview(itemImages[item.uniqueId]!),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(itemImages[item.uniqueId]!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            // Multi-image preview (if exists)
            if (item.allowMultiImage &&
                itemMultiImages[item.uniqueId] != null &&
                itemMultiImages[item.uniqueId]!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Captured Images:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: itemMultiImages[item.uniqueId]!.length,
                      itemBuilder: (context, imgIndex) {
                        final imagePath =
                            itemMultiImages[item.uniqueId]![imgIndex];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(imagePath),
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    final updatedPaths = List<String>.from(
                                        itemMultiImages[item.uniqueId]!)
                                      ..removeAt(imgIndex);
                                    setState(() {
                                      itemMultiImages[item.uniqueId] =
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
                                    child: const Icon(
                                      Icons.cancel,
                                      size: 18,
                                      color: Colors.red,
                                    ),
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
            // Reference placeholder image (only for items that allow images)
            if (item.allowImage || item.allowMultiImage)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reference Image:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reference Image',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            // Item controls (dropdown/text field/remarks)
            _buildItemControls(item, sectionTitle),
          ],
        ),
      ),
    );
  }

  Widget _buildItemControls(InspectionItem<String> item, String sectionTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown or TextField
        if (item.useTextField)
          TextField(
            controller: textFieldControllers[item.uniqueId],
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[50],
              hintText: _getPlaceholderText(item.title, sectionTitle),
              hintStyle: TextStyle(
                color: Theme.of(context).hintColor.withAlpha(153),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withAlpha(128),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            keyboardType: TextInputType.multiline,
            onChanged: (value) {
              setState(() {
                itemValues[item.uniqueId] = value;
              });
              _autoSave();
            },
          )
        else if (item.options != null)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[50],
              border: Border.all(
                color: Theme.of(context).dividerColor.withAlpha(128),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              value: item.options?.any((option) =>
                          option.value == itemValues[item.uniqueId]) ==
                      true
                  ? itemValues[item.uniqueId]
                  : null,
              underline: Container(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              items: item.options
                      ?.map((option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (option.icon != null) ...[
                                  Icon(
                                    option.icon,
                                    size: 18,
                                    color: option.color,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: option.color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList() ??
                  [],
              onChanged: (String? newValue) {
                if (newValue != null && mounted) {
                  setState(() {
                    itemValues[item.uniqueId] = newValue;
                  });
                  _autoSave();
                }
              },
            ),
          ),
        // Remarks field
        if (item.allowRemarks) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withAlpha(128),
              ),
            ),
            child: TextField(
              controller:
                  remarksControllers[item.uniqueId] ?? TextEditingController(),
              decoration: InputDecoration(
                hintText: '✍️ Add remarks...',
                hintStyle: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              onChanged: (value) {
                itemRemarks[item.uniqueId] = value;
                _autoSave();
              },
            ),
          ),
        ],
        // Info button
        const SizedBox(height: 12),
        InspectionInfoButton(fieldId: item.uniqueId),
      ],
    );
  }

  void _showImagePickerOptions(InspectionItem<String> item) {
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
                  _pickImage(ImageSource.camera, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
      ImageSource source, InspectionItem<String> item) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          itemImages[item.uniqueId] = image.path;
        });
        _autoSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickMultiImages(InspectionItem<String> item) async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty && mounted) {
        final currentImages = itemMultiImages[item.uniqueId] ?? [];
        final newImagePaths = images.map((img) => img.path).toList();
        final updatedPaths = [...currentImages, ...newImagePaths];

        // Limit to 11 images max
        final finalPaths = updatedPaths.take(11).toList();

        setState(() {
          itemMultiImages[item.uniqueId] = finalPaths;
        });
        _autoSave();

        if (images.length > 11 - currentImages.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Only ${11 - currentImages.length} images added. Maximum is 11.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                        final item = _sections[_currentSection]['items']
                            as List<InspectionItem<String>>;
                        final currentItem = item[_currentItemIndex];
                        setState(() {
                          itemImages[currentItem.uniqueId] = null;
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
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                    ),
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
    final items = currentSection['items'] as List<InspectionItem<String>>;
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

  void _nextSection() {
    if (_currentSection < _sections.length - 1) {
      setState(() {
        _currentSection++;
        _currentItemIndex = 0; // Reset item index when changing sections
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
      if (_isSubmitting) return; // Prevent multiple submissions

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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
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
          print('User earned reward: ${rewardItem.amount} ${rewardItem.type}');
          // Proceed with submission after earning reward
          _handleSubmission();
        },
        onAdClosed: () {
          print('Rewarded ad closed');
          // Still proceed with submission even if ad was closed without reward
          _handleSubmission();
        },
        onAdFailedToShow: () {
          print('Failed to show rewarded ad');
          // Proceed with submission if ad fails to show
          _handleSubmission();
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      // Proceed with submission if there's an error
      _handleSubmission();
    }
  }

  Future<void> _handleSubmission() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare data for submission
      Map<String, String?> finalItemImages = Map.from(itemImages);
      Map<String, String> summaryImagePaths = {};

      // Handle multi-images for all sections
      itemMultiImages.forEach((key, images) {
        if (images != null && images.isNotEmpty) {
          // Special handling for summary section
          if (key.contains('summary')) {
            for (int i = 0; i < images.length; i++) {
              final imagePath = images[i];
              final imageKey = 'summary_image_${i + 1}';
              summaryImagePaths[imageKey] = imagePath;
              finalItemImages[imageKey] = imagePath;
            }
          } else {
            // Handle other section multi-images
            for (int i = 0; i < images.length; i++) {
              final imagePath = images[i];
              final imageKey = '${key}_${i + 1}';
              finalItemImages[imageKey] = imagePath;
            }
          }
        }
      });

      // Prepare formatted data with summary image paths
      final formattedData = InspectionDataFormatter.formatData(
        itemValues: itemValues,
        itemImages: finalItemImages,
        itemRemarks: itemRemarks,
        sections: _sections,
        additionalData: {
          'summaryImagePaths': summaryImagePaths,
        },
      );

      // Save inspection locally first
      await LocalStorageService.saveInspection(
        data: formattedData,
        images: finalItemImages,
        status: 'pending', // Mark as pending initially
      );

      // Complete the current inspection locally
      await _completeInspection();
      await _cleanupCurrentInspection();

      // Navigate to LocalInspections page
      _navigateToLocalInspections(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection saved locally. Will attempt to submit.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in submission process: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving inspection: $e'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _saveOfflineInspection(
    Map<String, dynamic> formattedData,
    Map<String, String?> finalItemImages, {
    String status = 'offline',
  }) async {
    try {
      await LocalStorageService.saveInspection(
        data: formattedData,
        images: finalItemImages,
        status: status,
      );

      // Delete the current inspection from Hive
      await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);
    } catch (e) {
      print('Error saving offline inspection: $e');
      rethrow;
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

  Future<void> _processSubmissionInBackground() async {
    try {
      // Create a copy of itemImages to modify
      Map<String, String?> finalItemImages = Map.from(itemImages);

      // Create a dictionary to store summary image paths
      Map<String, String> summaryImagePaths = {};

      // Handle multi-images for all sections
      itemMultiImages.forEach((key, images) {
        if (images != null && images.isNotEmpty) {
          // Special handling for summary section
          if (key.contains('summary')) {
            for (int i = 0; i < images.length; i++) {
              final imagePath = images[i];
              final imageKey = 'summary_image_${i + 1}';

              // Add to summary image paths dictionary
              summaryImagePaths[imageKey] = imagePath;

              // Also add to finalItemImages for backward compatibility
              finalItemImages[imageKey] = imagePath;
            }
          } else {
            // Handle other section multi-images
            for (int i = 0; i < images.length; i++) {
              final imagePath = images[i];
              final imageKey = '${key}_${i + 1}';
              finalItemImages[imageKey] = imagePath;
            }
          }
        }
      });

      // Prepare formatted data with summary image paths
      final formattedData = InspectionDataFormatter.formatData(
        itemValues: itemValues,
        itemImages: finalItemImages,
        itemRemarks: itemRemarks,
        sections: _sections,
        additionalData: {
          'summaryImagePaths': summaryImagePaths,
        },
      );

      // Check internet connectivity
      bool hasInternet = await ConnectivityChecker.hasInternetConnection();

      if (!hasInternet) {
        // Save offline if no internet
        await LocalStorageService.saveOfflineInspection(
          data: formattedData,
          images: finalItemImages,
          status: 'offline',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Inspection saved locally. Will submit when online.'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        await _cleanupCurrentInspection();
        return;
      }

      // If internet is available, attempt to submit
      try {
        final result = await ApiService.sendInspectionData(formattedData);

        if (result['success']) {
          await _completeInspection();
          await _cleanupCurrentInspection();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inspection submitted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // If API submission fails, save as pending
          await LocalStorageService.saveInspection(
            data: formattedData,
            images: finalItemImages,
            status: 'pending',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to submit: ${result['message'] ?? 'Unknown error'}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          await _cleanupCurrentInspection();
        }
      } catch (apiError) {
        // Network or API error, save as pending
        await LocalStorageService.saveInspection(
          data: formattedData,
          images: finalItemImages,
          status: 'pending',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Submission error: $apiError. Will retry later.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        await _cleanupCurrentInspection();
      }
    } catch (e) {
      print('Unexpected error in submission: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e. Saving locally.'),
            backgroundColor: Colors.red,
          ),
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

  void _previousSection() async {
    await _saveDataLocally();
    if (_currentSection > 0) {
      setState(() {
        _currentSection--;
        _currentItemIndex = 0; // Reset item index when changing sections
        _showButton = false; // Hide button when changing sections
      });

      // Reset scroll position for new section
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
    final currentSection = _sections[_currentSection];

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }

        // Show confirmation dialog
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
                          onPressed: _handleClose, // Add this line
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
        endDrawer: _buildDrawer(), // Add this line
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
                    style: TextStyle(
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
                key: PageStorageKey<int>(
                    _currentSection), // Add a key to force rebuild
                controller: _scrollController,
                children: [
                  _buildInspectionSection(
                    currentSection['title'],
                    currentSection['items'] as List<InspectionItem<String>>,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _currentSection == _sections.length - 1
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF11998e),
                                    Color(0xFF38ef7d)
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF667eea),
                                    Color(0xFF764ba2)
                                  ],
                                ),
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
    final items = section['items'] as List<InspectionItem<String>>;

    for (var item in items) {
      // Check items with allowImage - must have image captured
      if (item.allowImage) {
        if (itemImages[item.uniqueId] == null ||
            itemImages[item.uniqueId]!.isEmpty) {
          return false;
        }
      }

      // Check items with useTextField - must have value
      if (item.useTextField) {
        final value = itemValues[item.uniqueId] ?? '';
        if (value.trim().isEmpty) {
          return false;
        }
      }

      // Check items with options (dropdown) - must have selected value (not 'N/A')
      if (item.options != null && item.options!.isNotEmpty) {
        final value = itemValues[item.uniqueId] ?? 'N/A';
        if (value == 'N/A' || value.isEmpty) {
          return false;
        }
      }

      // Remarks are optional, so we don't check them
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
            // Premium Header with gradient
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

            // Sections list
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
                                colors: [
                                  Color(0xFF667eea),
                                  Color(0xFF764ba2),
                                ],
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
                                BoxShadow(
                                  color: const Color(0xFF764ba2).withAlpha(51),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
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
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              )
                            : isSelected
                                ? Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.white,
                                  )
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
                            _currentItemIndex =
                                0; // Reset item index when selecting section
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
    // Dispose old controllers
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

    // Close the box if it's open
    if (_inspectionBox?.isOpen ?? false) {
      _inspectionBox?.close();
    }
    super.dispose();
  }

  void _handleClose() async {
    try {
      await _saveDataLocally(); // Ensure data is saved before closing
      if (!mounted) return;
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pop(); // Close inspection screen
    } catch (e) {
      print('Error handling close: $e');
      // Show error message to user if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving data')),
      );
    }
  }
}
