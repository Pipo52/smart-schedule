import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_schedule/l10n/generated/app_localizations.dart';
import 'package:smart_schedule/models/lesson.dart';
import 'package:smart_schedule/widgets/lesson_card.dart';

void main() {
  final sampleLesson = Lesson(
    id: 'test_lesson_1',
    subjectName: 'Вища математика',
    type: LessonType.lecture,
    room: '402',
    lecturer: 'Проф. Іваненко І.І.',
    startTime: '08:30',
    endTime: '10:05',
    weekday: 1,
    weekType: WeekType.every,
    profileId: 'default',
  );

  group('LessonCard Live Indicators', () {
    testWidgets('renders normally without progress bar when isCurrent is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uk'),
          home: Scaffold(
            body: LessonCard(lesson: sampleLesson),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Вища математика'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('renders progress bar when isCurrent is true and progress is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uk'),
          home: Scaffold(
            body: LessonCard(
              lesson: sampleLesson,
              isCurrent: true,
              progress: 0.55,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, closeTo(0.55, 0.001));
    });

    testWidgets('renders trailingBadge inline with long subjectName without overflow',
        (tester) async {
      final longLesson = Lesson(
        id: 'test_long',
        subjectName: 'Algorithms and Data Structures (FMISB23204)',
        type: LessonType.practical,
        room: '501',
        lecturer: 'Romanas Tumasonis',
        startTime: '14:30',
        endTime: '16:05',
        weekday: 5,
        weekType: WeekType.every,
        profileId: 'default',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: LessonCard(
                lesson: longLesson,
                isCurrent: true,
                progress: 0.2,
                trailingBadge: const Text('1h 31m left'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Algorithms and Data Structures (FMISB23204)'), findsOneWidget);
      expect(find.text('1h 31m left'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Localization Formatting Tests', () {
    testWidgets('formats short remaining time in Ukrainian correctly',
        (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uk'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n.lessonTimeRemaining(25), 'До кінця: 25 хв');
      expect(l10n.lessonTimeRemainingHours(1, 30), 'До кінця: 1 год 30 хв');
      expect(l10n.lessonTimeRemainingHoursOnly(2), 'До кінця: 2 год');
    });

    testWidgets('formats remaining time in Russian correctly', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n.lessonTimeRemaining(15), 'До конца: 15 мин');
      expect(l10n.lessonTimeRemainingHours(1, 10), 'До конца: 1 ч 10 мин');
      expect(l10n.lessonTimeRemainingHoursOnly(1), 'До конца: 1 ч');
    });

    testWidgets('formats remaining time in English correctly', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n.lessonTimeRemaining(40), '40m left');
      expect(l10n.lessonTimeRemainingHours(1, 15), '1h 15m left');
      expect(l10n.lessonTimeRemainingHoursOnly(2), '2h left');
    });
  });
}
