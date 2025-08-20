// lib/services/local_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/local_inspection.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  static const String INSPECTIONS_BOX = 'inspections';
  static const String IMAGES_DIR = 'inspection_images';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(LocalInspectionAdapter());
    }
    await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);
  }

  static Future<String> saveImage(String filePath) async {
    try {
      final File imageFile = File(filePath);

      // Check if the file exists
      if (!imageFile.existsSync()) {
        print('File does not exist at path: $filePath');
        throw Exception('File not found');
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/$IMAGES_DIR';
      await Directory(imagesDir).create(recursive: true);

      final String fileName = '${const Uuid().v4()}.jpg';
      final String destinationPath = '$imagesDir/$fileName';

      await imageFile.copy(destinationPath);
      return destinationPath;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }

  static Future<String> saveInspection({
    required Map<String, dynamic> data,
    required Map<String, String?> images,
    String status = 'pending',
  }) async {
    try {
      final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);

      // Save images to local storage
      Map<String, String> savedImages = {};
      for (var entry in images.entries) {
        if (entry.value != null) {
          String filePath;

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

          // Validate file path
          final File imageFile = File(filePath);
          if (!imageFile.existsSync()) {
            print('Image file does not exist: $filePath');
            continue; // Skip this image
          }

          try {
            final savedPath = await saveImage(filePath);
            savedImages[entry.key] = savedPath;
          } catch (e) {
            print('Error saving image $filePath: $e');
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
        status: status,
        isSubmitted: false,
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

  static Future<List<LocalInspection>> getPendingInspections() async {
    final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);
    return box.values
        .where((inspection) =>
            !inspection.isSubmitted && inspection.status != 'completed')
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

  // Helper method to delete inspection images
  static Future<void> _deleteInspectionImages(
      LocalInspection inspection) async {
    for (String imagePath in inspection.images.values) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting image: $e');
      }
    }
  }

  static bool _isSameInspection(
      Map<String, dynamic> data1, Map<String, dynamic> data2) {
    try {
      // Basic validation
      if (data1 == null || data2 == null) return false;
      if (data1.isEmpty || data2.isEmpty) return false;

      // Helper function to safely compare nested maps
      bool compareNestedMap(Map<String, dynamic>? map1,
          Map<String, dynamic>? map2, List<String> keys) {
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
      final vehicleInfo1 =
          getNestedValue<Map<String, dynamic>>(data1, ['vehicleInfo']);
      final vehicleInfo2 =
          getNestedValue<Map<String, dynamic>>(data2, ['vehicleInfo']);

      if (vehicleInfo1 != null && vehicleInfo2 != null) {
        final vehicleMatches = compareNestedMap(
          vehicleInfo1,
          vehicleInfo2,
          ['registrationNumber', 'chassisNumber', 'engineNumber'],
        );
        if (!vehicleMatches) return false;
      }

      // 2. Check Inspection Metadata
      final inspectionMetadata1 =
          getNestedValue<Map<String, dynamic>>(data1, ['metadata']);
      final inspectionMetadata2 =
          getNestedValue<Map<String, dynamic>>(data2, ['metadata']);

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
      final location1 =
          getNestedValue<Map<String, dynamic>>(data1, ['location']);
      final location2 =
          getNestedValue<Map<String, dynamic>>(data2, ['location']);

      if (location1 != null && location2 != null) {
        final locationMatches = compareNestedMap(
          location1,
          location2,
          ['latitude', 'longitude', 'address'],
        );
        if (!locationMatches) return false;
      }

      // 5. Check Customer Information (if available)
      final customer1 =
          getNestedValue<Map<String, dynamic>>(data1, ['customer']);
      final customer2 =
          getNestedValue<Map<String, dynamic>>(data2, ['customer']);

      if (customer1 != null && customer2 != null) {
        final customerMatches = compareNestedMap(
          customer1,
          customer2,
          ['id', 'name', 'contact'],
        );
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
  }) async {
    try {
      final box = await Hive.openBox<LocalInspection>(INSPECTIONS_BOX);

      // Save images to local storage
      Map<String, String> savedImages = {};
      for (var entry in images.entries) {
        if (entry.value != null) {
          String filePath;

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

          // Validate file path
          final File imageFile = File(filePath);
          if (!imageFile.existsSync()) {
            print('Image file does not exist: $filePath');
            continue; // Skip this image
          }

          try {
            final savedPath = await saveImage(filePath);
            savedImages[entry.key] = savedPath;
          } catch (e) {
            print('Error saving image $filePath: $e');
          }
        }
      }

      // Create new offline inspection
      final String inspectionId = const Uuid().v4();
      final inspection = LocalInspection(
        id: inspectionId,
        createdAt: DateTime.now(),
        data: data,
        images: savedImages,
        status: status,
        isSubmitted: false,
      );

      await box.put(inspectionId, inspection);
      return inspectionId;
    } catch (e) {
      print('Error saving offline inspection: $e');

      // Log the full error details
      if (e is Error) {
        print('Stacktrace: ${e.stackTrace}');
      }

      rethrow;
    }
  }
}
