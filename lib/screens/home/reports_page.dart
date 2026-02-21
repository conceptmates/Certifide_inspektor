import 'package:flutter/material.dart';

import '../../services/reports_cache_service.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = report.createdAt.year == DateTime.now().year
        ? '${report.createdAt.day}/${report.createdAt.month}'
        : '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}';
    // Accent matches Quick Actions on home; use primary in dark for contrast
    final accentColor = isDark ? theme.colorScheme.primary : const Color(0xFF6366F1);
    final cardBg = isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white;
    final titleColor = isDark ? theme.colorScheme.onSurface : const Color(0xFF1F2937);
    final subtitleColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspection #${report.inspectionId}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: subtitleColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8F9FA);
    final headerBg = isDark ? theme.colorScheme.surface : Colors.white;
    final titleColor = isDark ? theme.colorScheme.onSurface : const Color(0xFF1F2937);
    final subtitleColor = isDark ? theme.colorScheme.onSurfaceVariant : const Color(0xFF6B7280);
    final emptyColor = isDark ? theme.colorScheme.onSurfaceVariant : const Color(0xFF9CA3AF);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header card (same pattern as Home welcome block)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: headerBg,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark ? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)) : null,
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ) ?? TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'View your submitted inspection reports',
                        style: TextStyle(
                          fontSize: 15,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_cachedReports.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 72,
                          color: emptyColor,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No reports yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Complete an inspection to see your reports here.',
                          style: TextStyle(
                            fontSize: 15,
                            color: emptyColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
