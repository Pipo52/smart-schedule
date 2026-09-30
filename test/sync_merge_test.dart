import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:smart_schedule/hive_registrar.g.dart';
import 'package:smart_schedule/models/app_settings.dart';
import 'package:smart_schedule/models/lesson.dart';
import 'package:smart_schedule/models/schedule_exception.dart';
import 'package:smart_schedule/providers/schedule_provider.dart';
import 'package:smart_schedule/services/cloud_sync_service.dart';
import 'package:smart_schedule/services/firestore_service.dart';

void main() {
  late Directory tempDir;
  late Box<Lesson> lessonBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('smart_calendar_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    lessonBox = await Hive.openBox<Lesson>(
      'test_lessons_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await lessonBox.deleteFromDisk();
  });

  Lesson makeLesson({
    required String id,
    required String subjectName,
    required DateTime updatedAt,
  }) {
    return Lesson(
      id: id,
      subjectName: subjectName,
      type: LessonType.lecture,
      room: '101',
      lecturer: 'Prof. Smith',
      startTime: '08:30',
      endTime: '10:00',
      weekday: 1,
      weekType: WeekType.every,
      profileId: 'default',
      updatedAt: updatedAt,
    );
  }

  group('Last-Write-Wins mergeBatch tests', () {
    test('Remote active item is inserted when not present locally', () async {
      final t1 = DateTime.utc(2026, 9, 24, 10, 0);
      final remoteLesson = makeLesson(
        id: 'L1',
        subjectName: 'Math',
        updatedAt: t1,
      );

      await CloudSyncService.instance.mergeBatch(
        box: lessonBox,
        batch: SyncBatch<Lesson>(active: [remoteLesson], tombstones: {}),
        getId: (l) => l.id,
        getUpdatedAt: (l) => l.updatedAt,
      );

      expect(lessonBox.containsKey('L1'), isTrue);
      expect(lessonBox.get('L1')?.subjectName, 'Math');
    });

    test(
      'Remote active item overwrites local item when remote updatedAt is newer',
      () async {
        final tOld = DateTime.utc(2026, 9, 24, 10, 0);
        final tNew = DateTime.utc(2026, 9, 24, 11, 0);

        final localLesson = makeLesson(
          id: 'L1',
          subjectName: 'Old Math',
          updatedAt: tOld,
        );
        await lessonBox.put('L1', localLesson);

        final remoteLesson = makeLesson(
          id: 'L1',
          subjectName: 'New Physics',
          updatedAt: tNew,
        );

        await CloudSyncService.instance.mergeBatch(
          box: lessonBox,
          batch: SyncBatch<Lesson>(active: [remoteLesson], tombstones: {}),
          getId: (l) => l.id,
          getUpdatedAt: (l) => l.updatedAt,
        );

        expect(lessonBox.get('L1')?.subjectName, 'New Physics');
        expect(lessonBox.get('L1')?.updatedAt, tNew);
      },
    );

    test(
      'Local item is preserved when local updatedAt is newer than remote',
      () async {
        final tOld = DateTime.utc(2026, 9, 24, 10, 0);
        final tNew = DateTime.utc(2026, 9, 24, 11, 0);

        final localLesson = makeLesson(
          id: 'L1',
          subjectName: 'Local Newer Math',
          updatedAt: tNew,
        );
        await lessonBox.put('L1', localLesson);

        final remoteLesson = makeLesson(
          id: 'L1',
          subjectName: 'Remote Stale Math',
          updatedAt: tOld,
        );

        final revived = await CloudSyncService.instance.mergeBatch(
          box: lessonBox,
          batch: SyncBatch<Lesson>(active: [remoteLesson], tombstones: {}),
          getId: (l) => l.id,
          getUpdatedAt: (l) => l.updatedAt,
        );

        expect(lessonBox.get('L1')?.subjectName, 'Local Newer Math');
        expect(lessonBox.get('L1')?.updatedAt, tNew);
        expect(revived.revived, isEmpty);
        expect(revived.changed, isFalse);
      },
    );

    test(
      'One-day cancellation syncs as an exception and keeps the lesson',
      () async {
        final lesson = makeLesson(
          id: 'L1',
          subjectName: 'Algebra',
          updatedAt: DateTime.utc(2026, 9, 29, 9),
        );
        await lessonBox.put(lesson.id, lesson);

        final exceptions = await Hive.openBox<ScheduleException>(
          'test_exceptions_${DateTime.now().microsecondsSinceEpoch}',
        );
        addTearDown(() async {
          if (exceptions.isOpen) await exceptions.deleteFromDisk();
        });

        final cancel = ScheduleException(
          id: 'E1',
          lessonId: 'L1',
          date: DateTime.utc(2026, 10, 5),
          type: ExceptionType.cancelled,
          profileId: 'seminar',
          updatedAt: DateTime.utc(2026, 9, 29, 12),
        );

        await CloudSyncService.instance.mergeBatch(
          box: exceptions,
          batch: SyncBatch<ScheduleException>(active: [cancel], tombstones: {}),
          getId: (e) => e.id,
          getUpdatedAt: (e) => e.updatedAt,
        );

        expect(lessonBox.get('L1')?.subjectName, 'Algebra');
        expect(exceptions.get('E1')?.type, ExceptionType.cancelled);
        expect(exceptions.get('E1')?.profileId, 'seminar');
        expect(exceptions.get('E1')?.date, DateTime.utc(2026, 10, 5));
      },
    );

    test('Remote tombstone deletes local item when tombstone is newer or same time', () async {
      final tLocal = DateTime.utc(2026, 9, 24, 10, 0);
      final tDelete = DateTime.utc(2026, 9, 24, 10, 30);

      final localLesson = makeLesson(
        id: 'L1',
        subjectName: 'To Be Deleted',
        updatedAt: tLocal,
      );
      await lessonBox.put('L1', localLesson);

      await CloudSyncService.instance.mergeBatch(
        box: lessonBox,
        batch: SyncBatch<Lesson>(active: [], tombstones: {'L1': tDelete}),
        getId: (l) => l.id,
        getUpdatedAt: (l) => l.updatedAt,
      );

      expect(lessonBox.containsKey('L1'), isFalse);
    });

    test('Local edit wins and survives when local updatedAt is newer than remote tombstone', () async {
      // Offline edit scenario: item was deleted on device A at 10:00,
      // but modified offline on device B at 10:15.
      final tDelete = DateTime.utc(2026, 9, 24, 10, 0);
      final tOfflineEdit = DateTime.utc(2026, 9, 24, 10, 15);

      final localLesson = makeLesson(
        id: 'L1',
        subjectName: 'Offline Modified',
        updatedAt: tOfflineEdit,
      );
      await lessonBox.put('L1', localLesson);

      final revived = await CloudSyncService.instance.mergeBatch(
        box: lessonBox,
        batch: SyncBatch<Lesson>(active: [], tombstones: {'L1': tDelete}),
        getId: (l) => l.id,
        getUpdatedAt: (l) => l.updatedAt,
      );

      // Must NOT be deleted! Local edit is newer than deletion.
      expect(lessonBox.containsKey('L1'), isTrue);
      expect(lessonBox.get('L1')?.subjectName, 'Offline Modified');
      expect(revived.revived, hasLength(1));
      expect(revived.revived.single.subjectName, 'Offline Modified');
      expect(revived.changed, isFalse);
    });
  });

  group('AppSettings Last-Write-Wins tests', () {
    test('Remote settings overwrite local when remote updatedAt is newer', () {
      final localSettings = AppSettings(
        semesterReferenceDate: DateTime.utc(2026, 9, 1),
        themeMode: AppThemeMode.light,
        updatedAt: DateTime.utc(2026, 9, 24, 9, 0),
      );

      final remoteMap = <String, dynamic>{
        'semesterReferenceDate': '2026-09-08T00:00:00.000Z',
        'themeMode': AppThemeMode.dark.index,
        'updatedAt': '2026-09-24T10:00:00.000Z',
      };

      CloudSyncService.instance.applySettingsForTesting(
        localSettings,
        remoteMap,
      );

      expect(localSettings.themeMode, AppThemeMode.dark);
      expect(localSettings.semesterReferenceDate, DateTime.utc(2026, 9, 8));
      expect(localSettings.updatedAt, DateTime.utc(2026, 9, 24, 10, 0));
    });

    test('Local settings win when local updatedAt is newer than remote', () {
      final localSettings = AppSettings(
        semesterReferenceDate: DateTime.utc(2026, 9, 1),
        themeMode: AppThemeMode.dark,
        updatedAt: DateTime.utc(2026, 9, 24, 12, 0),
      );

      final remoteMap = <String, dynamic>{
        'semesterReferenceDate': '2026-09-08T00:00:00.000Z',
        'themeMode': AppThemeMode.light.index,
        'updatedAt': '2026-09-24T10:00:00.000Z',
      };

      CloudSyncService.instance.applySettingsForTesting(
        localSettings,
        remoteMap,
      );

      expect(localSettings.themeMode, AppThemeMode.dark);
      expect(localSettings.semesterReferenceDate, DateTime.utc(2026, 9, 1));
      expect(localSettings.updatedAt, DateTime.utc(2026, 9, 24, 12, 0));
    });

    test('Partial wipe document is safely ignored by applySettings', () {
      final localSettings = AppSettings(
        semesterReferenceDate: DateTime.utc(2026, 9, 1),
        themeMode: AppThemeMode.light,
        updatedAt: DateTime.utc(2026, 9, 24, 9, 0),
      );

      final partialWipeMap = <String, dynamic>{
        'wipedAt': '2026-09-24T10:00:00.000Z',
        'updatedAt': '2026-09-24T10:00:00.000Z',
      };

      // Must not throw exception
      CloudSyncService.instance.applySettingsForTesting(
        localSettings,
        partialWipeMap,
      );

      expect(localSettings.themeMode, AppThemeMode.light);
      expect(localSettings.semesterReferenceDate, DateTime.utc(2026, 9, 1));
    });

    test('A clock sample is not applied as settings', () {
      final localSettings = AppSettings(
        semesterReferenceDate: DateTime.utc(2026, 9, 1),
        themeMode: AppThemeMode.light,
        updatedAt: DateTime.utc(2026, 9, 24, 9, 0),
      );

      final applied = CloudSyncService.instance.applySettingsForTesting(
        localSettings,
        {'clockSample': '2026-09-24T10:00:00.000Z'},
      );

      expect(applied, isFalse);
      expect(localSettings.themeMode, AppThemeMode.light);
      expect(localSettings.semesterReferenceDate, DateTime.utc(2026, 9, 1));
    });

    test('Equal updatedAt does not rewrite the local lesson', () async {
      final sameTime = DateTime.utc(2026, 9, 24, 12);
      await lessonBox.put(
        'L1',
        makeLesson(id: 'L1', subjectName: 'Local Algebra', updatedAt: sameTime),
      );

      final result = await CloudSyncService.instance.mergeBatch(
        box: lessonBox,
        batch: SyncBatch<Lesson>(
          active: [
            makeLesson(
              id: 'L1',
              subjectName: 'Echo Algebra',
              updatedAt: sameTime,
            ),
          ],
          tombstones: {},
        ),
        getId: (lesson) => lesson.id,
        getUpdatedAt: (lesson) => lesson.updatedAt,
      );

      expect(lessonBox.get('L1')?.subjectName, 'Local Algebra');
      expect(result.changed, isFalse);
      expect(result.revived, isEmpty);
    });
  });

  test('Own pending writes are not applied from a snapshot', () {
    expect(
      FirestoreService.shouldApplySnapshotChange(hasPendingWrites: true),
      isFalse,
    );
    expect(
      FirestoreService.shouldApplySnapshotChange(hasPendingWrites: false),
      isTrue,
    );
  });

  test('Resume pull waits a few minutes unless a cloud write failed', () {
    final now = DateTime.utc(2026, 9, 30, 10);
    expect(
      CloudSyncService.shouldSkipResumePull(
        lastPullAt: now.subtract(const Duration(minutes: 1)),
        now: now,
        hasPendingFailure: false,
      ),
      isTrue,
    );
    expect(
      CloudSyncService.shouldSkipResumePull(
        lastPullAt: now.subtract(const Duration(minutes: 4)),
        now: now,
        hasPendingFailure: false,
      ),
      isFalse,
    );
    expect(
      CloudSyncService.shouldSkipResumePull(
        lastPullAt: now.subtract(const Duration(minutes: 1)),
        now: now,
        hasPendingFailure: true,
      ),
      isFalse,
    );
    expect(
      CloudSyncService.shouldSkipResumePull(
        lastPullAt: null,
        now: now,
        hasPendingFailure: false,
      ),
      isFalse,
    );
  });

  test('Imported lessons take the open profile, not the parser default', () {
    final lesson = makeLesson(
      id: 'L1',
      subjectName: 'History',
      updatedAt: DateTime.utc(2026, 9, 1),
    );
    lesson.profileId = 'default';

    ScheduleProvider.stampImportedLessons(
      [lesson],
      profileId: 'seminar',
      updatedAt: DateTime.utc(2026, 9, 29, 15),
    );

    expect(lesson.profileId, 'seminar');
    expect(lesson.updatedAt, DateTime.utc(2026, 9, 29, 15));
  });
}
