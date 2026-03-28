// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 0;

  @override
  Medicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicine()
      ..name = fields[0] as String
      ..frequency = fields[1] as String
      ..times = (fields[2] as List).cast<String>()
      ..durationType = fields[3] as String
      ..endDate = fields[4] as DateTime?
      ..durationDays = fields[5] as int?
      ..instructions = fields[6] as String?
      ..startDate = fields[7] as DateTime
      ..isActive = fields[8] as bool;
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.frequency)
      ..writeByte(2)
      ..write(obj.times)
      ..writeByte(3)
      ..write(obj.durationType)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.durationDays)
      ..writeByte(6)
      ..write(obj.instructions)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
