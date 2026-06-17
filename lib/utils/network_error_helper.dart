import 'dart:async' show TimeoutException;
import 'dart:io' show HandshakeException, SocketException;

import 'package:flutter/material.dart';

/// Centralised handling of connectivity failures so every screen speaks about
/// being offline the same calm way the login page does — instead of leaking raw
/// `Network error: SocketException...` strings from the API layer into the UI.
///
/// Used by the login page, the vehicle-details form and the home dashboard.
class NetworkErrorHelper {
  const NetworkErrorHelper._();

  /// The canonical "you're offline" copy shown before a request is attempted.
  static const String offlineMessage =
      "You're offline. Please check your internet connection.";

  // ─── Message translation ──────────────────────────────────────────────────

  /// True when [message] is a connectivity failure wrapped by the API layer
  /// (which prefixes such errors with `Network error: ...`) rather than a real
  /// server message that should be shown to the user verbatim.
  static bool isNetworkFailure(String message) {
    return message.startsWith('Network error:') ||
        message.contains('SocketException') ||
        message.contains('TimeoutException') ||
        message.contains('HandshakeException') ||
        message.contains('Failed host lookup') ||
        message.contains('No internet connection') ||
        message.contains('Connection closed') ||
        message.contains('Connection refused') ||
        message.contains('Network is unreachable');
  }

  /// Maps any error/exception (or its string form) to a friendly sentence.
  static String friendlyMessage(dynamic error) {
    if (error is SocketException) {
      return "No internet connection. Please check your network settings and try again.";
    }
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup')) {
      return "Unable to connect to the server. Please check your internet connection.";
    } else if (error is TimeoutException) {
      return "Connection timed out. Please check your internet connection and try again.";
    } else if (text.contains('TimeoutException')) {
      return "The request took too long. Please check your internet speed and try again.";
    } else if (error is HandshakeException) {
      return "Secure connection failed. Please check your network settings.";
    } else if (text.contains('HandshakeException')) {
      return "We're having trouble establishing a secure connection. Please try again.";
    } else if (text.contains('Certificate')) {
      return "Security certificate issue. Please check your network or try again later.";
    } else if (text.contains('No internet connection')) {
      return "No internet connection. Please check your network settings and try again.";
    }
    return "An unexpected error occurred. Please try again or contact support.";
  }

  /// Given a raw API `message`, returns the friendly version when it is a
  /// connectivity failure and the original (real server) message otherwise.
  static String resolveMessage(
    String? rawMessage, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final message = (rawMessage == null || rawMessage.trim().isEmpty)
        ? fallback
        : rawMessage;
    return isNetworkFailure(message) ? friendlyMessage(message) : message;
  }

  // ─── Offline snackbar ─────────────────────────────────────────────────────

  /// Shows the standard floating "offline" snackbar, styled like the one on the
  /// login page.
  static void showOfflineSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A2A2A),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: Color(0xFFFFBF81), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFFE5E2E1)),
              ),
            ),
          ],
        ),
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: 'Retry',
                textColor: const Color(0xFFADC6FF),
                onPressed: onRetry,
              ),
      ),
    );
  }
}
