// lib/models/inspection_storage_model.dart
import 'package:hive/hive.dart';

part 'inspection_storage_model.g.dart';

@HiveType(typeId: 0)
class InspectionStorageModel extends HiveObject {
  @HiveField(0)
  final Map<dynamic, dynamic> itemValues;

  @HiveField(1)
  final Map<dynamic, dynamic> itemImages;

  @HiveField(2)
  final Map<dynamic, dynamic> itemRemarks;

  @HiveField(3)
  final int currentSection;

  @HiveField(4)
  final Map<dynamic, dynamic> textFieldValues;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final Map<dynamic, dynamic>? multiImages;

  // New field for status with a default value
  @HiveField(8, defaultValue: 'draft')
  final String status;

  @HiveField(9)
  final Map<dynamic, dynamic> itemVideos;

  @HiveField(10)
  final Map<dynamic, dynamic> itemAudios;

  @HiveField(11)
  final Map<dynamic, dynamic> itemFiles;

  @HiveField(12)
  final Map<dynamic, dynamic>? vehicleDetails;

  @HiveField(13)
  final Map<dynamic, dynamic>? inspectionTemplate;

  @HiveField(14)
  final int? inspectionId;

  InspectionStorageModel({
    Map<String, String>? itemValues,
    Map<String, String?>? itemImages,
    Map<String, String>? itemRemarks,
    int? currentSection,
    Map<String, String>? textFieldValues,
    DateTime? timestamp,
    bool? isCompleted,
    Map<String, List<String>>? multiImages,
    String? status,
    Map<String, String?>? itemVideos,
    Map<String, String?>? itemAudios,
    Map<String, String?>? itemFiles,
    Map<String, dynamic>? vehicleDetails,
    Map<String, dynamic>? inspectionTemplate,
    this.inspectionId,
  })  : this.itemValues = Map<dynamic, dynamic>.from(itemValues ?? {}),
        this.itemImages = Map<dynamic, dynamic>.from(itemImages ?? {}),
        this.itemRemarks = Map<dynamic, dynamic>.from(itemRemarks ?? {}),
        this.currentSection = currentSection ?? 0,
        this.textFieldValues =
            Map<dynamic, dynamic>.from(textFieldValues ?? {}),
        this.timestamp = timestamp ?? DateTime.now(),
        this.isCompleted = isCompleted ?? false,
        this.multiImages = multiImages != null
            ? Map<dynamic, dynamic>.from(multiImages)
            : null,
        this.status = status ?? 'draft',
        this.itemVideos = Map<dynamic, dynamic>.from(itemVideos ?? {}),
        this.itemAudios = Map<dynamic, dynamic>.from(itemAudios ?? {}),
        this.itemFiles = Map<dynamic, dynamic>.from(itemFiles ?? {}),
        this.vehicleDetails = vehicleDetails != null
            ? Map<dynamic, dynamic>.from(vehicleDetails)
            : null,
        this.inspectionTemplate = inspectionTemplate != null
            ? Map<dynamic, dynamic>.from(inspectionTemplate)
            : null;

  // Convert dynamic Maps back to strongly typed Maps
  Map<String, String> get typedItemValues {
    try {
      return Map<String, String>.from(itemValues);
    } catch (_) {
      return {};
    }
  }

  Map<String, String?> get typedItemImages {
    try {
      return Map<String, String?>.from(itemImages);
    } catch (_) {
      return {};
    }
  }

  Map<String, String> get typedItemRemarks {
    try {
      return Map<String, String>.from(itemRemarks);
    } catch (_) {
      return {};
    }
  }

  Map<String, String?> get typedItemVideos {
    try {
      return Map<String, String?>.from(itemVideos);
    } catch (_) {
      return {};
    }
  }

  Map<String, String?> get typedItemAudios {
    try {
      return Map<String, String?>.from(itemAudios);
    } catch (_) {
      return {};
    }
  }

  Map<String, String?> get typedItemFiles {
    try {
      return Map<String, String?>.from(itemFiles);
    } catch (_) {
      return {};
    }
  }

  Map<String, String> get typedTextFieldValues {
    try {
      return Map<String, String>.from(textFieldValues);
    } catch (_) {
      return {};
    }
  }

