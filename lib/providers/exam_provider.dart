import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../models/exam.dart';
import '../services/cloud_write_reporter.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../services/sync_clock.dart';
import '../services/notification_service.dart';

class ExamProvider extends ChangeNotifier {
  ExamProvider({required String profileId}) : _profileId = profileId {
    _load();
  }

  String _profileId;
  String? _uid;
  final Box<Exam> _box = HiveService.examsBox;
  List<Exam> _exams = <Exam>[];
  List<Exam> _examsView = const [];
  List<Exam> _upcoming = const [];

  List<Exam> get exams => _examsView;

  List<Exam> get upcoming => _upcoming;

  void _load() {
    _exams = _box.values.where((exam) => exam.profileId == _profileId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    _examsView = List.unmodifiable(_exams);
    final now = DateTime.now();
    _upcoming = List.unmodifiable(
      _exams.where((e) => e.date.isAfter(now)).toList(),
    );
  }

  void updateUid(String? uid) {
    _uid = uid;
  }

  String? get _effectiveUid => _uid ?? FirebaseAuth.instance.currentUser?.uid;

  void updateProfileId(String id) {
    if (_profileId == id) return;
    _profileId = id;
    _load();
    notifyListeners();
  }

  Future<void> saveExam(Exam exam) async {
    exam.profileId = _profileId;
    exam.updatedAt = SyncClock.now();
    await _box.put(exam.id, exam);
    _load();
    notifyListeners();
    await NotificationService.instance.scheduleExamNotifications(exam);
    final uid = _effectiveUid;
    if (uid != null) {
      try {
        await FirestoreService.instance.saveExam(uid, exam);
      } catch (e) {
        CloudWriteReporter.instance.report(e);
      }
    }
  }

  Future<void> deleteExam(String id) async {
    await NotificationService.instance.cancelExamNotifications(id);
    await _box.delete(id);
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      try {
        await FirestoreService.instance.deleteExam(uid, id);
      } catch (e) {
        CloudWriteReporter.instance.report(e);
      }
    }
  }

  Future<void> linkTask(String examId, String taskId) async {
    final exam = _box.get(examId);
    if (exam == null || exam.revisionTasks.contains(taskId)) return;
    exam.revisionTasks = [...exam.revisionTasks, taskId];
    exam.updatedAt = SyncClock.now();
    await exam.save();
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      try {
        await FirestoreService.instance.saveExam(uid, exam);
      } catch (e) {
        CloudWriteReporter.instance.report(e);
      }
    }
  }

  Future<void> unlinkTask(String examId, String taskId) async {
    final exam = _box.get(examId);
    if (exam == null) return;
    exam.revisionTasks = exam.revisionTasks
        .where((id) => id != taskId)
        .toList();
    exam.updatedAt = SyncClock.now();
    await exam.save();
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      try {
        await FirestoreService.instance.saveExam(uid, exam);
      } catch (e) {
        CloudWriteReporter.instance.report(e);
      }
    }
  }

  /// Re-reads exams from the box (used right after an import or cloud sync).
  void reloadFromBox() {
    _load();
    notifyListeners();
    unawaited(_rescheduleNotifications());
  }

  Future<void> _rescheduleNotifications() async {
    for (final exam in _upcoming) {
      await NotificationService.instance.scheduleExamNotifications(exam);
    }
  }
}
