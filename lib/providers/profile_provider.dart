import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/schedule_profile.dart';
import '../services/cloud_write_reporter.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../services/sync_clock.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required SettingsProvider settings})
    : _settings = settings,
      _activeProfileId = _resolveInitialProfileId(settings) {
    _load();
  }

  static const Uuid _uuid = Uuid();

  final SettingsProvider _settings;
  final Box<ScheduleProfile> _box = HiveService.profilesBox;
  List<ScheduleProfile> _cachedProfiles = [];
  String _activeProfileId;
  String? _uid;

  List<ScheduleProfile> get profiles => _cachedProfiles;

  String get activeProfileId => _activeProfileId;

  ScheduleProfile? get activeProfile => _box.get(_activeProfileId);

  void _load() {
    _cachedProfiles = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void reloadFromBox() {
    _load();
    if (!_box.containsKey(_activeProfileId)) {
      _activeProfileId = _resolveInitialProfileId(_settings);
    }
    notifyListeners();
  }

  void updateUid(String? uid) {
    _uid = uid;
  }

  String? get _effectiveUid => _uid ?? FirebaseAuth.instance.currentUser?.uid;

  void updateSettings(SettingsProvider settings) {
    if (_box.containsKey(_activeProfileId)) return;
    _activeProfileId = _resolveInitialProfileId(settings);
    notifyListeners();
  }

  static String _resolveInitialProfileId(SettingsProvider settings) {
    final profiles = HiveService.profilesBox.values.toList();
    if (profiles.isEmpty) {
      throw StateError('No schedule profiles are available.');
    }

    final appSettings = settings.settings;
    ScheduleProfile? selected;
    if (appSettings.startupBehavior == StartupBehavior.lastOpened) {
      final lastOpenedId = appSettings.lastOpenedProfileId;
      if (lastOpenedId != null) {
        selected = HiveService.profilesBox.get(lastOpenedId);
      }
    }

    selected ??= _firstDefault(profiles);
    return selected?.id ?? profiles.first.id;
  }

  static ScheduleProfile? _firstDefault(Iterable<ScheduleProfile> profiles) {
    for (final profile in profiles) {
      if (profile.isDefault) return profile;
    }
    return null;
  }

  Future<void> switchProfile(String profileId) async {
    if (!_box.containsKey(profileId)) {
      throw ArgumentError.value(profileId, 'profileId', 'Unknown profile');
    }
    final changed = _activeProfileId != profileId;
    _activeProfileId = profileId;
    _settings.settings.lastOpenedProfileId = profileId;
    await _settings.settings.save();
    await _settings.pushToCloud();
    if (changed) notifyListeners();
  }

  Future<ScheduleProfile> createProfile(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name cannot be empty');
    }

    final profile = ScheduleProfile(
      id: _uuid.v4(),
      name: trimmedName,
      createdAt: DateTime.now(),
      isDefault: false,
      updatedAt: SyncClock.now(),
    );
    await _box.put(profile.id, profile);
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      await CloudWriteReporter.instance.guard(
        PendingCloudWrite(PendingCloudWrite.profile, profile.id),
        () => FirestoreService.instance.saveProfile(uid, profile),
      );
    }
    return profile;
  }

  Future<void> renameProfile(String id, String newName) async {
    final profile = _box.get(id);
    if (profile == null) {
      throw ArgumentError.value(id, 'id', 'Unknown profile');
    }
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(
        newName,
        'newName',
        'Profile name cannot be empty',
      );
    }

    profile.name = trimmedName;
    profile.updatedAt = SyncClock.now();
    await profile.save();
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      await CloudWriteReporter.instance.guard(
        PendingCloudWrite(PendingCloudWrite.profile, profile.id),
        () => FirestoreService.instance.saveProfile(uid, profile),
      );
    }
  }

  Future<void> deleteProfile(String id) async {
    final currentProfiles = profiles;
    if (currentProfiles.length <= 1) {
      throw StateError('The last schedule profile cannot be deleted.');
    }

    final profile = _box.get(id);
    if (profile == null) {
      throw ArgumentError.value(id, 'id', 'Unknown profile');
    }

    final replacement = currentProfiles.firstWhere((item) => item.id != id);

    final lessons = HiveService.lessonsBox.values
        .where((lesson) => lesson.profileId == id)
        .toList();
    final tasks = HiveService.tasksBox.values
        .where((task) => task.profileId == id)
        .toList();
    final exams = HiveService.examsBox.values
        .where((exam) => exam.profileId == id)
        .toList();

    for (final lesson in lessons) {
      await NotificationService.instance.cancelLessonNotifications(lesson.id);
    }
    for (final task in tasks) {
      await NotificationService.instance.cancelTaskNotification(task.id);
    }
    for (final exam in exams) {
      await NotificationService.instance.cancelExamNotifications(exam.id);
    }

    await HiveService.lessonsBox.deleteAll(lessons.map((item) => item.id));
    await HiveService.tasksBox.deleteAll(tasks.map((item) => item.id));
    await HiveService.examsBox.deleteAll(exams.map((item) => item.id));

    final exceptions = HiveService.exceptionsBox.values
        .where((item) => item.profileId == id)
        .toList();
    final periods = HiveService.periodsBox.values
        .where((item) => item.profileId == id)
        .toList();
    await HiveService.exceptionsBox.deleteAll(
      exceptions.map((item) => item.id),
    );
    await HiveService.periodsBox.deleteAll(periods.map((item) => item.id));

    await _box.delete(id);

    if (profile.isDefault) {
      replacement.isDefault = true;
      await replacement.save();
    }
    if (_activeProfileId == id) {
      _activeProfileId = replacement.id;
      _settings.settings.lastOpenedProfileId = replacement.id;
      await _settings.settings.save();
      await _settings.pushToCloud();
    }

    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      await CloudWriteReporter.instance.guard(
        PendingCloudWrite(PendingCloudWrite.profile, id, delete: true),
        () => FirestoreService.instance.deleteProfile(uid, id),
      );
      for (final lesson in lessons) {
        await CloudWriteReporter.instance.guard(
          PendingCloudWrite(PendingCloudWrite.lesson, lesson.id, delete: true),
          () => FirestoreService.instance.deleteLesson(uid, lesson.id),
        );
      }
      for (final task in tasks) {
        await CloudWriteReporter.instance.guard(
          PendingCloudWrite(PendingCloudWrite.task, task.id, delete: true),
          () => FirestoreService.instance.deleteTask(uid, task.id),
        );
      }
      for (final exam in exams) {
        await CloudWriteReporter.instance.guard(
          PendingCloudWrite(PendingCloudWrite.exam, exam.id, delete: true),
          () => FirestoreService.instance.deleteExam(uid, exam.id),
        );
      }
      for (final exception in exceptions) {
        await CloudWriteReporter.instance.guard(
          PendingCloudWrite(
            PendingCloudWrite.exception,
            exception.id,
            delete: true,
          ),
          () => FirestoreService.instance.deleteException(uid, exception.id),
        );
      }
      for (final period in periods) {
        await CloudWriteReporter.instance.guard(
          PendingCloudWrite(PendingCloudWrite.period, period.id, delete: true),
          () => FirestoreService.instance.deletePeriod(uid, period.id),
        );
      }
      if (profile.isDefault) {
        await CloudWriteReporter.instance.guard(
          PendingCloudWrite(PendingCloudWrite.profile, replacement.id),
          () => FirestoreService.instance.saveProfile(uid, replacement),
        );
      }
    }
  }

  Future<void> setDefaultProfile(String id) async {
    if (!_box.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'Unknown profile');
    }

    for (final profile in _box.values) {
      final shouldBeDefault = profile.id == id;
      if (profile.isDefault != shouldBeDefault) {
        profile.isDefault = shouldBeDefault;
        await profile.save();
      }
    }
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      for (final profile in _box.values) {
        await CloudWriteReporter.instance.guard(
          PendingCloudWrite(PendingCloudWrite.profile, profile.id),
          () => FirestoreService.instance.saveProfile(uid, profile),
        );
      }
    }
  }
}
