import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../constants/hive_constants.dart';
import '../../../data/inspection_storage_model.dart';
import '../../../routes/routes.dart';
import '../../profile/profile.dart';
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
                const SizedBox(height: 32),
                const CarSpyPendingReportCard(),
                const SizedBox(height: 24),
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
            const _CarSpyGaragePlaceholder(),
            const ProfilePage(key: ValueKey('car_spy_profile')),
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

class _CarSpyGaragePlaceholder extends StatelessWidget {
  const _CarSpyGaragePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Garage',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CarSpyColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CarSpyColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.construction_rounded,
                          size: 14,
                          color: CarSpyColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'In progress',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CarSpyColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Save and manage vehicles you follow.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                  color: CarSpyColors.onSurfaceVariant.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CarSpyColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: CarSpyColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -16,
                      bottom: -16,
                      child: Icon(
                        Icons.garage_outlined,
                        size: 120,
                        color: CarSpyColors.primary.withValues(alpha: 0.06),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: CarSpyColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'COMING SOON',
                              style: TextStyle(
                                color: CarSpyColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your garage is on the way',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: CarSpyColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Soon you will be able to bookmark vehicles, track listings, and pick up where you left off — all in one place.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: CarSpyColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CarSpyColors.outlineVariant
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                size: 20,
                                color: CarSpyColors.primary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'We will notify you when it is ready.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CarSpyColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
