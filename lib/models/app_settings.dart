import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 8)
enum AppThemeMode {
  @HiveField(0)
  system,
  @HiveField(1)
  light,
  @HiveField(2)
  dark,
}

/// Single Hive object (box "settings", one entry) holding all app-wide
/// preferences.
@HiveType(typeId: 7)
class AppSettings extends HiveObject {
  AppSettings({
    required this.semesterReferenceDate,
    this.manualWeekOverride,
    this.defaultLessonReminderMinutes = 10,
    this.themeMode = AppThemeMode.system,
    this.appLocale,
  });

  /// Monday of the week containing September 1st of the current academic
  /// year (see `WeekCalculator`).
  @HiveField(0)
  DateTime semesterReferenceDate;

  /// 1 or 2 if the user manually overrides the computed current week
  /// (e.g. the professor shifted the schedule). `null` = use the computed
  /// value.
  @HiveField(1)
  int? manualWeekOverride;

  @HiveField(2)
  int defaultLessonReminderMinutes;

  @HiveField(3)
  AppThemeMode themeMode;

  /// `null` = follow system locale (falls back to English if unsupported).
  /// Otherwise an explicit language code: 'en' / 'uk' / 'ru'.
  @HiveField(4)
  String? appLocale;
}
