import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../models/schedule_exception.dart';
import '../services/hive_service.dart';

class ScheduleExceptionProvider extends ChangeNotifier {
  ScheduleExceptionProvider({required String profileId})
    : _profileId = profileId {
    _load();
  }

  final Box<ScheduleException> _box = HiveService.exceptionsBox;
  String _profileId;
  List<ScheduleException> _exceptions = [];
  List<ScheduleException> _exceptionsView = const [];
  Set<String> _cancelledKeys = const {};
  Map<String, ScheduleException> _modifications = const {};
  Map<String, List<ScheduleException>> _exceptionsByDate = const {};

  List<ScheduleException> get exceptions => _exceptionsView;

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
    await _box.put(exception.id, exception);
    _load();
    notifyListeners();
  }

  Future<void> deleteException(String id) async {
    await _box.delete(id);
    _load();
    notifyListeners();
  }

  /// Удаляет все исключения для конкретной пары (используется при удалении пары целиком).
  Future<void> deleteAllForLesson(String lessonId) async {
    final toDelete = _exceptions.where((e) => e.lessonId == lessonId).toList();
    for (final e in toDelete) {
      await _box.delete(e.id);
    }
    _load();
    notifyListeners();
  }

  void reloadFromBox() {
    _load();
    notifyListeners();
  }
}
