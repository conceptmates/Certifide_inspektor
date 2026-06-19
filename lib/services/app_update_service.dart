import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Wraps the Play In-App-Update flow.
///
/// Android-only: the underlying Play Core API has no iOS equivalent, so every
/// call is a no-op on other platforms.
class AppUpdateService {
  const AppUpdateService();

  bool get _supported => Platform.isAndroid;

  /// Asks Play whether a newer build is available and, if so, runs the most
  /// appropriate update flow:
  ///  - flexible (background download, keep using the app) when allowed,
  ///  - otherwise an immediate (blocking, full-screen) update.
  ///
  /// Safe to fire-and-forget; all errors are swallowed and logged so a failed
  /// check never disrupts the user.
  Future<void> checkForUpdate() async {
    if (!_supported) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        // Download finished; prompt Play to install it.
        await InAppUpdate.completeFlexibleUpdate();
      } else if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e, st) {
      debugPrint('AppUpdateService.checkForUpdate failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}
