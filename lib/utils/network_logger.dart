// lib/utils/network_logger.dart

import 'dart:convert';
import 'dart:developer';

class NetworkLogger {
  static bool _loggingEnabled = true;

  /// Enable or disable network logging
  static void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
    log(_loggingEnabled
        ? '🟢 NETWORK LOGGING: Enabled'
        : '🔴 NETWORK LOGGING: Disabled');
  }

  /// Check if logging is enabled
  static bool get isLoggingEnabled => _loggingEnabled;

  /// Log a summary of all network activity for debugging
  static void logNetworkSummary() {
    if (!_loggingEnabled) return;

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('📊 NETWORK ACTIVITY SUMMARY');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('📅 Generated at: ${DateTime.now().toIso8601String()}');
    log('🔧 Logging Status: ${_loggingEnabled ? "ENABLED" : "DISABLED"}');
    log('');
    log('🌐 Available API Endpoints:');
    log('   • Authentication: /auth/login, /auth/register, /auth/refresh');
    log('   • Profile: /auth/me');
    log('   • Inspections: /inspections (GET, POST)');
    log('   • Tokens: /tokens/balance, /tokens/allocate, /tokens/inspectors');
    log('   • Approval: /inspections/{id}/approve-api');
    log('');
    log('📋 Common Network Issues to Check:');
    log('   • SocketException: No internet connection');
    log('   • TimeoutException: Server response timeout');
    log('   • HandshakeException: SSL/Certificate issues');
    log('   • FormatException: Invalid JSON response');
    log('   • HTTP 401: Authentication token expired');
    log('   • HTTP 403: Access denied');
    log('   • HTTP 500: Server error');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Log device network connectivity info
  static void logDeviceInfo() {
    if (!_loggingEnabled) return;

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('📱 DEVICE NETWORK INFO');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('📅 Time: ${DateTime.now().toIso8601String()}');
    log('🌐 Base URL: https://dev.certifide.in/api');
    log('⏱️ Request Timeout: 30 seconds');
    log('🔒 SSL Verification: Enabled');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Log custom debug information
  static void logDebug(String message, {String? category}) {
    if (!_loggingEnabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final categoryPrefix = category != null ? '[$category] ' : '';
    log('🐛 DEBUG $categoryPrefix($timestamp): $message');
  }

  /// Log warning information
  static void logWarning(String message, {String? category}) {
    if (!_loggingEnabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final categoryPrefix = category != null ? '[$category] ' : '';
    log('⚠️ WARNING $categoryPrefix($timestamp): $message');
  }

  /// Log error information
  static void logError(String message, {String? category, dynamic error}) {
    if (!_loggingEnabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final categoryPrefix = category != null ? '[$category] ' : '';
    log('❌ ERROR $categoryPrefix($timestamp): $message');
    if (error != null) {
      log('   Stack Trace: $error');
    }
  }

  /// Format JSON for better readability in logs
  static String formatJson(String jsonString) {
    try {
      final jsonData = json.decode(jsonString);
      return JsonEncoder.withIndent('  ').convert(jsonData);
    } catch (e) {
      return jsonString; // Return original if parsing fails
    }
  }

  /// Get network error category based on error type
  static String getErrorCategory(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception')) {
      return 'NETWORK_CONNECTIVITY';
    } else if (errorString.contains('timeoutexception')) {
      return 'REQUEST_TIMEOUT';
    } else if (errorString.contains('handshakeexception')) {
      return 'SSL_CERTIFICATE';
    } else if (errorString.contains('formatexception')) {
      return 'RESPONSE_FORMAT';
    } else if (errorString.contains('unauthorizedexception')) {
      return 'AUTHENTICATION';
    } else {
      return 'UNKNOWN_ERROR';
    }
  }

  /// Create a troubleshooting guide based on error type
  static String getTroubleshootingTip(String errorCategory) {
    switch (errorCategory) {
      case 'NETWORK_CONNECTIVITY':
        return 'Check internet connection and server availability';
      case 'REQUEST_TIMEOUT':
        return 'Server is responding slowly. Try again or check server status';
      case 'SSL_CERTIFICATE':
        return 'SSL certificate issue. Check server certificate validity';
      case 'RESPONSE_FORMAT':
        return 'Server returned invalid data format. Check API response';
      case 'AUTHENTICATION':
        return 'Authentication failed. Check token validity or re-login';
      default:
        return 'Unknown error occurred. Check logs for more details';
    }
  }
}
