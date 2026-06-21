/// A single attendance record from `GET /api/admin/attendance`.
///
/// `type` is `available` (inspector marked themselves available for the day)
/// or `working` (an active/closed work session with check-in/out times).
class AttendanceRecord {
  final int id;
  final int? inspectorId;
  final String inspectorName;
  final String inspectorEmail;
  final String type;
  final DateTime? date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double? latitude;
  final double? longitude;

  const AttendanceRecord({
    required this.id,
    required this.inspectorId,
    required this.inspectorName,
    required this.inspectorEmail,
    required this.type,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.latitude,
    required this.longitude,
  });

  bool get isWorking => type.toLowerCase() == 'working';
  bool get isAvailable => type.toLowerCase() == 'available';
  bool get hasLocation => latitude != null && longitude != null;

  /// Worked duration when both check-in and check-out are present.
  Duration? get duration {
    if (checkIn == null || checkOut == null) return null;
    final d = checkOut!.difference(checkIn!);
    return d.isNegative ? null : d;
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final inspector = json['inspector'];
    final inspectorMap =
        inspector is Map ? inspector.cast<String, dynamic>() : const {};

    return AttendanceRecord(
      id: AttendanceParse.toInt(json['id']) ?? 0,
      inspectorId:
          AttendanceParse.toInt(json['inspector_id'] ?? inspectorMap['id']),
      inspectorName: (inspectorMap['name'] ??
              json['inspector_name'] ??
              json['name'] ??
              'Inspector')
          .toString(),
      inspectorEmail: (inspectorMap['email'] ??
              json['inspector_email'] ??
              json['email'] ??
              '')
          .toString(),
      type: (json['type'] ?? 'available').toString(),
      date: AttendanceParse.toDate(json['date'] ?? json['created_at']),
      checkIn: AttendanceParse.toDate(
          json['check_in'] ?? json['checked_in_at'] ?? json['start_time']),
      checkOut: AttendanceParse.toDate(
          json['check_out'] ?? json['checked_out_at'] ?? json['end_time']),
      latitude: AttendanceParse.toDouble(json['latitude'] ?? json['lat']),
      longitude: AttendanceParse.toDouble(json['longitude'] ?? json['lng']),
    );
  }
}

/// Shared, null-tolerant parsing helpers for the attendance/leave models.
extension AttendanceParse on Never {
  static int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  static List<String> toStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }
}
