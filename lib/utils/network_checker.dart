import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class NetworkConnectivityHandler {
  static final NetworkConnectivityHandler _instance =
      NetworkConnectivityHandler._internal();
  StreamSubscription? _connectivitySubscription;
  bool _snackBarVisible = false;

  factory NetworkConnectivityHandler() {
    return _instance;
  }

  NetworkConnectivityHandler._internal();

  void initialize(BuildContext context) {
    _initConnectivityListener(context);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<bool> hasInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    return await InternetConnectionChecker.createInstance().hasConnection;
  }

  Future<void> _initConnectivityListener(BuildContext context) async {
    // Check initial connectivity
    bool hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      _showNoInternetSnackBar(context);
    }

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final result = results.first;
      if (result == ConnectivityResult.none) {
        _showNoInternetSnackBar(context);
      } else {
        bool hasInternet = await hasInternetConnection();
        if (!hasInternet) {
          _showNoInternetSnackBar(context);
        } else {
          _hideNoInternetSnackBar(context);
          // _showOnlineSnackBar(context);
        }
      }
    });
  }

  void _showNoInternetSnackBar(BuildContext context) {
    if (!_snackBarVisible && context.mounted) {
      _snackBarVisible = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.signal_wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('No Internet Connection'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () async {
              bool hasInternet = await hasInternetConnection();
              if (hasInternet) {
                _hideNoInternetSnackBar(context);
                // _showOnlineSnackBar(context);
              }
            },
          ),
        ),
      );
    }
  }

  void _hideNoInternetSnackBar(BuildContext context) {
    if (_snackBarVisible && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _snackBarVisible = false;
    }
  }

  void showErrorDialog(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: _buildErrorTitle(error),
          content: _buildErrorContent(error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                bool hasInternet = await hasInternetConnection();
                if (hasInternet) {
                  // Implement retry logic here
                }
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorTitle(dynamic error) {
    IconData icon;
    String title;
    Color iconColor;

    if (error.toString().contains('NetworkClient') ||
        error.toString().contains('SocketException')) {
      icon = Icons.wifi_off;
      title = 'Connection Error';
      iconColor = Colors.red;
    } else if (error.toString().contains('Unauthorized')) {
      icon = Icons.security;
      title = 'Authentication Error';
      iconColor = Colors.orange;
    } else if (error.toString().contains('TimeoutException')) {
      icon = Icons.timer_off;
      title = 'Timeout Error';
      iconColor = Colors.red;
    } else {
      icon = Icons.error_outline;
      title = 'Error';
      iconColor = Colors.red;
    }

    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }

  Widget _buildErrorContent(dynamic error) {
    String message = getReadableErrorMessage(error);
    String suggestion = _getErrorSuggestion(error);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 12),
        Text(
          suggestion,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _getErrorSuggestion(dynamic error) {
    if (error.toString().contains('NetworkClient') ||
        error.toString().contains('SocketException')) {
      return '• Check your internet connection\n'
          '• Make sure you\'re connected to Wi-Fi or mobile data\n'
          '• Try switching between Wi-Fi and mobile data';
    } else if (error.toString().contains('Unauthorized')) {
      return '• Your session might have expired\n'
          '• Try logging in again\n'
          '• Contact support if the problem persists';
    } else if (error.toString().contains('TimeoutException')) {
      return '• The server is taking too long to respond\n'
          '• Check your internet speed\n'
          '• Try again in a few moments';
    }
    return '• Try refreshing the page\n'
        '• Check if the app is up to date\n'
        '• Contact support if the problem persists';
  }

  String getReadableErrorMessage(dynamic error) {
    if (error.toString().contains('NetworkClient')) {
      return 'Unable to connect to the server.';
    } else if (error.toString().contains('Unauthorized')) {
      return 'Your session has expired.';
    } else if (error.toString().contains('SocketException')) {
      return 'Unable to establish a network connection.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'The connection has timed out.';
    } else if (error.toString().contains('Permission')) {
      return 'You don\'t have permission to perform this action.';
    }
    return 'An unexpected error occurred.';
  }
}
