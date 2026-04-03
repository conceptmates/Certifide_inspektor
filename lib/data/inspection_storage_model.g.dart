// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_storage_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InspectionStorageModelAdapter
    extends TypeAdapter<InspectionStorageModel> {
  @override
  final int typeId = 0;

  @override
  InspectionStorageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InspectionStorageModel(
      itemValues: (fields[0] as Map?)?.cast<String, String>(),
      itemImages: (fields[1] as Map?)?.cast<String, String?>(),
      itemRemarks: (fields[2] as Map?)?.cast<String, String>(),
      currentSection: fields[3] as int?,
      textFieldValues: (fields[4] as Map?)?.cast<String, String>(),
      timestamp: fields[5] as DateTime?,
      isCompleted: fields[6] as bool?,
      multiImages: (fields[7] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      status: fields[8] == null ? 'draft' : fields[8] as String?,
      itemVideos: (fields[9] as Map?)?.cast<String, String?>(),
      itemAudios: (fields[10] as Map?)?.cast<String, String?>(),
      itemFiles: (fields[11] as Map?)?.cast<String, String?>(),
    );
  }

  @override
  void write(BinaryWriter writer, InspectionStorageModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.itemValues)
      ..writeByte(1)
      ..write(obj.itemImages)
      ..writeByte(2)
      ..write(obj.itemRemarks)
      ..writeByte(3)
      ..write(obj.currentSection)
      ..writeByte(4)
      ..write(obj.textFieldValues)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.multiImages)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.itemVideos)
      ..writeByte(10)
      ..write(obj.itemAudios)
      ..writeByte(11)
      ..write(obj.itemFiles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionStorageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
