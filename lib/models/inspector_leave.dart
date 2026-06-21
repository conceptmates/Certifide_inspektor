import 'attendance_record.dart' show AttendanceParse;

/// An inspector's own leave request, as returned by the inspector leave API
/// (`GET /api/inspector/leaves`, `POST /api/inspector/leaves`).
///
/// Inspector leaves are single-day (`leave_date`), unlike the admin-side range
/// model in [LeaveRequest].
class InspectorLeave {
  final int id;
  final DateTime? leaveDate;
  final String reason;
  final String status;
  final String? adminNote;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime? createdAt;

  const InspectorLeave({
    required this.id,
    required this.leaveDate,
    required this.reason,
    required this.status,
    required this.adminNote,
    required this.reviewedAt,
    required this.reviewedBy,
    required this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory InspectorLeave.fromJson(Map<String, dynamic> json) {
    final reviewedBy = json['reviewed_by'];
    return InspectorLeave(
      id: AttendanceParse.toInt(json['id']) ?? 0,
      leaveDate: AttendanceParse.toDate(json['leave_date'] ?? json['date']),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      adminNote: json['admin_note']?.toString(),
      reviewedAt: AttendanceParse.toDate(json['reviewed_at']),
      reviewedBy: reviewedBy is Map
          ? (reviewedBy['name'] ?? reviewedBy['id'])?.toString()
          : reviewedBy?.toString(),
      createdAt: AttendanceParse.toDate(json['created_at']),
    );
  }
}
