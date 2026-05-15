import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../constants/hive_constants.dart';
import '../../../data/inspection_storage_model.dart';
import '../../../routes/routes.dart';
import '../../attendance/attendance_screen.dart';
import '../../profile/profile.dart';
import '../../work_assigned/work_assigned_screen.dart';
import '../reports_page.dart';
import 'car_spy_data.dart';
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
        _inspectionBox =
            Hive.box<InspectionStorageModel>(HiveConstants.INSPECTION_BOX);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error initializing inspection data')),
      );
    }
  }

  /// Matches [MainContent.hasExistingInspection]: draft with data, &lt; 24h.
  Future<bool> _hasExistingInspection() async {
    try {
      if (!Hive.isBoxOpen(HiveConstants.INSPECTION_BOX)) {
        _inspectionBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_BOX,
        );
      } else {
        _inspectionBox =
            Hive.box<InspectionStorageModel>(HiveConstants.INSPECTION_BOX);
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
            existingData.itemRemarks.isNotEmpty ||
            existingData.itemVideos.isNotEmpty ||
            existingData.itemAudios.isNotEmpty ||
            existingData.itemFiles.isNotEmpty ||
            (existingData.multiImages?.isNotEmpty ?? false);

        if (hasValidData) {
          final inspectionTime = existingData.timestamp;
          final currentTime = DateTime.now();
          final timeDifference = currentTime.difference(inspectionTime);
          return timeDifference.inHours < 24;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking existing inspection: $e');
      return false;
    }
  }

  Future<void> _clearSavedInspectionAndStartNew() async {
    try {
      if (_inspectionBox?.isOpen ?? false) {
        await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);
      } else if (Hive.isBoxOpen(HiveConstants.INSPECTION_BOX)) {
        await Hive.box<InspectionStorageModel>(HiveConstants.INSPECTION_BOX)
            .delete(HiveConstants.CURRENT_INSPECTION_KEY);
      }
      _navigateToInspection(true);
    } catch (e) {
      debugPrint('Error clearing inspection: $e');
      _navigateToInspection(true);
    }
  }

  Future<void> _handleInitializeScanTap() async {
    try {
      if (!mounted) return;

      final hasExisting = await _hasExistingInspection();
      if (!mounted) return;

      if (hasExisting) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: CarSpyColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Continue saved inspection?',
                style: TextStyle(
                  color: CarSpyColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: const Text(
                'You have an unfinished inspection. Continue where you left off, or start a new scan.',
                style: TextStyle(
                  color: CarSpyColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _clearSavedInspectionAndStartNew();
                  },
                  child: const Text('Start new'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _navigateToInspection(false);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: CarSpyColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue'),
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

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CarSpyHeroSection(
            onInitializeScan: _handleInitializeScanTap,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          builder: (context) => const RcDetailsVerifyPage(),
                        ),
                      );
                    }
                  },
                ),
                // const SizedBox(height: 32),
                // const CarSpyPendingReportCard(),
                // const SizedBox(height: 24),
                const CarSpyStatsRow(),
                const SizedBox(height: 24),
                const CarSpyHeritageVaultCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: _selectedIndex == 0 ? const CarSpyTopAppBar() : null,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(),
            const ReportsPage(key: ValueKey('car_spy_reports')),
            const AttendanceScreen(key: ValueKey('car_spy_attendance')),
            const WorkAssignedScreen(key: ValueKey('car_spy_work_assigned')),
          ],
        ),
      ),
      bottomNavigationBar: CarSpyBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
