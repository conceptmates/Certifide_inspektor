// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inspectionStats)
const inspectionStatsProvider = InspectionStatsProvider._();

final class InspectionStatsProvider extends $FunctionalProvider<
        AsyncValue<InspectionStats?>,
        InspectionStats?,
        FutureOr<InspectionStats?>>
    with $FutureModifier<InspectionStats?>, $FutureProvider<InspectionStats?> {
  const InspectionStatsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'inspectionStatsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$inspectionStatsHash();

  @$internal
  @override
  $FutureProviderElement<InspectionStats?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<InspectionStats?> create(Ref ref) {
    return inspectionStats(ref);
  }
}

String _$inspectionStatsHash() => r'734fe3bdce14cfcb3b06878338431d1b6931ddd0';

@ProviderFor(monthlyInspectionStats)
const monthlyInspectionStatsProvider = MonthlyInspectionStatsProvider._();

final class MonthlyInspectionStatsProvider extends $FunctionalProvider<
        AsyncValue<InspectionStats?>,
        InspectionStats?,
        FutureOr<InspectionStats?>>
    with $FutureModifier<InspectionStats?>, $FutureProvider<InspectionStats?> {
  const MonthlyInspectionStatsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'monthlyInspectionStatsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$monthlyInspectionStatsHash();

  @$internal
  @override
  $FutureProviderElement<InspectionStats?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<InspectionStats?> create(Ref ref) {
    return monthlyInspectionStats(ref);
  }
}

String _$monthlyInspectionStatsHash() =>
    r'20e44c52c9218f6cc992687430230fafe59ae9d1';
