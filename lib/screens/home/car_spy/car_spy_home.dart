import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../constants/hive_constants.dart';
import '../../../data/inspection_storage_model.dart';
import '../../../models/local_inspection.dart';
import '../../../providers/inspection_provider.dart';
import '../../../routes/routes.dart';
import '../../attendance/attendance_screen.dart';
import '../../work_assigned/work_assigned_screen.dart';
import '../reports_page.dart';
import 'car_spy_data.dart';
import 'widgets/car_spy_bottom_nav_bar.dart';
import 'widgets/car_spy_hero_section.dart';
import 'widgets/car_spy_top_app_bar.dart';

class CarSpyHome extends ConsumerStatefulWidget {
  final int initialIndex;

  const CarSpyHome({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CarSpyHome> createState() => _CarSpyHomeState();
}

class _CarSpyHomeState extends ConsumerState<CarSpyHome> {
  late int _selectedIndex;
  int _selectedChartTab = 0; // 0 = daily, 1 = monthly
  Box<InspectionStorageModel>? _inspectionBox;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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

  // ── Chart helpers ────────────────────────────────────────────────────────

  List<String> _getDayLabels() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return days[day.weekday - 1];
    });
  }

  List<String> _getMonthLabels() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i);
      return months[(m.month - 1) % 12];
    });
  }

  List<FlSpot> _getDailySpots(List<LocalInspection> inspections) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final count = inspections.where((insp) =>
          insp.createdAt.year == day.year &&
          insp.createdAt.month == day.month &&
          insp.createdAt.day == day.day).length;
      return FlSpot(i.toDouble(), count.toDouble());
    });
  }

  List<FlSpot> _getMonthlySpots(List<LocalInspection> inspections) {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i);
      final count = inspections.where((insp) =>
          insp.createdAt.year == m.year &&
          insp.createdAt.month == m.month).length;
      return FlSpot(i.toDouble(), count.toDouble());
    });
  }

  Widget _buildChartTabButton(String label, int index) {
    final isSelected = _selectedChartTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? CarSpyColors.onSurface
                : CarSpyColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildChartStat(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CarSpyColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: CarSpyColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInspectionChart(List<LocalInspection> inspections) {
    final isDaily = _selectedChartTab == 0;
    final spots =
        isDaily ? _getDailySpots(inspections) : _getMonthlySpots(inspections);
    final labels = isDaily ? _getDayLabels() : _getMonthLabels();
    final rawMax =
        spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final chartMaxY = rawMax < 4 ? 4.0 : rawMax + 2;
    final totalCount = spots.fold(0.0, (sum, s) => sum + s.y).toInt();
    final todayCount = spots.isNotEmpty ? spots.last.y.toInt() : 0;

    return Container(
      decoration: BoxDecoration(
        color: CarSpyColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CarSpyColors.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inspections',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: CarSpyColors.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDaily ? 'Last 7 days' : 'Last 6 months',
                    style: TextStyle(
                      fontSize: 12,
                      color: CarSpyColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildChartTabButton('Daily', 0),
                    _buildChartTabButton('Monthly', 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: CarSpyColors.outlineVariant.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: chartMaxY / 4,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: CarSpyColors.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: TextStyle(
                              fontSize: 11,
                              color: CarSpyColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (labels.length - 1).toDouble(),
                minY: 0,
                maxY: chartMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: CarSpyColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: CarSpyColors.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          CarSpyColors.primary.withValues(alpha: 0.18),
                          CarSpyColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildChartStat(
                  'Today',
                  todayCount.toString(),
                  Icons.today_outlined,
                  CarSpyColors.primary,
                ),
              ),
              Expanded(
                child: _buildChartStat(
                  isDaily ? 'This Week' : 'This Year (6m)',
                  totalCount.toString(),
                  Icons.bar_chart_rounded,
                  const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildInspectionChart(
              ref.watch(inspectionNotifierProvider).inspections,
            ),
          ),
          const SizedBox(height: 24),
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
        disabledIndices: const [2, 3],
      ),
    );
  }
}
