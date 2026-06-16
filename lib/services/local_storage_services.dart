// lib/services/local_storage_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/local_inspection.dart';
import '../models/pending_image.dart';
import '../models/pending_media.dart';

enum MediaType { image, video, audio, file }

class LocalStorageService {
  static const String INSPECTIONS_BOX = 'inspections';
  static const String IMAGES_DIR = 'inspection_images';
  static const String PENDING_IMAGES_BOX = 'pending_images';

  /// Lightweight index of just the flags the filter scans need, keyed by the
  /// same id as [INSPECTIONS_BOX]. Lets getPendingInspections /
  /// getInspectionsWithPending* find candidates without deserializing every
  /// full record (the main box is now a LazyBox).
  static const String INSPECTIONS_INDEX_BOX = 'inspections_index';

  // Whether the index has been verified/rebuilt this session.
  static bool _indexChecked = false;

  static Future<LazyBox<LocalInspection>> _getBox() async {
    final box = Hive.isBoxOpen(INSPECTIONS_BOX)
        ? Hive.lazyBox<LocalInspection>(INSPECTIONS_BOX)
        : await Hive.openLazyBox<LocalInspection>(INSPECTIONS_BOX);
    await _ensureIndex(box);
    return box;
  }

  static Future<Box> _getIndexBox() async {
    if (Hive.isBoxOpen(INSPECTIONS_INDEX_BOX)) {
      return Hive.box(INSPECTIONS_INDEX_BOX);
    }
    return Hive.openBox(INSPECTIONS_INDEX_BOX);
  }

  // The flags every scan predicate needs, derived from a record.
  static Map<String, dynamic> _indexEntry(LocalInspection insp) => {
        's': insp.status,
        'sub': insp.isSubmitted,
        'pi': insp.pendingImages.isNotEmpty,
        'pm': insp.hasPendingMedia,
      };

  /// Builds/repairs the index once per session. If counts disagree (first run
  /// after upgrade, or a crash mid-write), the index is rebuilt from the box —
  /// a one-time full read. Steady state: writes keep it in sync incrementally.
  static Future<void> _ensureIndex(LazyBox<LocalInspection> box) async {
    if (_indexChecked) return;
    _indexChecked = true;
    final idx = await _getIndexBox();
    if (idx.length != box.length) {
      await idx.clear();
      for (final key in box.keys) {
        final insp = await box.get(key);
        if (insp != null) await idx.put(key, _indexEntry(insp));
      }
    }
  }

  /// Single write path: persists the record AND its index entry so the two
  /// can never drift.
  static Future<void> _writeInspection(
      LazyBox<LocalInspection> box, dynamic id, LocalInspection insp) async {
    await box.put(id, insp);
    final idx = await _getIndexBox();
    await idx.put(id, _indexEntry(insp));
  }

  /// Single delete path: removes the record AND its index entry.
  static Future<void> _removeInspection(
      LazyBox<LocalInspection> box, dynamic id) async {
    await box.delete(id);
    final idx = await _getIndexBox();
    await idx.delete(id);
  }

  /// Collects full records whose index entry matches [match], deserializing
  /// only the matches.
  static Future<List<LocalInspection>> _collectByIndex(
      LazyBox<LocalInspection> box, bool Function(Map) match) async {
    final idx = await _getIndexBox();
    final result = <LocalInspection>[];
    for (final key in idx.keys) {
      final e = idx.get(key);
      if (e is Map && match(e)) {
        final insp = await box.get(key);
        if (insp != null) result.add(insp);
      }
    }
    return result;
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(LocalInspectionAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PendingImageAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(PendingMediaAdapter());
    }
    await Hive.openLazyBox<LocalInspection>(INSPECTIONS_BOX);
  }

  /// Status used for media-only queue containers created when an in-progress
  /// inspection is closed with media still awaiting upload. These are NOT
  /// returned by [getPendingInspections] (so they never trigger a full submit),
  /// only by [getInspectionsWithPendingMedia].
  static const String MEDIA_PENDING_STATUS = 'media_pending';

  static String mediaQueueId(int serverInspectionId) =>
      'mediaq_$serverInspectionId';

