// lib/services/reports_cache_service.dart
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../constants/hive_constants.dart';

/// Cached report entry: redirect URL from a successfully submitted inspection.
class CachedReport {
  final String url;
  final int inspectionId;
  final DateTime createdAt;

  CachedReport({
    required this.url,
    required this.inspectionId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'inspection_id': inspectionId,
        'created_at': createdAt.toIso8601String(),
      };

  static CachedReport fromJson(Map<String, dynamic> json) {
    return CachedReport(
      url: json['url'] as String? ?? '',
      inspectionId: json['inspection_id'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ReportsCacheService {
  static Box<dynamic>? _box;

  static Future<Box<dynamic>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(HiveConstants.REPORTS_BOX);
    return _box!;
  }

  /// Saves a report redirect URL (call when inspection is created successfully).
  static Future<void> addReport({
    required String redirectUrl,
    required int inspectionId,
  }) async {
    if (redirectUrl.isEmpty) return;
    final box = await _getBox();
    final list = List<Map<String, dynamic>>.from(
      (box.get(HiveConstants.REPORT_LIST_KEY) as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
    list.insert(0, {
      'url': redirectUrl,
      'inspection_id': inspectionId,
      'created_at': DateTime.now().toIso8601String(),
    });
    await box.put(HiveConstants.REPORT_LIST_KEY, list);
  }

  /// Returns all cached reports (newest first).
  static Future<List<CachedReport>> getReports() async {
    final box = await _getBox();
    final list = box.get(HiveConstants.REPORT_LIST_KEY) as List<dynamic>?;
    if (list == null || list.isEmpty) return [];
    return list
        .map((e) => CachedReport.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Removes a report by URL (optional, for future use).
  static Future<void> removeReport(String url) async {
    final box = await _getBox();
    final list = List<Map<String, dynamic>>.from(
      (box.get(HiveConstants.REPORT_LIST_KEY) as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
    list.removeWhere((e) => e['url'] == url);
    await box.put(HiveConstants.REPORT_LIST_KEY, list);
  }
}
