import 'dart:developer';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils/media_url.dart';

/// Disk cache for admin-uploaded **reference media** (the guide images / videos
/// / audio shown to inspectors on each field).
///
/// The read cache ([LocalCacheService]) only holds JSON payloads; binary media
/// loaded straight from the network (`Image.network`,
/// `VideoPlayerController.networkUrl`) disappears the moment the device goes
/// offline. This service persists the actual files to disk so they remain
/// visible offline, mirroring the offline-first pattern used elsewhere: warm
/// the cache while online, serve from disk when the network is gone.
///
/// Everything is keyed by [mediaUri] (the normalised URL) so an image fetched
/// for display and the same file warmed by [prefetch] share one cache entry
/// instead of being downloaded twice under slightly different keys.
class ReferenceMediaCache {
  const ReferenceMediaCache._();

  static const _cacheKey = 'reference_media_cache';

  /// Reference media is small in count but must outlive a single job, so we
  /// keep it far longer and allow more objects than the package defaults
  /// (30 days / 200 objects) — an inspector may review a guide weeks after it
  /// was first downloaded, still offline.
  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 180),
      maxNrOfCacheObjects: 1000,
    ),
  );

  /// Returns the already-downloaded file for [rawUrl], or null when it has not
  /// been cached yet. Never hits the network — safe to call while offline.
  static Future<FileInfo?> cachedFile(String rawUrl) async {
    if (rawUrl.trim().isEmpty) return null;
    try {
      return await instance.getFileFromCache(mediaUri(rawUrl).toString());
    } catch (e) {
      log('ReferenceMediaCache.cachedFile($rawUrl) failed: $e');
      return null;
    }
  }

  /// Downloads and stores the file for [rawUrl] if it is not already cached.
  /// Use this to lazily warm the cache as a single item is displayed.
  static Future<void> warm(String rawUrl) async {
    if (rawUrl.trim().isEmpty) return;
    final key = mediaUri(rawUrl).toString();
    try {
      final existing = await instance.getFileFromCache(key);
      if (existing != null) return;
      await instance.downloadFile(key);
    } catch (e) {
      log('ReferenceMediaCache.warm($rawUrl) failed: $e');
    }
  }

  /// Pre-downloads every cacheable URL in [urls] so the media survives going
  /// offline. Skips empty/duplicate URLs. Failures (e.g. a single unreachable
  /// file) are swallowed per-item so one bad URL never aborts the batch.
  static Future<void> prefetch(Iterable<String> urls) async {
    final seen = <String>{};
    for (final url in urls) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      await warm(trimmed);
    }
  }
}