  static Future<String> saveImage(String filePath, {int rotateAngle = 0}) async {
    try {
      final File imageFile = File(filePath);

      if (!imageFile.existsSync()) {
        log('File does not exist at path: $filePath');
        throw Exception('File not found');
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/$IMAGES_DIR';
      await Directory(imagesDir).create(recursive: true);

      final String finalPath = '$imagesDir/${const Uuid().v4()}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        finalPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1920,
        autoCorrectionAngle: true,
        keepExif: false,
        rotate: rotateAngle,
      );
      // Fall back to copying the raw file if compression fails.
      if (result == null) {
        await imageFile.copy(finalPath);
      }

      return finalPath;
    } catch (e) {
      log('Error saving image: $e');
      rethrow;
    }
  }

  static Future<String> saveVideo(String filePath, {int rotateAngle = 0}) async {
    try {
      final File videoFile = File(filePath);
      if (!videoFile.existsSync()) throw Exception('File not found');

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videosDir = '${appDir.path}/inspection_videos';
      await Directory(videosDir).create(recursive: true);

      final String finalPath = '$videosDir/${const Uuid().v4()}.mp4';
      await videoFile.copy(finalPath);
      return finalPath;
    } catch (e) {
      log('Error saving video: $e');
      rethrow;
    }
  }

  /// Saves captured media to an organized folder tree visible to the user:
  ///   Android  → Download/Certifide Inspections/{inspectionId}/{type}/
  ///   iOS      → Documents/Certifide Inspections/{inspectionId}/{type}/
  /// Each inspection keeps all its media in one place, split by media type.
  /// Errors are non-fatal — the inspection continues even if this fails.
  static Future<void> saveMediaToUserStorage(
    String sourcePath,
    MediaType type, {
    String? inspectionId,
  }) async {
    try {
      if (sourcePath.startsWith('http')) return;
      if (!File(sourcePath).existsSync()) return;

      final subfolder = _mediaSubfolder(type);
      final idSegment =
          (inspectionId != null && inspectionId.isNotEmpty) ? inspectionId : 'pending';
      final relFolder = 'Certifide Inspections/$idSegment/$subfolder';
      final ext = sourcePath.split('.').last;

      if (Platform.isAndroid) {
        // MediaStore Download — single accessible location on all Android versions.
        // saveFile() deletes the temp file, so copy first to preserve the original.
        MediaStore.appFolder = relFolder;
        final tmpDir = await getTemporaryDirectory();
        final copyPath = '${tmpDir.path}/ms_${const Uuid().v4()}.$ext';
        await File(sourcePath).copy(copyPath);
        try {
          await MediaStore().saveFile(
            tempFilePath: copyPath,
            dirType: DirType.download,
            dirName: DirName.download,
          );
        } finally {
          // saveFile() normally deletes the temp copy, but clean up defensively
          // in case it throws before completing.
          try {
            await File(copyPath).delete();
          } catch (_) {}
        }
      } else {
        // iOS — Documents/Certifide Inspections/{id}/{type}/ visible in Files app
        // because UIFileSharingEnabled is set in Info.plist.
        final docs = await getApplicationDocumentsDirectory();
        final destDir = Directory('${docs.path}/$relFolder');
        await destDir.create(recursive: true);
        await File(sourcePath).copy('${destDir.path}/${const Uuid().v4()}.$ext');
      }
    } catch (e) {
      log('saveMediaToUserStorage: $e');
    }
  }

