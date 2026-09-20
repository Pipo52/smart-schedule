import 'package:hive_ce/hive.dart';

part 'lesson.g.dart';

/// Type of a lesson. Determines the color/icon used across the UI.
@HiveType(typeId: 1)
enum LessonType {
  @HiveField(0)
  lecture,
  @HiveField(1)
  practical,
  @HiveField(2)
  laboratory,
}

/// Determines on which weeks (in the Week 1 / Week 2 rotation) a lesson
/// actually happens.
@HiveType(typeId: 2)
enum WeekType {
  @HiveField(0)
  every,
  @HiveField(1)
  week1,
  @HiveField(2)
  week2,
}

/// A single recurring class ("пара") in the schedule.
@HiveType(typeId: 0)
class Lesson extends HiveObject {
  Lesson({
    required this.id,
    required this.subjectName,
    required this.type,
    required this.room,
    required this.lecturer,
    required this.startTime,
    required this.endTime,
    required this.weekday,
    required this.weekType,
    required this.profileId,
    this.notes,
    this.reminderEnabled = true,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectName;

  @HiveField(2)
  LessonType type;

  @HiveField(3)
  String room;

  @HiveField(4)
  String lecturer;

  /// Stored as "HH:mm" in 24h local time, e.g. "08:30".
  @HiveField(5)
  String startTime;

  /// Stored as "HH:mm" in 24h local time, e.g. "10:05".
  @HiveField(6)
  String endTime;

  /// 1 = Monday ... 6 = Saturday.
  @HiveField(7)
  int weekday;

  @HiveField(8)
  WeekType weekType;

  @HiveField(9)
  String? notes;

  /// Whether a local notification reminder should be scheduled for this
  /// lesson. The actual offset (in minutes before the lesson) comes from
  /// [AppSettings.defaultLessonReminderMinutes].
  ///
  /// Note: this field is not explicitly listed in the original spec's model
  /// definition, but is required to support "Lesson с активным напоминанием"
  /// from the notifications section, since Lesson itself has no per-lesson
  /// reminder-offset field.
  @HiveField(10)
  bool reminderEnabled;

  @HiveField(11, defaultValue: 'default')
  String profileId;

  int get startMinutes => _parseMinutesSinceMidnight(startTime);

  int get endMinutes => _parseMinutesSinceMidnight(endTime);

  static int _parseMinutesSinceMidnight(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    } catch (_) {
      return 0;
    }
  }

  Lesson copyWith({
    String? subjectName,
    LessonType? type,
    String? room,
    String? lecturer,
    String? startTime,
    String? endTime,
    int? weekday,
    WeekType? weekType,
    String? profileId,
    String? notes,
    bool? reminderEnabled,
  }) {
    return Lesson(
      id: id,
      subjectName: subjectName ?? this.subjectName,
      type: type ?? this.type,
      room: room ?? this.room,
      lecturer: lecturer ?? this.lecturer,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      weekday: weekday ?? this.weekday,
      weekType: weekType ?? this.weekType,
      profileId: profileId ?? this.profileId,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}
