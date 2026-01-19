import 'package:flutter/material.dart';
import '../../models/inspection_history_model.dart';
import '../../models/pagination_data_model.dart';
import '../../services/api_services.dart';
import '../../widgets/fade_animation.dart';
import 'inspection_webview_screen.dart';
import 'package:intl/intl.dart';

class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});

  @override
  State<InspectionHistoryScreen> createState() => _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<InspectionHistoryScreen> {
  List<InspectionHistory> _inspections = [];
  PaginationData? _paginationData;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInspectionHistory();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _paginationData != null) {
        if (_currentPage < _paginationData!.lastPage) {
          _loadMoreInspections();
        }
      }
    }
  }

  Future<void> _loadInspectionHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await ApiService.getInspectionHistory(
        context,
        page: 1,
      );

      if (result['success'] && mounted) {
        setState(() {
          _inspections = List<InspectionHistory>.from(result['inspections']);
          _paginationData = result['pagination'];
          _currentPage = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreInspections() async {
    if (mounted) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final nextPage = _currentPage + 1;
      final result = await ApiService.getInspectionHistory(
        context,
        page: nextPage,
      );

      if (result['success'] && mounted) {
        setState(() {
          _inspections.addAll(List<InspectionHistory>.from(result['inspections']));
          _paginationData = result['pagination'];
          _currentPage = nextPage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inspectionDate = DateTime(date.year, date.month, date.day);

    if (inspectionDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (inspectionDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    }

    return DateFormat('MMM d, yyyy, h:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInspectionCard(InspectionHistory inspection) {
    final vehicleInfo = inspection.vehicleInfo;
    final registrationNumber = vehicleInfo['registration_number'] ?? 'N/A';
    final makeModel = vehicleInfo['make_model'] ?? 'Unknown Vehicle';
    final variant = vehicleInfo['variant'] ?? '';
    final year = vehicleInfo['manufacturing_year'] ?? '';
    final color = vehicleInfo['color'] ?? '';

    return FadeAnimation(
      0.1,
      Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            onTap: () {
              if (inspection.links != null &&
                  inspection.links!['view'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InspectionWebViewScreen(
                      url: inspection.links!['view']!,
                      title: 'Inspection #${inspection.id}',
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          makeModel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(inspection.status)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(inspection.status)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          inspection.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _getStatusColor(inspection.status),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (variant.isNotEmpty && variant != 'N/A')
                    Text(
                      '$variant${year.isNotEmpty && year != 'N/A' ? ' • $year' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (color.isNotEmpty && color != 'N/A')
                    Text(
                      color,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(inspection.date),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (registrationNumber.isNotEmpty &&
                          registrationNumber != 'N/A')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            registrationNumber,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        inspection.inspectorName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Inspections Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your inspection history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadInspectionHistory,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              backgroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Inspection History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadInspectionHistory,
            icon: Icon(
              Icons.refresh,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading inspections...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _inspections.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadInspectionHistory,
                  color: const Color(0xFF1A73E8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Text(
                              '${_paginationData?.total ?? 0} inspections',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Page $_currentPage of ${_paginationData?.lastPage ?? 1}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _inspections.length +
                              (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _inspections.length) {
                              return _buildLoadingIndicator();
                            }
                            return _buildInspectionCard(
                              _inspections[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
