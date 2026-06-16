import 'dart:async';
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/inspection_state.dart';
import '../models/local_inspection.dart';
import '../models/pending_media.dart';
import '../services/api_services.dart';
import '../services/local_storage_services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/connectivity_checker.dart';

part 'inspection_provider.g.dart';

@Riverpod(keepAlive: true)
class InspectionNotifier extends _$InspectionNotifier {
  Timer? _cooldownTimer;
  Timer? _connectivityDebounce;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isAutoSubmitting = false;
  bool _isSyncingMedia = false;

  /// Per-container locks so the connectivity-driven [syncPendingMedia] and the
  /// manual [uploadInspectionMedia] never process the same queue container
  /// concurrently (which would double-upload its files).
  final Set<String> _uploadingContainerIds = {};

  @override
  InspectionState build() {
    ref.onDispose(() {
      _cooldownTimer?.cancel();
      _connectivityDebounce?.cancel();
      _connectivitySubscription?.cancel();
    });
    _startConnectivityListener();
    return const InspectionState();
  }

  void _startConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        // Debounce: a Wi-Fi/cellular handoff emits a burst of events, and each
        // sync runs full-box scans. Coalesce bursts into one sync after a short
        // quiet period (the syncing flags still guard against overlap).
        _connectivityDebounce?.cancel();
        _connectivityDebounce = Timer(const Duration(seconds: 2), () {
          // Stream listeners must be synchronous; async work is scheduled via
          // unawaited() and all errors are caught explicitly inside.
          unawaited(Future(() async {
            try {
              final hasInternet =
                  await ConnectivityChecker.canReachServer();
              if (!hasInternet) return;
              // First drain the media-only upload queue (uploads each file and
              // replays save-step, keeping the inspection resumable), then
              // submit any inspections that were fully completed while offline.
              await syncPendingMedia();
              await _autoSubmitPending();
            } catch (e) {
              log('Connectivity listener error: $e');
            }
          }));
        });
      }
    });
  }

  Future<void> _autoSubmitPending() async {
    if (_isAutoSubmitting) return;
    _isAutoSubmitting = true;
    try {
      final pending = await LocalStorageService.getPendingInspections();
      if (pending.isEmpty) return;
      for (final inspection in pending) {
        if (!(state.submittingStates[inspection.id] ?? false)) {
          await retrySubmission(inspection);
        }
      }
      state = state.copyWith(isDirty: true);
    } catch (e) {
      log('Error auto-submitting pending inspections: $e');
    } finally {
      _isAutoSubmitting = false;
    }
  }

  void _startRefreshCooldown() {
    _cooldownTimer?.cancel();
    state = state.copyWith(refreshCooldown: true);
    _cooldownTimer = Timer(const Duration(seconds: 10), () {
      state = state.copyWith(refreshCooldown: false);
    });
  }

  Future<void> loadInspections() async {
    if (state.isLoading || state.refreshCooldown || !state.isDirty) return;

    _startRefreshCooldown();
    state = state.copyWith(isLoading: true);

    try {
      final inspections = await LocalStorageService.getPendingInspections();
      inspections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Merge (don't clobber) progress maps so an in-flight upload's flags
      // survive a reload triggered mid-sync.
      final submitting = {
        for (var i in inspections) i.id: state.submittingStates[i.id] ?? false,
      };
      final uploading = {
        for (var i in inspections)
          i.id: state.uploadingImagesStates[i.id] ?? false,
      };

      state = state.copyWith(
        inspections: inspections,
        isDirty: false,
        isLoading: false,
        submittingStates: submitting,
        uploadingImagesStates: uploading,
      );

      await _reloadMediaQueue();

      final hasInternet = await ConnectivityChecker.canReachServer();
      if (hasInternet) {
        await syncPendingImages();
        await syncPendingMedia();
      }
    } catch (e) {
      log('Error loading inspections: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Reloads the "awaiting upload" media queue from local storage and tries to
  /// sync it. Not gated by the refresh cooldown, so the Pending tab reflects a
  /// just-closed inspection immediately.
  Future<void> refreshMediaQueue() async {
    await _reloadMediaQueue();
    await syncPendingMedia();
  }

  /// Refreshes the "awaiting upload" media queue from local storage, pruning
  /// progress entries for inspections that have fully drained.
  Future<void> _reloadMediaQueue() async {
    final queue = await LocalStorageService.getInspectionsWithPendingMedia();
    queue.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final ids = queue.map((e) => e.id).toSet();
    final prunedProgress = {
      for (final e in state.mediaProgress.entries)
        if (ids.contains(e.key)) e.key: e.value,
    };
    state = state.copyWith(mediaQueue: queue, mediaProgress: prunedProgress);
  }

  void _setMediaProgress(String id, MediaUploadProgress progress) {
    state = state.copyWith(
      mediaProgress: {...state.mediaProgress, id: progress},
    );
  }

  /// Re-reads one queue container and replaces it in [InspectionState.mediaQueue]
  /// so the per-file upload status (queued/uploading/uploaded/failed) shown in
  /// the Pending tab updates live as each file is processed.
  Future<void> _patchContainerInState(String id) async {
    final updated = await LocalStorageService.getMediaQueueById(id);
    if (updated == null) {
      if (state.mediaQueue.any((c) => c.id == id)) {
        state = state.copyWith(
          mediaQueue: state.mediaQueue.where((c) => c.id != id).toList(),
        );
      }
      return;
    }
    final list = state.mediaQueue.toList();
    final idx = list.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      list[idx] = updated;
    } else {
      list.insert(0, updated);
    }
    state = state.copyWith(mediaQueue: list);
  }

  /// Re-reads one container AND updates its progress entry in a SINGLE state
  /// mutation. Equivalent to [_patchContainerInState] + [_setMediaProgress]
  /// back-to-back, but with one notify/equality pass instead of two — called
  /// once per file in the upload loop, so this halves that per-file cost.
  Future<void> _patchContainerAndProgress(
      String id, MediaUploadProgress progress) async {
    final updated = await LocalStorageService.getMediaQueueById(id);
    final newProgress = {...state.mediaProgress, id: progress};
    if (updated == null) {
      state = state.copyWith(
        mediaQueue: state.mediaQueue.where((c) => c.id != id).toList(),
        mediaProgress: newProgress,
      );
      return;
    }
    final list = state.mediaQueue.toList();
    final idx = list.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      list[idx] = updated;
    } else {
      list.insert(0, updated);
    }
    state = state.copyWith(mediaQueue: list, mediaProgress: newProgress);
  }

  /// Uploads every queued media file (any type) for inspections that have
  /// pending media, WITHOUT submitting the inspection. Each uploaded file's URL
  /// is recorded and the field is re-saved server-side via save-step so the
  /// inspection stays resumable with its media already on the server.
  Future<void> syncPendingMedia() async {
    if (_isSyncingMedia) return;
    _isSyncingMedia = true;
    try {
      final hasInternet = await ConnectivityChecker.canReachServer();
      if (!hasInternet) return;

      final containers =
          await LocalStorageService.getInspectionsWithPendingMedia();
      // Surface in-flight containers as live cards BEFORE uploading so their
      // progress spinner is visible during an auto-sync.
      await _reloadMediaQueue();
      for (final container in containers) {
        await _uploadContainerMedia(container.id);
      }
      await _reloadMediaQueue();
    } catch (e) {
      log('Error syncing pending media: $e');
    } finally {
      _isSyncingMedia = false;
    }
  }

  /// Manually triggers upload of a single inspection's queued media (the
  /// Pending-tab "Upload" button). Returns true if the queue fully drained.
  Future<bool> uploadInspectionMedia(LocalInspection container) async {
    final hasInternet = await ConnectivityChecker.canReachServer();
    if (!hasInternet) {
      // Seed progress from the container's real contents (not a 0/0 default).
      _setMediaProgress(
        container.id,
        MediaUploadProgress(
          total: container.pendingMedia.length,
          uploaded: container.pendingMedia.values.where((m) => m.isUploaded).length,
          isUploading: false,
        ),
      );
      return false;
    }
    await _uploadContainerMedia(container.id);
    await _reloadMediaQueue();
    final remaining =
        await LocalStorageService.getInspectionsWithPendingMedia();
    return !remaining.any((c) => c.id == container.id);
  }

  /// Uploads all not-yet-uploaded media for one queue container, then — only
  /// once EVERY entry of a field has uploaded — replays that field's save-step
  /// (with each media type substituted into its own slot and any non-http path
  /// stripped) and removes the field's entries (deleting their local files).
  ///
  /// Takes the container id and re-reads the record fresh from storage so
  /// per-entry status guards reflect concurrent passes. Guarded by a
  /// per-container lock so a manual upload can't race the auto-sync.
  Future<void> _uploadContainerMedia(String id) async {
    if (_uploadingContainerIds.contains(id)) return;
    _uploadingContainerIds.add(id);
    try {
      var container = await LocalStorageService.getMediaQueueById(id);
      if (container == null) return;
      final serverId = container.serverInspectionId;

      int total = container.pendingMedia.length;
      int uploaded = container.pendingMedia.values.where((m) => m.isUploaded).length;
      int failed = 0;
      _setMediaProgress(
        id,
        MediaUploadProgress(total: total, uploaded: uploaded, isUploading: true),
      );

      // 1) Upload every not-yet-uploaded entry. Already-uploaded entries are
      //    kept (their save-step may still be pending) and replayed below.
      //
      //    The network upload (the slow part) runs in bounded-parallel chunks,
      //    but every Hive status write stays sequential: setPendingMediaStatus
      //    is a read-modify-write of the whole container, so concurrent writes
      //    on different keys would clobber each other (lost update).
      final pending = container.pendingMedia.entries
          .where((e) =>
              !(e.value.isUploaded && (e.value.uploadedUrl?.isNotEmpty ?? false)))
          .toList();

      // Mark the whole batch "uploading" (sequential RMW) and show it once.
      for (final entry in pending) {
        await LocalStorageService.setPendingMediaStatus(
          inspectionId: id,
          key: entry.key,
          status: PendingMediaStatus.uploading,
        );
      }
      if (pending.isNotEmpty) await _patchContainerInState(id);

      const uploadConcurrency = 4;
      for (var i = 0; i < pending.length; i += uploadConcurrency) {
        final end = (i + uploadConcurrency < pending.length)
            ? i + uploadConcurrency
            : pending.length;
        final chunk = pending.sublist(i, end);

        // Upload this chunk concurrently (no Hive writes here).
        final results = await Future.wait(chunk.map((entry) async {
          final media = entry.value;
          final result = await ApiService.uploadImage(
            media.localPath,
            inspectionId: serverId,
            section: media.section,
            itemId: media.itemId,
            mediaType: media.mediaType,
          );
          return MapEntry(entry.key, result);
        }));

        // Apply each result's status sequentially (RMW-safe).
        for (final r in results) {
          final url = r.value['url']?.toString();
          if (r.value['success'] == true && url != null && url.isNotEmpty) {
            await LocalStorageService.setPendingMediaStatus(
              inspectionId: id,
              key: r.key,
              status: PendingMediaStatus.uploaded,
              url: url,
            );
            uploaded++;
          } else {
            await LocalStorageService.setPendingMediaStatus(
              inspectionId: id,
              key: r.key,
              status: PendingMediaStatus.failed,
              error: r.value['message']?.toString(),
            );
            failed++;
          }
        }

        // One state + progress patch per chunk instead of per file.
        await _patchContainerAndProgress(
          id,
          MediaUploadProgress(
            total: total,
            uploaded: uploaded,
            failed: failed,
            isUploading: true,
          ),
        );
      }

      // 2) Re-read and group remaining entries by their form field.
      container = await LocalStorageService.getMediaQueueById(id) ?? container;
      final byField = <String, List<MapEntry<String, PendingMedia>>>{};
      for (final e in container.pendingMedia.entries) {
        byField.putIfAbsent(e.value.fieldKey, () => []).add(e);
      }

      // 3) Replay save-step ONLY for fields whose every entry has uploaded
      //    (so a multi-type / multi-image field is never sent half-local), then
      //    remove that field's entries.
      for (final fieldKey in byField.keys) {
        final entries = byField[fieldKey]!;
        final allUploaded = entries.every(
          (e) => e.value.isUploaded && (e.value.uploadedUrl?.isNotEmpty ?? false),
        );
        if (!allUploaded) continue;

        final desc = await LocalStorageService.getSaveStepFor(id, fieldKey);
        final section = desc?['section']?.toString() ?? '';

        bool persisted = false;
        if (serverId != null && desc != null && section.isNotEmpty) {
          final item = Map<String, dynamic>.from((desc['item'] as Map?) ?? {});
          _applyUrlsToSaveStepItem(item, entries.map((e) => e.value).toList());
          _stripLocalMediaPaths(item);
          try {
            final r = await ApiService.saveInspectionStep(
              serverId,
              section: section,
              items: [item],
            );
            persisted = r['success'] != false;
          } catch (e) {
            log('Media save-step replay error ($fieldKey): $e');
            persisted = false;
          }
        } else {
          // No usable save-step descriptor — the upload itself already carried
          // inspection_id/section/itemId, so drain rather than loop forever.
          if (section.isEmpty) {
            log('Media queue: empty section for field $fieldKey; draining.');
          }
          persisted = true;
        }

        if (persisted) {
          for (final e in entries) {
            await LocalStorageService.removePendingMedia(id, e.key);
          }
        }
      }

      // 4) Final progress from the post-drain state.
      final after = await LocalStorageService.getMediaQueueById(id);
      if (after == null) {
        _setMediaProgress(
          id,
          MediaUploadProgress(total: total, uploaded: total, isUploading: false),
        );
      } else {
        _setMediaProgress(
          id,
          MediaUploadProgress(
            total: after.pendingMedia.length,
            uploaded: after.pendingMedia.values.where((m) => m.isUploaded).length,
            failed: after.pendingMedia.values
                .where((m) => m.uploadStatus == PendingMediaStatus.failed)
                .length,
            isUploading: false,
          ),
        );
      }
    } catch (e) {
      log('Error uploading container media ($id): $e');
    } finally {
      _uploadingContainerIds.remove(id);
      // Always clear a lingering spinner even if something threw mid-pass.
      final p = state.mediaProgress[id];
      if (p != null && p.isUploading) {
        _setMediaProgress(id, p.copyWith(isUploading: false));
      }
    }
  }

  /// Substitutes each uploaded entry's URL into its own slot of a save-step
  /// item (image/video/audio/file/multiImages), so a field that owns several
  /// media types gets all of them filled.
  void _applyUrlsToSaveStepItem(
    Map<String, dynamic> item,
    List<PendingMedia> entries,
  ) {
    final multiUrls = <String, String>{}; // localPath -> url
    for (final m in entries) {
      final url = m.uploadedUrl;
      if (url == null || url.isEmpty) continue;
      switch (m.mediaType) {
        case 'video':
          item['videoPath'] = url;
          break;
        case 'audio':
          item['audioPath'] = url;
          break;
        case 'file':
          item['filePath'] = url;
          break;
        case 'multiImage':
          multiUrls[m.localPath] = url;
          break;
        case 'image':
        default:
          item['imagePath'] = url;
          break;
      }
    }
    if (multiUrls.isNotEmpty) {
      final existing =
          (item['multiImages'] as List?)?.map((e) => e.toString()).toList();
      if (existing != null && existing.isNotEmpty) {
        // Preserve order; map local paths to URLs and keep only uploaded ones.
        item['multiImages'] = existing
            .map((p) => multiUrls[p] ?? p)
            .where((u) => u.startsWith('http'))
            .toList();
      } else {
        item['multiImages'] = multiUrls.values.toList();
      }
    }
  }

  /// Nulls out any single media slot still holding a local (non-http) path and
  /// filters multiImages to http URLs, so a local filesystem path is never
  /// POSTed to the server.
  void _stripLocalMediaPaths(Map<String, dynamic> item) {
    for (final k in const ['imagePath', 'videoPath', 'audioPath', 'filePath']) {
      final v = item[k];
      if (v is String && v.isNotEmpty && !v.startsWith('http')) item[k] = null;
    }
    final mi = item['multiImages'];
    if (mi is List) {
      item['multiImages'] =
          mi.map((e) => e.toString()).where((u) => u.startsWith('http')).toList();
    }
  }

  Future<void> syncPendingImages() async {
    try {
      final pending =
          await LocalStorageService.getInspectionsWithPendingImages();

      for (var inspection in pending) {
        if (inspection.pendingImages.isEmpty) continue;

        state = state.copyWith(
          uploadingImagesStates: {
            ...state.uploadingImagesStates,
            inspection.id: true,
          },
        );

        final uploadedImages = <String, String>{};

        for (var entry in inspection.pendingImages.entries) {
          final result = await ApiService.uploadImage(
            entry.value.imagePath,
            inspectionId: null,
            section: entry.value.section,
            itemId: entry.value.itemId,
          );

          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            uploadedImages[entry.key] = url;
          }
        }

        if (uploadedImages.isNotEmpty) {
          await LocalStorageService.updateInspectionImages(
            inspectionId: inspection.id,
            uploadedImages: uploadedImages,
          );
        }

        state = state.copyWith(
          uploadingImagesStates: {
            ...state.uploadingImagesStates,
            inspection.id: false,
          },
        );
      }

      state = state.copyWith(isDirty: true);
      await loadInspections();
    } catch (e) {
      log('Error syncing pending images: $e');
    }
  }

  Future<bool> retrySubmission(LocalInspection inspection) async {
    if (state.submittingStates[inspection.id] ?? false) return false;

    state = state.copyWith(
      submittingStates: {...state.submittingStates, inspection.id: true},
    );

    try {
      final hasInternet = await ConnectivityChecker.canReachServer();
      if (!hasInternet) {
        state = state.copyWith(
          submittingStates: {...state.submittingStates, inspection.id: false},
        );
        return false;
      }

      var currentInspection = inspection;

      // Upload pending images
      if (inspection.pendingImages.isNotEmpty) {
        state = state.copyWith(
          uploadingImagesStates: {
            ...state.uploadingImagesStates,
            inspection.id: true,
          },
        );

        final uploadedImages = <String, String>{};

        for (var entry in inspection.pendingImages.entries) {
          final result = await ApiService.uploadImage(
            entry.value.imagePath,
            inspectionId: null,
            section: entry.value.section,
            itemId: entry.value.itemId,
          );
          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            uploadedImages[entry.key] = url;
          }
        }

        if (uploadedImages.isNotEmpty) {
          await LocalStorageService.updateInspectionImages(
            inspectionId: inspection.id,
            uploadedImages: uploadedImages,
          );
          final updated = await LocalStorageService.getPendingInspections();
          currentInspection = updated.firstWhere(
            (i) => i.id == inspection.id,
            orElse: () => currentInspection,
          );
        }

        state = state.copyWith(
          uploadingImagesStates: {
            ...state.uploadingImagesStates,
            inspection.id: false,
          },
        );
      }

      // Upload local videos, audios, and files
      // Maps: localPath -> uploadedUrl (for in-data replacement)
      final videoReplacements = <String, String>{};
      final audioReplacements = <String, String>{};
      final fileReplacements = <String, String>{};

      for (var entry in currentInspection.videos.entries) {
        if (!entry.value.startsWith('http')) {
          final result = await ApiService.uploadImage(
            entry.value,
            section: '',
            itemId: entry.key,
            fieldName: 'image',
          );
          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            videoReplacements[entry.key] = url;
          }
        }
      }

      for (var entry in currentInspection.audios.entries) {
        if (!entry.value.startsWith('http')) {
          final result = await ApiService.uploadImage(
            entry.value,
            section: '',
            itemId: entry.key,
            fieldName: 'image',
          );
          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            audioReplacements[entry.key] = url;
          }
        }
      }

      for (var entry in currentInspection.files.entries) {
        if (!entry.value.startsWith('http')) {
          final result = await ApiService.uploadImage(
            entry.value,
            section: '',
            itemId: entry.key,
            fieldName: 'image',
          );
          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            fileReplacements[entry.key] = url;
          }
        }
      }

      // Upload local multi-images (each local path in the list -> URL).
      final multiImageReplacements = <String, List<String>>{};
      for (var entry in currentInspection.multiImages.entries) {
        final newList = <String>[];
        bool changed = false;
        for (final p in entry.value) {
          if (p.startsWith('http')) {
            newList.add(p);
            continue;
          }
          final result = await ApiService.uploadImage(
            p,
            section: '',
            itemId: entry.key,
            fieldName: 'image',
          );
          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            newList.add(url);
            changed = true;
          } else {
            newList.add(p);
          }
        }
        if (changed) multiImageReplacements[entry.key] = newList;
      }

      // Persist uploaded media URLs to local storage
      if (videoReplacements.isNotEmpty ||
          audioReplacements.isNotEmpty ||
          fileReplacements.isNotEmpty ||
          multiImageReplacements.isNotEmpty) {
        await LocalStorageService.updateInspectionMedia(
          inspectionId: inspection.id,
          uploadedVideos: {
            for (var e in currentInspection.videos.entries)
              if (videoReplacements.containsKey(e.value))
                e.key: videoReplacements[e.value]!,
          },
          uploadedAudios: {
            for (var e in currentInspection.audios.entries)
              if (audioReplacements.containsKey(e.value))
                e.key: audioReplacements[e.value]!,
          },
          uploadedFiles: {
            for (var e in currentInspection.files.entries)
              if (fileReplacements.containsKey(e.value))
                e.key: fileReplacements[e.value]!,
          },
          uploadedMultiImages: multiImageReplacements,
        );
      }

      // Build final submission payload with all uploaded URLs applied.
      // Deep-copy so mutations to nested item maps don't affect Riverpod state.
      // A manual clone avoids the encode-to-string + parse round trip that
      // json.decode(json.encode(...)) pays on the UI thread for a large map.
      final inspectionData =
          _deepCopyJson(currentInspection.data) as Map<String, dynamic>;
      final itemIndex = <String, Map<String, dynamic>>{};
      List<dynamic>? summaryImages;

      final inspDataRaw = inspectionData['inspection_data'];
      if (inspDataRaw is Map<String, dynamic>) {
        for (final section in inspDataRaw.values) {
          if (section is Map<String, dynamic>) {
            final items = section['items'];
            if (items is List) {
              for (final item in items) {
                if (item is Map<String, dynamic> && item['id'] != null) {
                  itemIndex[item['id'].toString()] = item;
                }
              }
            }
          }
        }
      }
      final summaryRaw = inspectionData['summaryImages'];
      if (summaryRaw is List) summaryImages = summaryRaw;

      for (var entry in currentInspection.images.entries) {
        if (!entry.value.startsWith('http')) continue;
        final item = itemIndex[entry.key];
        if (item != null) {
          item['imagePath'] = entry.value;
          if (item['multiImages'] is List) {
            for (final img in item['multiImages'] as List<dynamic>) {
              if (img is Map<String, dynamic> && img.containsKey('imagePath')) {
                final p = img['imagePath'];
                if (p is String && !p.startsWith('http')) img['imagePath'] = entry.value;
              }
            }
          }
        }
        if (summaryImages != null) {
          for (final img in summaryImages) {
            if (img is Map<String, dynamic> && img['key'] == entry.key) {
              img['imagePath'] = entry.value;
            }
          }
        }
      }
      for (var entry in videoReplacements.entries) {
        itemIndex[entry.key]?['videoPath'] = entry.value;
      }
      for (var entry in audioReplacements.entries) {
        itemIndex[entry.key]?['audioPath'] = entry.value;
      }
      for (var entry in fileReplacements.entries) {
        itemIndex[entry.key]?['filePath'] = entry.value;
      }
      for (var entry in multiImageReplacements.entries) {
        final item = itemIndex[entry.key];
        if (item != null) {
          item['multiImages'] =
              entry.value.map((u) => {'imagePath': u}).toList();
        }
      }

      final result = await ApiService.submitInspection(inspectionData);

      if (result['success'] == true) {
        await LocalStorageService.markInspectionAsSubmitted(inspection.id);
        final updatedList = state.inspections
            .where((i) => i.id != inspection.id)
            .toList();
        final updatedSubmitting =
            Map<String, bool>.from(state.submittingStates)
              ..remove(inspection.id);
        final updatedUploading =
            Map<String, bool>.from(state.uploadingImagesStates)
              ..remove(inspection.id);
        state = state.copyWith(
          inspections: updatedList,
          submittingStates: updatedSubmitting,
          uploadingImagesStates: updatedUploading,
        );
        return true;
      } else {
        state = state.copyWith(
          submittingStates: {
            ...state.submittingStates,
            inspection.id: false,
          },
        );
        return false;
      }
    } catch (e) {
      log('Error submitting inspection ${inspection.id}: $e');
      state = state.copyWith(
        submittingStates: {...state.submittingStates, inspection.id: false},
      );
      return false;
    }
  }

  Future<void> deleteInspection(String id) async {
    if (state.isLoading || (state.submittingStates[id] ?? false)) return;

    state = state.copyWith(isLoading: true);
    try {
      await LocalStorageService.deleteInspection(id);
      state = state.copyWith(isDirty: true, isLoading: false);
      await loadInspections();
    } catch (e) {
      log('Error deleting inspection: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void markDirty() {
    state = state.copyWith(isDirty: true);
  }

}

/// Recursively deep-copies a JSON-shaped value (Maps and Lists). Primitives
/// (String, num, bool, null) are immutable so they are shared as-is. Cheaper
/// than json.decode(json.encode(...)) because it skips the string round trip.
dynamic _deepCopyJson(dynamic value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _deepCopyJson(entry.value),
    };
  }
  if (value is List) {
    return [for (final item in value) _deepCopyJson(item)];
  }
  return value;
}
