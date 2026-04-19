import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class VehicleBrandDto {
  final int id;
  final String name;

  const VehicleBrandDto({
    required this.id,
    required this.name,
  });

  factory VehicleBrandDto.fromJson(Map<String, dynamic> json) {
    return VehicleBrandDto(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class VehicleModelDto {
  final int id;
  final int brandId;
  final String name;
  final VehicleBrandDto brand;

  const VehicleModelDto({
    required this.id,
    required this.brandId,
    required this.name,
    required this.brand,
  });

  factory VehicleModelDto.fromJson(Map<String, dynamic> json) {
    final embeddedBrand = json['brand'] is Map<String, dynamic>
        ? VehicleBrandDto.fromJson(json['brand'] as Map<String, dynamic>)
        : VehicleBrandDto(
            id: _asInt(json['brand_id']),
            name: '',
          );

    return VehicleModelDto(
      id: _asInt(json['id']),
      brandId: _asInt(json['brand_id']),
      name: (json['name'] ?? '').toString(),
      brand: embeddedBrand,
    );
  }
}

class VehicleCatalogResponse {
  final List<VehicleBrandDto> brands;
  final List<VehicleModelDto> models;

  const VehicleCatalogResponse({
    required this.brands,
    required this.models,
  });
}

class VehicleCatalogApi {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  const VehicleCatalogApi({
    required this.baseUrl,
    required http.Client client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client;

  /// Fetches all vehicle models and returns unique brands + models.
  ///
  /// Example:
  /// final api = VehicleCatalogApi(
  ///   baseUrl: 'https://api.certifide.in/api',
  ///   client: http.Client(),
  /// );
  /// final data = await api.fetchVehicleCatalog(bearerToken: '<token>');
  Future<VehicleCatalogResponse> fetchVehicleCatalog({
    required String bearerToken,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/vehicles/models');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    ).timeout(timeout);

    if (response.statusCode != 200) {
      throw VehicleCatalogApiException(
        'Failed to fetch models (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = json.decode(response.body);
    final list = _extractModelList(decoded);

    final models = <VehicleModelDto>[];
    final brandsById = <int, VehicleBrandDto>{};

    for (final item in list) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final model = VehicleModelDto.fromJson(map);
      models.add(model);

      if (!brandsById.containsKey(model.brand.id)) {
        brandsById[model.brand.id] = VehicleBrandDto(
          id: model.brand.id,
          name: model.brand.name,
        );
      }
    }

    final brands = brandsById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return VehicleCatalogResponse(
      brands: brands,
      models: models,
    );
  }

  List<VehicleModelDto> modelsByBrand({
    required VehicleCatalogResponse catalog,
    required int brandId,
  }) {
    return catalog.models.where((m) => m.brandId == brandId).toList();
  }
}

class VehicleCatalogApiException implements Exception {
  final String message;

  const VehicleCatalogApiException(this.message);

  @override
  String toString() => 'VehicleCatalogApiException: $message';
}

List<dynamic> _extractModelList(dynamic decoded) {
  if (decoded is List) return decoded;
  if (decoded is Map<String, dynamic>) {
    final data = decoded['data'];
    if (data is List) return data;
  }
  throw const VehicleCatalogApiException(
    'Unexpected API response format while reading vehicle models.',
  );
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '0') ?? 0;
}
