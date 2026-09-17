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

  List<ScheduleException> get exceptions => List.unmodifiable(_exceptions);

  void updateProfileId(String id) {
    if (_profileId == id) return;
    _profileId = id;
    _load();
    notifyListeners();
  }

  void _load() {
    _exceptions = _box.values.where((e) => e.profileId == _profileId).toList();
  }

  /// Нормализует дату до полуночи для корректного сравнения.
  static DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Проверяет, отменена ли конкретная пара на конкретную дату.
  bool isCancelled(String lessonId, DateTime date) {
    final d = _normalize(date);
    return _exceptions.any(
      (e) =>
          e.lessonId == lessonId &&
          e.type == ExceptionType.cancelled &&
          _normalize(e.date) == d,
    );
  }

  /// Возвращает исключение типа modified для конкретной пары на конкретную дату.
  ScheduleException? getModification(String lessonId, DateTime date) {
    final d = _normalize(date);
    return _exceptions.cast<ScheduleException?>().firstWhere(
      (e) =>
          e!.lessonId == lessonId &&
          e.type == ExceptionType.modified &&
          _normalize(e.date) == d,
      orElse: () => null,
    );
  }

  /// Возвращает все исключения на конкретную дату.
  List<ScheduleException> exceptionsForDate(DateTime date) {
    final d = _normalize(date);
    return _exceptions.where((e) => _normalize(e.date) == d).toList();
  }

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
