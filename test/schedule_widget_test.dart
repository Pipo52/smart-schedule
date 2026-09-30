import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_schedule/models/lesson.dart';
import 'package:smart_schedule/models/schedule_exception.dart';
import 'package:smart_schedule/services/schedule_widget_data.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  final day = DateTime(2026, 9, 30);
  final from = DateTime(2026, 9, 30, 9);

  Lesson make({
    required String id,
    required String subject,
    String start = '08:30',
    String end = '10:00',
    WeekType weekType = WeekType.every,
    String profileId = 'seminar',
    String room = '101',
  }) {
    return Lesson(
      id: id,
      subjectName: subject,
      type: LessonType.lecture,
      room: room,
      lecturer: '',
      startTime: start,
      endTime: end,
      weekday: day.weekday,
      weekType: weekType,
      profileId: profileId,
    );
  }

  List<WidgetLessonEntry> upcoming({
    required List<Lesson> lessons,
    List<ScheduleException> exceptions = const [],
    int? manualOverride,
    DateTime? at,
    int horizonDays = 1,
  }) {
    return upcomingWidgetLessons(
      lessons: lessons,
      exceptions: exceptions,
      profileId: 'seminar',
      referenceMonday: DateTime(2026, 9, 7),
      manualOverride: manualOverride,
      from: at ?? from,
      localeCode: 'en',
      horizonDays: horizonDays,
    );
  }

  test('shows the class in progress and the one after it', () {
    final entries = upcoming(
      lessons: [
        make(id: 'done', subject: 'Early', start: '07:00', end: '08:00'),
        make(id: 'now', subject: 'Algebra', start: '08:30', end: '10:00'),
        make(
          id: 'later',
          subject: 'Physics',
          start: '12:00',
          end: '13:30',
          room: '202',
        ),
      ],
    );

    expect(entries.map((entry) => entry.subject), ['Algebra', 'Physics']);
    expect(entries.first.room, '101');
    expect(entries.first.timeLabel, '08:30–10:00');
    expect(entries.last.room, '202');

    final weekAhead = upcoming(
      lessons: [
        make(id: 'now', subject: 'Algebra', start: '08:30', end: '10:00'),
      ],
      horizonDays: 8,
    );
    expect(weekAhead.map((entry) => entry.subject), ['Algebra', 'Algebra']);
  });

  test('a one-day cancellation is hidden and an edit changes the room', () {
    final entries = upcoming(
      lessons: [
        make(id: 'gone', subject: 'History'),
        make(id: 'moved', subject: 'Lab', start: '12:00', end: '13:30'),
      ],
      exceptions: [
        ScheduleException(
          id: 'c1',
          lessonId: 'gone',
          date: day,
          type: ExceptionType.cancelled,
          profileId: 'seminar',
        ),
        ScheduleException(
          id: 'm1',
          lessonId: 'moved',
          date: day,
          type: ExceptionType.modified,
          profileId: 'seminar',
          newRoom: 'Lab-4',
          newStartTime: '12:10',
        ),
      ],
    );

    expect(entries, hasLength(1));
    expect(entries.single.subject, 'Lab');
    expect(entries.single.room, 'Lab-4');
    expect(entries.single.timeLabel, '12:10–13:30');
  });

  test('another profile and the other week stay off the widget', () {
    final entries = upcoming(
      lessons: [
        make(id: 'other', subject: 'Other', profileId: 'default'),
        make(id: 'odd', subject: 'Odd week', weekType: WeekType.week2),
      ],
      manualOverride: 1,
    );

    expect(entries, isEmpty);
  });
}
