import 'attendance_record.dart' show AttendanceParse;

/// A single leave request as returned by the admin leaves endpoints
/// (`GET /api/admin/leaves`, approve/reject responses).
///
/// Leaves are single-day (`leave_date`). The backend response shape isn't
/// strictly fixed, so every field is parsed defensively with sensible
/// fallbacks (mirroring the rest of the codebase).
class LeaveRequest {
  final int id;
  final int? inspectorId;
  final String inspectorName;
  final String inspectorEmail;
  final String status;
  final DateTime? leaveDate;
  final String reason;
  final String? adminNote;
  final DateTime? createdAt;

  /// Order IDs of bookings that clash with an approved leave and need
  /// reassigning. Populated from the approve response's `conflicting_bookings`.
  final List<String> conflictingBookings;

  const LeaveRequest({
    required this.id,
    required this.inspectorId,
    required this.inspectorName,
    required this.inspectorEmail,
    required this.status,
    required this.leaveDate,
    required this.reason,
    required this.adminNote,
    required this.createdAt,
    this.conflictingBookings = const [],
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final inspector = json['inspector'];
    final inspectorMap =
        inspector is Map ? inspector.cast<String, dynamic>() : const {};

    return LeaveRequest(
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
      status: (json['status'] ?? 'pending').toString(),
      leaveDate: AttendanceParse.toDate(json['leave_date'] ??
          json['date'] ??
          json['from_date'] ??
          json['start_date']),
      reason: (json['reason'] ?? json['note'] ?? '').toString(),
      adminNote: json['admin_note']?.toString(),
      createdAt: AttendanceParse.toDate(json['created_at']),
      conflictingBookings:
          AttendanceParse.toStringList(json['conflicting_bookings']),
    );
  }

  LeaveRequest copyWith({
    String? status,
    String? adminNote,
    List<String>? conflictingBookings,
  }) {
    return LeaveRequest(
      id: id,
      inspectorId: inspectorId,
      inspectorName: inspectorName,
      inspectorEmail: inspectorEmail,
      status: status ?? this.status,
      leaveDate: leaveDate,
      reason: reason,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt,
      conflictingBookings: conflictingBookings ?? this.conflictingBookings,
    );
  }
}
