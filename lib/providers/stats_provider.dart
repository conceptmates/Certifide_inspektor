import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inspection_stats_model.dart';
import '../services/api_services.dart';

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// Daily stats for the current month (used by the Daily tab)
final inspectionStatsProvider =
    FutureProvider.autoDispose<InspectionStats?>((ref) async {
  final now = DateTime.now();
  final from = _fmt(DateTime(now.year, now.month, 1));
  final to = _fmt(DateTime(now.year, now.month + 1, 0));

  final result = await ApiService.getInspectionStats(
    period: 'daily',
    from: from,
    to: to,
  );

  if (result['success'] == true) return result['data'] as InspectionStats;
  return null;
});

// Monthly stats for the last 6 months (used by the Monthly tab)
final monthlyInspectionStatsProvider =
    FutureProvider.autoDispose<InspectionStats?>((ref) async {
  final now = DateTime.now();
  final from = _fmt(DateTime(now.year, now.month - 5, 1));
  final to = _fmt(DateTime(now.year, now.month + 1, 0));

  final result = await ApiService.getInspectionStats(
    period: 'monthly',
    from: from,
    to: to,
  );

  if (result['success'] == true) return result['data'] as InspectionStats;
  return null;
});
