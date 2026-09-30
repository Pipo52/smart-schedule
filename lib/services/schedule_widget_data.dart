import '../models/lesson.dart';
import '../models/schedule_exception.dart';
import '../utils/weekday_utils.dart';
import 'week_calculator.dart';

/// One concrete class the home-screen widget can show without opening Hive.
class WidgetLessonEntry {
  const WidgetLessonEntry({
    required this.subject,
    required this.room,
    required this.start,
    required this.end,
    required this.timeLabel,
    required this.dateLabel,
  });

  final String subject;
  final String room;
  final DateTime start;
  final DateTime end;
  final String timeLabel;
  final String dateLabel;

  Map<String, Object> toJson() => {
    'subject': subject,
    'room': room,
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'time': timeLabel,
    'date': dateLabel,
  };
}

/// Classes for [profileId] from [from] through the next [horizonDays],
/// skipping cancellations and applying one-day edits.
List<WidgetLessonEntry> upcomingWidgetLessons({
  required Iterable<Lesson> lessons,
  required Iterable<ScheduleException> exceptions,
  required String profileId,
  required DateTime referenceMonday,
  int? manualOverride,
  required DateTime from,
  required String localeCode,
  int horizonDays = 8,
}) {
  final startDay = DateTime(from.year, from.month, from.day);
  final profileLessons = lessons.where(
    (lesson) => lesson.profileId == profileId,
  );
  final result = <WidgetLessonEntry>[];

  for (var offset = 0; offset < horizonDays && result.length < 16; offset++) {
    final day = startDay.add(Duration(days: offset));
    if (day.weekday == DateTime.sunday) continue;
    final week = WeekCalculator.currentWeek(
      referenceMonday: referenceMonday,
      manualOverride: manualOverride,
      today: day,
    );
    final dayLessons = profileLessons.where((lesson) {
      return lesson.weekday == day.weekday &&
          WeekCalculator.isLessonActiveOnWeek(
            weekType: lesson.weekType,
            week: week,
          );
    }).toList()..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    for (final lesson in dayLessons) {
      if (result.length >= 16) break;
      if (_isCancelled(exceptions, lesson.id, day, profileId)) continue;
      final edit = _modification(exceptions, lesson.id, day, profileId);
      final startTime = edit?.newStartTime ?? lesson.startTime;
      final endTime = edit?.newEndTime ?? lesson.endTime;
      final room = edit?.newRoom ?? lesson.room;
      final start = _onDay(day, startTime);
      final end = _onDay(day, endTime);
      if (!end.isAfter(from)) continue;
      final weekday = localizedWeekdayName(
        day.weekday,
        localeCode,
        abbreviated: true,
      );
      result.add(
        WidgetLessonEntry(
          subject: lesson.subjectName,
          room: room,
          start: start,
          end: end,
          timeLabel: '$startTime–$endTime',
          dateLabel: '$weekday, ${day.day}.${day.month}',
        ),
      );
    }
  }
  return result;
}

bool _isCancelled(
  Iterable<ScheduleException> exceptions,
  String lessonId,
  DateTime day,
  String profileId,
) {
  for (final exception in exceptions) {
    if (exception.type != ExceptionType.cancelled) continue;
    if (!_matches(exception, lessonId, day, profileId)) continue;
    return true;
  }
  return false;
}

ScheduleException? _modification(
  Iterable<ScheduleException> exceptions,
  String lessonId,
  DateTime day,
  String profileId,
) {
  ScheduleException? match;
  for (final exception in exceptions) {
    if (exception.type != ExceptionType.modified) continue;
    if (!_matches(exception, lessonId, day, profileId)) continue;
    match = exception;
  }
  return match;
}

bool _matches(
  ScheduleException exception,
  String lessonId,
  DateTime day,
  String profileId,
) {
  return exception.profileId == profileId &&
      exception.lessonId == lessonId &&
      exception.date.year == day.year &&
      exception.date.month == day.month &&
      exception.date.day == day.day;
}

DateTime _onDay(DateTime day, String hhmm) {
  final parts = hhmm.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(day.year, day.month, day.day, hour, minute);
}
