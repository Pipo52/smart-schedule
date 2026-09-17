// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExamAdapter extends TypeAdapter<Exam> {
  @override
  final typeId = 5;

  @override
  Exam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exam(
      id: fields[0] as String,
      subjectName: fields[1] as String,
      date: fields[2] as DateTime,
      room: fields[3] as String?,
      examType: fields[4] as ExamType,
      notes: fields[5] as String?,
      revisionTasks: (fields[6] as List?)?.cast<String>(),
      profileId: fields[7] == null ? 'default' : fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Exam obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectName)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.room)
      ..writeByte(4)
      ..write(obj.examType)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.revisionTasks)
      ..writeByte(7)
      ..write(obj.profileId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExamTypeAdapter extends TypeAdapter<ExamType> {
  @override
  final typeId = 6;

  @override
  ExamType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExamType.midterm;
      case 1:
        return ExamType.finalExam;
      case 2:
        return ExamType.retake;
      default:
        return ExamType.midterm;
    }
  }

  @override
  void write(BinaryWriter writer, ExamType obj) {
    switch (obj) {
      case ExamType.midterm:
        writer.writeByte(0);
      case ExamType.finalExam:
        writer.writeByte(1);
      case ExamType.retake:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
