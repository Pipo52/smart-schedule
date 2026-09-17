import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/schedule_profile.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required SettingsProvider settings})
    : _settings = settings,
      _activeProfileId = _resolveInitialProfileId(settings);

  static const Uuid _uuid = Uuid();

  final SettingsProvider _settings;
  final Box<ScheduleProfile> _box = HiveService.profilesBox;
  List<ScheduleProfile> _profiles = <ScheduleProfile>[];
  String _activeProfileId;

  List<ScheduleProfile> get profiles {
    _profiles = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(_profiles);
  }

  String get activeProfileId => _activeProfileId;

  ScheduleProfile? get activeProfile => _box.get(_activeProfileId);

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
    );
    await _box.put(profile.id, profile);
    notifyListeners();
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
    await profile.save();
    notifyListeners();
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
    await _box.delete(id);

    if (profile.isDefault) {
      replacement.isDefault = true;
      await replacement.save();
    }
    if (_activeProfileId == id) {
      _activeProfileId = replacement.id;
      _settings.settings.lastOpenedProfileId = replacement.id;
      await _settings.settings.save();
    }

    notifyListeners();
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
    notifyListeners();
  }
}
