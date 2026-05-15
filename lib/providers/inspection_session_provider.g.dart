// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inspectionSessionNotifierHash() =>
    r'1f25c23854fa4fef2acb19af474c8463bf86b3b8';

/// Holds active inspection data in memory across screen navigations.
/// Cleared on successful submit or explicit abandon.
///
/// Copied from [InspectionSessionNotifier].
@ProviderFor(InspectionSessionNotifier)
final inspectionSessionNotifierProvider = NotifierProvider<
    InspectionSessionNotifier, InspectionSessionSnapshot?>.internal(
  InspectionSessionNotifier.new,
  name: r'inspectionSessionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inspectionSessionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InspectionSessionNotifier = Notifier<InspectionSessionSnapshot?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
