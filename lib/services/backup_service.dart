import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/lesson.dart';
import '../models/schedule_exception.dart';
import '../models/schedule_profile.dart';
import '../models/semester_period.dart';
import '../models/task.dart';
import 'backup_file_io.dart'
    if (dart.library.js_interop) 'backup_file_web.dart';
import 'hive_service.dart';

/// Exports/imports the entire local database (lessons, tasks, exams,
/// profiles, periods, exceptions, settings) as a single JSON file. This is
/// the only way to move data between devices, since the app has no cloud
/// backend.
class BackupService {
  BackupService._();

  static const int _formatVersion = 1;

  // ---------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------

  static Map<String, dynamic> buildExportJson() {
    return <String, dynamic>{
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'lessons': HiveService.lessonsBox.values.map(_lessonToJson).toList(),
      'tasks': HiveService.tasksBox.values.map(_taskToJson).toList(),
      'exams': HiveService.examsBox.values.map(_examToJson).toList(),
      'profiles': HiveService.profilesBox.values.map(_profileToJson).toList(),
      'periods': HiveService.periodsBox.values.map(_periodToJson).toList(),
      'exceptions': HiveService.exceptionsBox.values
          .map(_exceptionToJson)
          .toList(),
      'settings': _settingsToJson(
        HiveService.settingsBox.get(HiveService.settingsKey),
      ),
    };
  }

  /// Writes the export JSON to a temporary file and returns its path.
  static Future<String> writeExportFile() async {
    if (kIsWeb) {
      throw UnsupportedError('Backup export is not available on web.');
    }
    final json = const JsonEncoder.withIndent('  ').convert(buildExportJson());
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return writeBackupFile(
      json,
      filename: 'smart_schedule_backup_$timestamp.json',
    );
  }

