import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/connectivity_checker.dart';

part 'connectivity_provider.g.dart';

/// Single source of truth for whether the app can currently reach the backend.
///
/// It subscribes to OS connectivity changes ONCE, confirms real reachability
/// with a DNS probe, and exposes a single `bool`. Every screen watches this
/// provider instead of calling [ConnectivityChecker.canReachServer] on its own,
/// so when the connection drops or is restored every listener updates at once
/// from this one event — no per-screen polling.
@Riverpod(keepAlive: true)
class ConnectivityStatus extends _$ConnectivityStatus {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounce;

  @override
  bool build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _subscription?.cancel();
    });
    _start();
    // Optimistic until the first probe resolves; corrected within milliseconds.
    return true;
  }

  Future<void> _start() async {
    await _probe();
    _subscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasInterface =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      // A Wi-Fi/cellular handoff emits a burst of events; coalesce them into a
      // single update after a short quiet period.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), () {
        if (!hasInterface) {
          _set(false);
        } else {
          unawaited(_probe());
        }
      });
    });
  }

  Future<void> _probe() async {
    _set(await ConnectivityChecker.canReachServer());
  }

  void _set(bool online) {
    if (state != online) state = online;
  }

  /// Imperative re-check (e.g. from a "Retry" button). Returns the fresh state.
  Future<bool> refresh() async {
    await _probe();
    return state;
  }
}
