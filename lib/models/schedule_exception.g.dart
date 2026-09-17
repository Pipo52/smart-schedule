// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_exception.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleExceptionAdapter extends TypeAdapter<ScheduleException> {
  @override
  final typeId = 14;

  @override
  ScheduleException read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleException(
      id: fields[0] as String,
      lessonId: fields[1] as String,
      date: fields[2] as DateTime,
      type: fields[3] as ExceptionType,
      profileId: fields[4] as String,
      newStartTime: fields[5] as String?,
      newEndTime: fields[6] as String?,
      newRoom: fields[7] as String?,
      newLecturer: fields[8] as String?,
      newNotes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleException obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lessonId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.profileId)
      ..writeByte(5)
      ..write(obj.newStartTime)
      ..writeByte(6)
      ..write(obj.newEndTime)
      ..writeByte(7)
      ..write(obj.newRoom)
      ..writeByte(8)
      ..write(obj.newLecturer)
      ..writeByte(9)
      ..write(obj.newNotes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleExceptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExceptionTypeAdapter extends TypeAdapter<ExceptionType> {
  @override
  final typeId = 13;

  @override
  ExceptionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExceptionType.cancelled;
      case 1:
        return ExceptionType.modified;
      default:
        return ExceptionType.cancelled;
    }
  }

  @override
  void write(BinaryWriter writer, ExceptionType obj) {
    switch (obj) {
      case ExceptionType.cancelled:
        writer.writeByte(0);
      case ExceptionType.modified:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExceptionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
