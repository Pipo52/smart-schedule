// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_period.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SemesterPeriodAdapter extends TypeAdapter<SemesterPeriod> {
  @override
  final typeId = 12;

  @override
  SemesterPeriod read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SemesterPeriod(
      id: fields[0] as String,
      name: fields[1] as String,
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime,
      type: fields[4] as SemesterPeriodType,
      profileId: fields[5] as String,
      colorValue: (fields[6] as num?)?.toInt(),
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SemesterPeriod obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.profileId)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SemesterPeriodTypeAdapter extends TypeAdapter<SemesterPeriodType> {
  @override
  final typeId = 11;

  @override
  SemesterPeriodType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SemesterPeriodType.study;
      case 1:
        return SemesterPeriodType.exam;
      case 2:
        return SemesterPeriodType.holiday;
      case 3:
        return SemesterPeriodType.retake;
      case 4:
        return SemesterPeriodType.publicHoliday;
      case 5:
        return SemesterPeriodType.other;
      default:
        return SemesterPeriodType.study;
    }
  }

  @override
  void write(BinaryWriter writer, SemesterPeriodType obj) {
    switch (obj) {
      case SemesterPeriodType.study:
        writer.writeByte(0);
      case SemesterPeriodType.exam:
        writer.writeByte(1);
      case SemesterPeriodType.holiday:
        writer.writeByte(2);
      case SemesterPeriodType.retake:
        writer.writeByte(3);
      case SemesterPeriodType.publicHoliday:
        writer.writeByte(4);
      case SemesterPeriodType.other:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterPeriodTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
