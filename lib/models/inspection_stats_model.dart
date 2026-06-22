class InspectionStatsBucket {
  final String bucket;
  final int total;
  final int approved;
  final int pending;
  final int rejected;

  const InspectionStatsBucket({
    required this.bucket,
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  factory InspectionStatsBucket.fromJson(Map<String, dynamic> json) =>
      InspectionStatsBucket(
        bucket: json['bucket'] as String,
        total: (json['total'] as num).toInt(),
        approved: (json['approved'] as num).toInt(),
        pending: (json['pending'] as num).toInt(),
        rejected: (json['rejected'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'bucket': bucket,
        'total': total,
        'approved': approved,
        'pending': pending,
        'rejected': rejected,
      };
}

class InspectionStatsTotals {
  final int total;
  final int approved;
  final int pending;
  final int rejected;

  const InspectionStatsTotals({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  factory InspectionStatsTotals.fromJson(Map<String, dynamic> json) =>
      InspectionStatsTotals(
        total: (json['total'] as num).toInt(),
        approved: (json['approved'] as num).toInt(),
        pending: (json['pending'] as num).toInt(),
        rejected: (json['rejected'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'total': total,
        'approved': approved,
        'pending': pending,
        'rejected': rejected,
      };
}

class InspectionStats {
  final String period;
  final String from;
  final String to;
  final InspectionStatsTotals totals;
  final List<InspectionStatsBucket> buckets;

  const InspectionStats({
    required this.period,
    required this.from,
    required this.to,
    required this.totals,
    required this.buckets,
  });

  factory InspectionStats.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return InspectionStats(
      period: meta['period'] as String,
      from: meta['from'] as String,
      to: meta['to'] as String,
      totals: InspectionStatsTotals.fromJson(
          json['totals'] as Map<String, dynamic>),
      buckets: (json['buckets'] as List)
          .map((b) =>
              InspectionStatsBucket.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Mirrors the shape [InspectionStats.fromJson] expects, so a cached value
  /// round-trips back through the same factory.
  Map<String, dynamic> toJson() => {
        'meta': {'period': period, 'from': from, 'to': to},
        'totals': totals.toJson(),
        'buckets': buckets.map((b) => b.toJson()).toList(),
      };

  List<InspectionStatsBucket> get activeBuckets =>
      buckets.where((b) => b.total > 0).toList();
}
