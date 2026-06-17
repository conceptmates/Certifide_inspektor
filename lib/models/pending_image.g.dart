// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_image.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingImageAdapter extends TypeAdapter<PendingImage> {
  @override
  final typeId = 4;

  @override
  PendingImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingImage(
      imagePath: fields[0] as String,
      section: fields[1] as String,
      itemId: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PendingImage obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.section)
      ..writeByte(2)
      ..write(obj.itemId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
