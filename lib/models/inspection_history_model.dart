class InspectionHistory {
  final String id;
  final String inspectorName;
  final String status;
  final String processingStatus;
  final String? referenceNumber;
  final DateTime date;
  final Map<String, dynamic> vehicleInfo;
  final Map<String, String>? links;
  // Brand/model ids from the list payload — needed to rebuild a complete submit
  // body when resuming a draft (vehicleInfo only carries display names).
  final int? brandId;
  final int? modelId;

  InspectionHistory({
    required this.id,
    required this.inspectorName,
    required this.status,
    required this.processingStatus,
    this.referenceNumber,
    required this.date,
    required this.vehicleInfo,
    this.links,
    this.brandId,
    this.modelId,
  });

  /// True when the inspection can be resumed. Drafts are initialised-but-not-
  /// completed inspections shown in the Pending tab; 'pending' is kept for
  /// backward compatibility with older server responses.
  bool get isResumable =>
      status == 'draft' || status == 'pending' || processingStatus == 'completed';

  int? get idAsInt => int.tryParse(id);

  factory InspectionHistory.fromJson(Map<String, dynamic> json) {
    // Handle both the old /inspections shape and the new /dynamic-inspections
    // shape. The server's `vehicle_info` keys are inconsistent across endpoints
    // (history uses `manufacturing_year`, the template/resume shape uses `year`;
    // brand/model come as nested objects in either snake_case or camelCase), so
    // normalise everything here to the keys the UI reads — otherwise variant and
    // year silently fall through to "N/A" in the report cards.
    final rawVi = (json['vehicle_info'] as Map?)?.cast<String, dynamic>();

    String firstNonEmpty(List<dynamic> candidates) {
      for (final c in candidates) {
        if (c != null && c.toString().trim().isNotEmpty) return c.toString();
      }
      return '';
    }

    final brandName = firstNonEmpty([
      json['vehicle_brand']?['name'],
      json['vehicleBrand']?['name'],
    ]);
    final modelName = firstNonEmpty([
      json['vehicle_model']?['name'],
      json['vehicleModel']?['name'],
    ]);
    final builtMakeModel =
        [brandName, modelName].where((s) => s.isNotEmpty).join(' ');

    final vehicleInfo = <String, dynamic>{
      'registration_number': firstNonEmpty([
        rawVi?['registration_number'],
        json['registration_number'],
        json['reference_number'],
      ]),
      'make_model': firstNonEmpty([
        rawVi?['make_model'],
        builtMakeModel,
        [rawVi?['brand'], rawVi?['model']]
            .where((s) => s != null && s.toString().trim().isNotEmpty)
            .join(' '),
      ]),
      'variant': firstNonEmpty([
        rawVi?['variant'],
        json['variant'],
        json['vehicle_variant']?['name'],
        json['vehicleVariant']?['name'],
      ]),
      'manufacturing_year': firstNonEmpty([
        rawVi?['manufacturing_year'],
        rawVi?['year'],
        json['manufacturing_year'],
        json['manufacturingyear'],
        json['year'],
      ]),
      'fuel_type': firstNonEmpty([rawVi?['fuel_type'], json['fuel_type']]),
      'transmission':
          firstNonEmpty([rawVi?['transmission'], json['transmission']]),
      'color': firstNonEmpty([
        rawVi?['color'],
        rawVi?['colour'],
        json['color'],
        json['colour'],
      ]),
    };

    final inspectorName = json['inspector']?['name'] ?? json['user']?['name'] ?? '';

    Map<String, String>? links;
    final reportUrl = json['report_url']?.toString() ?? '';
    if (reportUrl.isNotEmpty) {
      links = {'view': reportUrl};
    }

    final processingStatus = (json['processing_status'] ?? '').toString();

    int? parseId(dynamic flat, dynamic obj) {
      if (flat != null) {
        return flat is int ? flat : int.tryParse(flat.toString());
      }
      if (obj is Map && obj['id'] != null) {
        final id = obj['id'];
        return id is int ? id : int.tryParse(id.toString());
      }
      return null;
    }

    // /dynamic-inspections uses is_approved; map it to status when status is missing
    String status = (json['status'] ?? '').toString();
    if (status.isEmpty) {
      status = (json['is_approved'] == true) ? 'approved' : 'pending';
    }

    return InspectionHistory(
      id: json['id'].toString(),
      inspectorName: inspectorName,
      status: status,
      processingStatus: processingStatus,
      referenceNumber: json['reference_number']?.toString(),
      date: DateTime.parse(json['created_at']),
      vehicleInfo: vehicleInfo,
      links: links,
      brandId: parseId(json['vehicle_brand_id'], json['vehicle_brand']),
      modelId: parseId(json['vehicle_model_id'], json['vehicle_model']),
    );
  }
}
