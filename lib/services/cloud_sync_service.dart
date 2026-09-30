import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/lesson.dart';
import '../models/schedule_exception.dart';
import '../models/schedule_profile.dart';
import '../models/semester_period.dart';
import '../models/task.dart';
import 'firestore_service.dart';
import 'hive_service.dart';
import 'sync_clock.dart';

class MergeResult<T> {
  const MergeResult({required this.revived, required this.changed});

  final List<T> revived;
  final bool changed;
}

/// Downloads Firestore into Hive on sign-in. Uploads Hive when the cloud
/// has no lessons, tasks, exams, periods, or exceptions yet.
class CloudSyncService {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  static const String ownerUidKey = 'cloud_owner_uid';
  static const String geminiApiKeyStorageKey = 'gemini_api_key';

  final FirestoreService _firestore = FirestoreService.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String? _listeningUid;
  bool _notifyScheduled = false;

  /// Fired after a remote snapshot has been written to Hive.
  void Function()? onRemoteChange;

  DateTime? _lastPullAt;

  DateTime? get lastPullAt => _lastPullAt;

  /// Resume pulls are skipped when a sync just finished. A failed cloud
  /// write still pulls, so the newer local copy can be uploaded.
  static const Duration resumePullMinGap = Duration(minutes: 3);

  static bool shouldSkipResumePull({
    required DateTime? lastPullAt,
    required DateTime now,
    required bool hasPendingFailure,
  }) {
    if (hasPendingFailure || lastPullAt == null) return false;
    return now.difference(lastPullAt) < resumePullMinGap;
  }

  void _noteSynced() {
    _lastPullAt = DateTime.now();
  }

  /// Pulls when the account already has profiles. Pushes local Hive when
  /// the cloud is empty. A different uid wipes Hive first so the previous
  /// account's lessons are not uploaded.
  Future<void> syncOnLogin(String uid) async {
    await _alignClock(uid);
    final owner = await _storage.read(key: ownerUidKey);
    if (owner != null && owner != uid) {
      await HiveService.wipeAllData();
      await _storage.delete(key: geminiApiKeyStorageKey);
    }

    final cloudProfiles = await _firestore.fetchProfiles(uid);
    final cloudLessons = await _firestore.fetchLessons(uid);
    final cloudTasks = await _firestore.fetchTasks(uid);
    final cloudExams = await _firestore.fetchExams(uid);
    final cloudPeriods = await _firestore.fetchPeriods(uid);
    final cloudExceptions = await _firestore.fetchExceptions(uid);
    final cloudHasSchedule =
        cloudLessons.isNotEmpty ||
        cloudTasks.isNotEmpty ||
        cloudExams.isNotEmpty ||
        cloudPeriods.isNotEmpty ||
        cloudExceptions.isNotEmpty;
    final localHasSchedule =
        HiveService.lessonsBox.isNotEmpty ||
        HiveService.tasksBox.isNotEmpty ||
        HiveService.examsBox.isNotEmpty ||
        HiveService.periodsBox.isNotEmpty ||
        HiveService.exceptionsBox.isNotEmpty;

    var pushedLocal = false;
    if (cloudHasSchedule) {
      await pullFromCloud(uid);
    } else if (localHasSchedule) {
      // A web sign-up pushes an empty default profile. That must not block
      // the phone's existing lessons from becoming the cloud copy.
      await _firestore.deleteAll(uid);
      await recordWipeTimestamp(uid);
      await pushLocalToCloud(uid);
      pushedLocal = true;
    } else if (cloudProfiles.isEmpty) {
      await pushLocalToCloud(uid);
      pushedLocal = true;
    } else {
      await pullFromCloud(uid);
    }
    if (pushedLocal) {
      await _uploadLocalOnlyFromCloud(uid);
      _noteSynced();
    }
    await _storage.write(key: ownerUidKey, value: uid);
    await startListening(uid);
  }

  Future<void> recordWipeTimestamp(String uid, [DateTime? time]) {
    final timestamp = (time ?? DateTime.now().toUtc()).toIso8601String();
    return _storage.write(key: 'last_wiped_at_$uid', value: timestamp);
  }

