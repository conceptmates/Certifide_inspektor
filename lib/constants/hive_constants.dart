class HiveConstants {
  static const String INSPECTION_BOX = 'inspection_box';

  /// Pointer to the single ACTIVE working copy (the inspection currently open on
  /// screen / the most-recent one the home screen offers to resume).
  static const String CURRENT_INSPECTION_KEY = 'current_inspection';

  /// Durable per-inspection slot keyed by server inspection id. Unlike
  /// [CURRENT_INSPECTION_KEY] (a single slot that the next inspection
  /// overwrites), each inspection keeps its own copy here so its structure +
  /// reference-media URLs survive offline even after another inspection is
  /// started. Cleared when that inspection is submitted/completed.
  static String inspectionKey(int inspectionId) => 'inspection_$inspectionId';
  static const String INSPECTION_HISTORY_BOX = 'inspection_history_box';
  static const String REPORTS_BOX = 'reports_box';
  static const String REPORT_LIST_KEY = 'report_list';

  // Generic offline cache for read-only server payloads (dashboard stats,
  // report lists, …) so screens can show last-known data instead of a blank
  // "no internet" state. Stores JSON strings — no type adapter required.
  static const String API_CACHE_BOX = 'api_cache_box';
  static const String STATS_DAILY_KEY = 'stats_daily';
  static const String STATS_MONTHLY_KEY = 'stats_monthly';
  static const String REPORTS_HISTORY_KEY = 'reports_history';
  static const String REPORTS_PENDING_KEY = 'reports_pending';
}
