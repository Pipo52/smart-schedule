import '../models/lesson.dart';

/// Pure, side-effect-free logic for computing the current Week 1 / Week 2
/// rotation used across the app.
///
/// Kept free of any Hive/Flutter dependency so it is trivial to unit test.
class WeekCalculator {
  const WeekCalculator._();

  /// Returns midnight of the Monday belonging to the same calendar week as
  /// [date] (Mon..Sun week). Time-of-day on [date] is ignored.
  static DateTime mondayOfWeekContaining(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    // DateTime.weekday: Monday = 1 ... Sunday = 7.
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  /// Returns September 1st of the "current" academic year relative to
  /// [today]: if [today] falls before September 1st of the calendar year it
  /// is in, the academic year is considered to have started the previous
  /// calendar year.
  static DateTime academicYearSeptemberFirst(DateTime today) {
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final septemberFirstThisYear = DateTime(today.year, 9, 1);
    if (todayDateOnly.isBefore(septemberFirstThisYear)) {
      return DateTime(today.year - 1, 9, 1);
    }
    return septemberFirstThisYear;
  }

  /// Default value for `AppSettings.semesterReferenceDate`: the Monday of
  /// the week containing September 1st of the current academic year.
  static DateTime defaultReferenceMonday({DateTime? now}) {
    final today = now ?? DateTime.now();
    return mondayOfWeekContaining(academicYearSeptemberFirst(today));
  }

  /// Core week-rotation formula.
  ///
  /// 1. If [manualOverride] is set (1 or 2), it is returned as-is; the
  ///    reference date is intentionally not touched/recomputed.
  /// 2. Otherwise the number of whole weeks between [referenceMonday] and
  ///    [today] is computed (floored, so dates *before* the reference date
  ///    correctly produce negative "virtual" week offsets), and the parity
  ///    of that count determines Week 1 vs Week 2.
  static int currentWeek({
    required DateTime referenceMonday,
    int? manualOverride,
    DateTime? today,
  }) {
    if (manualOverride != null) {
      assert(
        manualOverride == 1 || manualOverride == 2,
        'manualOverride must be 1 or 2',
      );
      return manualOverride;
    }

    final now = today ?? DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final normalizedReference = DateTime(
      referenceMonday.year,
      referenceMonday.month,
      referenceMonday.day,
    );

    final daysSince = normalizedToday.difference(normalizedReference).inDays;
    final weeksSince = (daysSince / 7).floor();

    // Dart's `%` on int already returns a non-negative result for a
    // positive divisor (Euclidean modulo), so this is correct even for
    // negative `weeksSince` (dates before the reference Monday).
    return (weeksSince % 2 == 0) ? 1 : 2;
  }

  /// Whether a lesson with the given [weekType] happens on the given
  /// [week] (1 or 2).
  static bool isLessonActiveOnWeek({
    required WeekType weekType,
    required int week,
  }) {
    switch (weekType) {
      case WeekType.every:
        return true;
      case WeekType.week1:
        return week == 1;
      case WeekType.week2:
        return week == 2;
    }
  }
}
