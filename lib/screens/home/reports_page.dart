import 'package:flutter/material.dart';

import '../../services/reports_cache_service.dart';
import 'car_spy/car_spy_data.dart';
import 'inspection_webview_screen.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<CachedReport> _cachedReports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final list = await ReportsCacheService.getReports();
      if (mounted) setState(() => _cachedReports = list);
    } catch (e) {
      if (mounted) setState(() => _cachedReports = []);
    }
  }

  Widget _buildReportCard(BuildContext context, CachedReport report) {
    final dateStr = report.createdAt.year == DateTime.now().year
        ? '${report.createdAt.day}/${report.createdAt.month}'
        : '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspectionWebViewScreen(
                  url: report.url,
                  title: 'Inspection #${report.inspectionId}',
                ),
              ),
            ).then((_) => _loadReports());
          },
          splashColor: CarSpyColors.primary.withValues(alpha: 0.1),
          highlightColor: CarSpyColors.primary.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: CarSpyColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: CarSpyColors.outlineVariant.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CarSpyColors.outlineVariant.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: CarSpyColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inspection #${report.inspectionId}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: CarSpyColors.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: CarSpyColors.onSurfaceVariant
                                .withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: CarSpyColors.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reports',
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
                                Icons.folder_open_rounded,
                                size: 14,
                                color: CarSpyColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Your files',
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
                      'View your submitted inspection reports.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                        color: CarSpyColors.onSurfaceVariant
                            .withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_cachedReports.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 56,
                            color: CarSpyColors.primary.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No reports yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: CarSpyColors.onSurface,
                              letterSpacing: -0.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Complete an inspection to see your reports here.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: CarSpyColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildReportCard(context, _cachedReports[index]),
                    childCount: _cachedReports.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
