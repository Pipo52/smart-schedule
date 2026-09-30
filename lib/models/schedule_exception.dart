import 'package:hive_ce/hive.dart';

part 'schedule_exception.g.dart';

@HiveType(typeId: 13)
enum ExceptionType {
  @HiveField(0)
  cancelled, // пара отменена на эту дату
  @HiveField(1)
  modified, // пара изменена на эту дату (другое время/кабинет/и т.д.)
}

@HiveType(typeId: 14)
class ScheduleException extends HiveObject {
  ScheduleException({
    required this.id,
    required this.lessonId,
    required this.date,
    required this.type,
    required this.profileId,
    this.newStartTime,
    this.newEndTime,
    this.newRoom,
    this.newLecturer,
    this.newNotes,
    this.updatedAt,
  });

  @HiveField(0)
  String id;

  /// ID повторяющейся пары, к которой относится исключение.
  @HiveField(1)
  String lessonId;

  /// Конкретная дата, на которую действует исключение (нормализована до полуночи).
  @HiveField(2)
  DateTime date;

  @HiveField(3)
  ExceptionType type;

  @HiveField(4)
  String profileId;

  // Следующие поля используются только при type == modified.
  // Если поле null — берётся значение из оригинальной Lesson.

  @HiveField(5)
  String? newStartTime;

  @HiveField(6)
  String? newEndTime;

  @HiveField(7)
  String? newRoom;

  @HiveField(8)
  String? newLecturer;

  @HiveField(9)
  String? newNotes;

  @HiveField(10)
  DateTime? updatedAt;
}
