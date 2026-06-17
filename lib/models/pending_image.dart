// lib/models/pending_image.dart
import 'package:hive_ce/hive.dart';

part 'pending_image.g.dart';

@HiveType(typeId: 4)
class PendingImage extends HiveObject {
  @HiveField(0)
  final String imagePath;

  @HiveField(1)
  final String section;

  @HiveField(2)
  final String itemId;

  PendingImage({
    required this.imagePath,
    required this.section,
    required this.itemId,
  });
}
