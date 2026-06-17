// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectivityStatusHash() =>
    r'e414335b9d1872a596965694151d7b02248cf4c9';

/// Single source of truth for whether the app can currently reach the backend.
///
/// It subscribes to OS connectivity changes ONCE, confirms real reachability
/// with a DNS probe, and exposes a single `bool`. Every screen watches this
/// provider instead of calling [ConnectivityChecker.canReachServer] on its own,
/// so when the connection drops or is restored every listener updates at once
/// from this one event — no per-screen polling.
///
/// Copied from [ConnectivityStatus].
@ProviderFor(ConnectivityStatus)
final connectivityStatusProvider =
    NotifierProvider<ConnectivityStatus, bool>.internal(
  ConnectivityStatus.new,
  name: r'connectivityStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConnectivityStatus = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
