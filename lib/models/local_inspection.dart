// lib/models/local_inspection.dart
import 'package:hive/hive.dart';

import 'pending_image.dart';

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

  @HiveField(6)
  final Map<String, PendingImage> pendingImages;

  @HiveField(7)
  final Map<String, String> videos;

  @HiveField(8)
  final Map<String, String> audios;

  @HiveField(9)
  final Map<String, String> files;

  @HiveField(10)
  final Map<String, List<String>> multiImages;

  LocalInspection({
    required this.id,
    required this.createdAt,
    required this.data,
    required this.images,
    this.isSubmitted = false,
    this.status = 'pending',
    Map<String, PendingImage>? pendingImages,
    Map<String, String>? videos,
    Map<String, String>? audios,
    Map<String, String>? files,
    Map<String, List<String>>? multiImages,
  })  : pendingImages = pendingImages ?? {},
        videos = videos ?? {},
        audios = audios ?? {},
        files = files ?? {},
        multiImages = multiImages ?? {};
}
