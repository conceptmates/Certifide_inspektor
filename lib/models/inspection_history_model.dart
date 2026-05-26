class InspectionHistory {
  final String id;
  final String inspectorName;
  final String status;
  final DateTime date;
  final Map<String, dynamic> vehicleInfo;
  final Map<String, String>? links;

  InspectionHistory({
    required this.id,
    required this.inspectorName,
    required this.status,
    required this.date,
    required this.vehicleInfo,
    this.links,
  });

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
    if (json['report_url'] != null &&
        (json['report_url'] as String).isNotEmpty) {
      links = {'view': json['report_url'] as String};
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
      date: DateTime.parse(json['created_at']),
      vehicleInfo: vehicleInfo,
      links: links,
    );
  }
}
