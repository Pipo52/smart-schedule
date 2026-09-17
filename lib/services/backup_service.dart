import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/lesson.dart';
import '../models/task.dart';
import 'backup_file_io.dart'
    if (dart.library.js_interop) 'backup_file_web.dart';
import 'hive_service.dart';

/// Exports/imports the entire local database (lessons, tasks, exams,
/// settings) as a single JSON file. This is the only way to move data
/// between devices, since the app has no cloud backend.
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
    if (kIsWeb) {
      throw UnsupportedError('Backup import is not available on web.');
    }
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty) return false;
    final path = files.first.path;
    if (path == null) return false;

    final content = await readBackupFile(path);
    final Map<String, dynamic> data =
        jsonDecode(content) as Map<String, dynamic>;
    await importFromJson(data);
    return true;
  }

  static Future<void> importFromJson(Map<String, dynamic> data) async {
    await HiveService.lessonsBox.clear();
    await HiveService.tasksBox.clear();
    await HiveService.examsBox.clear();

    for (final raw in (data['lessons'] as List? ?? const [])) {
      final lesson = _lessonFromJson(raw as Map<String, dynamic>);
      await HiveService.lessonsBox.put(lesson.id, lesson);
    }
    for (final raw in (data['tasks'] as List? ?? const [])) {
      final task = _taskFromJson(raw as Map<String, dynamic>);
      await HiveService.tasksBox.put(task.id, task);
    }
    for (final raw in (data['exams'] as List? ?? const [])) {
      final exam = _examFromJson(raw as Map<String, dynamic>);
      await HiveService.examsBox.put(exam.id, exam);
    }
    final settingsRaw = data['settings'] as Map<String, dynamic>?;
    if (settingsRaw != null) {
      final imported = _settingsFromJson(settingsRaw);
      await HiveService.settingsBox.put(HiveService.settingsKey, imported);
    }
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
}
