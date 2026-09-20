import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/exam_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/schedule_exception_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/semester_period_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/root_shell.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await HiveService.init();
    await HiveService.ensureDefaultProfile();
    await NotificationService.instance.init();
    runApp(const SmartScheduleApp());
  } catch (error, stackTrace) {
    developer.log(
      'Startup failed',
      error: error,
      stackTrace: stackTrace,
      name: 'SmartSchedule',
    );
    runApp(_StartupErrorApp(message: error.toString()));
  }
}

class SmartScheduleApp extends StatelessWidget {
  const SmartScheduleApp({super.key});

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
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request notification permissions and top-up the scheduling window on
    // first launch, without blocking the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.requestPermissions();
      if (mounted) {
        await context.read<ScheduleProvider>().rescheduleAllNotifications();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep the rolling notification window topped up whenever the app comes
    // back to the foreground.
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.read<ScheduleProvider>().rescheduleAllNotifications();
        }
      });
    }
  }

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
      home: const AuthWrapper(),
    );
  }
}

/// Shows [AuthScreen] when signed out, or the main app ([RootShell]) once a
/// Firebase user is authenticated.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return user == null ? const AuthScreen() : const RootShell();
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Ошибка запуска\n\n$message',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
