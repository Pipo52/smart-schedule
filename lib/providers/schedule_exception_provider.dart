import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../models/schedule_exception.dart';
import '../services/cloud_write_reporter.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../services/schedule_widget_service.dart';
import '../services/sync_clock.dart';

class ScheduleExceptionProvider extends ChangeNotifier {
  ScheduleExceptionProvider({required String profileId})
    : _profileId = profileId {
    _load();
  }

  final Box<ScheduleException> _box = HiveService.exceptionsBox;
  String _profileId;
  String? _uid;
  List<ScheduleException> _exceptions = [];
  List<ScheduleException> _exceptionsView = const [];
  Set<String> _cancelledKeys = const {};
  Map<String, ScheduleException> _modifications = const {};
  Map<String, List<ScheduleException>> _exceptionsByDate = const {};

  List<ScheduleException> get exceptions => _exceptionsView;

  String? get _effectiveUid => _uid ?? FirebaseAuth.instance.currentUser?.uid;

  void updateUid(String? uid) {
    _uid = uid;
  }

  void updateProfileId(String id) {
    if (_profileId == id) return;
    _profileId = id;
    _load();
    notifyListeners();
  }

  void _load() {
    _exceptions = _box.values.where((e) => e.profileId == _profileId).toList();
    _exceptionsView = List.unmodifiable(_exceptions);

    final cancelledKeys = <String>{};
    final modifications = <String, ScheduleException>{};
    final byDate = <String, List<ScheduleException>>{};

    for (final exception in _exceptions) {
      final dateKey = _dateKey(exception.date);
      final lookupKey = '${exception.lessonId}|$dateKey';
      (byDate[dateKey] ??= <ScheduleException>[]).add(exception);
      if (exception.type == ExceptionType.cancelled) {
        cancelledKeys.add(lookupKey);
      } else if (exception.type == ExceptionType.modified) {
        modifications[lookupKey] = exception;
      }
    }

    _cancelledKeys = cancelledKeys;
    _modifications = modifications;
    _exceptionsByDate = {
      for (final entry in byDate.entries)
        entry.key: List.unmodifiable(entry.value),
    };
    unawaited(ScheduleWidgetService.refresh(_profileId));
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  static String _lookupKey(String lessonId, DateTime date) =>
      '$lessonId|${_dateKey(date)}';

  /// Проверяет, отменена ли конкретная пара на конкретную дату.
  bool isCancelled(String lessonId, DateTime date) =>
      _cancelledKeys.contains(_lookupKey(lessonId, date));

  /// Возвращает исключение типа modified для конкретной пары на конкретную дату.
  ScheduleException? getModification(String lessonId, DateTime date) =>
      _modifications[_lookupKey(lessonId, date)];

  /// Возвращает все исключения на конкретную дату.
  List<ScheduleException> exceptionsForDate(DateTime date) =>
      _exceptionsByDate[_dateKey(date)] ?? const [];

  Future<void> saveException(ScheduleException exception) async {
    exception.updatedAt = SyncClock.now();
    await _box.put(exception.id, exception);
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      await CloudWriteReporter.instance.guard(
        PendingCloudWrite(PendingCloudWrite.exception, exception.id),
        () => FirestoreService.instance.saveException(uid, exception),
      );
    }
  }

  Future<void> deleteException(String id) async {
    await _box.delete(id);
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      await CloudWriteReporter.instance.guard(
        PendingCloudWrite(PendingCloudWrite.exception, id, delete: true),
        () => FirestoreService.instance.deleteException(uid, id),
      );
    }
  }

  /// Удаляет все исключения для конкретной пары (используется при удалении пары целиком).
  Future<void> deleteAllForLesson(String lessonId) async {
    final toDelete = _exceptions.where((e) => e.lessonId == lessonId).toList();
    for (final e in toDelete) {
      await _box.delete(e.id);
    }
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      for (final exception in toDelete) {
        await CloudWriteReporter.instance.guard(
          PendingCloudWrite(
            PendingCloudWrite.exception,
            exception.id,
            delete: true,
          ),
          () => FirestoreService.instance.deleteException(uid, exception.id),
        );
      }
    }
  }

  void reloadFromBox() {
    _load();
    notifyListeners();
  }
}
