// lib/services/hive_storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../data/inspection_storage_model.dart';

class HiveStorageService {
  static const String boxName = 'inspection_box';
  static const String inspectionKey = 'current_inspection';
  static const String userData = 'user_data';
  static const String lastProfileUpdate = 'last_profile_update';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(InspectionStorageModelAdapter());
    await Hive.openBox<InspectionStorageModel>(boxName);
  }

  static Future<Box<InspectionStorageModel>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<InspectionStorageModel>(boxName);
    }
    return Hive.openBox<InspectionStorageModel>(boxName);
  }

  static Future<void> saveInspectionData({
    required Map<String, String> itemValues,
    required Map<String, String?> itemImages,
    required Map<String, String> itemRemarks,
    required int currentSection,
    required Map<String, String> textFieldValues,
  }) async {
    final box = await _openBox();

    final inspectionData = InspectionStorageModel(
      itemValues: itemValues,
      itemImages: itemImages,
      itemRemarks: itemRemarks,
      currentSection: currentSection,
      textFieldValues: textFieldValues,
    );

    await box.put(inspectionKey, inspectionData);
  }

  static Future<InspectionStorageModel?> getInspectionData() async {
    final box = await _openBox();
    return box.get(inspectionKey);
  }

  static Future<void> clearInspectionData() async {
    final box = await _openBox();
    await box.delete(inspectionKey);
  }
}
