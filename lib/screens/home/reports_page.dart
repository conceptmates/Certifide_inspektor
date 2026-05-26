import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/inspection_history_model.dart';
import '../../models/local_inspection.dart';
import '../../models/pagination_data_model.dart';
import '../../providers/inspection_provider.dart';
import '../../services/api_services.dart';
import '../../utils/loading_animation.dart';
import '../../widgets/error_widget.dart';
import 'car_spy/car_spy_data.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // History tab state
  List<InspectionHistory> _historyItems = [];
  bool _isHistoryLoading = true;
  bool _isLoadingMore = false;
  String _historyError = '';
  late PaginationData _paginationData;
  final ScrollController _scrollController = ScrollController();
  bool _isCancelled = false;

  // Pending tab state
  bool _isPendingInitialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _paginationData = PaginationData(
      currentPage: 1,
      lastPage: 1,
      perPage: 10,
      total: 0,
    );
    _loadHistory();
    _scrollController.addListener(_onScroll);
    _loadPendingInspections();
  }

  @override
  void dispose() {
    _isCancelled = true;
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isCancelled && mounted) setState(fn);
  }

  // --- History ---

  String _getReadableErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.contains('NetworkClient')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    } else if (str.contains('Unauthorized')) {
      return 'Your session has expired. Please login again.';
    } else if (str.contains('SocketException')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (str.contains('TimeoutException')) {
      return 'Connection timed out. Please try again.';
    } else if (str.contains('Permission')) {
      return 'Permission denied. Please check your credentials.';
    }
    return 'Something went wrong. Please try again later.';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return CarSpyColors.onSurfaceVariant;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today, ${DateFormat('h:mm a').format(date)}';
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    }
    return DateFormat('MMM d, yyyy, h:mm a').format(date);
  }

  Future<void> _launchURL(String url) async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: LoadingAnimation());
          },
        );
      }

      final Uri uri = Uri.parse(url);

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      await _launchInBrowser(uri);
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(_getReadableErrorMessage(e)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildHistoryCard(InspectionHistory inspection) {
    final vehicleInfo = inspection.vehicleInfo;
    final statusColor = _getStatusColor(inspection.status);
    final canView = inspection.links != null &&
        inspection.links!['view'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
          splashColor: CarSpyColors.primary.withValues(alpha: 0.08),
          highlightColor: CarSpyColors.primary.withValues(alpha: 0.04),
          onTap: null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reg: ${vehicleInfo['registration_number'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        inspection.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _infoRow('Make & Model', vehicleInfo['make_model']),
                _infoRow('Variant', vehicleInfo['variant']),
                _infoRow('Year', vehicleInfo['manufacturing_year']),
                _infoRow('Date', _formatDate(inspection.date)),
                if (canView) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => _launchURL(inspection.links!['view']!),
                      icon: Icon(
                        Icons.visibility_outlined,
                        color: CarSpyColors.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    final text = (value == null || value.toString().trim().isEmpty)
        ? 'N/A'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore ||
        _paginationData.currentPage >= _paginationData.lastPage) {
      return;
    }

    _safeSetState(() => _isLoadingMore = true);

    try {
      final result = await ApiService.getDynamicInspectionMyHistory(
        context,
        page: _paginationData.currentPage + 1,
      );
      if (_isCancelled) return;
      if (result['success']) {
        _safeSetState(() {
          _historyItems.addAll(result['inspections']);
          _paginationData = result['pagination'];
          _isLoadingMore = false;
        });
      } else {
        _safeSetState(() {
          _historyError = result['message'];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      _safeSetState(() {
        _historyError = 'Failed to load more data';
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    _safeSetState(() {
      _isHistoryLoading = true;
      _historyError = '';
    });
    try {
      final result = await ApiService.getDynamicInspectionMyHistory(context, page: 1);
      if (_isCancelled) return;
      if (result['success']) {
        _safeSetState(() {
          _historyItems = result['inspections'];
          _paginationData = result['pagination'];
          _isHistoryLoading = false;
        });
      } else {
        _safeSetState(() {
          _historyError = result['message'];
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      _safeSetState(() {
        _historyError = 'Failed to load history';
        _isHistoryLoading = false;
      });
    }
  }

  // --- Pending ---

  Future<void> _loadPendingInspections() async {
    try {
      await Future.microtask(() {
        ref.read(inspectionNotifierProvider.notifier).loadInspections();
      });
      _safeSetState(() => _isPendingInitialLoadComplete = true);
    } catch (e) {
      _safeSetState(() => _isPendingInitialLoadComplete = true);
    }
  }

  void _showCooldownMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please wait a few seconds before refreshing again'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSubmission(LocalInspection inspection) async {
    try {
      final success = await ref
          .read(inspectionNotifierProvider.notifier)
          .retrySubmission(inspection);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Inspection submitted successfully'
                : 'Failed to submit inspection'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting inspection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInspectionDetailsDialog(LocalInspection inspection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inspection Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Inspection ID: ${inspection.id}'),
              Text(
                  'Created: ${DateFormat('dd-MM-yyyy hh:mm a').format(inspection.createdAt)}'),
              Text('Status: ${inspection.status}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --- Tab content builders ---

  Widget _buildHistoryTab() {
    if (_isHistoryLoading) {
      return const Center(child: LoadingAnimation());
    }
    if (_historyError.isNotEmpty) {
      return ErrorDisplayWidget(
        message: _getReadableErrorMessage(_historyError),
        onRetry: _loadHistory,
      );
    }
    if (_historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: CarSpyColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.history,
                  size: 48, color: CarSpyColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            const Text(
              'No inspection history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Completed inspections will appear here.',
              style: TextStyle(
                  fontSize: 14, color: CarSpyColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: CarSpyColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
        itemCount: _historyItems.length +
            (_isLoadingMore &&
                    _paginationData.currentPage < _paginationData.lastPage
                ? 1
                : 0),
        itemBuilder: (context, index) {
          if (index == _historyItems.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: LoadingAnimation(),
              ),
            );
          }
          return _buildHistoryCard(_historyItems[index]);
        },
      ),
    );
  }

  Widget _buildPendingTab(({
    List<LocalInspection> inspections,
    bool isLoading,
    bool refreshCooldown,
    Map<String, bool> submittingStates,
  }) provider) {
    if (!_isPendingInitialLoadComplete) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading inspections...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return Column(
      children: [
        if (provider.inspections.any(
            (i) => provider.submittingStates[i.id] == true))
          const LinearProgressIndicator(),
        Expanded(
          child: provider.isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading inspections...',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : provider.inspections.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending inspections',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 16),
                      itemCount: provider.inspections.length,
                      itemBuilder: (context, index) {
                        final inspection = provider.inspections[index];
                        final displayId = inspection.id.length > 8
                            ? inspection.id.substring(0, 8)
                            : inspection.id;
                        final isSubmitting =
                            provider.submittingStates[inspection.id] ?? false;
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(
                              'Inspection $displayId',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Created: ${DateFormat('dd-MM-yyyy hh:mm a').format(inspection.createdAt)}\n'
                              'Status: ${inspection.status}${isSubmitting ? ' Submitting...' : ''}',
                            ),
                            leading: IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () =>
                                  _showInspectionDetailsDialog(inspection),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: isSubmitting
                                  ? null
                                  : () => _handleSubmission(inspection),
                              tooltip: isSubmitting
                                  ? 'Submitting...'
                                  : 'Retry submission',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inspectionState = ref.watch(
      inspectionNotifierProvider.select(
        (s) => (
          inspections: s.inspections,
          isLoading: s.isLoading,
          refreshCooldown: s.refreshCooldown,
          submittingStates: s.submittingStates,
        ),
      ),
    );
    final isOnPendingTab = _tabController.index == 1;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (isOnPendingTab)
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: (inspectionState.isLoading ||
                                inspectionState.refreshCooldown)
                            ? Colors.grey
                            : CarSpyColors.primary,
                      ),
                      onPressed:
                          (inspectionState.isLoading ||
                                  inspectionState.refreshCooldown)
                              ? _showCooldownMessage
                              : () => ref
                                  .read(inspectionNotifierProvider.notifier)
                                  .loadInspections(),
                    ),
                  if (!isOnPendingTab)
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: _isHistoryLoading
                            ? Colors.grey
                            : CarSpyColors.primary,
                      ),
                      onPressed: _isHistoryLoading ? null : _loadHistory,
                    ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: CarSpyColors.primary,
              unselectedLabelColor: CarSpyColors.onSurfaceVariant,
              indicatorColor: CarSpyColors.primary,
              tabs: const [
                Tab(text: 'History'),
                Tab(text: 'Pending'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(),
                  _buildPendingTab(inspectionState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