  Future<void> _uploadLocalOnlyFromCloud(String uid) async {
    final results = await Future.wait([
      _firestore.fetchLessonsSplit(uid),
      _firestore.fetchTasksSplit(uid),
      _firestore.fetchExamsSplit(uid),
      _firestore.fetchPeriodsSplit(uid),
      _firestore.fetchExceptionsSplit(uid),
      _firestore.fetchProfilesSplit(uid),
    ]);
    final lessons = results[0] as FetchedCollection<Lesson>;
    final tasks = results[1] as FetchedCollection<Task>;
    final exams = results[2] as FetchedCollection<Exam>;
    final periods = results[3] as FetchedCollection<SemesterPeriod>;
    final exceptions = results[4] as FetchedCollection<ScheduleException>;
    final profiles = results[5] as FetchedCollection<ScheduleProfile>;
    await _uploadLocalOnly(
      uid,
      lessons: lessons.active,
      lessonTombstones: lessons.tombstones,
      tasks: tasks.active,
      taskTombstones: tasks.tombstones,
      exams: exams.active,
      examTombstones: exams.tombstones,
      periods: periods.active,
      periodTombstones: periods.tombstones,
      exceptions: exceptions.active,
      exceptionTombstones: exceptions.tombstones,
      profiles: profiles.active,
      profileTombstones: profiles.tombstones,
    );
  }

  /// Uploads Hive rows the cloud does not have yet, or rows that have a newer
  /// local `updatedAt`. Also removes local rows that were deleted remotely,
  /// or revives remotely deleted rows if local edits are newer than the tombstone.
  /// Callers pass a collection snapshot they already paid for.
  Future<void> _uploadLocalOnly(
    String uid, {
    required List<Lesson> lessons,
    required Map<String, DateTime> lessonTombstones,
    required List<Task> tasks,
    required Map<String, DateTime> taskTombstones,
    required List<Exam> exams,
    required Map<String, DateTime> examTombstones,
    required List<SemesterPeriod> periods,
    required Map<String, DateTime> periodTombstones,
    required List<ScheduleException> exceptions,
    required Map<String, DateTime> exceptionTombstones,
    required List<ScheduleProfile> profiles,
    required Map<String, DateTime> profileTombstones,
  }) async {
    final cloudLessons = {for (final l in lessons) l.id: l};
    final cloudTasks = {for (final t in tasks) t.id: t};
    final cloudExams = {for (final e in exams) e.id: e};
    final cloudPeriods = {for (final p in periods) p.id: p};
    final cloudExceptions = {for (final e in exceptions) e.id: e};
    final cloudProfiles = {for (final p in profiles) p.id: p};

    final futures = <Future<void>>[];

    // Lessons
    for (final lesson in HiveService.lessonsBox.values) {
      final localTime = lesson.updatedAt ?? DateTime(0);
      final tombstoneTime = lessonTombstones[lesson.id];
      if (tombstoneTime != null) {
        if (localTime.isAfter(tombstoneTime)) {
          futures.add(_firestore.saveLesson(uid, lesson));
        } else {
          await HiveService.lessonsBox.delete(lesson.id);
        }
        continue;
      }
      final remote = cloudLessons[lesson.id];
      if (remote == null ||
          localTime.isAfter(remote.updatedAt ?? DateTime(0))) {
        futures.add(_firestore.saveLesson(uid, lesson));
      }
    }

    // Tasks
    for (final task in HiveService.tasksBox.values) {
      final localTime = task.updatedAt ?? DateTime(0);
      final tombstoneTime = taskTombstones[task.id];
      if (tombstoneTime != null) {
        if (localTime.isAfter(tombstoneTime)) {
          futures.add(_firestore.saveTask(uid, task));
        } else {
          await HiveService.tasksBox.delete(task.id);
        }
        continue;
      }
      final remote = cloudTasks[task.id];
      if (remote == null ||
          localTime.isAfter(remote.updatedAt ?? DateTime(0))) {
        futures.add(_firestore.saveTask(uid, task));
      }
    }

    // Exams
    for (final exam in HiveService.examsBox.values) {
      final localTime = exam.updatedAt ?? DateTime(0);
      final tombstoneTime = examTombstones[exam.id];
      if (tombstoneTime != null) {
        if (localTime.isAfter(tombstoneTime)) {
          futures.add(_firestore.saveExam(uid, exam));
        } else {
          await HiveService.examsBox.delete(exam.id);
        }
        continue;
      }
      final remote = cloudExams[exam.id];
      if (remote == null ||
          localTime.isAfter(remote.updatedAt ?? DateTime(0))) {
        futures.add(_firestore.saveExam(uid, exam));
      }
    }

    // Periods
    for (final period in HiveService.periodsBox.values) {
      final localTime = period.updatedAt ?? DateTime(0);
      final tombstoneTime = periodTombstones[period.id];
      if (tombstoneTime != null) {
        if (localTime.isAfter(tombstoneTime)) {
          futures.add(_firestore.savePeriod(uid, period));
        } else {
          await HiveService.periodsBox.delete(period.id);
        }
        continue;
      }
      final remote = cloudPeriods[period.id];
      if (remote == null ||
          localTime.isAfter(remote.updatedAt ?? DateTime(0))) {
        futures.add(_firestore.savePeriod(uid, period));
      }
    }

    // Exceptions
    for (final exception in HiveService.exceptionsBox.values) {
      final localTime = exception.updatedAt ?? DateTime(0);
      final tombstoneTime = exceptionTombstones[exception.id];
      if (tombstoneTime != null) {
        if (localTime.isAfter(tombstoneTime)) {
          futures.add(_firestore.saveException(uid, exception));
        } else {
          await HiveService.exceptionsBox.delete(exception.id);
        }
        continue;
      }
      final remote = cloudExceptions[exception.id];
      if (remote == null ||
          localTime.isAfter(remote.updatedAt ?? DateTime(0))) {
        futures.add(_firestore.saveException(uid, exception));
      }
    }

    // Profiles
    for (final profile in HiveService.profilesBox.values) {
      final localTime = profile.updatedAt ?? DateTime(0);
      final tombstoneTime = profileTombstones[profile.id];
      if (tombstoneTime != null) {
        if (localTime.isAfter(tombstoneTime)) {
          futures.add(_firestore.saveProfile(uid, profile));
        } else {
          await HiveService.profilesBox.delete(profile.id);
        }
        continue;
      }
      final remote = cloudProfiles[profile.id];
      if (remote == null ||
          localTime.isAfter(remote.updatedAt ?? DateTime(0))) {
        futures.add(_firestore.saveProfile(uid, profile));
      }
    }

    await Future.wait(futures);
  }

