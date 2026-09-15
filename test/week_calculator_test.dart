import 'package:flutter_test/flutter_test.dart';
import 'package:smart_schedule/models/lesson.dart';
import 'package:smart_schedule/services/week_calculator.dart';

void main() {
  group('WeekCalculator.mondayOfWeekContaining', () {
    test('returns the same date when already a Monday', () {
      final monday = DateTime(2025, 9, 1); // known Monday, see below.
      expect(WeekCalculator.mondayOfWeekContaining(monday), monday);
    });

    test('September 1st 2024 is a Sunday -> Monday is August 26th', () {
      // 2024-01-01 is a well-known Monday; 2024 is a leap year, and
      // Jan1 -> Sep1 spans 244 days (31+29+31+30+31+30+31+31),
      // 244 % 7 == 6, so Sep1 2024 = Monday + 6 = Sunday.
      final sept1 = DateTime(2024, 9, 1);
      expect(sept1.weekday, DateTime.sunday);
      expect(
        WeekCalculator.mondayOfWeekContaining(sept1),
        DateTime(2024, 8, 26),
      );
    });

    test('September 1st 2029 is a Saturday -> Monday is August 27th', () {
      final sept1 = DateTime(2029, 9, 1);
      expect(sept1.weekday, DateTime.saturday);
      expect(
        WeekCalculator.mondayOfWeekContaining(sept1),
        DateTime(2029, 8, 27),
      );
    });

    test('ignores time-of-day component', () {
      // 2024-08-29 (Thursday) is in the same Mon..Sun week as 2024-09-01
      // (Sunday), whose Monday is 2024-08-26.
      final withTime = DateTime(2024, 8, 29, 23, 59);
      expect(
        WeekCalculator.mondayOfWeekContaining(withTime),
        DateTime(2024, 8, 26),
      );
    });
  });

  group('WeekCalculator.academicYearSeptemberFirst', () {
    test('returns this calendar year Sept 1st when today is on/after it', () {
      expect(
        WeekCalculator.academicYearSeptemberFirst(DateTime(2025, 9, 1)),
        DateTime(2025, 9, 1),
      );
      expect(
        WeekCalculator.academicYearSeptemberFirst(DateTime(2025, 10, 10)),
        DateTime(2025, 9, 1),
      );
    });

    test('returns previous calendar year Sept 1st when today is before it', () {
      expect(
        WeekCalculator.academicYearSeptemberFirst(DateTime(2025, 3, 15)),
        DateTime(2024, 9, 1),
      );
      expect(
        WeekCalculator.academicYearSeptemberFirst(DateTime(2025, 8, 31)),
        DateTime(2024, 9, 1),
      );
    });
  });

  group('WeekCalculator.currentWeek', () {
    // Reference case: Sept 1 2024 falls on a Sunday -> reference Monday is
    // 2024-08-26.
    final referenceMondaySundayCase = DateTime(2024, 8, 26);

    test('reference Monday itself is Week 1', () {
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySundayCase,
          today: referenceMondaySundayCase,
        ),
        1,
      );
    });

    test('one week later is Week 2', () {
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySundayCase,
          today: referenceMondaySundayCase.add(const Duration(days: 7)),
        ),
        2,
      );
    });

    test('two weeks later is back to Week 1', () {
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySundayCase,
          today: referenceMondaySundayCase.add(const Duration(days: 14)),
        ),
        1,
      );
    });

    test('any day within the reference week is still Week 1', () {
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySundayCase,
          today: referenceMondaySundayCase.add(
            const Duration(days: 5),
          ), // Saturday
        ),
        1,
      );
    });

    test('a date before the reference Monday still resolves correctly '
        '(virtual pre-semester weeks)', () {
      // One week before the reference Monday -> should behave like the
      // "week after" would (parity flips), i.e. Week 2.
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySundayCase,
          today: referenceMondaySundayCase.subtract(const Duration(days: 7)),
        ),
        2,
      );
      // Two weeks before -> Week 1 again.
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySundayCase,
          today: referenceMondaySundayCase.subtract(const Duration(days: 14)),
        ),
        1,
      );
      // One day before the reference Monday (still inside the "previous"
      // virtual week) -> Week 2.
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySundayCase,
          today: referenceMondaySundayCase.subtract(const Duration(days: 1)),
        ),
        2,
      );
    });

    test('manualOverride short-circuits the computed value', () {
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySundayCase,
          today: referenceMondaySundayCase.add(
            const Duration(days: 7),
          ), // would be Week 2
          manualOverride: 1,
        ),
        1,
      );
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySundayCase,
          today: referenceMondaySundayCase, // would be Week 1
          manualOverride: 2,
        ),
        2,
      );
    });

    // Second reference case: Sept 1 2029 falls on a Saturday -> reference
    // Monday is 2029-08-27.
    final referenceMondaySaturdayCase = DateTime(2029, 8, 27);

    test('Saturday Sept-1 case: reference Monday is Week 1, +7d is Week 2', () {
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySaturdayCase,
          today: referenceMondaySaturdayCase,
        ),
        1,
      );
      expect(
        WeekCalculator.currentWeek(
          referenceMonday: referenceMondaySaturdayCase,
          today: referenceMondaySaturdayCase.add(const Duration(days: 7)),
        ),
        2,
      );
    });
  });

  group('WeekCalculator.isLessonActiveOnWeek', () {
    test('"every" is always active', () {
      expect(
        WeekCalculator.isLessonActiveOnWeek(weekType: WeekType.every, week: 1),
        isTrue,
      );
      expect(
        WeekCalculator.isLessonActiveOnWeek(weekType: WeekType.every, week: 2),
        isTrue,
      );
    });

    test('"week1" is only active on week 1', () {
      expect(
        WeekCalculator.isLessonActiveOnWeek(weekType: WeekType.week1, week: 1),
        isTrue,
      );
      expect(
        WeekCalculator.isLessonActiveOnWeek(weekType: WeekType.week1, week: 2),
        isFalse,
      );
    });

    test('"week2" is only active on week 2', () {
      expect(
        WeekCalculator.isLessonActiveOnWeek(weekType: WeekType.week2, week: 1),
        isFalse,
      );
      expect(
        WeekCalculator.isLessonActiveOnWeek(weekType: WeekType.week2, week: 2),
        isTrue,
      );
    });
  });
}
