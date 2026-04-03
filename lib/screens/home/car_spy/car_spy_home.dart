import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../constants/hive_constants.dart';
import '../../../data/inspection_storage_model.dart';
import '../../../routes/routes.dart';
import 'new_cars_list_page.dart';
import 'rc_details_verify_page.dart';
import 'used_cars_list_page.dart';
import 'widgets/car_spy_bottom_nav_bar.dart';
import 'widgets/car_spy_content_sections.dart';
import 'widgets/car_spy_hero_section.dart';
import 'widgets/car_spy_top_app_bar.dart';

class CarSpyHome extends StatefulWidget {
  const CarSpyHome({super.key});

  @override
  State<CarSpyHome> createState() => _CarSpyHomeState();
}

class _CarSpyHomeState extends State<CarSpyHome> {
  int _selectedIndex = 0;
  Box<InspectionStorageModel>? _inspectionBox;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      if (!Hive.isBoxOpen(HiveConstants.INSPECTION_BOX)) {
        await Hive.initFlutter();

        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(InspectionStorageModelAdapter());
        }

        _inspectionBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_BOX,
        );
      } else {
        _inspectionBox = Hive.box<InspectionStorageModel>(
          HiveConstants.INSPECTION_BOX,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error initializing inspection data')),
      );
    }
  }

  Future<bool> _hasExistingInspection() async {
    try {
      if (!Hive.isBoxOpen(HiveConstants.INSPECTION_BOX)) {
        _inspectionBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_BOX,
        );
      }

      final existingData =
          _inspectionBox?.get(HiveConstants.CURRENT_INSPECTION_KEY);

      if (existingData != null) {
        if (existingData.isCompleted ||
            existingData.status == 'submitted' ||
            existingData.status == 'offline') {
          return false;
        }

        final hasValidData = existingData.itemValues.isNotEmpty ||
            existingData.itemImages.isNotEmpty ||
            existingData.itemRemarks.isNotEmpty;

        if (hasValidData) {
          final inspectionTime = existingData.timestamp;
          final currentTime = DateTime.now();
          final timeDifference = currentTime.difference(inspectionTime);
          return timeDifference.inHours < 24;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleInitializeScanTap() async {
    try {
      final hasExisting = await _hasExistingInspection();
      if (!mounted) return;

      if (hasExisting) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Continue Previous Inspection?'),
              content: const Text(
                'Would you like to continue your previous inspection or start a new one?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _navigateToInspection(true);
                  },
                  child: const Text('Start New'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _navigateToInspection(false);
                  },
                  child: const Text('Continue Previous'),
                ),
              ],
            );
          },
        );
      } else {
        _navigateToInspection(true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error starting inspection. Please try again.'),
        ),
      );
    }
  }

  void _navigateToInspection(bool isNew) {
    if (isNew) {
      Navigator.pushNamed(
        context,
        Routes.vehicleDetails,
        arguments: {'isNew': isNew},
      ).then((_) {
        if (mounted) setState(() {});
      });
    } else {
      Navigator.pushNamed(
        context,
        Routes.inspection,
        arguments: {'isNew': isNew},
      ).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: const CarSpyTopAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              CarSpyHeroSection(
                onInitializeScan: _handleInitializeScanTap,
              ),
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CarSpyCoreServicesSection(
                      onServiceTap: (index) {
                        if (index == 0) {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (context) => const NewCarsListPage(),
                            ),
                          );
                        } else if (index == 1) {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (context) => const UsedCarsListPage(),
                            ),
                          );
                        } else if (index == 2) {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  const RcDetailsVerifyPage(),
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 32),
                    CarSpyPendingReportCard(),
                    SizedBox(height: 24),
                    CarSpyStatsRow(),
                    SizedBox(height: 24),
                    CarSpyHeritageVaultCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CarSpyBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
