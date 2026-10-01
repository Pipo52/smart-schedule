import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_settings.dart';
import '../services/cloud_sync_service.dart';
import '../services/cloud_write_reporter.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../services/sync_clock.dart';
import '../services/week_calculator.dart';

/// Exposes [AppSettings] as observable state, and derives the current
/// Week 1 / Week 2 rotation, [Locale] and [ThemeMode] from it.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() : _settings = HiveService.loadOrCreateSettings() {
    _loadSecrets();
  }

  static const _geminiApiKeyStorageKey =
      CloudSyncService.geminiApiKeyStorageKey;
  static const moodleCalendarUrlKey = 'moodle_calendar_url';
  final _storage = const FlutterSecureStorage();
  AppSettings _settings;
  String? _geminiApiKey;
  String? _moodleCalendarUrl;
  String? _uid;

  AppSettings get settings => _settings;
  String? get geminiApiKey => _geminiApiKey;
  String? get moodleCalendarUrl => _moodleCalendarUrl;
  StartupBehavior get startupBehavior => _settings.startupBehavior;

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
    _settings.updatedAt = SyncClock.now();
    await _settings.save();
    notifyListeners();
    await pushToCloud();
  }

  void updateUid(String? uid) {
    _uid = uid;
  }

  String? get _effectiveUid => _uid ?? FirebaseAuth.instance.currentUser?.uid;

  Future<void> pushToCloud() async {
    final uid = _effectiveUid;
    if (uid == null) return;
    await CloudWriteReporter.instance.guard(
      PendingCloudWrite(PendingCloudWrite.settings, 'app'),
      () => FirestoreService.instance.saveSettings(
        uid,
        _settings,
        geminiApiKey: _geminiApiKey,
      ),
    );
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

  Future<void> setStartupBehavior(StartupBehavior behavior) async {
    _settings.startupBehavior = behavior;
    await _persist();
  }

  /// [code] must be one of 'en' / 'uk' / 'ru', or `null` for "system".
  Future<void> setAppLocale(String? code) async {
    _settings.appLocale = code;
    await _persist();
  }

  Future<void> setGeminiApiKey(String? key) async {
    _geminiApiKey = key;
    notifyListeners();
    if (key == null || key.isEmpty) {
      await _storage.delete(key: _geminiApiKeyStorageKey);
    } else {
      await _storage.write(key: _geminiApiKeyStorageKey, value: key);
    }
    await pushToCloud();
  }

  /// The calendar link contains a secret token, so it stays on this device.
  Future<void> setMoodleCalendarUrl(String? url) async {
    final trimmed = url?.trim();
    _moodleCalendarUrl = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    notifyListeners();
    if (_moodleCalendarUrl == null) {
      await _storage.delete(key: moodleCalendarUrlKey);
    } else {
      await _storage.write(
        key: moodleCalendarUrlKey,
        value: _moodleCalendarUrl,
      );
    }
  }

  /// Wipes all data and resets settings to defaults.
  Future<void> resetAllData() async {
    final uid = _effectiveUid;
    if (uid != null) {
      await FirestoreService.instance.deleteAll(uid);
    }
    await HiveService.wipeAllData();
    await _storage.deleteAll();
    await HiveService.ensureDefaultProfile();
    _settings = HiveService.loadOrCreateSettings();
    _geminiApiKey = null;
    _moodleCalendarUrl = null;
    if (uid != null) {
      await CloudSyncService.instance.rememberOwner(uid);
      await CloudSyncService.instance.recordWipeTimestamp(uid);
      await CloudSyncService.instance.pushLocalToCloud(uid);
    }
    notifyListeners();
  }

  /// Re-reads settings from the box (used right after an import).
  void reloadFromBox() {
    _settings = HiveService.loadOrCreateSettings();
    notifyListeners();
    _loadSecrets();
  }

  void _loadSecrets() {
    _storage
        .read(key: _geminiApiKeyStorageKey)
        .then((value) {
          _geminiApiKey = value;
          notifyListeners();
        })
        .catchError((_) {});
    _storage
        .read(key: moodleCalendarUrlKey)
        .then((value) {
          _moodleCalendarUrl = value;
          notifyListeners();
        })
        .catchError((_) {});
  }
}