  @visibleForTesting
  Future<MergeResult<T>> mergeBatch<T>({
    required Box<T> box,
    required SyncBatch<T> batch,
    required String Function(T) getId,
    required DateTime? Function(T) getUpdatedAt,
  }) {
    return _mergeBatch(
      box: box,
      batch: batch,
      getId: getId,
      getUpdatedAt: getUpdatedAt,
    );
  }

  Future<void> _alignClock(String uid) async {
    final serverNow = await _firestore.sampleServerTime(uid);
    if (serverNow != null) SyncClock.alignTo(serverNow);
  }

  Future<MergeResult<T>> _mergeBatch<T>({
    required Box<T> box,
    required SyncBatch<T> batch,
    required String Function(T) getId,
    required DateTime? Function(T) getUpdatedAt,
  }) async {
    final revived = <T>[];
    var changed = false;
    for (final entry in batch.tombstones.entries) {
      final id = entry.key;
      final deletedAt = entry.value;
      final local = box.get(id);
      if (local != null) {
        final localTime = getUpdatedAt(local) ?? DateTime(0);
        if (localTime.isAfter(deletedAt)) {
          revived.add(local);
        } else {
          await box.delete(id);
          changed = true;
        }
      }
    }
    for (final item in batch.active) {
      final id = getId(item);
      final local = box.get(id);
      final remoteTime = getUpdatedAt(item) ?? DateTime(0);
      if (local == null) {
        await box.put(id, item);
        changed = true;
      } else {
        final localTime = getUpdatedAt(local) ?? DateTime(0);
        if (remoteTime.isAfter(localTime)) {
          await box.put(id, item);
          changed = true;
        }
      }
    }
    return MergeResult(revived: revived, changed: changed);
  }

