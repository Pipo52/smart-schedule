import 'package:hive_ce/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 4)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

/// A task/deadline, optionally linked to a subject or an exam.
@HiveType(typeId: 3)
class Task extends HiveObject {
  Task({
    required this.id,
    required this.title,
    this.linkedSubject,
    this.description,
    required this.dueDate,
    required this.priority,
    this.isDone = false,
    this.reminderOffsetMinutes,
    this.linkedExamId,
    required this.profileId,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  /// Optional free-text subject name this task relates to. Not required to
  /// match any [Lesson.subjectName] exactly.
  @HiveField(2)
  String? linkedSubject;

  @HiveField(3)
  String? description;

  @HiveField(4)
  DateTime dueDate;

  @HiveField(5)
  Priority priority;

  @HiveField(6)
  bool isDone;

  /// Minutes before [dueDate] to fire a local notification. `null` = no
  /// reminder.
  @HiveField(7)
  int? reminderOffsetMinutes;

  /// Back-reference to an [Exam] when this task was created as a
  /// "preparation" task from the exam screen. Convenience field, not part of
  /// the strict spec (the spec only requires `Exam.revisionTasks`).
  @HiveField(8)
  String? linkedExamId;

  @HiveField(9, defaultValue: 'default')
  String profileId;

  Task copyWith({
    String? title,
    String? linkedSubject,
    String? description,
    DateTime? dueDate,
    Priority? priority,
    bool? isDone,
    int? reminderOffsetMinutes,
    String? linkedExamId,
    String? profileId,
    bool clearReminder = false,
    bool clearLinkedSubject = false,
    bool clearLinkedExam = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      linkedSubject: clearLinkedSubject
          ? null
          : (linkedSubject ?? this.linkedSubject),
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      reminderOffsetMinutes: clearReminder
          ? null
          : (reminderOffsetMinutes ?? this.reminderOffsetMinutes),
      linkedExamId: clearLinkedExam
          ? null
          : (linkedExamId ?? this.linkedExamId),
      profileId: profileId ?? this.profileId,
    );
  }
}
