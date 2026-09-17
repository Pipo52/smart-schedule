import 'package:hive_ce/hive.dart';

part 'exam.g.dart';

@HiveType(typeId: 6)
enum ExamType {
  @HiveField(0)
  midterm,
  @HiveField(1)
  finalExam,
  @HiveField(2)
  retake,
}

/// An exam, separate from the regular recurring [Lesson] schedule.
@HiveType(typeId: 5)
class Exam extends HiveObject {
  Exam({
    required this.id,
    required this.subjectName,
    required this.date,
    this.room,
    required this.examType,
    this.notes,
    List<String>? revisionTasks,
    required this.profileId,
  }) : revisionTasks = revisionTasks ?? <String>[];

  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectName;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? room;

  @HiveField(4)
  ExamType examType;

  @HiveField(5)
  String? notes;

  /// Ids of [Task]s created to help prepare for this exam.
  @HiveField(6)
  List<String> revisionTasks;

  @HiveField(7, defaultValue: 'default')
  String profileId;

  Exam copyWith({
    String? subjectName,
    DateTime? date,
    String? room,
    ExamType? examType,
    String? notes,
    List<String>? revisionTasks,
    String? profileId,
  }) {
    return Exam(
      id: id,
      subjectName: subjectName ?? this.subjectName,
      date: date ?? this.date,
      room: room ?? this.room,
      examType: examType ?? this.examType,
      notes: notes ?? this.notes,
      revisionTasks: revisionTasks ?? List<String>.from(this.revisionTasks),
      profileId: profileId ?? this.profileId,
    );
  }
}