  Future<void> startListening(String uid) async {
    await stopListening();
    _listeningUid = uid;
    _listen(
      uid,
      _firestore.watchLessons(uid),
      (batch) => _applyBatch(
        uid,
        batch,
        HiveService.lessonsBox,
        (l) => l.id,
        (l) => l.updatedAt,
        _firestore.saveLesson,
      ),
    );
    _listen(
      uid,
      _firestore.watchTasks(uid),
      (batch) => _applyBatch(
        uid,
        batch,
        HiveService.tasksBox,
        (t) => t.id,
        (t) => t.updatedAt,
        _firestore.saveTask,
      ),
    );
    _listen(
      uid,
      _firestore.watchExams(uid),
      (batch) => _applyBatch(
        uid,
        batch,
        HiveService.examsBox,
        (e) => e.id,
        (e) => e.updatedAt,
        _firestore.saveExam,
      ),
    );
    _listen(
      uid,
      _firestore.watchPeriods(uid),
      (batch) => _applyBatch(
        uid,
        batch,
        HiveService.periodsBox,
        (p) => p.id,
        (p) => p.updatedAt,
        _firestore.savePeriod,
      ),
    );
    _listen(
      uid,
      _firestore.watchExceptions(uid),
      (batch) => _applyBatch(
        uid,
        batch,
        HiveService.exceptionsBox,
        (e) => e.id,
        (e) => e.updatedAt,
        _firestore.saveException,
      ),
    );
    _listen(
      uid,
      _firestore.watchProfiles(uid),
      (batch) => _applyBatch(
        uid,
        batch,
        HiveService.profilesBox,
        (p) => p.id,
        (p) => p.updatedAt,
        _firestore.saveProfile,
      ),
    );
    _listen(uid, _firestore.watchSettings(uid), (settings) {
      return _applyRemoteSettings(uid, settings);
    });
  }

  Future<bool> _applyBatch<T>(
    String uid,
    SyncBatch<T> batch,
    Box<T> box,
    String Function(T) getId,
    DateTime? Function(T) getUpdatedAt,
    Future<void> Function(String uid, T item) save,
  ) async {
    if (!batch.hasChanges) return false;
    final result = await _mergeBatch(
      box: box,
      batch: batch,
      getId: getId,
      getUpdatedAt: getUpdatedAt,
    );
    for (final item in result.revived) {
      await save(uid, item);
    }
    return result.changed;
  }

  Future<bool> _applyRemoteSettings(
    String uid,
    Map<String, dynamic>? settings,
  ) async {
    if (settings == null) return false;
    var changed = false;
    final wipedAtStr = settings['wipedAt'] as String?;
    if (wipedAtStr != null) {
      final remoteWipedAt = DateTime.tryParse(wipedAtStr);
      if (remoteWipedAt != null) {
        final lastWipedAtStr = await _storage.read(key: 'last_wiped_at_$uid');
        final lastWipedAt = lastWipedAtStr != null
            ? DateTime.tryParse(lastWipedAtStr)
            : null;
        if (lastWipedAt == null || remoteWipedAt.isAfter(lastWipedAt)) {
          await HiveService.wipeAllData();
          await recordWipeTimestamp(uid, remoteWipedAt);
          await HiveService.ensureDefaultProfile();
          changed = true;
        }
      }
    }
    final localSettings = HiveService.loadOrCreateSettings();
    if (!_applySettings(localSettings, settings)) return changed;
    await localSettings.save();
    final key = settings['geminiApiKey'] as String?;
    if (key != null && key.isNotEmpty) {
      await _storage.write(key: geminiApiKeyStorageKey, value: key);
    }
    return true;
  }

