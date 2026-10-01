import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../models/semester_period.dart';
import '../services/cloud_write_reporter.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../services/sync_clock.dart';

class SemesterPeriodProvider extends ChangeNotifier {
  SemesterPeriodProvider({required String profileId}) : _profileId = profileId {
    _load();
  }

  final Box<SemesterPeriod> _box = HiveService.periodsBox;
  String _profileId;
  String? _uid;
  List<SemesterPeriod> _periods = [];
  List<SemesterPeriod> _periodsView = const [];
  Map<int, SemesterPeriodType> _typeByDay = const {};
  Map<int, Color> _colorByDay = const {};

  List<SemesterPeriod> get periods => _periodsView;

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

  void _load() {
    _periods = _box.values.where((p) => p.profileId == _profileId).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    _periodsView = List.unmodifiable(_periods);
    _rebuildDayLookups();
  }

  void _rebuildDayLookups() {
    final typeByDay = <int, SemesterPeriodType>{};
    final colorByDay = <int, Color>{};
    for (final period in _periods) {
      var day = DateTime(
        period.startDate.year,
        period.startDate.month,
        period.startDate.day,
      );
      final end = DateTime(
        period.endDate.year,
        period.endDate.month,
        period.endDate.day,
      );
      final color = period.colorValue != null
          ? Color(period.colorValue!)
          : period.type.defaultColor;
      while (!day.isAfter(end)) {
        final key = _dayKey(day);
        typeByDay.putIfAbsent(key, () => period.type);
        colorByDay.putIfAbsent(key, () => color);
        day = day.add(const Duration(days: 1));
      }
    }
    _typeByDay = typeByDay;
    _colorByDay = colorByDay;
  }

  static int _dayKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  /// Возвращает тип периода для конкретной даты (или null если дата не входит
  /// ни в один период).
  SemesterPeriodType? periodTypeForDate(DateTime date) =>
      _typeByDay[_dayKey(date)];

  /// Возвращает цвет для конкретной даты, включая пользовательский цвет.
  Color? colorForDate(DateTime date) => _colorByDay[_dayKey(date)];

  Future<void> savePeriod(SemesterPeriod period) async {
    period.updatedAt = SyncClock.now();
    await _box.put(period.id, period);
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      await CloudWriteReporter.instance.guard(
        PendingCloudWrite(PendingCloudWrite.period, period.id),
        () => FirestoreService.instance.savePeriod(uid, period),
      );
    }
  }

  Future<void> deletePeriod(String id) async {
    await _box.delete(id);
    _load();
    notifyListeners();
    final uid = _effectiveUid;
    if (uid != null) {
      await CloudWriteReporter.instance.guard(
        PendingCloudWrite(PendingCloudWrite.period, id, delete: true),
        () => FirestoreService.instance.deletePeriod(uid, id),
      );
    }
  }

  void reloadFromBox() {
    _load();
    notifyListeners();
  }
}
