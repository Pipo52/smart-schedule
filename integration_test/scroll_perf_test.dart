import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_schedule/firebase_options.dart';
import 'package:smart_schedule/l10n/generated/app_localizations.dart';
import 'package:smart_schedule/models/lesson.dart';
import 'package:smart_schedule/providers/auth_provider.dart';
import 'package:smart_schedule/providers/exam_provider.dart';
import 'package:smart_schedule/providers/profile_provider.dart';
import 'package:smart_schedule/providers/schedule_exception_provider.dart';
import 'package:smart_schedule/providers/schedule_provider.dart';
import 'package:smart_schedule/providers/semester_period_provider.dart';
import 'package:smart_schedule/providers/settings_provider.dart';
import 'package:smart_schedule/providers/task_provider.dart';
import 'package:smart_schedule/screens/root_shell.dart';
import 'package:smart_schedule/services/hive_service.dart';
import 'package:smart_schedule/widgets/lesson_card.dart';

const _homeScrollKey = Key('home_scroll_view');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeScreen scroll frame timings', (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await HiveService.init();
    await HiveService.ensureDefaultProfile();
    await _seedLessonsIfNeeded();

    await tester.pumpWidget(const _ScrollPerfApp());

    final scrollFinder = find.byKey(_homeScrollKey);
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );
    } catch (_) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(scrollFinder, findsOneWidget);

    if (find.byType(LessonCard).evaluate().length < 8) {
      final schedule = tester.element(scrollFinder).read<ScheduleProvider>();
      await schedule.saveLessons(_fakeLessons(count: 20));
      await tester.pump();
    }

    await binding.traceAction(
      () async {
        for (var i = 0; i < 5; i++) {
          await tester.fling(scrollFinder, const Offset(0, -600), 3000);
          await tester.pump();
        }
        try {
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 15),
          );
        } catch (_) {
          await tester.pump(const Duration(seconds: 1));
        }
      },
      reportKey: 'scrolling_summary',
    );
  });
}

Future<void> _seedLessonsIfNeeded() async {
  final weekday = _homeWeekday();
  final existing = HiveService.lessonsBox.values
      .where((lesson) => lesson.weekday == weekday)
      .length;
  if (existing >= 20) return;
  final lessons = _fakeLessons(count: 20, weekday: weekday);
  for (final lesson in lessons) {
    await HiveService.lessonsBox.put(lesson.id, lesson);
  }
}

int _homeWeekday() {
  final today = DateTime.now().weekday;
  return today >= 1 && today <= 6 ? today : 1;
}

List<Lesson> _fakeLessons({required int count, int? weekday}) {
  final day = weekday ?? _homeWeekday();
  return List<Lesson>.generate(count, (i) {
    final hour = 8 + (i % 10);
    final start = '${hour.toString().padLeft(2, '0')}:00';
    final endHour = hour + 1;
    final end = '${endHour.toString().padLeft(2, '0')}:00';
    return Lesson(
      id: 'scroll-perf-$i',
      subjectName: 'Perf Subject ${i + 1}',
      type: LessonType.values[i % LessonType.values.length],
      room: 'R${100 + i}',
      lecturer: 'Lecturer $i',
      startTime: start,
      endTime: end,
      weekday: day,
      weekType: WeekType.every,
      profileId: 'default',
      reminderEnabled: false,
    );
  });
}

class _ScrollPerfApp extends StatelessWidget {
  const _ScrollPerfApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, ProfileProvider>(
          create: (context) =>
              ProfileProvider(settings: context.read<SettingsProvider>()),
          update: (context, settings, previous) {
            final provider = previous ?? ProfileProvider(settings: settings);
            provider.updateSettings(settings);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<
          ProfileProvider,
          SettingsProvider,
          ScheduleProvider
        >(
          create: (context) => ScheduleProvider(
            settings: context.read<SettingsProvider>(),
            profileId: context.read<ProfileProvider>().activeProfileId,
          ),
          update: (context, profile, settings, previous) {
            final provider =
                previous ??
                ScheduleProvider(
                  settings: settings,
                  profileId: profile.activeProfileId,
                );
            provider.updateSettings(settings);
            provider.updateProfileId(profile.activeProfileId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<ProfileProvider, TaskProvider>(
          create: (context) => TaskProvider(
            profileId: context.read<ProfileProvider>().activeProfileId,
          ),
          update: (context, profile, previous) {
            final provider =
                previous ?? TaskProvider(profileId: profile.activeProfileId);
            provider.updateProfileId(profile.activeProfileId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<ProfileProvider, ExamProvider>(
          create: (context) => ExamProvider(
            profileId: context.read<ProfileProvider>().activeProfileId,
          ),
          update: (context, profile, previous) {
            final provider =
                previous ?? ExamProvider(profileId: profile.activeProfileId);
            provider.updateProfileId(profile.activeProfileId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<ProfileProvider, SemesterPeriodProvider>(
          create: (context) => SemesterPeriodProvider(
            profileId: context.read<ProfileProvider>().activeProfileId,
          ),
          update: (context, profile, previous) {
            final provider =
                previous ??
                SemesterPeriodProvider(profileId: profile.activeProfileId);
            provider.updateProfileId(profile.activeProfileId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<ProfileProvider, ScheduleExceptionProvider>(
          create: (context) => ScheduleExceptionProvider(
            profileId: context.read<ProfileProvider>().activeProfileId,
          ),
          update: (context, profile, previous) {
            final provider =
                previous ??
                ScheduleExceptionProvider(profileId: profile.activeProfileId);
            provider.updateProfileId(profile.activeProfileId);
            return provider;
          },
        ),
      ],
      child: const _ScrollPerfView(),
    );
  }
}

class _ScrollPerfView extends StatelessWidget {
  const _ScrollPerfView();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      scrollBehavior: const _NoOverscrollBehavior(),
      themeMode: settings.themeMode,
      theme: ThemeData(
        colorScheme: lightColorScheme,
        textTheme: ThemeData.light().textTheme,
        scaffoldBackgroundColor: const Color(0xFFF8F9FD),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        textTheme: ThemeData.dark().textTheme,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const RootShell(),
    );
  }
}

class _NoOverscrollBehavior extends MaterialScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
