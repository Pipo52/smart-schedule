import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/lesson.dart';
import '../models/schedule_exception.dart';
import '../models/schedule_profile.dart';
import '../models/semester_period.dart';
import '../models/task.dart';
import 'secret_crypto.dart';
import 'sync_clock.dart';

class SyncBatch<T> {
  const SyncBatch({
    required this.active,
    required this.tombstones,
    this.hasChanges = true,
  });

  final List<T> active;
  final Map<String, DateTime> tombstones;

  /// False when every change in the snapshot was our own unconfirmed write.
  final bool hasChanges;
}

/// One collection read: live documents and deletion markers together.
class FetchedCollection<T> {
  const FetchedCollection({required this.active, required this.tombstones});

  final List<T> active;
  final Map<String, DateTime> tombstones;
}

/// Thin Firestore facade. Every path is `users/{uid}/...`.
/// The uid comes from [AuthProvider], not from this class.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  /// Own writes show up in the local snapshot before the server confirms
  /// them. Applying those echoes rewrites Hive with the same data.
  static bool shouldApplySnapshotChange({required bool hasPendingWrites}) =>
      !hasPendingWrites;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const List<String> dataCollections = [
    'lessons',
    'tasks',
    'exams',
    'semester_periods',
    'schedule_exceptions',
    'profiles',
  ];

  CollectionReference<Map<String, dynamic>> _col(String uid, String name) =>
      _db.collection('users').doc(uid).collection(name);

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) =>
      _col(uid, 'settings').doc('app');

  DocumentReference<Map<String, dynamic>> _clockDoc(String uid) =>
      _col(uid, 'meta').doc('clock');

  Future<void> saveLesson(String uid, Lesson lesson) async {
    final map = _lessonToMap(lesson);
    map['isDeleted'] = false;
    map['updatedAt'] = (lesson.updatedAt ?? DateTime.now().toUtc())
        .toIso8601String();
    await _col(uid, 'lessons').doc(lesson.id).set(map, SetOptions(merge: true));
  }

  Future<void> deleteLesson(String uid, String id) async {
    await _col(uid, 'lessons').doc(id).set({
      'isDeleted': true,
      'updatedAt': SyncClock.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<Lesson>> fetchLessons(String uid) async =>
      (await fetchLessonsSplit(uid)).active;

  Future<FetchedCollection<Lesson>> fetchLessonsSplit(String uid) =>
      _fetchSplit(uid, 'lessons', _lessonFromMap);

  Map<String, dynamic> _lessonToMap(Lesson l) => {
    'subjectName': l.subjectName,
    'type': l.type.index,
    'room': l.room,
    'lecturer': l.lecturer,
    'startTime': l.startTime,
    'endTime': l.endTime,
    'weekday': l.weekday,
    'weekType': l.weekType.index,
    'notes': l.notes,
    'reminderEnabled': l.reminderEnabled,
    'profileId': l.profileId,
    'updatedAt': (l.updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'isDeleted': false,
  };

  Lesson _lessonFromMap(String id, Map<String, dynamic> m) => Lesson(
    id: id,
    subjectName: m['subjectName'] as String,
    type: LessonType.values[m['type'] as int],
    room: m['room'] as String,
    lecturer: m['lecturer'] as String,
    startTime: m['startTime'] as String,
    endTime: m['endTime'] as String,
    weekday: m['weekday'] as int,
    weekType: WeekType.values[m['weekType'] as int],
    notes: m['notes'] as String?,
    reminderEnabled: m['reminderEnabled'] as bool? ?? true,
    profileId: m['profileId'] as String,
    updatedAt: m['updatedAt'] != null
        ? DateTime.tryParse(m['updatedAt'] as String)
        : null,
  );

  Future<void> saveTask(String uid, Task task) async {
    final map = _taskToMap(task);
    map['isDeleted'] = false;
    map['updatedAt'] = (task.updatedAt ?? DateTime.now().toUtc())
        .toIso8601String();
    await _col(uid, 'tasks').doc(task.id).set(map, SetOptions(merge: true));
  }

  Future<void> deleteTask(String uid, String id) async {
    await _col(uid, 'tasks').doc(id).set({
      'isDeleted': true,
      'updatedAt': SyncClock.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<Task>> fetchTasks(String uid) async =>
      (await fetchTasksSplit(uid)).active;

  Future<FetchedCollection<Task>> fetchTasksSplit(String uid) =>
      _fetchSplit(uid, 'tasks', _taskFromMap);

  Map<String, dynamic> _taskToMap(Task t) => {
    'title': t.title,
    'linkedSubject': t.linkedSubject,
    'description': t.description,
    'dueDate': t.dueDate.toIso8601String(),
    'priority': t.priority.index,
    'isDone': t.isDone,
    'reminderOffsetMinutes': t.reminderOffsetMinutes,
    'linkedExamId': t.linkedExamId,
    'profileId': t.profileId,
    'updatedAt': (t.updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'isDeleted': false,
  };

  Task _taskFromMap(String id, Map<String, dynamic> m) => Task(
    id: id,
    title: m['title'] as String,
    linkedSubject: m['linkedSubject'] as String?,
    description: m['description'] as String?,
    dueDate: DateTime.parse(m['dueDate'] as String),
    priority: Priority.values[m['priority'] as int],
    isDone: m['isDone'] as bool? ?? false,
    reminderOffsetMinutes: m['reminderOffsetMinutes'] as int?,
    linkedExamId: m['linkedExamId'] as String?,
    profileId: m['profileId'] as String,
    updatedAt: m['updatedAt'] != null
        ? DateTime.tryParse(m['updatedAt'] as String)
        : null,
  );

  Future<void> saveExam(String uid, Exam exam) async {
    final map = _examToMap(exam);
    map['isDeleted'] = false;
    map['updatedAt'] = (exam.updatedAt ?? DateTime.now().toUtc())
        .toIso8601String();
    await _col(uid, 'exams').doc(exam.id).set(map, SetOptions(merge: true));
  }

  Future<void> deleteExam(String uid, String id) async {
    await _col(uid, 'exams').doc(id).set({
      'isDeleted': true,
      'updatedAt': SyncClock.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<Exam>> fetchExams(String uid) async =>
      (await fetchExamsSplit(uid)).active;

  Future<FetchedCollection<Exam>> fetchExamsSplit(String uid) =>
      _fetchSplit(uid, 'exams', _examFromMap);

  Map<String, dynamic> _examToMap(Exam e) => {
    'subjectName': e.subjectName,
    'date': e.date.toIso8601String(),
    'room': e.room,
    'examType': e.examType.index,
    'notes': e.notes,
    'revisionTasks': e.revisionTasks,
    'profileId': e.profileId,
    'updatedAt': (e.updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'isDeleted': false,
  };

  Exam _examFromMap(String id, Map<String, dynamic> m) => Exam(
    id: id,
    subjectName: m['subjectName'] as String,
    date: DateTime.parse(m['date'] as String),
    room: m['room'] as String?,
    examType: ExamType.values[m['examType'] as int],
    notes: m['notes'] as String?,
    revisionTasks: List<String>.from(m['revisionTasks'] as List? ?? []),
    profileId: m['profileId'] as String,
    updatedAt: m['updatedAt'] != null
        ? DateTime.tryParse(m['updatedAt'] as String)
        : null,
  );

  Future<void> savePeriod(String uid, SemesterPeriod period) async {
    final map = _periodToMap(period);
    map['isDeleted'] = false;
    map['updatedAt'] = (period.updatedAt ?? DateTime.now().toUtc())
        .toIso8601String();
    await _col(
      uid,
      'semester_periods',
    ).doc(period.id).set(map, SetOptions(merge: true));
  }

  Future<void> deletePeriod(String uid, String id) async {
    await _col(uid, 'semester_periods').doc(id).set({
      'isDeleted': true,
      'updatedAt': SyncClock.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<SemesterPeriod>> fetchPeriods(String uid) async =>
      (await fetchPeriodsSplit(uid)).active;

  Future<FetchedCollection<SemesterPeriod>> fetchPeriodsSplit(String uid) =>
      _fetchSplit(uid, 'semester_periods', _periodFromMap);

  Map<String, dynamic> _periodToMap(SemesterPeriod p) => {
    'name': p.name,
    'startDate': p.startDate.toIso8601String(),
    'endDate': p.endDate.toIso8601String(),
    'type': p.type.index,
    'profileId': p.profileId,
    'colorValue': p.colorValue,
    'updatedAt': (p.updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'isDeleted': false,
  };

  SemesterPeriod _periodFromMap(String id, Map<String, dynamic> m) =>
      SemesterPeriod(
        id: id,
        name: m['name'] as String,
        startDate: DateTime.parse(m['startDate'] as String),
        endDate: DateTime.parse(m['endDate'] as String),
        type: SemesterPeriodType.values[m['type'] as int],
        profileId: m['profileId'] as String,
        colorValue: (m['colorValue'] as num?)?.toInt(),
        updatedAt: m['updatedAt'] != null
            ? DateTime.tryParse(m['updatedAt'] as String)
            : null,
      );

  Future<void> saveException(String uid, ScheduleException exception) async {
    final map = _exceptionToMap(exception);
    map['isDeleted'] = false;
    map['updatedAt'] = (exception.updatedAt ?? DateTime.now().toUtc())
        .toIso8601String();
    await _col(
      uid,
      'schedule_exceptions',
    ).doc(exception.id).set(map, SetOptions(merge: true));
  }

  Future<void> deleteException(String uid, String id) async {
    await _col(uid, 'schedule_exceptions').doc(id).set({
      'isDeleted': true,
      'updatedAt': SyncClock.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<ScheduleException>> fetchExceptions(String uid) async =>
      (await fetchExceptionsSplit(uid)).active;

  Future<FetchedCollection<ScheduleException>> fetchExceptionsSplit(
    String uid,
  ) => _fetchSplit(uid, 'schedule_exceptions', _exceptionFromMap);

  Map<String, dynamic> _exceptionToMap(ScheduleException e) => {
    'lessonId': e.lessonId,
    'date': e.date.toIso8601String(),
    'type': e.type.index,
    'profileId': e.profileId,
    'newStartTime': e.newStartTime,
    'newEndTime': e.newEndTime,
    'newRoom': e.newRoom,
    'newLecturer': e.newLecturer,
    'newNotes': e.newNotes,
    'updatedAt': (e.updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'isDeleted': false,
  };

  ScheduleException _exceptionFromMap(String id, Map<String, dynamic> m) =>
      ScheduleException(
        id: id,
        lessonId: m['lessonId'] as String,
        date: DateTime.parse(m['date'] as String),
        type: ExceptionType.values[m['type'] as int],
        profileId: m['profileId'] as String,
        newStartTime: m['newStartTime'] as String?,
        newEndTime: m['newEndTime'] as String?,
        newRoom: m['newRoom'] as String?,
        newLecturer: m['newLecturer'] as String?,
        newNotes: m['newNotes'] as String?,
        updatedAt: m['updatedAt'] != null
            ? DateTime.tryParse(m['updatedAt'] as String)
            : null,
      );

  Future<void> saveProfile(String uid, ScheduleProfile profile) async {
    final map = _profileToMap(profile);
    map['isDeleted'] = false;
    map['updatedAt'] = (profile.updatedAt ?? DateTime.now().toUtc())
        .toIso8601String();
    await _col(
      uid,
      'profiles',
    ).doc(profile.id).set(map, SetOptions(merge: true));
  }

  Future<void> deleteProfile(String uid, String id) async {
    await _col(uid, 'profiles').doc(id).set({
      'isDeleted': true,
      'updatedAt': SyncClock.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<ScheduleProfile>> fetchProfiles(String uid) async =>
      (await fetchProfilesSplit(uid)).active;

  Future<FetchedCollection<ScheduleProfile>> fetchProfilesSplit(String uid) =>
      _fetchSplit(uid, 'profiles', _profileFromMap);

  Future<FetchedCollection<T>> _fetchSplit<T>(
    String uid,
    String collectionName,
    T Function(String id, Map<String, dynamic> data) fromMap,
  ) async {
    final snap = await _col(uid, collectionName).get();
    final active = <T>[];
    final tombstones = <String, DateTime>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isDeleted'] == true) {
        tombstones[doc.id] = _deletedAt(data);
      } else {
        active.add(fromMap(doc.id, data));
      }
    }
    return FetchedCollection(active: active, tombstones: tombstones);
  }

  DateTime _deletedAt(Map<String, dynamic>? data) {
    final raw = data?['updatedAt'];
    if (raw is String) {
      return DateTime.tryParse(raw) ?? SyncClock.now();
    }
    return data == null ? SyncClock.now() : DateTime(0);
  }

  Map<String, dynamic> _profileToMap(ScheduleProfile p) => {
    'name': p.name,
    'createdAt': p.createdAt.toIso8601String(),
    'isDefault': p.isDefault,
    'updatedAt': (p.updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'isDeleted': false,
  };

  ScheduleProfile _profileFromMap(String id, Map<String, dynamic> m) =>
      ScheduleProfile(
        id: id,
        name: m['name'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        isDefault: m['isDefault'] as bool? ?? false,
        updatedAt: m['updatedAt'] != null
            ? DateTime.tryParse(m['updatedAt'] as String)
            : null,
      );

  Future<void> saveSettings(
    String uid,
    AppSettings settings, {
    String? geminiApiKey,
  }) async {
    await _settingsDoc(uid)
        .set(await _settingsToMap(uid, settings, geminiApiKey));
  }

  Future<Map<String, dynamic>?> fetchSettings(String uid) async {
    final snap = await _settingsDoc(uid).get();
    if (!snap.exists) return null;
    final data = Map<String, dynamic>.from(snap.data()!);
    final encrypted = data['geminiApiKeyEnc'] as String?;
    final legacy = data['geminiApiKey'] as String?;
    data.remove('geminiApiKeyEnc');
    data.remove('geminiApiKey');

    if (encrypted != null && encrypted.isNotEmpty) {
      data['geminiApiKey'] = await SecretCrypto.instance.decrypt(
        uid,
        encrypted,
      );
    } else if (legacy != null && legacy.isNotEmpty) {
      data['geminiApiKey'] = legacy;
      await _settingsDoc(uid).update({
        'geminiApiKeyEnc': await SecretCrypto.instance.encrypt(uid, legacy),
        'geminiApiKey': FieldValue.delete(),
      });
    }
    return data;
  }

  Future<Map<String, dynamic>> _settingsToMap(
    String uid,
    AppSettings settings,
    String? geminiApiKey,
  ) async {
    final map = <String, dynamic>{
      'semesterReferenceDate': settings.semesterReferenceDate.toIso8601String(),
      'manualWeekOverride': settings.manualWeekOverride,
      'defaultLessonReminderMinutes': settings.defaultLessonReminderMinutes,
      'themeMode': settings.themeMode.index,
      'appLocale': settings.appLocale,
      'lastOpenedProfileId': settings.lastOpenedProfileId,
      'startupBehavior': settings.startupBehavior.index,
      'updatedAt': (settings.updatedAt ?? DateTime.now().toUtc())
          .toIso8601String(),
      'geminiApiKey': FieldValue.delete(),
    };
    if (geminiApiKey == null || geminiApiKey.isEmpty) {
      map['geminiApiKeyEnc'] = FieldValue.delete();
    } else {
      map['geminiApiKeyEnc'] = await SecretCrypto.instance.encrypt(
        uid,
        geminiApiKey,
      );
    }
    return map;
  }

  /// Deletes every synced document for [uid] and writes a wipe marker in settings.
  Future<void> deleteAll(String uid) async {
    final now = SyncClock.now();
    await Future.wait([
      for (final name in dataCollections) _deleteCollection(uid, name),
    ]);
    await _settingsDoc(uid).set({
      'wipedAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
  }

  /// Writes a server timestamp and reads it back so the client can correct
  /// its clock before last-write-wins comparisons. Stored apart from settings
  /// so the sample does not wake the settings snapshot.
  Future<DateTime?> sampleServerTime(String uid) async {
    final ref = _clockDoc(uid);
    await ref.set({'clockSample': FieldValue.serverTimestamp()});
    final snap = await ref.get();
    final raw = snap.data()?['clockSample'];
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is String) return DateTime.tryParse(raw)?.toUtc();
    return null;
  }

  /// A deletion marker with no lesson payload. Kept so an offline device
  /// cannot upload the row again after the body has been discarded.
  @visibleForTesting
  static bool isMinimalTombstone(Map<String, dynamic> data) {
    return data.length == 2 &&
        data['isDeleted'] == true &&
        data['updatedAt'] is String;
  }

  /// Drops the stored lesson and keeps the deletion time.
  @visibleForTesting
  static Map<String, dynamic> retainedTombstone(
    Map<String, dynamic> data,
    DateTime fallback,
  ) {
    final at = DateTime.tryParse('${data['updatedAt']}');
    return {'isDeleted': true, 'updatedAt': (at ?? fallback).toIso8601String()};
  }

  /// Shrinks soft-deleted documents older than [maxAge] down to a marker.
  /// The marker stays, so a phone that was offline does not treat the missing
  /// document as a new local row and upload it again.
  Future<void> purgeExpiredTombstones(
    String uid, {
    Duration maxAge = const Duration(days: 30),
  }) async {
    final now = SyncClock.now();
    final cutoff = now.subtract(maxAge);
    for (final name in dataCollections) {
      final snap = await _col(uid, name).get();
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['isDeleted'] != true) continue;
        if (isMinimalTombstone(data)) continue;
        final at = DateTime.tryParse('${data['updatedAt']}');
        if (at != null && !at.isBefore(cutoff)) continue;
        await doc.reference.set(retainedTombstone(data, now));
      }
    }
  }

  Future<void> _deleteCollection(String uid, String name) async {
    final snap = await _col(uid, name).get();
    if (snap.docs.isEmpty) return;

    var batch = _db.batch();
    var count = 0;
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      count++;
      if (count == 400) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  Stream<SyncBatch<Lesson>> watchLessons(String uid) =>
      _watchSplit(uid, 'lessons', _lessonFromMap);

  Stream<SyncBatch<Task>> watchTasks(String uid) =>
      _watchSplit(uid, 'tasks', _taskFromMap);

  Stream<SyncBatch<Exam>> watchExams(String uid) =>
      _watchSplit(uid, 'exams', _examFromMap);

  Stream<SyncBatch<SemesterPeriod>> watchPeriods(String uid) =>
      _watchSplit(uid, 'semester_periods', _periodFromMap);

  Stream<SyncBatch<ScheduleException>> watchExceptions(String uid) =>
      _watchSplit(uid, 'schedule_exceptions', _exceptionFromMap);

  Stream<SyncBatch<ScheduleProfile>> watchProfiles(String uid) =>
      _watchSplit(uid, 'profiles', _profileFromMap);

  Stream<SyncBatch<T>> _watchSplit<T>(
    String uid,
    String collectionName,
    T Function(String id, Map<String, dynamic> data) fromMap,
  ) {
    return _col(uid, collectionName).snapshots().map((snap) {
      final active = <T>[];
      final tombstones = <String, DateTime>{};
      var hasChanges = false;
      for (final change in snap.docChanges) {
        if (!shouldApplySnapshotChange(
          hasPendingWrites: change.doc.metadata.hasPendingWrites,
        )) {
          continue;
        }
        final data = change.doc.data();
        hasChanges = true;
        if (change.type == DocumentChangeType.removed ||
            data == null ||
            data['isDeleted'] == true) {
          tombstones[change.doc.id] = _deletedAt(data);
        } else {
          active.add(fromMap(change.doc.id, data));
        }
      }
      return SyncBatch<T>(
        active: active,
        tombstones: tombstones,
        hasChanges: hasChanges,
      );
    });
  }

  /// Settings snapshots are decoded only. They never write back to Firestore.
  Stream<Map<String, dynamic>?> watchSettings(String uid) {
    return _settingsDoc(uid)
        .snapshots()
        .where(
          (snap) => shouldApplySnapshotChange(
            hasPendingWrites: snap.metadata.hasPendingWrites,
          ),
        )
        .asyncMap((snap) async {
          if (!snap.exists || snap.data() == null) return null;
          final data = Map<String, dynamic>.from(snap.data()!);
          final encrypted = data['geminiApiKeyEnc'] as String?;
          final legacy = data['geminiApiKey'] as String?;
          data.remove('geminiApiKeyEnc');
          data.remove('geminiApiKey');
          if (encrypted != null && encrypted.isNotEmpty) {
            data['geminiApiKey'] = await SecretCrypto.instance.decrypt(
              uid,
              encrypted,
            );
          } else if (legacy != null && legacy.isNotEmpty) {
            data['geminiApiKey'] = legacy;
          }
          return data;
        });
  }
}
