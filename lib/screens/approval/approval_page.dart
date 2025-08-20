import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/inspection_history_model.dart';
import '../../models/pagination_data_model.dart';
import '../../services/api_services.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  List<InspectionHistory> _inspections = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  late PaginationData _paginationData;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _paginationData = PaginationData(
      currentPage: 1,
      lastPage: 1,
      perPage: 10,
      total: 0,
    );
    _loadInspections();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;
    if (_paginationData.currentPage >= _paginationData.lastPage) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await ApiService.getInspectionHistory(
        context,
        page: _paginationData.currentPage + 1,
      );

      if (result['success']) {
        setState(() {
          _inspections.addAll(result['inspections']);
          _paginationData = result['pagination'];
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load more data';
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadInspections() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await ApiService.getInspectionHistory(context, page: 1);

      if (result['success']) {
        setState(() {
          _inspections = result['inspections'];
          _paginationData = result['pagination'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load inspections';
        _isLoading = false;
      });
    }
  }

  void _refreshInspections() {
    _loadInspections();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Approvals',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshInspections,
            ),
          ],
          bottom: TabBar(
            physics: const NeverScrollableScrollPhysics(),
            enableFeedback: true,
            indicatorColor: Theme.of(context).primaryColor,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _refreshInspections,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _PendingApprovalsTab(
                        inspections: _inspections
                            .where((i) => i.status.toLowerCase() == 'pending')
                            .toList(),
                        onRefresh: _refreshInspections,
                        scrollController: _scrollController,
                        isLoadingMore: _isLoadingMore &&
                            _paginationData.currentPage <
                                _paginationData.lastPage,
                      ),
                      _ApprovedInspectionsTab(
                        inspections: _inspections
                            .where((i) => i.status.toLowerCase() == 'approved')
                            .toList(),
                        scrollController: _scrollController,
                        isLoadingMore: _isLoadingMore &&
                            _paginationData.currentPage <
                                _paginationData.lastPage,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _PendingApprovalsTab extends StatelessWidget {
  final List<InspectionHistory> inspections;
  final VoidCallback onRefresh;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const _PendingApprovalsTab({
    required this.inspections,
    required this.onRefresh,
    required this.scrollController,
    required this.isLoadingMore,
  });

  void _showApprovalDialog(BuildContext context, InspectionHistory inspection) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Approve Inspection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inspection #${inspection.id}'),
              const SizedBox(height: 8),
              Text('Vehicle: ${inspection.vehicleInfo['make_model'] ?? 'N/A'}'),
              Text('Inspector: ${inspection.inspectorName}'),
              Text('Date: ${_formatDate(inspection.date)}'),
              const SizedBox(height: 16),
              const Text('Are you sure you want to approve this inspection?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Approving...'),
                        ],
                      ),
                    );
                  },
                );

                try {
                  final result = await ApiService.approveInspection(
                    inspection.id.toString(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);

                    if (result['status'] == 'success') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Inspection approved successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      onRefresh();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(result['message'] ??
                              'Failed to approve inspection'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (inspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending approvals',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        itemCount: inspections.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == inspections.length && isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final inspection = inspections[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange.shade50,
                        child: Icon(
                          Icons.pending,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inspection #${inspection.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(inspection.date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.directions_car,
                    'Vehicle',
                    inspection.vehicleInfo['make_model'] ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.person,
                    'Inspector',
                    inspection.inspectorName,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.visibility),
                          label: const Text('View'),
                          onPressed: () async {
                            if (inspection.links?['view'] != null) {
                              await launchUrl(
                                  Uri.parse(inspection.links!['view']!));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          onPressed: () =>
                              _showApprovalDialog(context, inspection),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _ApprovedInspectionsTab extends StatelessWidget {
  final List<InspectionHistory> inspections;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const _ApprovedInspectionsTab({
    required this.inspections,
    required this.scrollController,
    required this.isLoadingMore,
  });

  void _copyLinkToClipboard(BuildContext context, String? link) {
    if (link != null) {
      Clipboard.setData(ClipboardData(text: link)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Link copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  void _showDetailsSheet(BuildContext context, InspectionHistory inspection) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Inspection Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy link',
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyLinkToClipboard(
                    context,
                    inspection.links?['view'],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              'Registration',
              inspection.vehicleInfo['registration_number'] ?? 'N/A',
            ),
            _buildDetailRow(
              'Make/Model',
              inspection.vehicleInfo['make_model'] ?? 'N/A',
            ),
            _buildDetailRow('Inspector', inspection.inspectorName),
            _buildDetailRow('Created', _formatDate(inspection.date)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Full Report'),
                    onPressed: () async {
                      if (inspection.links?['view'] != null) {
                        await launchUrl(Uri.parse(inspection.links!['view']!));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (inspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No approved inspections',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      itemCount: inspections.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == inspections.length && isLoadingMore) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final inspection = inspections[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showDetailsSheet(context, inspection),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inspection #${inspection.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(inspection.date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy link',
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () => _copyLinkToClipboard(
                          context,
                          inspection.links?['view'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 20),
                        onPressed: () => _showDetailsSheet(context, inspection),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.directions_car,
                    'Vehicle',
                    inspection.vehicleInfo['make_model'] ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.person,
                    'Inspector',
                    inspection.inspectorName,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
