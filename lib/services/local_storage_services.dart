// lib/services/local_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/local_inspection.dart';
import '../models/pending_image.dart';

class LocalStorageService {
  static const String INSPECTIONS_BOX = 'inspections';
  static const String IMAGES_DIR = 'inspection_images';
  static const String PENDING_IMAGES_BOX = 'pending_images';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(LocalInspectionAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PendingImageAdapter());
    }
    await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);
  }

  static Future<String> saveImage(String filePath) async {
    try {
      final File imageFile = File(filePath);

      if (!imageFile.existsSync()) {
        print('File does not exist at path: $filePath');
        throw Exception('File not found');
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/$IMAGES_DIR';
      await Directory(imagesDir).create(recursive: true);

      // Step 1: Bake EXIF orientation into pixels so the stored file is always
      // visually correct regardless of the capture angle.
      final String step1Path = '$imagesDir/${const Uuid().v4()}.jpg';
      final step1Result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        step1Path,
        quality: 92,
        autoCorrectionAngle: true,
        keepExif: false,
      );
      // Fall back to copying the raw file if compression fails.
      if (step1Result == null) {
        await imageFile.copy(step1Path);
      }

      // Step 2: Force portrait — if the image is still landscape (width > height)
      // after EXIF correction, rotate it 90° so it is portrait when uploaded
      // and displayed in the report.
      final Uint8List step1Bytes = await File(step1Path).readAsBytes();
      final size = _parseJpegSize(step1Bytes);
      final bool isLandscape = size != null && size.$1 > size.$2;

      final String finalPath = '$imagesDir/${const Uuid().v4()}.jpg';

      if (isLandscape) {
        final rotatedResult = await FlutterImageCompress.compressAndGetFile(
          step1Path,
          finalPath,
          quality: 92,
          rotate: 90,
          keepExif: false,
        );
        // If rotation failed, keep the step-1 result.
        if (rotatedResult == null) {
          await File(step1Path).copy(finalPath);
        }
      } else {
        await File(step1Path).copy(finalPath);
      }

      // Remove the intermediate file.
      try {
        await File(step1Path).delete();
      } catch (_) {}

      return finalPath;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
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
      final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);

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
              print('Image file does not exist: $filePath');
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
              print('Error saving image $filePath: $e');
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
                    print('Error saving multi-image $imagePath: $e');
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

      await box.put(inspectionId, inspection);
      return inspectionId;
    } catch (e) {
      print('Error saving inspection: $e');

      // Log the full error details
      if (e is Error) {
        print('Stacktrace: ${e.stackTrace}');
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
        print('Media file does not exist: $actualPath');
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
      print('Error saving media file: $e');
      return null;
    }
  }

  static Future<List<LocalInspection>> getPendingInspections() async {
    final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);
    return box.values
        .where(
          (inspection) =>
              !inspection.isSubmitted && inspection.status != 'completed',
        )
        .toList();
  }

  static Future<List<LocalInspection>> getInspectionsWithPendingImages() async {
    final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);
    return box.values
        .where(
          (inspection) =>
              !inspection.isSubmitted &&
              inspection.pendingImages.isNotEmpty &&
              inspection.status != 'completed',
        )
        .toList();
  }

  static Future<void> markInspectionAsSubmitted(String id) async {
    final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);
    final inspection = box.get(id);

    if (inspection != null) {
      // Delete images first
      await _deleteInspectionImages(inspection);
      // Then delete the inspection
      await box.delete(id);
    }
  }

  static Future<void> deleteInspection(String id) async {
    final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);
    final inspection = box.get(id);

    if (inspection != null) {
      await _deleteInspectionImages(inspection);
      await box.delete(id);
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
    try {
      if (filePath.startsWith('http')) return; // Skip URLs
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
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
      print('Error comparing inspections: $e');
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
    final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);
    final inspection = box.get(inspectionId);

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

      // Save updated inspection
      final updatedInspection = LocalInspection(
        id: inspection.id,
        createdAt: inspection.createdAt,
        data: inspection.data,
        images: updatedImages,
        pendingImages: updatedPendingImages,
        status: inspection.status,
        isSubmitted: inspection.isSubmitted,
      );

      await box.put(inspectionId, updatedInspection);
    }
  }

  static Future<void> addPendingImage({
    required String inspectionId,
    required String imageKey,
    required String imagePath,
    required String section,
    required String itemId,
  }) async {
    final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);
    final inspection = box.get(inspectionId);

    if (inspection != null) {
      final updatedPendingImages = Map<String, PendingImage>.from(inspection.pendingImages);
      updatedPendingImages[imageKey] = PendingImage(
        imagePath: imagePath,
        section: section,
        itemId: itemId,
      );

      final updatedInspection = LocalInspection(
        id: inspection.id,
        createdAt: inspection.createdAt,
        data: inspection.data,
        images: inspection.images,
        pendingImages: updatedPendingImages,
        status: inspection.status,
        isSubmitted: inspection.isSubmitted,
      );

      await box.put(inspectionId, updatedInspection);
    }
  }

  /// Walks the JPEG segment structure to find the SOF (Start-of-Frame) marker
  /// and returns (width, height). Returns null if the file is not a valid JPEG
  /// or the SOF marker is not found.
  ///
  /// Unlike a naive byte scan, this method skips segment payloads using the
  /// length fields so it cannot hit false positives in EXIF/thumbnail data.
  static (int, int)? _parseJpegSize(Uint8List bytes) {
    // Must start with SOI marker 0xFF 0xD8
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return null;
    }

    int i = 2;
    while (i + 3 < bytes.length) {
      // Every marker starts with 0xFF; skip padding bytes.
      if (bytes[i] != 0xFF) {
        i++;
        continue;
      }
      final int marker = bytes[i + 1];

      // SOF markers that encode image dimensions:
      // C0–C3 (baseline/extended), C5–C7 (differential), C9–CB (arithmetic)
      if ((marker >= 0xC0 && marker <= 0xC3) ||
          (marker >= 0xC5 && marker <= 0xC7) ||
          (marker >= 0xC9 && marker <= 0xCB)) {
        if (i + 9 < bytes.length) {
          final int height = (bytes[i + 5] << 8) | bytes[i + 6];
          final int width = (bytes[i + 7] << 8) | bytes[i + 8];
          return (width, height);
        }
        return null;
      }

      // Skip markers with no payload (SOI, EOI, standalone markers).
      if (marker == 0xD8 || marker == 0xD9 || marker == 0x01) {
        i += 2;
        continue;
      }

      // All other markers are followed by a 2-byte length that includes
      // the length field itself but not the 0xFF marker byte.
      if (i + 3 >= bytes.length) break;
      final int segLen = (bytes[i + 2] << 8) | bytes[i + 3];
      if (segLen < 2) break;
      i += 2 + segLen;
    }

    return null;
  }
}
