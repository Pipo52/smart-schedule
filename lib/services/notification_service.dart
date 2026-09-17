import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/exam.dart';
import '../models/lesson.dart';
import '../models/task.dart' show Task;
import 'week_calculator.dart';

/// Wraps `flutter_local_notifications` and encapsulates all scheduling
/// decisions (ids, look-ahead windows, cancellation) for lessons, tasks and
/// exams.
///
/// Design note: `flutter_local_notifications` has no built-in concept of a
/// "every other week" recurrence, so bi-weekly (Week 1 / Week 2 only)
/// lessons are scheduled as a batch of individual one-off notifications for
/// the next [_lessonLookaheadOccurrences] matching occurrences rather than a
/// single repeating rule. The same approach is used uniformly for "every
/// week" lessons too, for a single, easy-to-reason-about
/// schedule/cancel code path. Because of this, notifications only cover a
/// rolling window into the future - call [rescheduleAll] periodically (the
/// app does so on every launch, see `ScheduleProvider`) to keep the window
/// topped up.
class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// How many upcoming matching occurrences to schedule per lesson.
  static const int lessonLookaheadOccurrences = 24;

  static const AndroidNotificationDetails _androidLessonDetails =
      AndroidNotificationDetails(
        'lessons_channel',
        'Lessons',
        channelDescription: 'Reminders about upcoming lessons',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const AndroidNotificationDetails _androidTaskDetails =
      AndroidNotificationDetails(
        'tasks_channel',
        'Tasks',
        channelDescription: 'Reminders about task deadlines',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const AndroidNotificationDetails _androidExamDetails =
      AndroidNotificationDetails(
        'exams_channel',
        'Exams',
        channelDescription: 'Reminders about upcoming exams',
        importance: Importance.max,
        priority: Priority.high,
      );

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Fall back to UTC if the platform timezone lookup fails; scheduling
      // will still work, just not necessarily aligned to local wall time.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
    );

    _initialized = true;
  }

  /// Requests POST_NOTIFICATIONS (Android 13+) and exact-alarm permission
  /// (Android 12+). Safe to call multiple times.
  Future<void> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  /// Deterministic, well-distributed 31-bit positive id derived from an
  /// arbitrary string key, so lesson occurrences / tasks / exams never share
  /// notification ids while remaining trivially reproducible for
  /// cancellation (no need to persist ids anywhere else).
  int _stableId(String key) {
    var hash = 0x811c9dc5; // FNV-1a offset basis
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff; // FNV prime, keep 31 bits
    }
    return hash;
  }

  // ---------------------------------------------------------------------
  // Lessons
  // ---------------------------------------------------------------------

  List<DateTime> _nextOccurrenceDates(
    Lesson lesson, {
    required DateTime referenceMonday,
    int? manualOverride,
    required int maxOccurrences,
    DateTime? from,
  }) {
    final start = from ?? DateTime.now();
    var cursor = DateTime(start.year, start.month, start.day);
    final result = <DateTime>[];

    // Safety bound: at most ~2 years of scanning even in pathological cases.
    var daysScanned = 0;
    while (result.length < maxOccurrences && daysScanned < 730) {
      if (cursor.weekday == lesson.weekday) {
        final week = WeekCalculator.currentWeek(
          referenceMonday: referenceMonday,
          manualOverride: manualOverride,
          today: cursor,
        );
        if (WeekCalculator.isLessonActiveOnWeek(
          weekType: lesson.weekType,
          week: week,
        )) {
          result.add(cursor);
        }
      }
      cursor = cursor.add(const Duration(days: 1));
      daysScanned++;
    }
    return result;
  }

  Future<void> scheduleLessonNotifications(
    Lesson lesson, {
    required int reminderMinutes,
    required DateTime referenceMonday,
    int? manualOverride,
  }) async {
    await cancelLessonNotifications(lesson.id);
    if (!lesson.reminderEnabled || reminderMinutes <= 0) return;

    final occurrences = _nextOccurrenceDates(
      lesson,
      referenceMonday: referenceMonday,
      manualOverride: manualOverride,
      maxOccurrences: lessonLookaheadOccurrences,
    );

    final now = DateTime.now();
    for (var i = 0; i < occurrences.length; i++) {
      final day = occurrences[i];
      final fireAt = DateTime(
        day.year,
        day.month,
        day.day,
      ).add(Duration(minutes: lesson.startMinutes - reminderMinutes));
      if (!fireAt.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _stableId('lesson:${lesson.id}:$i'),
        title: lesson.subjectName,
        body:
            '${lesson.room.isNotEmpty ? '${lesson.room} • ' : ''}'
            '${lesson.startTime}-${lesson.endTime}',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: _androidLessonDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelLessonNotifications(String lessonId) async {
    for (var i = 0; i < lessonLookaheadOccurrences; i++) {
      await _plugin.cancel(id: _stableId('lesson:$lessonId:$i'));
    }
  }

  // ---------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------

  Future<void> scheduleTaskNotification(Task task) async {
    await cancelTaskNotification(task.id);
    final offset = task.reminderOffsetMinutes;
    if (offset == null || task.isDone) return;

    final fireAt = task.dueDate.subtract(Duration(minutes: offset));
    if (!fireAt.isAfter(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: _stableId('task:${task.id}'),
      title: task.title,
      body: task.linkedSubject == null || task.linkedSubject!.isEmpty
          ? 'Due soon'
          : task.linkedSubject!,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: _androidTaskDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskNotification(String taskId) async {
    await _plugin.cancel(id: _stableId('task:$taskId'));
  }

  // ---------------------------------------------------------------------
  // Exams
  // ---------------------------------------------------------------------

  Future<void> scheduleExamNotifications(Exam exam) async {
    await cancelExamNotifications(exam.id);
    final now = DateTime.now();

    final dayBefore = exam.date.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: _stableId('exam:${exam.id}:day'),
        title: exam.subjectName,
        body:
            'Exam tomorrow'
            '${exam.room != null && exam.room!.isNotEmpty ? ' • ${exam.room}' : ''}',
        scheduledDate: tz.TZDateTime.from(dayBefore, tz.local),
        notificationDetails: const NotificationDetails(
          android: _androidExamDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    final hourBefore = exam.date.subtract(const Duration(hours: 1));
    if (hourBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: _stableId('exam:${exam.id}:hour'),
        title: exam.subjectName,
        body:
            'Exam in 1 hour'
            '${exam.room != null && exam.room!.isNotEmpty ? ' • ${exam.room}' : ''}',
        scheduledDate: tz.TZDateTime.from(hourBefore, tz.local),
        notificationDetails: const NotificationDetails(
          android: _androidExamDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelExamNotifications(String examId) async {
    await _plugin.cancel(id: _stableId('exam:$examId:day'));
    await _plugin.cancel(id: _stableId('exam:$examId:hour'));
  }
}
