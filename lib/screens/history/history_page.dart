import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../models/inspection_history_model.dart';
import '../../models/pagination_data_model.dart';
import '../../services/api_services.dart';
import '../../utils/loading_animation.dart';
import '../../widgets/error_widget.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<InspectionHistory> _historyItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  late PaginationData _paginationData;
  final ScrollController _scrollController = ScrollController();

  // Add a cancellation flag
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _paginationData = PaginationData(
      currentPage: 1,
      lastPage: 1,
      perPage: 10,
      total: 0,
    );
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Set cancellation flag
    _isCancelled = true;
    _scrollController.dispose();
    super.dispose();
  }

  // Modify setState to check mounted and cancellation flag
  void _safeSetState(VoidCallback fn) {
    if (!_isCancelled && mounted) {
      setState(fn);
    }
  }

  String _getReadableErrorMessage(dynamic error) {
    // Convert technical errors to user-friendly messages
    if (error.toString().contains('NetworkClient')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    } else if (error.toString().contains('Unauthorized')) {
      return 'Your session has expired. Please login again.';
    } else if (error.toString().contains('SocketException')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Connection timed out. Please try again.';
    } else if (error.toString().contains('Permission')) {
      return 'Permission denied. Please check your credentials.';
    }
    // Default error message
    return 'Something went wrong. Please try again later.';
  }

  Future<void> _launchURL(String url) async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: LoadingAnimation(),
            );
          },
        );
      }

      final Uri uri = Uri.parse(url);

      // Remove loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Launch URL using the new method
      await _launchInBrowser(uri);
    } catch (e) {
      // Remove loading indicator if it's showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        // Show user-friendly error message
        String errorMessage = _getReadableErrorMessage(e);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(errorMessage),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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

    _safeSetState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await ApiService.getInspectionHistory(
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
          _error = result['message'];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      _safeSetState(() {
        _error = 'Failed to load more data';
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    _safeSetState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await ApiService.getInspectionHistory(context, page: 1);

      if (_isCancelled) return;

      if (result['success']) {
        _safeSetState(() {
          _historyItems = result['inspections'];
          _paginationData = result['pagination'];
          _isLoading = false;
        });
      } else {
        _safeSetState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      _safeSetState(() {
        _error = 'Failed to load history';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Inspection History'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingAnimation());
    }

    if (_error.isNotEmpty) {
      return ErrorDisplayWidget(
        message: _getReadableErrorMessage(_error),
        onRetry: _loadHistory,
      );
    }

    if (_historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No inspection history found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _historyItems.length +
          (_isLoadingMore &&
                  _paginationData.currentPage < _paginationData.lastPage
              ? 1
              : 0),
      itemBuilder: (context, index) {
        if (index == _historyItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: LoadingAnimation(),
            ),
          );
        }

        final history = _historyItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Registration: ${history.vehicleInfo['registration_number']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(history.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    history.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(history.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Make & Model: ${history.vehicleInfo['make_model']}'),
                Text('Variant: ${history.vehicleInfo['variant']}'),
                Text(
                    'Manufacturing Year: ${history.vehicleInfo['manufacturing_year']}'),
                Text('Fuel Type: ${history.vehicleInfo['fuel_type']}'),
                Text('Inspector: ${history.inspectorName}'),
                Text(
                    'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(history.date)}'),
              ],
            ),
            trailing: history.status == 'approved'
                ? IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    onPressed: () {
                      if (history.links != null &&
                          history.links!['view'] != null) {
                        _launchURL(history.links!['view']!);
                      }
                    },
                  )
                : null,
            onTap: () {
              if (history.status == 'approved' &&
                  history.links != null &&
                  history.links!['view'] != null) {
                _launchURL(history.links!['view']!);
              }
            },
          ),
        );
      },
    );
  }
}
