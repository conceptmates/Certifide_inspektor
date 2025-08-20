// lib/models/local_inspection.dart
import 'package:hive/hive.dart';

part 'local_inspection.g.dart';

@HiveType(typeId: 3)
class LocalInspection extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final Map<String, dynamic> data;

  @HiveField(3)
  final Map<String, String> images;

  @HiveField(4)
  final bool isSubmitted;

  @HiveField(5)
  final String status;

  LocalInspection({
    required this.id,
    required this.createdAt,
    required this.data,
    required this.images,
    this.isSubmitted = false,
    this.status = 'pending',
  });
}