  /// Writes the export file and opens the system share sheet.
  static Future<void> shareExport() async {
    if (kIsWeb) {
      throw UnsupportedError('Backup export is not available on web.');
    }
    final filePath = await writeExportFile();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)], text: 'Smart Schedule backup'),
    );
  }

  // ---------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------

  /// Opens a file picker for a `.json` file and imports it, replacing all
  /// existing local data. Returns `true` if a file was picked and imported.
  static Future<bool> pickAndImport() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty) return false;
    final file = files.first;
    final bytes = await file.readAsBytes();
    final content = utf8.decode(bytes);

    final Map<String, dynamic> data =
        jsonDecode(content) as Map<String, dynamic>;
    await importFromJson(data);
    return true;
  }

  static Future<void> importFromJson(Map<String, dynamic> data) async {
    final lessons = <Lesson>[];
    for (final raw in (data['lessons'] as List? ?? const [])) {
      lessons.add(_lessonFromJson(Map<String, dynamic>.from(raw as Map)));
    }
    final tasks = <Task>[];
    for (final raw in (data['tasks'] as List? ?? const [])) {
      tasks.add(_taskFromJson(Map<String, dynamic>.from(raw as Map)));
    }
    final exams = <Exam>[];
    for (final raw in (data['exams'] as List? ?? const [])) {
      exams.add(_examFromJson(Map<String, dynamic>.from(raw as Map)));
    }
    final profiles = <ScheduleProfile>[];
    for (final raw in (data['profiles'] as List? ?? const [])) {
      profiles.add(_profileFromJson(Map<String, dynamic>.from(raw as Map)));
    }
    final periods = <SemesterPeriod>[];
    for (final raw in (data['periods'] as List? ?? const [])) {
      periods.add(_periodFromJson(Map<String, dynamic>.from(raw as Map)));
    }
    final exceptions = <ScheduleException>[];
    for (final raw in (data['exceptions'] as List? ?? const [])) {
      exceptions.add(_exceptionFromJson(Map<String, dynamic>.from(raw as Map)));
    }
    final settingsRaw = data['settings'] as Map?;
    final importedSettings = settingsRaw == null
        ? null
        : _settingsFromJson(Map<String, dynamic>.from(settingsRaw));

    await HiveService.lessonsBox.clear();
    await HiveService.tasksBox.clear();
    await HiveService.examsBox.clear();
    await HiveService.profilesBox.clear();
    await HiveService.periodsBox.clear();
    await HiveService.exceptionsBox.clear();

    for (final lesson in lessons) {
      await HiveService.lessonsBox.put(lesson.id, lesson);
    }
    for (final task in tasks) {
      await HiveService.tasksBox.put(task.id, task);
    }
    for (final exam in exams) {
      await HiveService.examsBox.put(exam.id, exam);
    }
    for (final profile in profiles) {
      await HiveService.profilesBox.put(profile.id, profile);
    }
    for (final period in periods) {
      await HiveService.periodsBox.put(period.id, period);
    }
    for (final exception in exceptions) {
      await HiveService.exceptionsBox.put(exception.id, exception);
    }
    if (importedSettings != null) {
      await HiveService.settingsBox.put(
        HiveService.settingsKey,
        importedSettings,
      );
    }
    await HiveService.ensureDefaultProfile();
  }

  // ---------------------------------------------------------------------
  // (De)serialization helpers
  // ---------------------------------------------------------------------

  static Map<String, dynamic> _lessonToJson(Lesson l) => <String, dynamic>{
    'id': l.id,
    'subjectName': l.subjectName,
    'type': l.type.name,
    'room': l.room,
    'lecturer': l.lecturer,
    'startTime': l.startTime,
    'endTime': l.endTime,
    'weekday': l.weekday,
    'weekType': l.weekType.name,
    'notes': l.notes,
    'reminderEnabled': l.reminderEnabled,
    'profileId': l.profileId,
  };

  static Lesson _lessonFromJson(Map<String, dynamic> j) => Lesson(
    id: j['id'] as String,
    subjectName: j['subjectName'] as String,
    type: LessonType.values.byName(j['type'] as String),
    room: j['room'] as String? ?? '',
    lecturer: j['lecturer'] as String? ?? '',
    startTime: j['startTime'] as String,
    endTime: j['endTime'] as String,
    weekday: j['weekday'] as int,
    weekType: WeekType.values.byName(j['weekType'] as String),
    notes: j['notes'] as String?,
    reminderEnabled: j['reminderEnabled'] as bool? ?? true,
    profileId: j['profileId'] as String? ?? 'default',
  );

  static Map<String, dynamic> _taskToJson(Task t) => <String, dynamic>{
    'id': t.id,
    'title': t.title,
    'linkedSubject': t.linkedSubject,
    'description': t.description,
    'dueDate': t.dueDate.toIso8601String(),
    'priority': t.priority.name,
    'isDone': t.isDone,
    'reminderOffsetMinutes': t.reminderOffsetMinutes,
    'linkedExamId': t.linkedExamId,
    'profileId': t.profileId,
  };

  static Task _taskFromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String,
    title: j['title'] as String,
    linkedSubject: j['linkedSubject'] as String?,
    description: j['description'] as String?,
    dueDate: DateTime.parse(j['dueDate'] as String),
    priority: Priority.values.byName(j['priority'] as String),
    isDone: j['isDone'] as bool? ?? false,
    reminderOffsetMinutes: j['reminderOffsetMinutes'] as int?,
    linkedExamId: j['linkedExamId'] as String?,
    profileId: j['profileId'] as String? ?? 'default',
  );

  static Map<String, dynamic> _examToJson(Exam e) => <String, dynamic>{
    'id': e.id,
    'subjectName': e.subjectName,
    'date': e.date.toIso8601String(),
    'room': e.room,
    'examType': e.examType.name,
    'notes': e.notes,
    'revisionTasks': e.revisionTasks,
    'profileId': e.profileId,
  };

  static Exam _examFromJson(Map<String, dynamic> j) => Exam(
    id: j['id'] as String,
    subjectName: j['subjectName'] as String,
    date: DateTime.parse(j['date'] as String),
    room: j['room'] as String?,
    examType: ExamType.values.byName(j['examType'] as String),
    notes: j['notes'] as String?,
    revisionTasks:
        (j['revisionTasks'] as List?)?.map((e) => e as String).toList() ??
        const [],
    profileId: j['profileId'] as String? ?? 'default',
  );

  static Map<String, dynamic>? _settingsToJson(AppSettings? s) {
    if (s == null) return null;
    return <String, dynamic>{
      'semesterReferenceDate': s.semesterReferenceDate.toIso8601String(),
      'manualWeekOverride': s.manualWeekOverride,
      'defaultLessonReminderMinutes': s.defaultLessonReminderMinutes,
      'themeMode': s.themeMode.name,
      'appLocale': s.appLocale,
      'schemaVersion': s.schemaVersion,
    };
  }

  static AppSettings _settingsFromJson(Map<String, dynamic> j) => AppSettings(
    semesterReferenceDate: DateTime.parse(j['semesterReferenceDate'] as String),
    manualWeekOverride: j['manualWeekOverride'] as int?,
    defaultLessonReminderMinutes:
        j['defaultLessonReminderMinutes'] as int? ?? 10,
    themeMode: AppThemeMode.values.byName(
      (j['themeMode'] as String?) ?? 'system',
    ),
    appLocale: j['appLocale'] as String?,
    schemaVersion: j['schemaVersion'] as int? ?? 2,
  );

  static Map<String, dynamic> _profileToJson(ScheduleProfile p) =>
      <String, dynamic>{
        'id': p.id,
        'name': p.name,
        'createdAt': p.createdAt.toIso8601String(),
        'isDefault': p.isDefault,
      };

  static ScheduleProfile _profileFromJson(Map<String, dynamic> j) =>
      ScheduleProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isDefault: j['isDefault'] as bool? ?? false,
      );

  static Map<String, dynamic> _periodToJson(SemesterPeriod p) =>
      <String, dynamic>{
        'id': p.id,
        'name': p.name,
        'startDate': p.startDate.toIso8601String(),
        'endDate': p.endDate.toIso8601String(),
        'type': p.type.name,
        'profileId': p.profileId,
        'colorValue': p.colorValue,
      };

  static SemesterPeriod _periodFromJson(Map<String, dynamic> j) =>
      SemesterPeriod(
        id: j['id'] as String,
        name: j['name'] as String,
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: DateTime.parse(j['endDate'] as String),
        type: SemesterPeriodType.values.byName(
          (j['type'] as String?) ?? 'other',
        ),
        profileId: j['profileId'] as String? ?? 'default',
        colorValue: j['colorValue'] as int?,
      );

  static Map<String, dynamic> _exceptionToJson(ScheduleException e) =>
      <String, dynamic>{
        'id': e.id,
        'lessonId': e.lessonId,
        'date': e.date.toIso8601String(),
        'type': e.type.name,
        'profileId': e.profileId,
        'newStartTime': e.newStartTime,
        'newEndTime': e.newEndTime,
        'newRoom': e.newRoom,
        'newLecturer': e.newLecturer,
        'newNotes': e.newNotes,
      };

  static ScheduleException _exceptionFromJson(Map<String, dynamic> j) =>
      ScheduleException(
        id: j['id'] as String,
        lessonId: j['lessonId'] as String,
        date: DateTime.parse(j['date'] as String),
        type: ExceptionType.values.byName(
          (j['type'] as String?) ?? 'cancelled',
        ),
        profileId: j['profileId'] as String? ?? 'default',
        newStartTime: j['newStartTime'] as String?,
        newEndTime: j['newEndTime'] as String?,
        newRoom: j['newRoom'] as String?,
        newLecturer: j['newLecturer'] as String?,
        newNotes: j['newNotes'] as String?,
      );
}
