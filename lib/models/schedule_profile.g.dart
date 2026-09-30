// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleProfileAdapter extends TypeAdapter<ScheduleProfile> {
  @override
  final typeId = 9;

  @override
  ScheduleProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      isDefault: fields[3] as bool,
      updatedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.isDefault)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
