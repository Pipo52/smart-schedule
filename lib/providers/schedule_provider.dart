import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../models/lesson.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/week_calculator.dart';
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
  final Box<Lesson> _box = HiveService.lessonsBox;
  List<Lesson> _lessons = <Lesson>[];

  List<Lesson> get lessons => List.unmodifiable(_lessons);

  void _loadLessons() {
    _lessons =
        _box.values.where((lesson) => lesson.profileId == _profileId).toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  }

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
  }

  List<Lesson> lessonsForDay({required int weekday, required int week}) {
    final result = _lessons
        .where(
          (l) =>
              l.weekday == weekday &&
              WeekCalculator.isLessonActiveOnWeek(
                weekType: l.weekType,
                week: week,
              ),
        )
        .toList();
    result.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return result;
  }

  Future<void> saveLesson(Lesson lesson) async {
    lesson.profileId = _profileId;
    await _box.put(lesson.id, lesson);
    _loadLessons();
    notifyListeners();
    await _scheduleFor(lesson);
  }

  Future<void> deleteLesson(String id) async {
    await NotificationService.instance.cancelLessonNotifications(id);
    await _box.delete(id);
    _loadLessons();
    notifyListeners();
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
    for (final lesson in _lessons) {
      await _scheduleFor(lesson);
    }
  }

  /// Re-reads lessons from the box (used right after an import).
  void reloadFromBox() {
    _loadLessons();
    notifyListeners();
  }
}
