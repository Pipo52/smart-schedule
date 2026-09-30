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
/// the next [lessonLookaheadOccurrences] matching occurrences rather than a
/// single repeating rule. The same approach is used uniformly for "every
/// week" lessons too, for a single, easy-to-reason-about
/// schedule/cancel code path. Because of this, notifications only cover a
/// rolling window into the future. The app tops the window up on launch and
/// whenever it returns to the foreground.
class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// How many upcoming matching occurrences to schedule per lesson.
  /// About eleven months of a weekly class. Cancelling a lesson removes only
  /// the occurrence numbers this process actually scheduled. The full window
  /// is cleared when those numbers are not known yet, for example after a restart.
  static const int lessonLookaheadOccurrences = 48;

  /// Keeps the total of exact lesson alarms under Android's practical limit
  /// when many lessons have reminders turned on.
  static const int maxPendingLessonAlarms = 400;

  static const Duration reminderWindowWarning = Duration(days: 14);

  DateTime? _earliestCoverageEnd;
  int _occurrencesThisPass = lessonLookaheadOccurrences;
  final Map<String, String> _fingerprints = {};
  final Map<String, List<int>> _scheduledIndices = {};
  final Map<String, DateTime> _coverageByLesson = {};

  DateTime? get coverageEndsAt {
    if (_coverageByLesson.isEmpty) return _earliestCoverageEnd;
    DateTime? earliest;
    for (final end in _coverageByLesson.values) {
      if (earliest == null || end.isBefore(earliest)) earliest = end;
    }
    return earliest;
  }

  int get occurrencesThisPass => _occurrencesThisPass;

  /// True when the soonest scheduled lesson reminder window ends within
  /// [reminderWindowWarning]. Opening the app reschedules and pushes this out.
  bool get reminderWindowEndingSoon {
    final ends = coverageEndsAt;
    if (ends == null) return false;
    final remaining = ends.difference(DateTime.now());
    return !remaining.isNegative && remaining < reminderWindowWarning;
  }

  /// Splits [maxPendingLessonAlarms] across lessons that have reminders.
  void beginSchedulingPass(int remindingLessons) {
    if (remindingLessons <= 0) {
      _occurrencesThisPass = lessonLookaheadOccurrences;
      return;
    }
    final share = maxPendingLessonAlarms ~/ remindingLessons;
    if (share < 8) {
      _occurrencesThisPass = 8;
    } else if (share > lessonLookaheadOccurrences) {
      _occurrencesThisPass = lessonLookaheadOccurrences;
    } else {
      _occurrencesThisPass = share;
    }
  }

  @visibleForTesting
  void setCoverageEndForTesting(DateTime? ends) {
    _coverageByLesson.clear();
    _earliestCoverageEnd = ends;
  }

  /// Stable description of one lesson's alarms. Unchanged lessons are left
  /// alone while their scheduled coverage still reaches past the warning window.
  static String lessonAlarmKey({
    required Lesson lesson,
    required int reminderMinutes,
    required DateTime referenceMonday,
    int? manualOverride,
    required int occurrences,
  }) {
    return [
      lesson.id,
      lesson.subjectName,
      lesson.room,
      lesson.startTime,
      lesson.endTime,
      lesson.weekday,
      lesson.weekType.index,
      lesson.reminderEnabled,
      reminderMinutes,
      referenceMonday.toIso8601String(),
      manualOverride ?? '',
      occurrences,
    ].join('|');
  }

  bool _coverageFresh(String lessonId) {
    final end = _coverageByLesson[lessonId];
    if (end == null) return false;
    return end.isAfter(DateTime.now().add(reminderWindowWarning));
  }

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
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Fall back to UTC if the platform timezone lookup fails; scheduling
      // will still work, just not necessarily aligned to local wall time.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');

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
    if (kIsWeb) return;
    final fingerprint = lessonAlarmKey(
      lesson: lesson,
      reminderMinutes: reminderMinutes,
      referenceMonday: referenceMonday,
      manualOverride: manualOverride,
      occurrences: _occurrencesThisPass,
    );
    final remindersOff = !lesson.reminderEnabled || reminderMinutes <= 0;
    if (_fingerprints[lesson.id] == fingerprint &&
        (remindersOff || _coverageFresh(lesson.id))) {
      return;
    }
    await cancelLessonNotifications(lesson.id);
    if (remindersOff) {
      _fingerprints[lesson.id] = fingerprint;
      return;
    }

    final occurrences = _nextOccurrenceDates(
      lesson,
      referenceMonday: referenceMonday,
      manualOverride: manualOverride,
      maxOccurrences: _occurrencesThisPass,
    );

    final now = DateTime.now();
    DateTime? lastFire;
    final scheduled = <int>[];
    for (var i = 0; i < occurrences.length; i++) {
      final day = occurrences[i];
      final fireAt = DateTime(
        day.year,
        day.month,
        day.day,
      ).add(Duration(minutes: lesson.startMinutes - reminderMinutes));
      if (!fireAt.isAfter(now)) continue;
      if (lastFire == null || fireAt.isAfter(lastFire)) {
        lastFire = fireAt;
      }
      scheduled.add(i);

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
    _scheduledIndices[lesson.id] = scheduled;
    _fingerprints[lesson.id] = fingerprint;
    _noteCoverage(lesson.id, lastFire);
  }

  void _noteCoverage(String lessonId, DateTime? lastFire) {
    if (lastFire == null) {
      _coverageByLesson.remove(lessonId);
    } else {
      _coverageByLesson[lessonId] = lastFire;
    }
    DateTime? earliest;
    for (final end in _coverageByLesson.values) {
      if (earliest == null || end.isBefore(earliest)) earliest = end;
    }
    _earliestCoverageEnd = earliest;
  }

  Future<void> cancelLessonNotifications(String lessonId) async {
    if (kIsWeb) return;
    final indices = _scheduledIndices.remove(lessonId);
    _coverageByLesson.remove(lessonId);
    _fingerprints.remove(lessonId);
    DateTime? earliest;
    for (final end in _coverageByLesson.values) {
      if (earliest == null || end.isBefore(earliest)) earliest = end;
    }
    _earliestCoverageEnd = earliest;
    final toCancel =
        indices ??
        List<int>.generate(lessonLookaheadOccurrences, (index) => index);
    for (final index in toCancel) {
      await _plugin.cancel(id: _stableId('lesson:$lessonId:$index'));
    }
  }

  // ---------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------

  Future<void> scheduleTaskNotification(Task task) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    await _plugin.cancel(id: _stableId('task:$taskId'));
  }

  // ---------------------------------------------------------------------
  // Exams
  // ---------------------------------------------------------------------

  Future<void> scheduleExamNotifications(Exam exam) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    await _plugin.cancel(id: _stableId('exam:$examId:day'));
    await _plugin.cancel(id: _stableId('exam:$examId:hour'));
  }
}
