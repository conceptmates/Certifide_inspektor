import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/inspection_history_model.dart';
import '../../models/inspection_state.dart';
import '../../models/inspection_template_model.dart';
import '../../models/local_inspection.dart';
import '../../models/pending_media.dart';
import '../../models/pagination_data_model.dart';
import '../../providers/inspection_provider.dart';
import '../../routes/routes.dart';
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
  List<InspectionHistory> _pendingItems = [];
  bool _isPendingLoading = false;
  bool _isPendingLoadingMore = false;
  String _pendingError = '';
  late PaginationData _pendingPagination;
  final ScrollController _pendingScrollController = ScrollController();
  final Set<String> _resumingIds = {};

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
    _pendingPagination = PaginationData(
      currentPage: 1,
      lastPage: 1,
      perPage: 10,
      total: 0,
    );
    _loadHistory();
    _scrollController.addListener(_onScroll);
    _pendingScrollController.addListener(_onPendingScroll);
    _loadPendingInspections();
    // Load the local "awaiting upload" media queue and opportunistically sync
    // it (the provider also auto-syncs on reconnect).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(inspectionNotifierProvider.notifier).refreshMediaQueue();
      }
    });
  }

  final Set<String> _uploadingMediaIds = {};

  /// Queue containers whose per-file media list is expanded in the UI.
  final Set<String> _expandedMediaIds = {};

  IconData _mediaTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam_outlined;
      case 'audio':
        return Icons.mic_none_outlined;
      case 'file':
        return Icons.insert_drive_file_outlined;
      case 'multiImage':
        return Icons.collections_outlined;
      case 'image':
      default:
        return Icons.image_outlined;
    }
  }

  String _mediaRowLabel(String key, PendingMedia m) {
    switch (m.mediaType) {
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'file':
        return 'Document';
      case 'multiImage':
        final idx = int.tryParse(key.split('_').last);
        return idx != null ? 'Photo ${idx + 1}' : 'Photo';
      case 'image':
      default:
        return 'Image';
    }
  }

  /// One media file with its own progress bar + status.
  Widget _mediaFileRow(String key, PendingMedia m) {
    final status = m.uploadStatus;
    final uploading = status == PendingMediaStatus.uploading;
    final done = status == PendingMediaStatus.uploaded;
    final failed = status == PendingMediaStatus.failed;

    final Color barColor = failed
        ? const Color(0xFFEF4444)
        : (done ? const Color(0xFF22C55E) : CarSpyColors.primary);
    // null => indeterminate (actively uploading); else a filled fraction.
    final double? barValue = uploading ? null : (done || failed ? 1.0 : 0.05);

    final String statusText = failed
        ? 'Failed'
        : (done ? 'Uploaded' : (uploading ? 'Uploading…' : 'Queued'));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_mediaTypeIcon(m.mediaType),
              size: 18, color: CarSpyColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _mediaRowLabel(key, m),
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: barValue,
                    minHeight: 4,
                    backgroundColor: CarSpyColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            const Icon(Icons.check_circle,
                size: 16, color: Color(0xFF22C55E))
          else if (failed)
            const Icon(Icons.error_outline,
                size: 16, color: Color(0xFFEF4444))
          else if (uploading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.schedule,
                size: 16, color: CarSpyColors.onSurfaceVariant),
        ],
      ),
    );
  }

  Future<void> _uploadMedia(LocalInspection container) async {
    if (_uploadingMediaIds.contains(container.id)) return;
    _safeSetState(() => _uploadingMediaIds.add(container.id));
    try {
      final ok = await ref
          .read(inspectionNotifierProvider.notifier)
          .uploadInspectionMedia(container);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'All media uploaded'
              : 'Some media still pending — will retry when online'),
          backgroundColor: ok ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.')),
        );
      }
    } finally {
      _safeSetState(() => _uploadingMediaIds.remove(container.id));
    }
  }

  Future<void> _refreshPending() async {
    await Future.wait([
      _loadPendingInspections(),
      ref.read(inspectionNotifierProvider.notifier).refreshMediaQueue(),
    ]);
  }

  @override
  void dispose() {
    _isCancelled = true;
    _tabController.dispose();
    _scrollController.dispose();
    _pendingScrollController.dispose();
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
      margin: const EdgeInsets.only(bottom: 10),
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
            padding: const EdgeInsets.all(13),
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
                const SizedBox(height: 7),
                _infoRow('Make & Model', vehicleInfo['make_model']),
                _infoRow('Variant', vehicleInfo['variant']),
                _infoRow('Year', vehicleInfo['manufacturing_year']),
                _infoRow('Date', _formatDate(inspection.date)),
                if (canView)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () => _launchURL(inspection.links!['view']!),
                      icon: const Icon(
                        Icons.visibility_outlined,
                        color: CarSpyColors.primary,
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

  Widget _infoRow(String label, dynamic value) {
    // Hide rows the server didn't populate (e.g. the my-history endpoint omits
    // variant/year) instead of rendering a bare "N/A" placeholder.
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final text = value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
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
          _historyItems.addAll(
            List<InspectionHistory>.from(result['inspections'])
                .where((i) => i.status != 'draft'),
          );
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
          // Drafts (initialised-but-not-completed inspections) live in the
          // Pending tab only; keep them out of History so the two are exclusive.
          _historyItems = List<InspectionHistory>.from(result['inspections'])
              .where((i) => i.status != 'draft')
              .toList();
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
    _safeSetState(() {
      _isPendingLoading = true;
      _pendingError = '';
    });
    try {
      // Drafts are served only by the `status=draft` filter (the default
      // my-history list excludes them). Page through it the same way the
      // History tab pages its list so any future overflow lazy-loads.
      final result = await ApiService.getDynamicInspectionMyHistory(
        context,
        page: 1,
        status: 'draft',
      );
      if (_isCancelled) return;
      if (result['success'] == true) {
        _safeSetState(() {
          _pendingItems = List<InspectionHistory>.from(result['inspections']);
          _pendingPagination = result['pagination'];
          _isPendingLoading = false;
        });
      } else {
        _safeSetState(() {
          _pendingError = result['message'] ?? 'Failed to load pending inspections';
          _isPendingLoading = false;
        });
      }
    } catch (e) {
      _safeSetState(() {
        _pendingError = 'Failed to load pending inspections';
        _isPendingLoading = false;
      });
    }
  }

  void _onPendingScroll() {
    final pos = _pendingScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMorePending();
    }
  }

  Future<void> _loadMorePending() async {
    if (_isPendingLoadingMore ||
        _pendingPagination.currentPage >= _pendingPagination.lastPage) {
      return;
    }

    _safeSetState(() => _isPendingLoadingMore = true);

    try {
      final result = await ApiService.getDynamicInspectionMyHistory(
        context,
        page: _pendingPagination.currentPage + 1,
        status: 'draft',
      );
      if (_isCancelled) return;
      if (result['success'] == true) {
        _safeSetState(() {
          _pendingItems
              .addAll(List<InspectionHistory>.from(result['inspections']));
          _pendingPagination = result['pagination'];
          _isPendingLoadingMore = false;
        });
      } else {
        _safeSetState(() => _isPendingLoadingMore = false);
      }
    } catch (e) {
      _safeSetState(() => _isPendingLoadingMore = false);
    }
  }

  Future<void> _resumeInspection(InspectionHistory history) async {
    final id = history.idAsInt;
    if (id == null) return;
    _safeSetState(() => _resumingIds.add(history.id));
    try {
      final result = await ApiService.resumeInspection(id);
      if (_isCancelled || !mounted) return;
      if (result['success'] == true) {
        final template = result['data'] as InspectionInitializationResponse?;
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          Routes.inspection,
          arguments: {
            'isNew': true,
            'inspectionId': id,
            'vehicleDetails': _buildResumeVehicleDetails(
              history,
              template,
              brandId: result['vehicle_brand_id'] as int? ?? history.brandId,
              modelId: result['vehicle_model_id'] as int? ?? history.modelId,
            ),
            'inspectionTemplate': template,
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to resume')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    } finally {
      _safeSetState(() => _resumingIds.remove(history.id));
    }
  }

  Map<String, dynamic> _buildResumeVehicleDetails(
    InspectionHistory history,
    InspectionInitializationResponse? template, {
    int? brandId,
    int? modelId,
  }) {
    final vi = history.vehicleInfo;
    final tvi = template?.vehicleInfo;
    return {
      // brand_id/model_id are required by the submit body. Without them the
      // server rejects the resumed inspection with "failed to create
      // inspection". Fall back to the list payload's vehicle_brand/model ids.
      if (brandId != null) 'brand_id': brandId,
      if (modelId != null) 'model_id': modelId,
      // regno is dropped by the resume template's VehicleInfo unless surfaced
      // here, so a resumed draft would otherwise submit with an empty
      // registration number. Fall back to the list payload's reg fields.
      'regno': tvi?.regNo ??
          vi['registration_number']?.toString() ??
          vi['regno']?.toString() ??
          '',
      'make': tvi?.brand ?? vi['make_model']?.toString().split(' ').first ?? '',
      'model': tvi?.model ?? vi['make_model']?.toString().split(' ').skip(1).join(' ') ?? '',
      'year': tvi?.year ?? vi['manufacturing_year']?.toString() ?? '',
      'variant': tvi?.variant ?? vi['variant']?.toString() ?? '',
      'color': tvi?.colour ?? vi['color']?.toString() ?? '',
      'transmission': tvi?.transmission ?? vi['transmission']?.toString() ?? '',
    };
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

  Widget _buildPendingTab() {
    final media = ref.watch(
      inspectionNotifierProvider.select(
        (s) => (queue: s.mediaQueue, progress: s.mediaProgress),
      ),
    );
    final mediaQueue = media.queue;
    final hasAwaiting = mediaQueue.isNotEmpty;
    final hasServer = _pendingItems.isNotEmpty;

    if (_isPendingLoading && !hasAwaiting && !hasServer) {
      return const Center(child: LoadingAnimation());
    }

    // Show the server error only when there's nothing at all to display.
    if (_pendingError.isNotEmpty && !hasAwaiting && !hasServer) {
      return ErrorDisplayWidget(
        message: _pendingError,
        onRetry: _refreshPending,
      );
    }

    if (!hasAwaiting && !hasServer) {
      return RefreshIndicator(
        onRefresh: _refreshPending,
        color: CarSpyColors.primary,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 1,
          itemBuilder: (context, index) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
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
                      child: const Icon(Icons.pending_actions,
                          size: 48, color: CarSpyColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No pending inspections',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
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

    // Build a list of cheap row *builders* rather than the heavy widgets
    // themselves, so ListView.builder constructs each card (and runs its
    // per-card pendingMedia sort) lazily, only for rows in the viewport.
    final rowBuilders = <Widget Function()>[];
    if (hasAwaiting) {
      rowBuilders
          .add(() => _buildSectionHeader('AWAITING UPLOAD', mediaQueue.length));
      for (final container in mediaQueue) {
        final progress = media.progress[container.id];
        rowBuilders.add(() => _buildAwaitingUploadCard(container, progress));
      }
    }
    if (hasServer) {
      if (hasAwaiting) {
        rowBuilders
            .add(() => _buildSectionHeader('ON SERVER', _pendingItems.length));
      }
      for (final history in _pendingItems) {
        rowBuilders.add(
            () => _buildPendingCard(history, _resumingIds.contains(history.id)));
      }
    }

    return RefreshIndicator(
      onRefresh: _refreshPending,
      color: CarSpyColors.primary,
      child: ListView.builder(
        controller: _pendingScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
        itemCount: rowBuilders.length +
            (_isPendingLoadingMore &&
                    _pendingPagination.currentPage < _pendingPagination.lastPage
                ? 1
                : 0),
        itemBuilder: (context, index) {
          if (index == rowBuilders.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: LoadingAnimation(),
              ),
            );
          }
          return rowBuilders[index]();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: CarSpyColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwaitingUploadCard(
    LocalInspection container,
    MediaUploadProgress? progress,
  ) {
    final vehicleInfo =
        (container.data['vehicleInfo'] as Map?)?.cast<String, dynamic>() ??
            const {};

    final all = container.pendingMedia.values.toList();
    // Fall back to the container's own contents whenever there is no live
    // progress yet (or a stale 0-total progress), so a card never shows 0/0.
    final hasProgress = progress != null && progress.total > 0;
    final total = hasProgress ? progress.total : all.length;
    final uploaded = hasProgress
        ? progress.uploaded
        : all.where((m) => m.isUploaded).length;
    final failed = hasProgress
        ? progress.failed
        : all.where((m) => m.uploadStatus == PendingMediaStatus.failed).length;
    final isUploading =
        (progress?.isUploading ?? false) || _uploadingMediaIds.contains(container.id);
    final remaining = (total - uploaded).clamp(0, total);
    final fraction = total == 0 ? 0.0 : (uploaded / total).clamp(0.0, 1.0);

    // The per-file list auto-expands while uploading; can also be toggled.
    final expanded = isUploading || _expandedMediaIds.contains(container.id);
    // Only sort when the per-file list is actually shown. Collapsed cards (the
    // common case) skip the O(n log n) sort on every rebuild during upload.
    final mediaEntries = container.pendingMedia.entries.toList();
    if (expanded) {
      mediaEntries.sort((a, b) => a.key.compareTo(b.key));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reg: ${vehicleInfo['registration_number']?.toString().isNotEmpty == true ? vehicleInfo['registration_number'] : 'N/A'}',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'OFFLINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B82F6),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _infoRow('Make & Model', vehicleInfo['make_model']),
            _infoRow('Variant', vehicleInfo['variant']),
            _infoRow('Year', vehicleInfo['manufacturing_year']),
            const SizedBox(height: 10),
            // Media upload progress
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: isUploading && fraction == 0 ? null : fraction,
                minHeight: 6,
                backgroundColor: CarSpyColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  failed > 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF22C55E),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  failed > 0
                      ? Icons.error_outline
                      : (remaining == 0
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined),
                  size: 16,
                  color: failed > 0
                      ? const Color(0xFFF59E0B)
                      : CarSpyColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    failed > 0
                        ? '$uploaded of $total uploaded · $failed failed'
                        : (remaining == 0
                            ? 'All $total media uploaded'
                            : '$uploaded of $total media uploaded'),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                // Toggle the per-file list manually.
                InkWell(
                  onTap: () => setState(() {
                    if (expanded && !isUploading) {
                      _expandedMediaIds.remove(container.id);
                    } else {
                      _expandedMediaIds.add(container.id);
                    }
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: CarSpyColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            // Per-file progress list (shown while uploading or when expanded).
            if (expanded && mediaEntries.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Divider(height: 1),
              const SizedBox(height: 2),
              ...mediaEntries.map((e) => _mediaFileRow(e.key, e.value)),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: isUploading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Uploading…',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      // Reveal the per-file list AND start uploading.
                      onPressed: () {
                        setState(() => _expandedMediaIds.add(container.id));
                        _uploadMedia(container);
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(failed > 0 ? 'Retry upload' : 'Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CarSpyColors.primary,
                        foregroundColor: Colors.white,
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
    );
  }

  Widget _buildPendingCard(InspectionHistory inspection, bool isResuming) {
    final vehicleInfo = inspection.vehicleInfo;
    final canView = inspection.links != null && inspection.links!['view'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(13),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'DRAFT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _infoRow('Make & Model', vehicleInfo['make_model']),
            _infoRow('Variant', vehicleInfo['variant']),
            _infoRow('Year', vehicleInfo['manufacturing_year']),
            _infoRow('Date', _formatDate(inspection.date)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canView)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _launchURL(inspection.links!['view']!),
                    icon: const Icon(Icons.visibility_outlined,
                        color: CarSpyColors.primary),
                  ),
                if (inspection.isResumable)
                  isResuming
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Resume'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF59E0B),
                          ),
                          onPressed: () => _resumeInspection(inspection),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: (isOnPendingTab ? _isPendingLoading : _isHistoryLoading)
                          ? Colors.grey
                          : CarSpyColors.primary,
                    ),
                    onPressed: (isOnPendingTab ? _isPendingLoading : _isHistoryLoading)
                        ? null
                        : (isOnPendingTab ? _refreshPending : _loadHistory),
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
                  _buildPendingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

