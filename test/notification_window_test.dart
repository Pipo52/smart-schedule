import 'package:flutter_test/flutter_test.dart';
import 'package:smart_schedule/models/lesson.dart';
import 'package:smart_schedule/services/notification_service.dart';

void main() {
  final service = NotificationService.instance;

  tearDown(() {
    service.beginSchedulingPass(0);
    service.setCoverageEndForTesting(null);
  });

  test('lookahead stays at 48 and a small schedule uses the full window', () {
    expect(NotificationService.lessonLookaheadOccurrences, 48);
    service.beginSchedulingPass(2);
    expect(service.occurrencesThisPass, 48);
  });

  test('many reminding lessons share the alarm budget', () {
    service.beginSchedulingPass(20);
    expect(service.occurrencesThisPass, 20);
    service.beginSchedulingPass(100);
    expect(service.occurrencesThisPass, 8);
  });

  test('settings warning appears only when coverage ends within 14 days', () {
    service.setCoverageEndForTesting(
      DateTime.now().add(const Duration(days: 3)),
    );
    expect(service.reminderWindowEndingSoon, isTrue);

    service.setCoverageEndForTesting(
      DateTime.now().add(const Duration(days: 40)),
    );
    expect(service.reminderWindowEndingSoon, isFalse);

    service.setCoverageEndForTesting(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(service.reminderWindowEndingSoon, isFalse);
  });

  test('Lesson alarm fingerprint changes only when the alarm would', () {
    final monday = DateTime.utc(2026, 9, 1);
    final lesson = Lesson(
      id: 'L1',
      subjectName: 'Algebra',
      type: LessonType.lecture,
      room: '101',
      lecturer: 'Ada',
      startTime: '09:00',
      endTime: '10:20',
      weekday: 1,
      weekType: WeekType.every,
      profileId: 'default',
    );
    final first = NotificationService.lessonAlarmKey(
      lesson: lesson,
      reminderMinutes: 10,
      referenceMonday: monday,
      manualOverride: null,
      occurrences: 48,
    );
    expect(
      NotificationService.lessonAlarmKey(
        lesson: lesson,
        reminderMinutes: 10,
        referenceMonday: monday,
        manualOverride: null,
        occurrences: 48,
      ),
      first,
    );
    expect(
      NotificationService.lessonAlarmKey(
        lesson: lesson,
        reminderMinutes: 15,
        referenceMonday: monday,
        manualOverride: null,
        occurrences: 48,
      ),
      isNot(first),
    );
  });
}
