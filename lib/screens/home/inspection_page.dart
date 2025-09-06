import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import '../../widgets/custom_inspection_item.dart';
import '../main_screen.dart';

class InspectionScreen extends StatefulWidget {
  final bool isNewInspection;
  const InspectionScreen({
    super.key,
    this.isNewInspection = false,
  });

  @override
  _InspectionScreenState createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  Timer? _saveDebouncer;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  int _currentSection = 0;
  Map<String, String?> itemImages = {};
  Map<String, String> itemRemarks = {};
  Map<String, String> itemValues = {};
  Map<String, List<String>?> itemMultiImages = {};
  Map<String, TextEditingController> remarksControllers = {};
  Map<String, TextEditingController> numberRemarkControllers = {};
  Map<String, TextEditingController> textFieldControllers = {};
  bool _showButton = true;
  bool _isScrollable = false;
  bool _isSubmitting = false;

  static const String INSPECTION_BOX = HiveConstants.INSPECTION_BOX;
  Box<InspectionStorageModel>? _inspectionBox;

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

      if (widget.isNewInspection) {
        await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);
        _initializeValues();
        _initializeControllers();
      } else {
        await _loadDataFromStorage();
      }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return CustomInspectionItem<String>(
              key: ValueKey('${item.uniqueId}_$index'),
              title: item.title,
              currentValue: itemValues[item.uniqueId] ??
                  (item.useTextField ? '' : item.options?.first.value ?? ''),
              dropdownOptions: item.options,
              onValueChanged: (newValue) {
                Future.microtask(() {
                  if (mounted) {
                    setState(() {
                      itemValues[item.uniqueId] = newValue;
                    });
                    _autoSave();
                  }
                });
              },
              allowImage: item.allowImage,
              allowMultiImage: item.allowMultiImage,
              imagePath: itemImages[item.uniqueId],
              multiImagePaths: itemMultiImages[item.uniqueId],
              onImageChanged: (path) {
                Future.microtask(() {
                  if (mounted) {
                    setState(() {
                      itemImages[item.uniqueId] = path;
                    });
                    _autoSave();
                  }
                });
              },
              onMultiImageChanged: (paths) {
                Future.microtask(() {
                  if (mounted) {
                    setState(() {
                      itemMultiImages[item.uniqueId] = paths;
                    });
                    _autoSave();
                  }
                });
              },
              allowRemarks: item.allowRemarks,
              remarksController:
                  remarksControllers[item.uniqueId] ?? TextEditingController(),
              useTextField: item.useTextField,
              textFieldController: textFieldControllers[item.uniqueId],
              onDataChanged: () {
                Future.microtask(() {
                  if (mounted) {
                    _autoSave();
                  }
                });
              },
              allowFileAttachment: item.allowFileAttachment,
            );
          },
        ),
      ],
    );
  }

  void _nextSection() {
    if (_currentSection < _sections.length - 1) {
      setState(() {
        _currentSection++;
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
                        _handleSubmission();
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
          title: const Text(
            'Certifide',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
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
            LinearProgressIndicator(
              value: (_currentSection + 1) / _sections.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                            : Text(
                                _currentSection == _sections.length - 1
                                    ? 'FINISH'
                                    : 'NEXT',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        // Add SafeArea
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Center(
                child: Text(
                  'Sections',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  return ListTile(
                    title: Text(section['title']),
                    selected: _currentSection == index,
                    onTap: () {
                      setState(() {
                        _currentSection = index;
                        _isScrollable = false;
                        _showButton = true;
                      });

                      Future.delayed(const Duration(milliseconds: 100), () {
                        setState(() {
                          _isScrollable =
                              _scrollController.position.maxScrollExtent > 0;
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

                      Navigator.pop(context); // Close the drawer
                    },
                  );
                },
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
