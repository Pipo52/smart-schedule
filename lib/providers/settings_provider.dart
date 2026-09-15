import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/hive_service.dart';
import '../services/week_calculator.dart';

/// Exposes [AppSettings] as observable state, and derives the current
/// Week 1 / Week 2 rotation, [Locale] and [ThemeMode] from it.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() : _settings = HiveService.loadOrCreateSettings();

  AppSettings _settings;
  AppSettings get settings => _settings;

  int get currentWeek => WeekCalculator.currentWeek(
    referenceMonday: _settings.semesterReferenceDate,
    manualOverride: _settings.manualWeekOverride,
  );

  /// `null` means "follow system locale".
  Locale? get locale =>
      _settings.appLocale != null ? Locale(_settings.appLocale!) : null;

  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> _persist() async {
    await _settings.save();
    notifyListeners();
  }

  Future<void> setManualWeekOverride(int? week) async {
    assert(week == null || week == 1 || week == 2);
    _settings.manualWeekOverride = week;
    await _persist();
  }

  /// Sets the reference date directly to the Monday of the week containing
  /// [date] (any weekday within the target week can be passed in).
  Future<void> setSemesterReferenceDate(DateTime date) async {
    _settings.semesterReferenceDate = WeekCalculator.mondayOfWeekContaining(
      date,
    );
    await _persist();
  }

  Future<void> setDefaultLessonReminderMinutes(int minutes) async {
    _settings.defaultLessonReminderMinutes = minutes;
    await _persist();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _settings.themeMode = mode;
    await _persist();
  }

  /// [code] must be one of 'en' / 'uk' / 'ru', or `null` for "system".
  Future<void> setAppLocale(String? code) async {
    _settings.appLocale = code;
    await _persist();
  }

  /// Wipes all data and resets settings to defaults.
  Future<void> resetAllData() async {
    await HiveService.wipeAllData();
    _settings = HiveService.loadOrCreateSettings();
    notifyListeners();
  }

  /// Re-reads settings from the box (used right after an import).
  void reloadFromBox() {
    _settings = HiveService.loadOrCreateSettings();
    notifyListeners();
  }
}
