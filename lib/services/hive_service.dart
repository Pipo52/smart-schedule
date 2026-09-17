import 'package:hive_ce_flutter/hive_flutter.dart';

import '../hive_registrar.g.dart';
import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/lesson.dart';
import '../models/schedule_exception.dart';
import '../models/schedule_profile.dart';
import '../models/semester_period.dart';
import '../models/task.dart';
import 'week_calculator.dart';

/// Central place that owns Hive initialization, adapter registration and box
/// access. Kept as a thin static facade so providers/services can reach the
/// data without threading a repository object through every constructor.
class HiveService {
  HiveService._();

  static const String lessonsBoxName = 'lessons';
  static const String tasksBoxName = 'tasks';
  static const String examsBoxName = 'exams';
  static const String settingsBoxName = 'settings';
  static const String profilesBoxName = 'profiles';
  static const String periodsBoxName = 'semester_periods';
  static const String exceptionsBoxName = 'schedule_exceptions';
  static const String settingsKey = 'app_settings';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();
    Hive.registerAdapters();

    await Future.wait([
      Hive.openBox<Lesson>(lessonsBoxName),
      Hive.openBox<Task>(tasksBoxName),
      Hive.openBox<Exam>(examsBoxName),
      Hive.openBox<AppSettings>(settingsBoxName),
      Hive.openBox<ScheduleProfile>(profilesBoxName),
      Hive.openBox<SemesterPeriod>(periodsBoxName),
      Hive.openBox<ScheduleException>(exceptionsBoxName),
    ]);

    _initialized = true;
  }

  static Box<Lesson> get lessonsBox => Hive.box<Lesson>(lessonsBoxName);
  static Box<Task> get tasksBox => Hive.box<Task>(tasksBoxName);
  static Box<Exam> get examsBox => Hive.box<Exam>(examsBoxName);
  static Box<AppSettings> get settingsBox =>
      Hive.box<AppSettings>(settingsBoxName);
  static Box<ScheduleProfile> get profilesBox =>
      Hive.box<ScheduleProfile>(profilesBoxName);
  static Box<SemesterPeriod> get periodsBox =>
      Hive.box<SemesterPeriod>(periodsBoxName);
  static Box<ScheduleException> get exceptionsBox =>
      Hive.box<ScheduleException>(exceptionsBoxName);

  static Future<void> ensureDefaultProfile() async {
    final box = profilesBox;
    if (box.isEmpty) {
      final profile = ScheduleProfile(
        id: 'default',
        name: 'My Schedule',
        createdAt: DateTime.now(),
        isDefault: true,
      );
      await box.put(profile.id, profile);
    }
  }

  /// Loads the single settings object, creating one with sensible defaults
  /// on first launch.
  static AppSettings loadOrCreateSettings() {
    final box = settingsBox;
    final existing = box.get(settingsKey);
    if (existing != null) {
      if (existing.schemaVersion < 2) {
        // Schema v2 removes the plaintext Gemini key. Saving through the new
        // adapter rewrites this Hive record without the former field.
        existing.schemaVersion = 2;
        existing.save();
      }
      return existing;
    }

    final settings = AppSettings(
      semesterReferenceDate: WeekCalculator.defaultReferenceMonday(),
      schemaVersion: 2,
    );
    box.put(settingsKey, settings);
    return settings;
  }

  /// Wipes all user data (lessons/tasks/exams/settings) and recreates
  /// default settings. Used by "reset all data" in the settings screen.
  static Future<void> wipeAllData() async {
    await lessonsBox.clear();
    await tasksBox.clear();
    await examsBox.clear();
    await settingsBox.clear();
    await profilesBox.clear();
    await periodsBox.clear();
    await exceptionsBox.clear();
  }
}
