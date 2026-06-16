class PaginationData {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationData({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) {
    return PaginationData(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
    );
  }

  bool get hasMore => currentPage < lastPage;

  @override
  String toString() =>
      'PaginationData(currentPage: $currentPage, lastPage: $lastPage, '
      'perPage: $perPage, total: $total)';
}
