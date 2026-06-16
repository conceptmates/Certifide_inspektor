// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_inspection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalInspectionAdapter extends TypeAdapter<LocalInspection> {
  @override
  final int typeId = 3;

  @override
  LocalInspection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalInspection(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      data: (fields[2] as Map).cast<String, dynamic>(),
      images: (fields[3] as Map).cast<String, String>(),
      isSubmitted: fields[4] as bool,
      status: fields[5] as String,
      pendingImages: (fields[6] as Map?)?.cast<String, PendingImage>(),
      videos: (fields[7] as Map?)?.cast<String, String>(),
      audios: (fields[8] as Map?)?.cast<String, String>(),
      files: (fields[9] as Map?)?.cast<String, String>(),
      multiImages: (fields[10] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      pendingMedia: (fields[11] as Map?)?.cast<String, PendingMedia>(),
      serverInspectionId: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalInspection obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.images)
      ..writeByte(4)
      ..write(obj.isSubmitted)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.pendingImages)
      ..writeByte(7)
      ..write(obj.videos)
      ..writeByte(8)
      ..write(obj.audios)
      ..writeByte(9)
      ..write(obj.files)
      ..writeByte(10)
      ..write(obj.multiImages)
      ..writeByte(11)
      ..write(obj.pendingMedia)
      ..writeByte(12)
      ..write(obj.serverInspectionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalInspectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
