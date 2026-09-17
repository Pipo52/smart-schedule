import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../models/task.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({required String profileId}) : _profileId = profileId {
    _load();
  }

  String _profileId;
  final Box<Task> _box = HiveService.tasksBox;
  List<Task> _tasks = <Task>[];
  List<Task> _tasksView = const [];
  List<Task> _pending = const [];
  List<Task> _dueTodayOrOverdue = const [];
  Map<String, List<Task>> _tasksByExam = const {};

  List<Task> get tasks => _tasksView;

  List<Task> get pending => _pending;

  /// Overdue or due today (used on the Home screen).
  List<Task> get dueTodayOrOverdue => _dueTodayOrOverdue;

  void _load() {
    _tasks = _box.values.where((task) => task.profileId == _profileId).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    _tasksView = List.unmodifiable(_tasks);

    final pending = <Task>[];
    final dueTodayOrOverdue = <Task>[];
    final tasksByExam = <String, List<Task>>{};
    final endOfToday = _endOfDay(DateTime.now());

    for (final task in _tasks) {
      if (!task.isDone) {
        pending.add(task);
        if (!task.dueDate.isAfter(endOfToday)) {
          dueTodayOrOverdue.add(task);
        }
      }
      final examId = task.linkedExamId;
      if (examId != null) {
        (tasksByExam[examId] ??= <Task>[]).add(task);
      }
    }

    _pending = List.unmodifiable(pending);
    _dueTodayOrOverdue = List.unmodifiable(dueTodayOrOverdue);
    _tasksByExam = {
      for (final entry in tasksByExam.entries)
        entry.key: List.unmodifiable(entry.value),
    };
  }

  void updateProfileId(String id) {
    if (_profileId == id) return;
    _profileId = id;
    _load();
    notifyListeners();
  }

  List<Task> tasksForExam(String examId) => _tasksByExam[examId] ?? const [];

  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  Future<void> saveTask(Task task) async {
    task.profileId = _profileId;
    await _box.put(task.id, task);
    _load();
    notifyListeners();
    if (task.reminderOffsetMinutes != null && !task.isDone) {
      await NotificationService.instance.scheduleTaskNotification(task);
    } else {
      await NotificationService.instance.cancelTaskNotification(task.id);
    }
  }

  Future<void> deleteTask(String id) async {
    await NotificationService.instance.cancelTaskNotification(id);
    await _box.delete(id);
    _load();
    notifyListeners();
  }

  Future<void> toggleDone(Task task) async {
    task.isDone = !task.isDone;
    await task.save();
    if (task.isDone) {
      await NotificationService.instance.cancelTaskNotification(task.id);
    } else if (task.reminderOffsetMinutes != null) {
      await NotificationService.instance.scheduleTaskNotification(task);
    }
    _load();
    notifyListeners();
  }

  /// Re-reads tasks from the box (used right after an import).
  void reloadFromBox() {
    _load();
    notifyListeners();
  }
}
