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
    return InspectionHistory(
      id: json['id'].toString(),
      inspectorName: json['inspector']['name'] ?? '',
      status: json['status'] ?? '',
      date: DateTime.parse(json['created_at']),
      vehicleInfo: json['vehicle_info'] ?? {},
      links: json['links'] != null
          ? Map<String, String>.from(json['links'])
          : null,
    );
  }
}
