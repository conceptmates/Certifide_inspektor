import 'pagination_data_model.dart';

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String? _parseString(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

/// Public dealer listing (new / used) from `/api/cars/new` etc.
class PublicCarListing {
  PublicCarListing({
    required this.id,
    required this.userId,
    required this.type,
    this.vehicleModelId,
    required this.title,
    this.description,
    required this.price,
    this.year,
    this.mileageKm,
    this.registrationNumber,
    this.chassisNumber,
    required this.status,
    this.transmission,
    this.fuelType,
    this.engineCapacityCc,
    this.mileageFuelEfficiency,
    this.drivetrain,
    this.bodyType,
    this.seatingCapacity,
    this.bootSpace,
    this.groundClearance,
    this.safetyRatingNcap,
    this.airbagsCount,
    this.absEsc,
    this.infotainmentFeatures,
    this.onRoadPrice,
    this.maintenanceCost,
    this.insuranceCost,
    this.resaleValue,
    this.warranty,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.photos = const [],
    this.user,
    this.vehicleModel,
  });

  final int id;
  final int userId;
  final String type;
  final int? vehicleModelId;
  final String title;
  final String? description;
  final String price;
  final int? year;
  final int? mileageKm;
  final String? registrationNumber;
  final String? chassisNumber;
  final String status;
  final String? transmission;
  final String? fuelType;
  final int? engineCapacityCc;
  final String? mileageFuelEfficiency;
  final String? drivetrain;
  final String? bodyType;
  final int? seatingCapacity;
  final String? bootSpace;
  final String? groundClearance;
  final String? safetyRatingNcap;
  final int? airbagsCount;
  final String? absEsc;
  final String? infotainmentFeatures;
  final String? onRoadPrice;
  final String? maintenanceCost;
  final String? insuranceCost;
  final String? resaleValue;
  final String? warranty;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final List<PublicCarPhoto> photos;
  final PublicCarListingUser? user;
  final PublicCarVehicleModelNested? vehicleModel;

  String? get primaryImageUrl =>
      photos.isNotEmpty ? photos.first.url : null;

  String get subtitle {
    final brand = vehicleModel?.brand?.name;
    final model = vehicleModel?.name;
    if (brand != null && model != null) return '$brand $model';
    if (brand != null) return brand;
    if (model != null) return model;
    return user?.name ?? '';
  }

  factory PublicCarListing.fromJson(Map<String, dynamic> json) {
    return PublicCarListing(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      type: json['type']?.toString() ?? 'new',
      vehicleModelId: _parseInt(json['vehicle_model_id']),
      title: json['title']?.toString() ?? '',
      description: _parseString(json['description']),
      price: json['price']?.toString() ?? '0',
      year: _parseInt(json['year']),
      mileageKm: _parseInt(json['mileage_km']),
      registrationNumber: _parseString(json['registration_number']),
      chassisNumber: _parseString(json['chassis_number']),
      status: json['status']?.toString() ?? '',
      transmission: _parseString(json['transmission']),
      fuelType: _parseString(json['fuel_type']),
      engineCapacityCc: _parseInt(json['engine_capacity_cc']),
      mileageFuelEfficiency: _parseString(json['mileage_fuel_efficiency']),
      drivetrain: _parseString(json['drivetrain']),
      bodyType: _parseString(json['body_type']),
      seatingCapacity: _parseInt(json['seating_capacity']),
      bootSpace: _parseString(json['boot_space']),
      groundClearance: _parseString(json['ground_clearance']),
      safetyRatingNcap: _parseString(json['safety_rating_ncap']),
      airbagsCount: _parseInt(json['airbags_count']),
      absEsc: _parseString(json['abs_esc']),
      infotainmentFeatures: _parseString(json['infotainment_features']),
      onRoadPrice: _parseString(json['on_road_price']),
      maintenanceCost: _parseString(json['maintenance_cost']),
      insuranceCost: _parseString(json['insurance_cost']),
      resaleValue: _parseString(json['resale_value']),
      warranty: _parseString(json['warranty']),
      createdAt: _parseString(json['created_at']),
      updatedAt: _parseString(json['updated_at']),
      deletedAt: _parseString(json['deleted_at']),
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((e) => PublicCarPhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
      user: json['user'] != null
          ? PublicCarListingUser.fromJson(
              json['user'] as Map<String, dynamic>,
            )
          : null,
      vehicleModel: json['vehicle_model'] != null
          ? PublicCarVehicleModelNested.fromJson(
              json['vehicle_model'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class PublicCarPhoto {
  PublicCarPhoto({
    required this.id,
    required this.dealerListingId,
    this.path,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    required this.url,
  });

  final int id;
  final int dealerListingId;
  final String? path;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;
  final String url;

  factory PublicCarPhoto.fromJson(Map<String, dynamic> json) {
    return PublicCarPhoto(
      id: _parseInt(json['id']) ?? 0,
      dealerListingId: _parseInt(json['dealer_listing_id']) ?? 0,
      path: _parseString(json['path']),
      sortOrder: _parseInt(json['sort_order']) ?? 0,
      createdAt: _parseString(json['created_at']),
      updatedAt: _parseString(json['updated_at']),
      url: json['url']?.toString() ?? '',
    );
  }
}

class PublicCarListingUser {
  PublicCarListingUser({required this.id, required this.name});

  final int id;
  final String name;

  factory PublicCarListingUser.fromJson(Map<String, dynamic> json) {
    return PublicCarListingUser(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
    );
  }
}

class PublicCarVehicleModelNested {
  PublicCarVehicleModelNested({
    required this.id,
    this.brandId,
    this.categoryId,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.brand,
    this.category,
  });

  final int id;
  final int? brandId;
  final int? categoryId;
  final String name;
  final String? createdAt;
  final String? updatedAt;
  final PublicCarBrandBrief? brand;
  final PublicCarCategoryBrief? category;

  factory PublicCarVehicleModelNested.fromJson(Map<String, dynamic> json) {
    return PublicCarVehicleModelNested(
      id: _parseInt(json['id']) ?? 0,
      brandId: _parseInt(json['brand_id']),
      categoryId: _parseInt(json['category_id']),
      name: json['name']?.toString() ?? '',
      createdAt: _parseString(json['created_at']),
      updatedAt: _parseString(json['updated_at']),
      brand: json['brand'] != null
          ? PublicCarBrandBrief.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? PublicCarCategoryBrief.fromJson(
              json['category'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class PublicCarBrandBrief {
  PublicCarBrandBrief({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;

  factory PublicCarBrandBrief.fromJson(Map<String, dynamic> json) {
    return PublicCarBrandBrief(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      createdAt: _parseString(json['created_at']),
      updatedAt: _parseString(json['updated_at']),
    );
  }
}

class PublicCarCategoryBrief {
  PublicCarCategoryBrief({
    required this.id,
    required this.name,
    this.basePrice,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? basePrice;
  final String? createdAt;
  final String? updatedAt;

  factory PublicCarCategoryBrief.fromJson(Map<String, dynamic> json) {
    return PublicCarCategoryBrief(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      basePrice: _parseString(json['base_price']),
      createdAt: _parseString(json['created_at']),
      updatedAt: _parseString(json['updated_at']),
    );
  }
}

/// Response from `GET /api/cars/filters`
class CarFiltersData {
  CarFiltersData({
    required this.brands,
    required this.vehicleModels,
    required this.categories,
    required this.transmissions,
    required this.fuelTypes,
    required this.bodyTypes,
  });

  final List<CarFilterBrand> brands;
  final List<CarFilterVehicleModel> vehicleModels;
  final List<CarFilterCategory> categories;
  final List<String> transmissions;
  final List<String> fuelTypes;
  final List<String> bodyTypes;

  factory CarFiltersData.fromJson(Map<String, dynamic> json) {
    return CarFiltersData(
      brands: (json['brands'] as List<dynamic>? ?? [])
          .map((e) => CarFilterBrand.fromJson(e as Map<String, dynamic>))
          .toList(),
      vehicleModels: (json['vehicle_models'] as List<dynamic>? ?? [])
          .map((e) => CarFilterVehicleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => CarFilterCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      transmissions: (json['transmissions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      fuelTypes: (json['fuel_types'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      bodyTypes: (json['body_types'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class CarFilterBrand {
  CarFilterBrand({required this.id, required this.name});

  final int id;
  final String name;

  factory CarFilterBrand.fromJson(Map<String, dynamic> json) {
    return CarFilterBrand(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
    );
  }
}

class CarFilterVehicleModel {
  CarFilterVehicleModel({
    required this.id,
    required this.name,
    required this.brandId,
    required this.categoryId,
  });

  final int id;
  final String name;
  final int brandId;
  final int categoryId;

  factory CarFilterVehicleModel.fromJson(Map<String, dynamic> json) {
    return CarFilterVehicleModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      brandId: json['brand_id'] as int? ?? 0,
      categoryId: json['category_id'] as int? ?? 0,
    );
  }
}

class CarFilterCategory {
  CarFilterCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory CarFilterCategory.fromJson(Map<String, dynamic> json) {
    return CarFilterCategory(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Parsed new-cars payload: listings + pagination.
class NewCarsResult {
  NewCarsResult({required this.cars, required this.meta});

  final List<PublicCarListing> cars;
  final PaginationData meta;

  factory NewCarsResult.fromJson(Map<String, dynamic> json) {
    final carsJson = json['cars'] as List<dynamic>? ?? [];
    return NewCarsResult(
      cars: carsJson
          .map((e) => PublicCarListing.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationData.fromJson(
        json['meta'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
