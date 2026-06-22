import 'dart:convert';
import 'dart:developer';

import 'package:hive_ce/hive.dart';

import '../constants/hive_constants.dart';

/// Lightweight offline cache for read-only server payloads.
///
/// Screens write the last successful API response here and read it back when a
/// later fetch fails (e.g. the device went offline), so the UI shows the
/// last-known data instead of a blank "no internet" screen. Values are stored
/// as JSON strings in a single untyped Hive box, so no type adapters are
/// needed — any `Map`/`List` of primitives round-trips cleanly.
class LocalCacheService {
  const LocalCacheService._();

  static Box? _box;

  static Future<Box> _open() async {
    final existing = _box;
    if (existing != null && existing.isOpen) return existing;
    if (Hive.isBoxOpen(HiveConstants.API_CACHE_BOX)) {
      return _box = Hive.box(HiveConstants.API_CACHE_BOX);
    }
    return _box = await Hive.openBox(HiveConstants.API_CACHE_BOX);
  }

  /// Persists [value] (any JSON-encodable Map/List) under [key].
  static Future<void> write(String key, Object value) async {
    try {
      final box = await _open();
      await box.put(key, json.encode(value));
    } catch (e) {
      log('LocalCacheService.write($key) failed: $e');
    }
  }

  /// Returns the decoded JSON previously stored under [key], or null when
  /// nothing is cached (or the cache can't be read).
  static Future<dynamic> read(String key) async {
    try {
      final box = await _open();
      final raw = box.get(key);
      if (raw is String && raw.isNotEmpty) return json.decode(raw);
      return null;
    } catch (e) {
      log('LocalCacheService.read($key) failed: $e');
      return null;
    }
  }

  /// Convenience reader that always yields a `List` (empty when missing).
  static Future<List<dynamic>> readList(String key) async {
    final value = await read(key);
    return value is List ? value : const [];
  }

  /// Clears all cached payloads (e.g. on logout).
  static Future<void> clear() async {
    try {
      final box = await _open();
      await box.clear();
    } catch (e) {
      log('LocalCacheService.clear failed: $e');
    }
  }
}