  Map<String, List<String>> get typedMultiImages {
    if (multiImages == null) return {};
    try {
      return Map<String, List<String>>.from(multiImages!.map((key, value) =>
          MapEntry(key.toString(),
              (value as List).map((e) => e.toString()).toList())));
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic>? get typedVehicleDetails {
    if (vehicleDetails == null) return null;
    try {
      return Map<String, dynamic>.from(vehicleDetails!);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? get typedInspectionTemplate {
    if (inspectionTemplate == null) return null;
    try {
      return Map<String, dynamic>.from(inspectionTemplate!);
    } catch (_) {
      return null;
    }
  }

  factory InspectionStorageModel.fromMap(Map<String, dynamic> map) {
    return InspectionStorageModel(
      itemValues: _safeConvertMap<String>(map['itemValues']),
      itemImages: _safeConvertMap<String?>(map['itemImages']),
      itemRemarks: _safeConvertMap<String>(map['itemRemarks']),
      currentSection: map['currentSection'] ?? 0,
      textFieldValues: _safeConvertMap<String>(map['textFieldValues']),
      timestamp: map['timestamp'] is DateTime
          ? map['timestamp']
          : DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
      multiImages: map['multiImages'] != null
          ? _safeConvertMultiImageMap(map['multiImages'])
          : null,
      status: map['status'] ?? 'draft',
      itemVideos: _safeConvertMap<String?>(map['itemVideos']),
      itemAudios: _safeConvertMap<String?>(map['itemAudios']),
      itemFiles: _safeConvertMap<String?>(map['itemFiles']),
      vehicleDetails: map['vehicleDetails'] != null
          ? Map<String, dynamic>.from(map['vehicleDetails'])
          : null,
      inspectionTemplate: map['inspectionTemplate'] != null
          ? Map<String, dynamic>.from(map['inspectionTemplate'])
          : null,
      inspectionId: map['inspectionId'],
    );
  }

  // Helper method to safely convert maps
  static Map<String, T> _safeConvertMap<T>(dynamic mapData) {
    if (mapData == null) return {};
    try {
      return Map<String, T>.from(mapData);
    } catch (_) {
      return {};
    }
  }

  // Helper method to safely convert multi-image map
  static Map<String, List<String>> _safeConvertMultiImageMap(dynamic mapData) {
    if (mapData == null) return {};
    try {
      return Map<String, List<String>>.from(
        mapData.map((key, value) => MapEntry(
              key.toString(),
              (value as List).map((e) => e.toString()).toList(),
            )),
      );
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'itemValues': typedItemValues,
      'itemImages': typedItemImages,
      'itemRemarks': typedItemRemarks,
      'currentSection': currentSection,
      'textFieldValues': typedTextFieldValues,
      'timestamp': timestamp,
      'isCompleted': isCompleted,
      'multiImages': typedMultiImages,
      'status': status,
      'itemVideos': typedItemVideos,
      'itemAudios': typedItemAudios,
      'itemFiles': typedItemFiles,
      'vehicleDetails': typedVehicleDetails,
      'inspectionTemplate': typedInspectionTemplate,
      'inspectionId': inspectionId,
    };
  }

  InspectionStorageModel copyWith({
    Map<String, String>? itemValues,
    Map<String, String?>? itemImages,
    Map<String, String>? itemRemarks,
    int? currentSection,
    Map<String, String>? textFieldValues,
    DateTime? timestamp,
    bool? isCompleted,
    Map<String, List<String>>? multiImages,
    String? status,
    Map<String, String?>? itemVideos,
    Map<String, String?>? itemAudios,
    Map<String, String?>? itemFiles,
    Map<String, dynamic>? vehicleDetails,
    Map<String, dynamic>? inspectionTemplate,
    int? inspectionId,
  }) {
    return InspectionStorageModel(
      itemValues: itemValues ?? typedItemValues,
      itemImages: itemImages ?? typedItemImages,
      itemRemarks: itemRemarks ?? typedItemRemarks,
      currentSection: currentSection ?? this.currentSection,
      textFieldValues: textFieldValues ?? typedTextFieldValues,
      timestamp: timestamp ?? this.timestamp,
      isCompleted: isCompleted ?? this.isCompleted,
      multiImages: multiImages ?? typedMultiImages,
      status: status ?? this.status,
      itemVideos: itemVideos ?? typedItemVideos,
      itemAudios: itemAudios ?? typedItemAudios,
      itemFiles: itemFiles ?? typedItemFiles,
      vehicleDetails: vehicleDetails ?? typedVehicleDetails,
      inspectionTemplate: inspectionTemplate ?? typedInspectionTemplate,
      inspectionId: inspectionId ?? this.inspectionId,
    );
  }
}