  void _listen<T>(
    String uid,
    Stream<T> stream,
    Future<bool> Function(T value) apply,
  ) {
    _subscriptions.add(
      stream.listen((value) {
        unawaited(() async {
          if (_listeningUid != uid) return;
          final changed = await apply(value);
          if (!changed || _listeningUid != uid) return;
          _scheduleNotify();
        }());
      }, onError: (_, _) {}),
    );
  }

  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      onRemoteChange?.call();
    });
  }

  Future<void> stopListening() async {
    _listeningUid = null;
    final subscriptions = List<StreamSubscription<dynamic>>.from(
      _subscriptions,
    );
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  Future<void> rememberOwner(String uid) {
    return _storage.write(key: ownerUidKey, value: uid);
  }

  Future<void> pullFromCloud(
    String uid, {
    bool replaceEmpty = false,
    bool uploadLocalNewer = true,
  }) async {
    await _alignClock(uid);
    final results = await Future.wait([
      _firestore.fetchProfilesSplit(uid),
      _firestore.fetchLessonsSplit(uid),
      _firestore.fetchTasksSplit(uid),
      _firestore.fetchExamsSplit(uid),
      _firestore.fetchPeriodsSplit(uid),
      _firestore.fetchExceptionsSplit(uid),
      _firestore.fetchSettings(uid),
    ]);

    final profileSplit = results[0] as FetchedCollection<ScheduleProfile>;
    final lessonSplit = results[1] as FetchedCollection<Lesson>;
    final taskSplit = results[2] as FetchedCollection<Task>;
    final examSplit = results[3] as FetchedCollection<Exam>;
    final periodSplit = results[4] as FetchedCollection<SemesterPeriod>;
    final exceptionSplit = results[5] as FetchedCollection<ScheduleException>;
    final settings = results[6] as Map<String, dynamic>?;

    final profiles = profileSplit.active;
    final lessons = lessonSplit.active;
    final tasks = taskSplit.active;
    final exams = examSplit.active;
    final periods = periodSplit.active;
    final exceptions = exceptionSplit.active;
    final profileTombstones = profileSplit.tombstones;
    final lessonTombstones = lessonSplit.tombstones;
    final taskTombstones = taskSplit.tombstones;
    final examTombstones = examSplit.tombstones;
    final periodTombstones = periodSplit.tombstones;
    final exceptionTombstones = exceptionSplit.tombstones;

    if (settings != null) {
      final wipedAtStr = settings['wipedAt'] as String?;
      if (wipedAtStr != null) {
        final remoteWipedAt = DateTime.tryParse(wipedAtStr);
        if (remoteWipedAt != null) {
          final lastWipedAtStr = await _storage.read(key: 'last_wiped_at_$uid');
          final lastWipedAt = lastWipedAtStr != null
              ? DateTime.tryParse(lastWipedAtStr)
              : null;
          if (lastWipedAt == null || remoteWipedAt.isAfter(lastWipedAt)) {
            await HiveService.wipeAllData();
            await recordWipeTimestamp(uid, remoteWipedAt);
            await HiveService.ensureDefaultProfile();
          }
        }
      }
    }

    await _mergeBatch(
      box: HiveService.profilesBox,
      batch: SyncBatch<ScheduleProfile>(
        active: profiles,
        tombstones: profileTombstones,
      ),
      getId: (p) => p.id,
      getUpdatedAt: (p) => p.updatedAt,
    );
    await _mergeBatch(
      box: HiveService.lessonsBox,
      batch: SyncBatch<Lesson>(active: lessons, tombstones: lessonTombstones),
      getId: (l) => l.id,
      getUpdatedAt: (l) => l.updatedAt,
    );
    await _mergeBatch(
      box: HiveService.tasksBox,
      batch: SyncBatch<Task>(active: tasks, tombstones: taskTombstones),
      getId: (t) => t.id,
      getUpdatedAt: (t) => t.updatedAt,
    );
    await _mergeBatch(
      box: HiveService.examsBox,
      batch: SyncBatch<Exam>(active: exams, tombstones: examTombstones),
      getId: (e) => e.id,
      getUpdatedAt: (e) => e.updatedAt,
    );
    await _mergeBatch(
      box: HiveService.periodsBox,
      batch: SyncBatch<SemesterPeriod>(
        active: periods,
        tombstones: periodTombstones,
      ),
      getId: (p) => p.id,
      getUpdatedAt: (p) => p.updatedAt,
    );
    await _mergeBatch(
      box: HiveService.exceptionsBox,
      batch: SyncBatch<ScheduleException>(
        active: exceptions,
        tombstones: exceptionTombstones,
      ),
      getId: (e) => e.id,
      getUpdatedAt: (e) => e.updatedAt,
    );

    if (settings != null) {
      final localSettings = HiveService.loadOrCreateSettings();
      if (_applySettings(localSettings, settings)) {
        await localSettings.save();
        await _syncGeminiKey(uid, settings['geminiApiKey'] as String?);
      }
    } else {
      await _firestore.saveSettings(
        uid,
        HiveService.loadOrCreateSettings(),
        geminiApiKey: await _storage.read(key: geminiApiKeyStorageKey),
      );
    }

    if (uploadLocalNewer) {
      await _uploadLocalOnly(
        uid,
        lessons: lessons,
        lessonTombstones: lessonTombstones,
        tasks: tasks,
        taskTombstones: taskTombstones,
        exams: exams,
        examTombstones: examTombstones,
        periods: periods,
        periodTombstones: periodTombstones,
        exceptions: exceptions,
        exceptionTombstones: exceptionTombstones,
        profiles: profiles,
        profileTombstones: profileTombstones,
      );
    }
    await _purgeTombstonesIfDue(uid);
    _noteSynced();
  }

  static const Duration _tombstonePurgeGap = Duration(days: 1);

  Future<void> _purgeTombstonesIfDue(String uid) async {
    final key = 'tombstone_purge_at_$uid';
    final raw = await _storage.read(key: key);
    final last = raw == null ? null : DateTime.tryParse(raw);
    final now = DateTime.now().toUtc();
    if (last != null && now.difference(last) < _tombstonePurgeGap) return;
    await _firestore.purgeExpiredTombstones(uid);
    await _storage.write(key: key, value: now.toIso8601String());
  }

  Future<void> pushLocalToCloud(String uid) async {
    await HiveService.ensureDefaultProfile();
    final settings = HiveService.loadOrCreateSettings();
    final futures = <Future<void>>[
      _firestore.saveSettings(
        uid,
        settings,
        geminiApiKey: await _storage.read(key: geminiApiKeyStorageKey),
      ),
      for (final profile in HiveService.profilesBox.values)
        _firestore.saveProfile(uid, profile),
      for (final lesson in HiveService.lessonsBox.values)
        _firestore.saveLesson(uid, lesson),
      for (final task in HiveService.tasksBox.values)
        _firestore.saveTask(uid, task),
      for (final exam in HiveService.examsBox.values)
        _firestore.saveExam(uid, exam),
      for (final period in HiveService.periodsBox.values)
        _firestore.savePeriod(uid, period),
      for (final exception in HiveService.exceptionsBox.values)
        _firestore.saveException(uid, exception),
    ];
    await Future.wait(futures);
  }

  bool _applySettings(AppSettings settings, Map<String, dynamic> data) {
    if (data['semesterReferenceDate'] == null) {
      return false;
    }
    final remoteUpdatedAt = data['updatedAt'] != null
        ? DateTime.tryParse(data['updatedAt'] as String)
        : null;
    final localUpdatedAt = settings.updatedAt;

    if (remoteUpdatedAt != null && localUpdatedAt != null) {
      if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
        return false;
      }
    }

    settings.semesterReferenceDate = DateTime.parse(
      data['semesterReferenceDate'] as String,
    );
    settings.manualWeekOverride = (data['manualWeekOverride'] as num?)?.toInt();
    settings.defaultLessonReminderMinutes =
        (data['defaultLessonReminderMinutes'] as num?)?.toInt() ?? 10;
    settings.themeMode =
        AppThemeMode.values[(data['themeMode'] as num?)?.toInt() ?? 0];
    settings.appLocale = data['appLocale'] as String?;
    settings.lastOpenedProfileId = data['lastOpenedProfileId'] as String?;
    settings.startupBehavior =
        StartupBehavior.values[(data['startupBehavior'] as num?)?.toInt() ?? 1];
    settings.schemaVersion = 2;
    if (remoteUpdatedAt != null) {
      settings.updatedAt = remoteUpdatedAt;
    }
    return true;
  }

  @visibleForTesting
  bool applySettingsForTesting(
    AppSettings settings,
    Map<String, dynamic> data,
  ) => _applySettings(settings, data);

  /// Cloud key wins when present. Otherwise the local key is uploaded so
  /// a device that already had Gemini configured fills the account.
  Future<void> _syncGeminiKey(String uid, String? cloudKey) async {
    if (cloudKey != null && cloudKey.isNotEmpty) {
      await _storage.write(key: geminiApiKeyStorageKey, value: cloudKey);
      return;
    }
    final localKey = await _storage.read(key: geminiApiKeyStorageKey);
    if (localKey != null && localKey.isNotEmpty) {
      await _firestore.saveSettings(
        uid,
        HiveService.loadOrCreateSettings(),
        geminiApiKey: localKey,
      );
    } else {
      await _storage.delete(key: geminiApiKeyStorageKey);
    }
  }
}
