import 'pagination_data_model.dart';

/// Public dealer listing (new / used) from `/api/cars/new` etc.
class PublicCarListing {
  PublicCarListing({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.year,
    this.transmission,
    this.fuelType,
    this.photos = const [],
    this.user,
    this.vehicleModel,
  });

  final int id;
  final String title;
  final String? description;
  final String price;
  final int? year;
  final String? transmission;
  final String? fuelType;
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
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      price: json['price']?.toString() ?? '0',
      year: json['year'] as int?,
      transmission: json['transmission']?.toString(),
      fuelType: json['fuel_type']?.toString(),
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
  PublicCarPhoto({required this.url});

  final String url;

  factory PublicCarPhoto.fromJson(Map<String, dynamic> json) {
    return PublicCarPhoto(url: json['url']?.toString() ?? '');
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
    required this.name,
    this.brand,
    this.category,
  });

  final int id;
  final String name;
  final PublicCarBrandBrief? brand;
  final PublicCarCategoryBrief? category;

  factory PublicCarVehicleModelNested.fromJson(Map<String, dynamic> json) {
    return PublicCarVehicleModelNested(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
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
  PublicCarBrandBrief({required this.id, required this.name});

  final int id;
  final String name;

  factory PublicCarBrandBrief.fromJson(Map<String, dynamic> json) {
    return PublicCarBrandBrief(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
    );
  }
}

class PublicCarCategoryBrief {
  PublicCarCategoryBrief({required this.id, required this.name});

  final int id;
  final String name;

  factory PublicCarCategoryBrief.fromJson(Map<String, dynamic> json) {
    return PublicCarCategoryBrief(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
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
