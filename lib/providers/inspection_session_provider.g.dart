// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds active inspection data in memory across screen navigations.
/// Cleared on successful submit or explicit abandon.

@ProviderFor(InspectionSessionNotifier)
const inspectionSessionProvider = InspectionSessionNotifierProvider._();

/// Holds active inspection data in memory across screen navigations.
/// Cleared on successful submit or explicit abandon.
final class InspectionSessionNotifierProvider extends $NotifierProvider<
    InspectionSessionNotifier, InspectionSessionSnapshot?> {
  /// Holds active inspection data in memory across screen navigations.
  /// Cleared on successful submit or explicit abandon.
  const InspectionSessionNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'inspectionSessionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$inspectionSessionNotifierHash();

  @$internal
  @override
  InspectionSessionNotifier create() => InspectionSessionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InspectionSessionSnapshot? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InspectionSessionSnapshot?>(value),
    );
  }
}

String _$inspectionSessionNotifierHash() =>
    r'1f25c23854fa4fef2acb19af474c8463bf86b3b8';

/// Holds active inspection data in memory across screen navigations.
/// Cleared on successful submit or explicit abandon.

abstract class _$InspectionSessionNotifier
    extends $Notifier<InspectionSessionSnapshot?> {
  InspectionSessionSnapshot? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref
        as $Ref<InspectionSessionSnapshot?, InspectionSessionSnapshot?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<InspectionSessionSnapshot?, InspectionSessionSnapshot?>,
        InspectionSessionSnapshot?,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
