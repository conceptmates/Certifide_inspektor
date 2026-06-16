// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_media.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingMediaAdapter extends TypeAdapter<PendingMedia> {
  @override
  final int typeId = 5;

  @override
  PendingMedia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingMedia(
      localPath: fields[0] as String,
      section: fields[1] as String,
      itemId: fields[2] as String,
      mediaType: fields[3] as String,
      fieldKey: fields[4] as String,
      uploadStatus: fields[5] as String,
      uploadedUrl: fields[6] as String?,
      retryCount: fields[7] as int,
      lastError: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingMedia obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.localPath)
      ..writeByte(1)
      ..write(obj.section)
      ..writeByte(2)
      ..write(obj.itemId)
      ..writeByte(3)
      ..write(obj.mediaType)
      ..writeByte(4)
      ..write(obj.fieldKey)
      ..writeByte(5)
      ..write(obj.uploadStatus)
      ..writeByte(6)
      ..write(obj.uploadedUrl)
      ..writeByte(7)
      ..write(obj.retryCount)
      ..writeByte(8)
      ..write(obj.lastError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingMediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
