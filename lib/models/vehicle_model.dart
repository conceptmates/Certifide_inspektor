// lib/models/vehicle_model.dart

class VehicleBrand {
  final int id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleBrand({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleBrand.fromJson(dynamic json) {
    if (json == null) {
      return VehicleBrand(id: 0, name: '');
    }
    return VehicleBrand(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class VehicleCategory {
  final int id;
  final String name;
  final String basePrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleCategory({
    required this.id,
    required this.name,
    required this.basePrice,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleCategory.fromJson(dynamic json) {
    if (json == null) {
      return VehicleCategory(id: 0, name: '', basePrice: '0.00');
    }
    return VehicleCategory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      basePrice: json['base_price']?.toString() ?? '0.00',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'base_price': basePrice,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class VehicleModel {
  final int id;
  final int brandId;
  final int categoryId;
  final String name;
  final VehicleBrand brand;
  final VehicleCategory category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleModel({
    required this.id,
    required this.brandId,
    required this.categoryId,
    required this.name,
    required this.brand,
    required this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleModel.fromJson(dynamic json) {
    if (json == null) {
      return VehicleModel(
        id: 0,
        brandId: 0,
        categoryId: 0,
        name: '',
        brand: VehicleBrand.fromJson(null),
        category: VehicleCategory.fromJson(null),
      );
    }
    
    // Handle brand_id and category_id safely
    int brandId = 0;
    int categoryId = 0;
    
    if (json['brand_id'] is int) {
      brandId = json['brand_id'];
    } else if (json['brand_id'] is String) {
      brandId = int.tryParse(json['brand_id']) ?? 0;
    }
    
    if (json['category_id'] is int) {
      categoryId = json['category_id'];
    } else if (json['category_id'] is String) {
      categoryId = int.tryParse(json['category_id']) ?? 0;
    }
    
    return VehicleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      brandId: brandId,
      categoryId: categoryId,
      name: json['name']?.toString() ?? '',
      brand: VehicleBrand.fromJson(json['brand']),
      category: VehicleCategory.fromJson(json['category']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_id': brandId,
      'category_id': categoryId,
      'name': name,
      'brand': brand.toJson(),
      'category': category.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
