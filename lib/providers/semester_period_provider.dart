import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../models/semester_period.dart';
import '../services/hive_service.dart';

class SemesterPeriodProvider extends ChangeNotifier {
  SemesterPeriodProvider({required String profileId}) : _profileId = profileId {
    _load();
  }

  final Box<SemesterPeriod> _box = HiveService.periodsBox;
  String _profileId;
  List<SemesterPeriod> _periods = [];

  List<SemesterPeriod> get periods => List.unmodifiable(_periods);

  void updateProfileId(String id) {
    if (_profileId == id) return;
    _profileId = id;
    _load();
    notifyListeners();
  }

  void _load() {
    _periods = _box.values.where((p) => p.profileId == _profileId).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Возвращает тип периода для конкретной даты (или null если дата не входит
  /// ни в один период).
  SemesterPeriodType? periodTypeForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    for (final period in _periods) {
      final start = DateTime(
        period.startDate.year,
        period.startDate.month,
        period.startDate.day,
      );
      final end = DateTime(
        period.endDate.year,
        period.endDate.month,
        period.endDate.day,
      );
      if (!normalized.isBefore(start) && !normalized.isAfter(end)) {
        return period.type;
      }
    }
    return null;
  }

  /// Возвращает цвет для конкретной даты, включая пользовательский цвет.
  Color? colorForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    for (final period in _periods) {
      final start = DateTime(
        period.startDate.year,
        period.startDate.month,
        period.startDate.day,
      );
      final end = DateTime(
        period.endDate.year,
        period.endDate.month,
        period.endDate.day,
      );
      if (!normalized.isBefore(start) && !normalized.isAfter(end)) {
        return period.colorValue != null
            ? Color(period.colorValue!)
            : period.type.defaultColor;
      }
    }
    return null;
  }

  Future<void> savePeriod(SemesterPeriod period) async {
    await _box.put(period.id, period);
    _load();
    notifyListeners();
  }

  Future<void> deletePeriod(String id) async {
    await _box.delete(id);
    _load();
    notifyListeners();
  }

  void reloadFromBox() {
    _load();
    notifyListeners();
  }
}
