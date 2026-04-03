// lib/models/inspection_template_model.dart

class InspectionTemplate {
  final int id;
  final String name;
  final String displayName;
  final String description;
  final String? countryCode;
  final bool hasGovernmentApi;
  final String? governmentApiType;

  InspectionTemplate({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    this.countryCode,
    required this.hasGovernmentApi,
    this.governmentApiType,
  });

  factory InspectionTemplate.fromJson(Map<String, dynamic> json) {
    return InspectionTemplate(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'] ?? '',
      countryCode: json['country_code'],
      hasGovernmentApi: json['has_government_api'] ?? false,
      governmentApiType: json['government_api_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'country_code': countryCode,
      'has_government_api': hasGovernmentApi,
      'government_api_type': governmentApiType,
    };
  }
}

class VehicleInfo {
  final String brand;
  final String model;
  final String category;

  VehicleInfo({
    required this.brand,
    required this.model,
    required this.category,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'category': category,
    };
  }
}

class InspectionField {
  final int id;
  final String fieldId;
  final String title;
  final String fieldType;
  final bool isRequired;
  final bool hasRemarks;
  final bool hasImage;
  final bool hasVideo;
  final bool hasFile;
  final int order;
  final Map<String, dynamic>? metadata;
  final List<DropdownOption> options;
  final List<ReferenceMedia> referenceMedia;

  InspectionField({
    required this.id,
    required this.fieldId,
    required this.title,
    required this.fieldType,
    required this.isRequired,
    required this.hasRemarks,
    required this.hasImage,
    required this.hasVideo,
    required this.hasFile,
    required this.order,
    this.metadata,
    required this.options,
    required this.referenceMedia,
  });

  factory InspectionField.fromJson(Map<String, dynamic> json) {
    return InspectionField(
      id: json['id'] ?? 0,
      fieldId: json['field_id'] ?? '',
      title: json['title'] ?? '',
      fieldType: json['field_type'] ?? 'text',
      isRequired: json['is_required'] ?? false,
      hasRemarks: json['has_remarks'] ?? false,
      hasImage: json['has_image'] ?? false,
      hasVideo: json['has_video'] ?? false,
      hasFile: json['has_file'] ?? false,
      order: json['order'] ?? 0,
      metadata: json['metadata'],
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => DropdownOption.fromJson(e))
              .toList() ??
          [],
      referenceMedia: (json['reference_media'] as List<dynamic>?)
              ?.map((e) => ReferenceMedia.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_id': fieldId,
      'title': title,
      'field_type': fieldType,
      'is_required': isRequired,
      'has_remarks': hasRemarks,
      'has_image': hasImage,
      'has_video': hasVideo,
      'has_file': hasFile,
      'order': order,
      'metadata': metadata,
      'options': options.map((e) => e.toJson()).toList(),
      'reference_media': referenceMedia.map((e) => e.toJson()).toList(),
    };
  }
}

class DropdownOption {
  final int id;
  final String value;
  final String label;
  final String colorName;
  final String colorCode;
  final int order;

  DropdownOption({
    required this.id,
    required this.value,
    required this.label,
    required this.colorName,
    required this.colorCode,
    required this.order,
  });

  factory DropdownOption.fromJson(Map<String, dynamic> json) {
    return DropdownOption(
      id: json['id'] ?? 0,
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      colorName: json['color_name'] ?? '',
      colorCode: json['color_code'] ?? '#000000',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'label': label,
      'color_name': colorName,
      'color_code': colorCode,
      'order': order,
    };
  }
}

class ReferenceMedia {
  final int id;
  final String mediaType;
  final String filePath;
  final String url;
  final String? description;
  final int order;

  ReferenceMedia({
    required this.id,
    required this.mediaType,
    required this.filePath,
    required this.url,
    this.description,
    required this.order,
  });

  factory ReferenceMedia.fromJson(Map<String, dynamic> json) {
    return ReferenceMedia(
      id: json['id'] ?? 0,
      mediaType: json['media_type'] ?? json['type'] ?? '',
      filePath: json['file_path'] ?? '',
      url: json['url'] ?? '',
      description: json['description'],
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media_type': mediaType,
      'file_path': filePath,
      'url': url,
      'description': description,
      'order': order,
    };
  }
}

class InspectionSection {
  final int id;
  final String name;
  final String title;
  final String? description;
  final int order;
  final List<InspectionField> fields;

  InspectionSection({
    required this.id,
    required this.name,
    required this.title,
    this.description,
    required this.order,
    required this.fields,
  });

  factory InspectionSection.fromJson(Map<String, dynamic> json) {
    return InspectionSection(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      order: json['order'] ?? 0,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => InspectionField.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'description': description,
      'order': order,
      'fields': fields.map((e) => e.toJson()).toList(),
    };
  }
}

class InspectionStructure {
  final List<InspectionSection> sections;

  InspectionStructure({required this.sections});

  factory InspectionStructure.fromJson(Map<String, dynamic> json) {
    return InspectionStructure(
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => InspectionSection.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((e) => e.toJson()).toList(),
    };
  }
}

class InspectionInitializationResponse {
  final InspectionTemplate templateType;
  final VehicleInfo vehicleInfo;
  final InspectionStructure structure;

  InspectionInitializationResponse({
    required this.templateType,
    required this.vehicleInfo,
    required this.structure,
  });

  factory InspectionInitializationResponse.fromJson(Map<String, dynamic> json) {
    return InspectionInitializationResponse(
      templateType: InspectionTemplate.fromJson(
          json['template_type'] ?? json['templateType'] ?? {}),
      vehicleInfo: VehicleInfo.fromJson(
          json['vehicle_info'] ?? json['vehicleInfo'] ?? {}),
      structure: InspectionStructure.fromJson(
          json['structure'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'template_type': templateType.toJson(),
      'vehicle_info': vehicleInfo.toJson(),
      'structure': structure.toJson(),
    };
  }
}
