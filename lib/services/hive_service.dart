import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/lesson.dart';
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
  static const String settingsKey = 'app_settings';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    Hive.registerAdapter(LessonTypeAdapter());
    Hive.registerAdapter(WeekTypeAdapter());
    Hive.registerAdapter(LessonAdapter());
    Hive.registerAdapter(PriorityAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(ExamTypeAdapter());
    Hive.registerAdapter(ExamAdapter());
    Hive.registerAdapter(AppThemeModeAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    await Future.wait([
      Hive.openBox<Lesson>(lessonsBoxName),
      Hive.openBox<Task>(tasksBoxName),
      Hive.openBox<Exam>(examsBoxName),
      Hive.openBox<AppSettings>(settingsBoxName),
    ]);

    _initialized = true;
  }

  static Box<Lesson> get lessonsBox => Hive.box<Lesson>(lessonsBoxName);
  static Box<Task> get tasksBox => Hive.box<Task>(tasksBoxName);
  static Box<Exam> get examsBox => Hive.box<Exam>(examsBoxName);
  static Box<AppSettings> get settingsBox =>
      Hive.box<AppSettings>(settingsBoxName);

  /// Loads the single settings object, creating one with sensible defaults
  /// on first launch.
  static AppSettings loadOrCreateSettings() {
    final box = settingsBox;
    final existing = box.get(settingsKey);
    if (existing != null) return existing;

    final settings = AppSettings(
      semesterReferenceDate: WeekCalculator.defaultReferenceMonday(),
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
  }
}