  static String _mediaSubfolder(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 'images';
      case MediaType.video:
        return 'videos';
      case MediaType.audio:
        return 'audio';
      case MediaType.file:
        return 'files';
    }
  }

  static Future<String> saveInspection({
    required Map<String, dynamic> data,
    required Map<String, String?> images,
    String status = 'pending',
    Map<String, dynamic>? imageMetadata,
    Map<String, String?>? videos,
    Map<String, String?>? audios,
    Map<String, String?>? files,
    Map<String, List<String>>? multiImages,
  }) async {
    try {
      final box = await _getBox();

      // Save images to local storage
      Map<String, String> savedImages = {};
      Map<String, PendingImage> pendingImages = {};

      for (var entry in images.entries) {
        if (entry.value != null) {
          String filePath;
          String section = '';
          String itemId = entry.key;

          // Get section and itemId from metadata if available
          if (imageMetadata != null &&
              imageMetadata.containsKey(entry.key)) {
            final meta = imageMetadata[entry.key];
            section = meta['section'] ?? '';
            itemId = meta['itemId'] ?? entry.key;
          }

          try {
            // Try parsing as JSON first
            if (entry.value!.contains('{')) {
              try {
                final Map<String, dynamic> fileInfo = json.decode(entry.value!);
                filePath = fileInfo['filePath'] ?? entry.value!;
              } catch (jsonError) {
                // If JSON parsing fails, use the original value
                filePath = entry.value!;
              }
            } else {
              filePath = entry.value!;
            }
          } catch (e) {
            // Fallback to original value
            filePath = entry.value!;
          }

          // Check if it's a local path (needs upload) or already a URL
          if (filePath.startsWith('/') || filePath.startsWith('var/')) {
            // Local file path - needs to be uploaded
            final File imageFile = File(filePath);
            if (!imageFile.existsSync()) {
              log('Image file does not exist: $filePath');
              continue;
            }

            try {
              final savedPath = await saveImage(filePath);
              savedImages[entry.key] = savedPath;
              // Mark as pending upload with section and itemId
              pendingImages[entry.key] = PendingImage(
                imagePath: savedPath,
                section: section,
                itemId: itemId,
              );
            } catch (e) {
              log('Error saving image $filePath: $e');
            }
          } else if (filePath.startsWith('http')) {
            // Already uploaded - URL
            savedImages[entry.key] = filePath;
          } else {
            // Other format - save as is
            savedImages[entry.key] = filePath;
          }
        }
      }

      // Save videos to local storage
      Map<String, String> savedVideos = {};
      if (videos != null) {
        for (var entry in videos.entries) {
          if (entry.value != null && entry.value!.isNotEmpty) {
            final savedPath = await _saveMediaFile(entry.value!, 'videos');
            if (savedPath != null) {
              savedVideos[entry.key] = savedPath;
            }
          }
        }
      }

      // Save audios to local storage
      Map<String, String> savedAudios = {};
      if (audios != null) {
        for (var entry in audios.entries) {
          if (entry.value != null && entry.value!.isNotEmpty) {
            final savedPath = await _saveMediaFile(entry.value!, 'audios');
            if (savedPath != null) {
              savedAudios[entry.key] = savedPath;
            }
          }
        }
      }

      // Save files to local storage
      Map<String, String> savedFiles = {};
      if (files != null) {
        for (var entry in files.entries) {
          if (entry.value != null && entry.value!.isNotEmpty) {
            final savedPath = await _saveMediaFile(entry.value!, 'files');
            if (savedPath != null) {
              savedFiles[entry.key] = savedPath;
            }
          }
        }
      }

      // Save multi-images to local storage
      Map<String, List<String>> savedMultiImages = {};
      if (multiImages != null) {
        for (var entry in multiImages.entries) {
          if (entry.value.isNotEmpty) {
            List<String> savedPaths = [];
            for (var imagePath in entry.value) {
              if (imagePath.isNotEmpty) {
                if (imagePath.startsWith('/') || imagePath.startsWith('var/')) {
                  try {
                    final savedPath = await saveImage(imagePath);
                    savedPaths.add(savedPath);
                  } catch (e) {
                    log('Error saving multi-image $imagePath: $e');
                  }
                } else {
                  savedPaths.add(imagePath);
                }
              }
            }
            if (savedPaths.isNotEmpty) {
              savedMultiImages[entry.key] = savedPaths;
            }
          }
        }
      }

      // Create new inspection with a unique ID
      final String inspectionId = const Uuid().v4();
      final inspection = LocalInspection(
        id: inspectionId,
        createdAt: DateTime.now(),
        data: data,
        images: savedImages,
        pendingImages: pendingImages,
        status: status,
        isSubmitted: false,
        videos: savedVideos,
        audios: savedAudios,
        files: savedFiles,
        multiImages: savedMultiImages,
      );

      await _writeInspection(box, inspectionId, inspection);
      return inspectionId;
    } catch (e) {
      log('Error saving inspection: $e');

      // Log the full error details
      if (e is Error) {
        log('Stacktrace: ${e.stackTrace}');
      }

      rethrow;
    }
  }

  // Helper method to save media files (videos, audios, files)
  static Future<String?> _saveMediaFile(String filePath, String subDir) async {
    try {
      // Handle JSON encoded file paths
      String actualPath = filePath;
      if (filePath.contains('{')) {
        try {
          final Map<String, dynamic> fileInfo = json.decode(filePath);
          actualPath = fileInfo['filePath'] ?? filePath;
        } catch (_) {
          // Use original path if JSON parsing fails
        }
      }

      // Check if it's a local path or URL
      if (actualPath.startsWith('http')) {
        return actualPath; // Already a URL
      }

      if (!actualPath.startsWith('/') && !actualPath.startsWith('var/')) {
        return actualPath; // Other format, save as is
      }

      final File mediaFile = File(actualPath);
      if (!mediaFile.existsSync()) {
        log('Media file does not exist: $actualPath');
        return null;
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String mediaDir = '${appDir.path}/inspection_$subDir';
      await Directory(mediaDir).create(recursive: true);

      final String extension = actualPath.split('.').last;
      final String fileName = '${const Uuid().v4()}.$extension';
      final String destinationPath = '$mediaDir/$fileName';

      await mediaFile.copy(destinationPath);
      return destinationPath;
    } catch (e) {
      log('Error saving media file: $e');
      return null;
    }
  }

  static Future<List<LocalInspection>> getPendingInspections() async {
    final box = await _getBox();
    return _collectByIndex(
        box, (e) => e['sub'] != true && e['s'] == 'offline');
  }

  static Future<List<LocalInspection>> getInspectionsWithPendingImages() async {
    final box = await _getBox();
    return _collectByIndex(
        box,
        (e) =>
            e['sub'] != true && e['pi'] == true && e['s'] == 'offline');
  }

  static Future<void> markInspectionAsSubmitted(String id) async {
    final box = await _getBox();
    final inspection = await box.get(id);

    if (inspection != null) {
      // Delete images first
      await _deleteInspectionImages(inspection);
      // Then delete the inspection
      await _removeInspection(box, id);
    }
  }

  static Future<void> deleteInspection(String id) async {
    final box = await _getBox();
    final inspection = await box.get(id);

    if (inspection != null) {
      await _deleteInspectionImages(inspection);
      await _removeInspection(box, id);
    }
  }

  // Helper method to delete inspection media files
  static Future<void> _deleteInspectionImages(
    LocalInspection inspection,
  ) async {
    // Delete images
    for (String imagePath in inspection.images.values) {
      await _deleteFile(imagePath);
    }

    // Delete videos
    for (String videoPath in inspection.videos.values) {
      await _deleteFile(videoPath);
    }

    // Delete audios
    for (String audioPath in inspection.audios.values) {
      await _deleteFile(audioPath);
    }

    // Delete files
    for (String filePath in inspection.files.values) {
      await _deleteFile(filePath);
    }

    // Delete multi-images
    for (List<String> imagePaths in inspection.multiImages.values) {
      for (String imagePath in imagePaths) {
        await _deleteFile(imagePath);
      }
    }
  }

  static Future<void> _deleteFile(String filePath) async {
    if (filePath.startsWith('http')) return;
    try {
      await File(filePath).delete();
    } on PathNotFoundException {
      // File already gone — nothing to do.
    } catch (e) {
      log('Error deleting file: $e');
    }
  }

  static bool _isSameInspection(
    Map<String, dynamic> data1,
    Map<String, dynamic> data2,
  ) {
    try {
      // Basic validation
      if (data1.isEmpty || data2.isEmpty) return false;

      // Helper function to safely compare nested maps
      bool compareNestedMap(
        Map<String, dynamic>? map1,
        Map<String, dynamic>? map2,
        List<String> keys,
      ) {
        if (map1 == null || map2 == null) return false;
        return keys.every((key) => map1[key] == map2[key]);
      }

      // Helper function to safely get nested value
      T? getNestedValue<T>(Map<String, dynamic> map, List<String> keys) {
        dynamic current = map;
        for (String key in keys) {
          if (current is! Map<String, dynamic> || !current.containsKey(key)) {
            return null;
          }
          current = current[key];
        }
        return current as T?;
      }

      // 1. Check Vehicle Information
      final vehicleInfo1 = getNestedValue<Map<String, dynamic>>(data1, [
        'vehicleInfo',
      ]);
      final vehicleInfo2 = getNestedValue<Map<String, dynamic>>(data2, [
        'vehicleInfo',
      ]);

      if (vehicleInfo1 != null && vehicleInfo2 != null) {
        final vehicleMatches = compareNestedMap(vehicleInfo1, vehicleInfo2, [
          'registrationNumber',
          'chassisNumber',
          'engineNumber',
        ]);
        if (!vehicleMatches) return false;
      }

      // 2. Check Inspection Metadata
      final inspectionMetadata1 = getNestedValue<Map<String, dynamic>>(data1, [
        'metadata',
      ]);
      final inspectionMetadata2 = getNestedValue<Map<String, dynamic>>(data2, [
        'metadata',
      ]);

      if (inspectionMetadata1 != null && inspectionMetadata2 != null) {
        final metadataMatches = compareNestedMap(
          inspectionMetadata1,
          inspectionMetadata2,
          ['inspectionType', 'inspectorId', 'locationId'],
        );
        if (!metadataMatches) return false;
      }

      // 3. Check Timestamps
      final timestamp1 = getNestedValue<String>(data1, ['timestamp']);
      final timestamp2 = getNestedValue<String>(data2, ['timestamp']);

      if (timestamp1 != null && timestamp2 != null) {
        final time1 = DateTime.parse(timestamp1);
        final time2 = DateTime.parse(timestamp2);
        final timeDifference = time1.difference(time2).abs();

        // If inspections are more than 24 hours apart, consider them different
        if (timeDifference.inHours >= 24) return false;
      }

      // 4. Check Location Data (if available)
      final location1 = getNestedValue<Map<String, dynamic>>(data1, [
        'location',
      ]);
      final location2 = getNestedValue<Map<String, dynamic>>(data2, [
        'location',
      ]);

      if (location1 != null && location2 != null) {
        final locationMatches = compareNestedMap(location1, location2, [
          'latitude',
          'longitude',
          'address',
        ]);
        if (!locationMatches) return false;
      }

      // 5. Check Customer Information (if available)
      final customer1 = getNestedValue<Map<String, dynamic>>(data1, [
        'customer',
      ]);
      final customer2 = getNestedValue<Map<String, dynamic>>(data2, [
        'customer',
      ]);

      if (customer1 != null && customer2 != null) {
        final customerMatches = compareNestedMap(customer1, customer2, [
          'id',
          'name',
          'contact',
        ]);
        if (!customerMatches) return false;
      }

      // 6. Check Inspection Status
      final status1 = data1['status'];
      final status2 = data2['status'];
      if (status1 != null && status2 != null && status1 != status2) {
        // If one is completed and other is pending, consider them different
        if ((status1 == 'completed' && status2 != 'completed') ||
            (status2 == 'completed' && status1 != 'completed')) {
          return false;
        }
      }

      // If all checks pass, consider them the same inspection
      return true;
    } catch (e) {
      log('Error comparing inspections: $e');
      return false;
    }
  }

  static Future<String> saveOfflineInspection({
    required Map<String, dynamic> data,
    required Map<String, String?> images,
    String status = 'offline',
    Map<String, dynamic>? imageMetadata,
    Map<String, String?>? videos,
    Map<String, String?>? audios,
    Map<String, String?>? files,
    Map<String, List<String>>? multiImages,
  }) async {
    // Use saveInspection with offline status
    return saveInspection(
      data: data,
      images: images,
      status: status,
      imageMetadata: imageMetadata,
      videos: videos,
      audios: audios,
      files: files,
      multiImages: multiImages,
    );
  }

  static Future<void> updateInspectionImages({
    required String inspectionId,
    required Map<String, String> uploadedImages,
  }) async {
    final box = await _getBox();
    final inspection = await box.get(inspectionId);

    if (inspection != null) {
      // Update images map with uploaded URLs
      final updatedImages = Map<String, String>.from(inspection.images);
      final updatedPendingImages = Map<String, PendingImage>.from(inspection.pendingImages);

      for (var entry in uploadedImages.entries) {
        if (updatedPendingImages.containsKey(entry.key)) {
          // Remove from pending and update with URL
          updatedPendingImages.remove(entry.key);
          updatedImages[entry.key] = entry.value;
        }
      }

      await _writeInspection(
        box,
        inspectionId,
        inspection.copyWith(
          images: updatedImages,
          pendingImages: updatedPendingImages,
        ),
      );
    }
  }

  static Future<void> updateInspectionMedia({
    required String inspectionId,
    Map<String, String> uploadedVideos = const {},
    Map<String, String> uploadedAudios = const {},
    Map<String, String> uploadedFiles = const {},
    Map<String, List<String>> uploadedMultiImages = const {},
  }) async {
    final box = await _getBox();
    final inspection = await box.get(inspectionId);
    if (inspection == null) return;

    final updatedVideos = Map<String, String>.from(inspection.videos)
      ..addAll(uploadedVideos);
    final updatedAudios = Map<String, String>.from(inspection.audios)
      ..addAll(uploadedAudios);
    final updatedFiles = Map<String, String>.from(inspection.files)
      ..addAll(uploadedFiles);
    final updatedMultiImages =
        Map<String, List<String>>.from(inspection.multiImages)
          ..addAll(uploadedMultiImages);

    await _writeInspection(
      box,
      inspectionId,
      inspection.copyWith(
        videos: updatedVideos,
        audios: updatedAudios,
        files: updatedFiles,
        multiImages: updatedMultiImages,
      ),
    );
  }

  static Future<void> addPendingImage({
    required String inspectionId,
    required String imageKey,
    required String imagePath,
    required String section,
    required String itemId,
  }) async {
    final box = await _getBox();
    final inspection = await box.get(inspectionId);

    if (inspection != null) {
      final updatedPendingImages = Map<String, PendingImage>.from(inspection.pendingImages);
      updatedPendingImages[imageKey] = PendingImage(
        imagePath: imagePath,
        section: section,
        itemId: itemId,
      );

      await _writeInspection(
        box,
        inspectionId,
        inspection.copyWith(pendingImages: updatedPendingImages),
      );
    }
  }

  // ===========================================================================
  // Media-agnostic offline upload queue (images, videos, audios, files,
  // multi-images). Used when an in-progress inspection is closed with media
  // still awaiting upload, and drained by InspectionNotifier.syncPendingMedia.
  // ===========================================================================

  /// All inspections (queue containers and offline-submitted records) that
  /// still have at least one un-uploaded media item.
  static Future<List<LocalInspection>> getInspectionsWithPendingMedia() async {
    final box = await _getBox();
    return _collectByIndex(box, (e) => e['sub'] != true && e['pm'] == true);
  }

  /// The media-only queue container for a server inspection, or null.
  static Future<LocalInspection?> getMediaQueueById(String id) async {
    final box = await _getBox();
    return await box.get(id);
  }

  /// Creates or MERGES the media-only queue container for a server inspection.
  /// [pendingMedia] is the freshly-scanned set of still-local media; existing
  /// already-uploaded entries (awaiting save-step) are preserved, entries whose
  /// local file has vanished are skipped, and the sync engine's removals are
  /// never resurrected. [saveStepItems] maps each fieldKey to
  /// `{'section': <slug>, 'item': <save-step item map>}` for save-step replay.
  static Future<String> upsertMediaQueue({
    required int serverInspectionId,
    required Map<String, dynamic> vehicleInfo,
    required Map<String, PendingMedia> pendingMedia,
    required Map<String, dynamic> saveStepItems,
  }) async {
    final box = await _getBox();
    final id = mediaQueueId(serverInspectionId);
    final existing = await box.get(id);

    // Merge: keep already-uploaded entries from the existing container so a
    // pending save-step is not lost; add newly-scanned local entries (skipping
    // any whose file no longer exists); never downgrade an uploaded entry.
    final merged = <String, PendingMedia>{};
    if (existing != null) {
      for (final e in existing.pendingMedia.entries) {
        if (e.value.isUploaded) merged[e.key] = e.value;
      }
    }
    for (final e in pendingMedia.entries) {
      final ex = merged[e.key];
      if (ex != null && ex.isUploaded) continue;
      if (!File(e.value.localPath).existsSync()) continue;
      merged[e.key] = e.value;
    }

    if (merged.isEmpty) {
      // Nothing left to upload — drop any stale container.
      if (existing != null && existing.status == MEDIA_PENDING_STATUS) {
        await _removeInspection(box, id);
      }
      return id;
    }

    final mergedSaveSteps = <String, dynamic>{
      ...?(existing?.data['pendingSaveSteps'] as Map?)?.cast<String, dynamic>(),
      ...saveStepItems,
    };

    final container = LocalInspection(
      id: id,
      createdAt: existing?.createdAt ?? DateTime.now(),
      data: {
        'vehicleInfo': vehicleInfo,
        'inspection_id': serverInspectionId,
        'pendingSaveSteps': mergedSaveSteps,
      },
      images: const {},
      status: MEDIA_PENDING_STATUS,
      isSubmitted: false,
      pendingMedia: merged,
      serverInspectionId: serverInspectionId,
    );
    await _writeInspection(box, id, container);
    return id;
  }

  /// Updates a single pending-media entry's status (and optionally URL/error).
  static Future<void> setPendingMediaStatus({
    required String inspectionId,
    required String key,
    required String status,
    String? url,
    String? error,
  }) async {
    final box = await _getBox();
    final insp = await box.get(inspectionId);
    final entry = insp?.pendingMedia[key];
    if (insp == null || entry == null) return;

    final updated = Map<String, PendingMedia>.from(insp.pendingMedia);
    updated[key] = entry.copyWith(
      uploadStatus: status,
      uploadedUrl: url ?? entry.uploadedUrl,
      lastError: error,
      retryCount: status == PendingMediaStatus.failed
          ? entry.retryCount + 1
          : entry.retryCount,
    );
    await _writeInspection(
        box, inspectionId, insp.copyWith(pendingMedia: updated));
  }

  /// Removes a fully-uploaded entry from the queue (and deletes its local
  /// file). If the container is a media-only queue and becomes empty, the
  /// whole container is deleted.
  static Future<void> removePendingMedia(
    String inspectionId,
    String key, {
    bool deleteLocalFile = true,
  }) async {
    final box = await _getBox();
    final insp = await box.get(inspectionId);
    if (insp == null) return;

    final entry = insp.pendingMedia[key];
    final updated = Map<String, PendingMedia>.from(insp.pendingMedia)
      ..remove(key);
    if (deleteLocalFile && entry != null) {
      await _deleteFile(entry.localPath);
    }

    if (updated.isEmpty && insp.status == MEDIA_PENDING_STATUS) {
      await _removeInspection(box, inspectionId);
    } else {
      await _writeInspection(
          box, inspectionId, insp.copyWith(pendingMedia: updated));
    }
  }

  /// Reads the save-step replay descriptor for a field, or null.
  /// Returns `{'section': <slug>, 'item': <map>}`.
  static Future<Map<String, dynamic>?> getSaveStepFor(
    String inspectionId,
    String fieldKey,
  ) async {
    final box = await _getBox();
    final insp = await box.get(inspectionId);
    final steps = insp?.data['pendingSaveSteps'];
    if (steps is Map && steps[fieldKey] is Map) {
      return Map<String, dynamic>.from(steps[fieldKey] as Map);
    }
    return null;
  }

  /// Deletes the media-only queue container for a server inspection, if any
  /// (e.g. after the inspection is finally submitted). Local queued files are
  /// removed too.
  static Future<void> clearMediaQueueFor(int serverInspectionId) async {
    final box = await _getBox();
    final id = mediaQueueId(serverInspectionId);
    final insp = await box.get(id);
    if (insp == null) return;
    for (final entry in insp.pendingMedia.values) {
      await _deleteFile(entry.localPath);
    }
    await _removeInspection(box, id);
  }
}
