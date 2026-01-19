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
      pendingImages: (fields[6] as Map?)
          ?.map((key, value) => MapEntry(
                key as String,
                value as PendingImage,
              ))
          .cast<String, PendingImage>() ??
      {},
    );
  }

  @override
  void write(BinaryWriter writer, LocalInspection obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.pendingImages);
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
