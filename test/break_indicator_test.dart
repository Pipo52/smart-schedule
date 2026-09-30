import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_schedule/l10n/generated/app_localizations.dart';
import 'package:smart_schedule/utils/date_format_cache.dart';
import 'package:smart_schedule/widgets/break_indicator.dart';

void main() {
  group('BreakIndicator Widget Tests', () {
    testWidgets('renders short break (<60 min) correctly with coffee icon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('uk'),
          home: Scaffold(
            body: BreakIndicator(durationMinutes: 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Перерва 20 хв'), findsOneWidget);
      expect(find.byIcon(Icons.coffee_outlined), findsOneWidget);
    });

    testWidgets('renders long break (>= 60 min with remainder) with hourglass icon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('uk'),
          home: Scaffold(
            body: BreakIndicator(durationMinutes: 90),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Вікно 1 год 30 хв'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });

    testWidgets('renders long break with hours only (minutes == 0)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('uk'),
          home: Scaffold(
            body: BreakIndicator(durationMinutes: 120),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Вікно 2 год'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });

    testWidgets('renders English localization correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: BreakIndicator(durationMinutes: 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('15 min break'), findsOneWidget);
    });

    testWidgets('renders nothing when duration is 0 or negative',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('uk'),
          home: Scaffold(
            body: BreakIndicator(durationMinutes: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('DateFormatCache Tests', () {
    test('returns the same instance for repeated calls with same locale', () {
      final formatter1 = DateFormatCache.yMMMdHm('en');
      final formatter2 = DateFormatCache.yMMMdHm('en');
      expect(identical(formatter1, formatter2), isTrue);

      final dt = DateTime(2026, 9, 24, 14, 30);
      final formatted = formatter1.format(dt);
      expect(formatted.isNotEmpty, isTrue);
    });
  });
}
