import 'dart:developer';

// flutter_cache_manager's FileSystem.createFile must return a package:file
// File, so we depend on its transitive `file` package here intentionally.
// ignore: depend_on_referenced_packages
import 'package:file/file.dart' hide FileSystem;
// ignore: depend_on_referenced_packages
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

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
  ///
  /// Crucially the files are stored under [getApplicationSupportDirectory] via
  /// [_PersistentFileSystem]. The package default ([IOFileSystem]) writes to
  /// [getTemporaryDirectory], which iOS does NOT keep between app launches (it
  /// is purged when the app is not running) and Android may clear — so cached
  /// media vanished after a restart while the sqflite metadata DB still
  /// referenced it, surfacing as broken/blank media offline.
  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 180),
      maxNrOfCacheObjects: 1000,
      fileSystem: _PersistentFileSystem(_cacheKey),
    ),
  );

  /// Returns the already-downloaded file for [rawUrl], or null when it has not
  /// been cached yet (or its file was purged from disk). Never hits the
  /// network — safe to call while offline.
  static Future<FileInfo?> cachedFile(String rawUrl) async {
    if (rawUrl.trim().isEmpty) return null;
    try {
      final info = await instance.getFileFromCache(mediaUri(rawUrl).toString());
      // The metadata DB can outlive the file (e.g. an OS cache purge), and
      // getFileFromCache does NOT verify the file exists. Confirm it really is
      // on disk so callers fall back to the network instead of a dead path.
      if (info != null && info.file.existsSync()) return info;
      return null;
    } catch (e) {
      log('ReferenceMediaCache.cachedFile($rawUrl) failed: $e');
      return null;
    }
  }

  /// Downloads and stores the file for [rawUrl] unless an actual on-disk copy
  /// already exists. Use this to lazily warm the cache as an item is displayed.
  static Future<void> warm(String rawUrl) async {
    if (rawUrl.trim().isEmpty) return;
    final key = mediaUri(rawUrl).toString();
    try {
      if (await cachedFile(rawUrl) != null) return;
      await instance.downloadFile(key);
    } catch (e) {
      // A failed host lookup / socket error just means we're offline — the file
      // simply isn't cached yet and will be warmed on the next online load.
      // That's expected, so don't spam the log with it; surface only real errors.
      if (_isOffline(e)) return;
      log('ReferenceMediaCache.warm($rawUrl) failed: $e');
    }
  }

  static bool _isOffline(Object e) {
    final s = e.toString();
    return s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('ClientException') ||
        s.contains('Connection closed') ||
        s.contains('Connection reset');
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

/// A [FileSystem] for [CacheManager] that stores cached files in a persistent
/// app directory ([getApplicationSupportDirectory]) instead of the temporary
/// directory used by the package default. This is what makes reference media
/// survive an app restart/close while offline.
///
/// Mirrors the package's `IOFileSystem`, swapping only the base directory.
class _PersistentFileSystem implements FileSystem {
  final Future<Directory> _fileDir;
  final String _cacheKey;

  _PersistentFileSystem(this._cacheKey) : _fileDir = _createDirectory(_cacheKey);

  static Future<Directory> _createDirectory(String key) async {
    final baseDir = await getApplicationSupportDirectory();
    final path = '${baseDir.path}/$key';

    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<File> createFile(String name) async {
    final directory = await _fileDir;
    if (!(await directory.exists())) {
      await _createDirectory(_cacheKey);
    }
    return directory.childFile(name);
  }
}
