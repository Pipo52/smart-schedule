// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonAdapter extends TypeAdapter<Lesson> {
  @override
  final typeId = 0;

  @override
  Lesson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lesson(
      id: fields[0] as String,
      subjectName: fields[1] as String,
      type: fields[2] as LessonType,
      room: fields[3] as String,
      lecturer: fields[4] as String,
      startTime: fields[5] as String,
      endTime: fields[6] as String,
      weekday: (fields[7] as num).toInt(),
      weekType: fields[8] as WeekType,
      profileId: fields[11] == null ? 'default' : fields[11] as String,
      notes: fields[9] as String?,
      reminderEnabled: fields[10] == null ? true : fields[10] as bool,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Lesson obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectName)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.room)
      ..writeByte(4)
      ..write(obj.lecturer)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.weekday)
      ..writeByte(8)
      ..write(obj.weekType)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.reminderEnabled)
      ..writeByte(11)
      ..write(obj.profileId)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LessonTypeAdapter extends TypeAdapter<LessonType> {
  @override
  final typeId = 1;

  @override
  LessonType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LessonType.lecture;
      case 1:
        return LessonType.practical;
      case 2:
        return LessonType.laboratory;
      default:
        return LessonType.lecture;
    }
  }

  @override
  void write(BinaryWriter writer, LessonType obj) {
    switch (obj) {
      case LessonType.lecture:
        writer.writeByte(0);
      case LessonType.practical:
        writer.writeByte(1);
      case LessonType.laboratory:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeekTypeAdapter extends TypeAdapter<WeekType> {
  @override
  final typeId = 2;

  @override
  WeekType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WeekType.every;
      case 1:
        return WeekType.week1;
      case 2:
        return WeekType.week2;
      default:
        return WeekType.every;
    }
  }

  @override
  void write(BinaryWriter writer, WeekType obj) {
    switch (obj) {
      case WeekType.every:
        writer.writeByte(0);
      case WeekType.week1:
        writer.writeByte(1);
      case WeekType.week2:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
