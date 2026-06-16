// lib/models/pending_media.dart
import 'package:hive/hive.dart';

part 'pending_media.g.dart';

/// Upload-status values for a queued media item.
class PendingMediaStatus {
  static const String queued = 'queued';
  static const String uploading = 'uploading';
  static const String uploaded = 'uploaded';
  static const String failed = 'failed';
}

/// A single media file (image / video / audio / file / one frame of a
/// multi-image set) that still needs to be uploaded to the server.
///
/// Generalizes [PendingImage] so the offline upload queue can resume an
/// interrupted upload for ANY media type. Each entry carries everything the
/// sync engine needs to re-upload after an app restart: the local file path,
/// the routing metadata the upload endpoint expects (section + itemId) and the
/// field key that ties it back to a form field for save-step replay.
@HiveType(typeId: 5)
class PendingMedia extends HiveObject {
  /// Absolute path to the media file inside app storage.
  @HiveField(0)
  final String localPath;

  /// Section value sent to the upload endpoint (the section *title*, mirroring
  /// what the capture handlers pass as `section:`).
  @HiveField(1)
  final String section;

  /// Field id sent to the upload endpoint as `itemId`.
  @HiveField(2)
  final String itemId;

  /// One of `image`, `video`, `audio`, `file`, `multiImage`.
  @HiveField(3)
  final String mediaType;

  /// The per-field unique id used as the map key in the inspection screen.
  /// Multiple [PendingMedia] entries of type `multiImage` share one fieldKey.
  @HiveField(4)
  final String fieldKey;

  /// queued / uploading / uploaded / failed.
  @HiveField(5)
  final String uploadStatus;

  /// Server URL once uploaded, otherwise null.
  @HiveField(6)
  final String? uploadedUrl;

  /// Number of failed upload attempts (for backoff / diagnostics).
  @HiveField(7)
  final int retryCount;

  /// Last upload error message, if any.
  @HiveField(8)
  final String? lastError;

  PendingMedia({
    required this.localPath,
    required this.section,
    required this.itemId,
    required this.mediaType,
    required this.fieldKey,
    this.uploadStatus = PendingMediaStatus.queued,
    this.uploadedUrl,
    this.retryCount = 0,
    this.lastError,
  });

  bool get isUploaded => uploadStatus == PendingMediaStatus.uploaded;

  PendingMedia copyWith({
    String? localPath,
    String? section,
    String? itemId,
    String? mediaType,
    String? fieldKey,
    String? uploadStatus,
    String? uploadedUrl,
    int? retryCount,
    String? lastError,
  }) {
    return PendingMedia(
      localPath: localPath ?? this.localPath,
      section: section ?? this.section,
      itemId: itemId ?? this.itemId,
      mediaType: mediaType ?? this.mediaType,
      fieldKey: fieldKey ?? this.fieldKey,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }
}
