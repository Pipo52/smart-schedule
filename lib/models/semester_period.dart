import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'semester_period.g.dart';

@HiveType(typeId: 11)
enum SemesterPeriodType {
  @HiveField(0)
  study,
  @HiveField(1)
  exam,
  @HiveField(2)
  holiday,
  @HiveField(3)
  retake,
  @HiveField(4)
  publicHoliday,
  @HiveField(5)
  other,
}

@HiveType(typeId: 12)
class SemesterPeriod extends HiveObject {
  SemesterPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.profileId,
    this.colorValue,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Начало периода (включительно), нормализовано до полуночи.
  @HiveField(2)
  DateTime startDate;

  /// Конец периода (включительно), нормализовано до полуночи.
  @HiveField(3)
  DateTime endDate;

  @HiveField(4)
  SemesterPeriodType type;

  @HiveField(5)
  String profileId;

  /// Необязательный пользовательский цвет в формате 0xAARRGGBB.
  /// Если null — используется цвет по умолчанию из SemesterPeriodType.
  @HiveField(6)
  int? colorValue;

  SemesterPeriod copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    SemesterPeriodType? type,
    String? profileId,
    int? colorValue,
    bool clearColor = false,
  }) {
    return SemesterPeriod(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      profileId: profileId ?? this.profileId,
      colorValue: clearColor ? null : (colorValue ?? this.colorValue),
    );
  }
}

/// Цвета по умолчанию для каждого типа периода (вдохновлено календарём Vilnius Tech).
extension SemesterPeriodTypeColor on SemesterPeriodType {
  Color get defaultColor => switch (this) {
    SemesterPeriodType.study => const Color(0xFF5C6BC0),
    SemesterPeriodType.exam => const Color(0xFF7B1FA2),
    SemesterPeriodType.holiday => const Color(0xFF43A047),
    SemesterPeriodType.retake => const Color(0xFFFFA726),
    SemesterPeriodType.publicHoliday => const Color(0xFFE53935),
    SemesterPeriodType.other => const Color(0xFF78909C),
  };
}
