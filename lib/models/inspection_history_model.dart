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
    // Handle both old /inspections shape and new /dynamic-inspections shape
    final vehicleInfo = json['vehicle_info'] as Map<String, dynamic>? ?? {
      'registration_number': json['reference_number'] ?? json['registration_number'] ?? '',
      'make_model': [
        json['vehicle_brand']?['name'] ?? '',
        json['vehicle_model']?['name'] ?? '',
      ].where((s) => s.isNotEmpty).join(' '),
      'variant': json['variant'] ?? '',
      'manufacturing_year': json['year']?.toString() ?? '',
      'fuel_type': json['fuel_type'] ?? '',
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
