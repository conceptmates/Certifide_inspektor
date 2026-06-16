// lib/models/local_inspection.dart
import 'package:hive/hive.dart';

import 'pending_image.dart';
import 'pending_media.dart';

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

  /// Media-type-agnostic upload queue. Each entry is one file (image, video,
  /// audio, file, or one frame of a multi-image set) still awaiting upload.
  /// Used by the offline media-sync engine ([syncPendingMedia]) so an upload
  /// interrupted by closing the inspection survives an app restart.
  @HiveField(11)
  final Map<String, PendingMedia> pendingMedia;

  /// Server inspection id (from initialize/resume) used to associate uploaded
  /// media and replay save-step. Null for purely-local records.
  @HiveField(12)
  final int? serverInspectionId;

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
    Map<String, PendingMedia>? pendingMedia,
    this.serverInspectionId,
  })  : pendingImages = pendingImages ?? {},
        videos = videos ?? {},
        audios = audios ?? {},
        files = files ?? {},
        multiImages = multiImages ?? {},
        pendingMedia = pendingMedia ?? {};

  LocalInspection copyWith({
    String? id,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    Map<String, String>? images,
    bool? isSubmitted,
    String? status,
    Map<String, PendingImage>? pendingImages,
    Map<String, String>? videos,
    Map<String, String>? audios,
    Map<String, String>? files,
    Map<String, List<String>>? multiImages,
    Map<String, PendingMedia>? pendingMedia,
    int? serverInspectionId,
  }) {
    return LocalInspection(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      images: images ?? this.images,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      status: status ?? this.status,
      pendingImages: pendingImages ?? this.pendingImages,
      videos: videos ?? this.videos,
      audios: audios ?? this.audios,
      files: files ?? this.files,
      multiImages: multiImages ?? this.multiImages,
      pendingMedia: pendingMedia ?? this.pendingMedia,
      serverInspectionId: serverInspectionId ?? this.serverInspectionId,
    );
  }

  /// True when this record still has queued media work. Entries remain in
  /// [pendingMedia] until they are both uploaded AND their field's save-step
  /// has been replayed on the server, at which point they are removed — so any
  /// remaining entry means there is still work to finish.
  bool get hasPendingMedia => pendingMedia.isNotEmpty;
}
