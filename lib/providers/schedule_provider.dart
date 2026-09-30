import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../models/lesson.dart';
import '../services/cloud_write_reporter.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/schedule_widget_service.dart';
import '../services/sync_clock.dart';
import 'settings_provider.dart';

/// Owns the `Lesson` collection: CRUD + (re)scheduling notifications
/// whenever a lesson or the relevant settings (reference date, manual
/// override, default reminder minutes) change.
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider({
    required SettingsProvider settings,
    required String profileId,
  }) : _settings = settings,
       _profileId = profileId {
    _loadLessons();
  }

  SettingsProvider _settings;
  String _profileId;
  String? _uid;
  final Box<Lesson> _box = HiveService.lessonsBox;
  List<Lesson> _lessons = <Lesson>[];
  List<Lesson> _lessonsView = const [];
  String? _notificationSetKey;

  /// weekday 1..6 → week 1/2 buckets, already sorted by start time.
  List<List<List<Lesson>>> _lessonsForDay = _emptyDayBuckets();

  List<Lesson> get lessons => _lessonsView;

  static List<List<List<Lesson>>> _emptyDayBuckets() =>
      List<List<List<Lesson>>>.generate(
        7,
        (_) => <List<Lesson>>[const [], const []],
      );

  void _loadLessons() {
    _lessons =
        _box.values.where((lesson) => lesson.profileId == _profileId).toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    _lessonsView = List.unmodifiable(_lessons);
    _rebuildDayBuckets();
  }

  void _rebuildDayBuckets() {
    final buckets = List<List<List<Lesson>>>.generate(
      7,
      (_) => <List<Lesson>>[<Lesson>[], <Lesson>[]],
    );
    for (final lesson in _lessons) {
      final weekday = lesson.weekday;
      if (weekday < 1 || weekday > 6) continue;
      if (lesson.weekType != WeekType.week2) {
        buckets[weekday][0].add(lesson);
      }
      if (lesson.weekType != WeekType.week1) {
        buckets[weekday][1].add(lesson);
      }
    }
    for (var weekday = 1; weekday <= 6; weekday++) {
      buckets[weekday][0] = List.unmodifiable(buckets[weekday][0]);
      buckets[weekday][1] = List.unmodifiable(buckets[weekday][1]);
    }
    _lessonsForDay = buckets;
    unawaited(ScheduleWidgetService.refresh(_profileId));
  }

  String get profileId => _profileId;

  void updateUid(String? uid) {
    _uid = uid;
  }

  String? get _effectiveUid => _uid ?? FirebaseAuth.instance.currentUser?.uid;

  void updateProfileId(String id) {
    if (_profileId == id) return;
    _profileId = id;
    _loadLessons();
    notifyListeners();
  }

  /// Called by the `ChangeNotifierProxyProvider` in main.dart whenever
  /// `SettingsProvider` changes. Reschedules all notifications if anything
  /// relevant to scheduling changed.
  void updateSettings(SettingsProvider settings) {
    final old = _settings.settings;
    final next = settings.settings;
    final relevantChange =
        old.semesterReferenceDate != next.semesterReferenceDate ||
        old.manualWeekOverride != next.manualWeekOverride ||
        old.defaultLessonReminderMinutes != next.defaultLessonReminderMinutes;
    _settings = settings;
    if (relevantChange) {
      rescheduleAllNotifications();
    }
    unawaited(ScheduleWidgetService.refresh(_profileId));
  }

  List<Lesson> lessonsForDay({required int weekday, required int week}) {
    if (weekday < 1 || weekday > 6 || week < 1 || week > 2) {
      return const [];
    }
    return _lessonsForDay[weekday][week - 1];
  }

  Future<void> saveLesson(Lesson lesson) async {
    lesson.profileId = _profileId;
    lesson.updatedAt = SyncClock.now();
    await _box.put(lesson.id, lesson);
    _loadLessons();
    notifyListeners();
    await _scheduleFor(lesson);
    final uid = _effectiveUid;
    if (uid != null) {
      try {
        await FirestoreService.instance.saveLesson(uid, lesson);
      } catch (e) {
        CloudWriteReporter.instance.report(e);
      }
    }
  }

  /// Import always lands in the open profile, even if the parser tagged
  /// lessons as `default`.
  @visibleForTesting
  static void stampImportedLessons(
    List<Lesson> lessons, {
    required String profileId,
    required DateTime updatedAt,
  }) {
    for (final lesson in lessons) {
      lesson.profileId = profileId;
      lesson.updatedAt = updatedAt;
    }
  }

  Future<void> saveLessons(List<Lesson> lessons) async {
    if (lessons.isEmpty) return;
    final now = SyncClock.now();
    stampImportedLessons(lessons, profileId: _profileId, updatedAt: now);
    final entries = <String, Lesson>{
      for (final lesson in lessons) lesson.id: lesson,
    };
    await _box.putAll(entries);
    _loadLessons();
    notifyListeners();
    for (final lesson in lessons) {
      await _scheduleFor(lesson);
    }
    final uid = _effectiveUid;
    if (uid != null) {
      for (final lesson in lessons) {
        try {
          await FirestoreService.instance.saveLesson(uid, lesson);
        } catch (e) {
          CloudWriteReporter.instance.report(e);
        }
      }
    }
  }

  Future<void> deleteLesson(String id) async {
    await NotificationService.instance.cancelLessonNotifications(id);
    final exceptionIds = HiveService.exceptionsBox.values
        .where((exception) => exception.lessonId == id)
        .map((exception) => exception.id)
        .toList();
    await HiveService.exceptionsBox.deleteAll(exceptionIds);
    await _box.delete(id);
    _loadLessons();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      try {
        await FirestoreService.instance.deleteLesson(uid, id);
      } catch (e) {
        CloudWriteReporter.instance.report(e);
      }
      for (final exceptionId in exceptionIds) {
        try {
          await FirestoreService.instance.deleteException(uid, exceptionId);
        } catch (e) {
          CloudWriteReporter.instance.report(e);
        }
      }
    }
  }

  Future<void> _scheduleFor(Lesson lesson) {
    return NotificationService.instance.scheduleLessonNotifications(
      lesson,
      reminderMinutes: _settings.settings.defaultLessonReminderMinutes,
      referenceMonday: _settings.settings.semesterReferenceDate,
      manualOverride: _settings.settings.manualWeekOverride,
    );
  }

  Future<void> rescheduleAllNotifications() async {
    final reminding = _lessons.where((lesson) => lesson.reminderEnabled).length;
    NotificationService.instance.beginSchedulingPass(reminding);
    for (final lesson in _lessons) {
      await _scheduleFor(lesson);
    }
    _notificationSetKey = _notificationSetKeyNow();
  }

  String _notificationSetKeyNow() {
    final settings = _settings.settings;
    final reminding = _lessons.where((lesson) => lesson.reminderEnabled).length;
    final parts = [
      for (final lesson in _lessons)
        NotificationService.lessonAlarmKey(
          lesson: lesson,
          reminderMinutes: settings.defaultLessonReminderMinutes,
          referenceMonday: settings.semesterReferenceDate,
          manualOverride: settings.manualWeekOverride,
          occurrences: reminding,
        ),
    ]..sort();
    return parts.join('\n');
  }

  /// Re-reads lessons from the box (used right after an import or cloud sync).
  void reloadFromBox() {
    _loadLessons();
    notifyListeners();
    if (_notificationSetKeyNow() == _notificationSetKey) return;
    unawaited(rescheduleAllNotifications());
  }
}
