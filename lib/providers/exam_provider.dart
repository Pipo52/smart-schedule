import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/exam.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class ExamProvider extends ChangeNotifier {
  ExamProvider() {
    _load();
  }

  final Box<Exam> _box = HiveService.examsBox;
  List<Exam> _exams = <Exam>[];

  List<Exam> get exams => List.unmodifiable(_exams);

  void _load() {
    _exams = _box.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Exam> get upcoming =>
      _exams.where((e) => e.date.isAfter(DateTime.now())).toList();

  Future<void> saveExam(Exam exam) async {
    await _box.put(exam.id, exam);
    _load();
    notifyListeners();
    await NotificationService.instance.scheduleExamNotifications(exam);
  }

  Future<void> deleteExam(String id) async {
    await NotificationService.instance.cancelExamNotifications(id);
    await _box.delete(id);
    _load();
    notifyListeners();
  }

  Future<void> linkTask(String examId, String taskId) async {
    final exam = _box.get(examId);
    if (exam == null || exam.revisionTasks.contains(taskId)) return;
    exam.revisionTasks = [...exam.revisionTasks, taskId];
    await exam.save();
    _load();
    notifyListeners();
  }

  Future<void> unlinkTask(String examId, String taskId) async {
    final exam = _box.get(examId);
    if (exam == null) return;
    exam.revisionTasks = exam.revisionTasks
        .where((id) => id != taskId)
        .toList();
    await exam.save();
    _load();
    notifyListeners();
  }

  /// Re-reads exams from the box (used right after an import).
  void reloadFromBox() {
    _load();
    notifyListeners();
  }
}
