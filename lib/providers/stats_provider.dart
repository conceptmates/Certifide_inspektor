import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/hive_constants.dart';
import '../models/inspection_stats_model.dart';
import '../services/api_services.dart';
import '../services/local_cache_service.dart';

part 'stats_provider.g.dart';

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Reads the last-cached stats for [key] so the dashboard chart still renders
/// when the device is offline.
Future<InspectionStats?> _cachedStats(String key) async {
  final cached = await LocalCacheService.read(key);
  if (cached is Map<String, dynamic>) {
    try {
      return InspectionStats.fromJson(cached);
    } catch (_) {
      return null;
    }
  }
  return null;
}

// Daily stats for the current month (used by the Daily tab)
@riverpod
Future<InspectionStats?> inspectionStats(InspectionStatsRef ref) async {
  final now = DateTime.now();
  final from = _fmt(DateTime(now.year, now.month, 1));
  final to = _fmt(DateTime(now.year, now.month + 1, 0));

  final result = await ApiService.getInspectionStats(
    period: 'daily',
    from: from,
    to: to,
  );

  if (result['success'] == true) {
    final stats = result['data'] as InspectionStats;
    await LocalCacheService.write(HiveConstants.STATS_DAILY_KEY, stats.toJson());
    return stats;
  }
  // Offline / failed fetch — fall back to the last successful response.
  return _cachedStats(HiveConstants.STATS_DAILY_KEY);
}

// Monthly stats for the last 6 months (used by the Monthly tab)
@riverpod
Future<InspectionStats?> monthlyInspectionStats(
    MonthlyInspectionStatsRef ref) async {
  final now = DateTime.now();
  final from = _fmt(DateTime(now.year, now.month - 5, 1));
  final to = _fmt(DateTime(now.year, now.month + 1, 0));

  final result = await ApiService.getInspectionStats(
    period: 'monthly',
    from: from,
    to: to,
  );

  if (result['success'] == true) {
    final stats = result['data'] as InspectionStats;
    await LocalCacheService.write(
        HiveConstants.STATS_MONTHLY_KEY, stats.toJson());
    return stats;
  }
  // Offline / failed fetch — fall back to the last successful response.
  return _cachedStats(HiveConstants.STATS_MONTHLY_KEY);
}
