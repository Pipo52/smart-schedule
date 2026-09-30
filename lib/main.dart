import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
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
import 'services/cloud_write_reporter.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/schedule_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    unawaited(() async {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } catch (_) {}
    }());
  }
  try {
    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      HiveService.init(),
    ]);
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
        ProxyProvider<AuthProvider, int>(
          lazy: false,
          update: (context, auth, _) {
            final uid = auth.currentUser?.uid;
            context.read<ScheduleProvider>().updateUid(uid);
            context.read<TaskProvider>().updateUid(uid);
            context.read<ExamProvider>().updateUid(uid);
            context.read<SemesterPeriodProvider>().updateUid(uid);
            context.read<ScheduleExceptionProvider>().updateUid(uid);
            context.read<ProfileProvider>().updateUid(uid);
            context.read<SettingsProvider>().updateUid(uid);
            return auth.syncEpoch;
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
  int _appliedSyncEpoch = 0;

  // ColorScheme.fromSeed() performs expensive HCT palette generation.
  // Caching as static fields means it runs exactly once per app launch
  // instead of on every SettingsProvider.notifyListeners() rebuild.
  static final ThemeData _lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
    textTheme: ThemeData.light().textTheme,
    scaffoldBackgroundColor: const Color(0xFFF8F9FD),
    useMaterial3: true,
  );
  static final ThemeData _darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
    textTheme: ThemeData.dark().textTheme,
    scaffoldBackgroundColor: const Color(0xFF121212),
    useMaterial3: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request notification permissions and top-up the scheduling window on
    // first launch, without blocking the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileId = context.read<ScheduleProvider>().profileId;
      await NotificationService.instance.requestPermissions();
      if (!mounted) return;
      await context.read<ScheduleProvider>().rescheduleAllNotifications();
      await ScheduleWidgetService.refresh(profileId);
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
      unawaited(context.read<AuthProvider>().refreshFromCloud());
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.read<ScheduleProvider>().rescheduleAllNotifications();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.select<SettingsProvider, (Locale?, ThemeMode)>(
      (s) => (s.locale, s.themeMode),
    );
    final syncEpoch = context.select<AuthProvider, int>((a) => a.syncEpoch);
    _scheduleCloudReload(syncEpoch);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: settings.$1,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      scrollBehavior: const _NoOverscrollBehavior(),
      themeMode: settings.$2,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      home: const _CloudFailureListener(child: AuthWrapper()),
    );
  }

  void _scheduleCloudReload(int epoch) {
    if (epoch == 0 || epoch == _appliedSyncEpoch) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch == _appliedSyncEpoch) return;
      _appliedSyncEpoch = epoch;
      context.read<SettingsProvider>().reloadFromBox();
      context.read<ProfileProvider>().reloadFromBox();
      context.read<ScheduleProvider>().reloadFromBox();
      context.read<TaskProvider>().reloadFromBox();
      context.read<ExamProvider>().reloadFromBox();
      context.read<SemesterPeriodProvider>().reloadFromBox();
      context.read<ScheduleExceptionProvider>().reloadFromBox();
    });
  }
}

/// Shows one snackbar when a provider reports a failed Firestore write.
class _CloudFailureListener extends StatefulWidget {
  const _CloudFailureListener({required this.child});

  final Widget child;

  @override
  State<_CloudFailureListener> createState() => _CloudFailureListenerState();
}

class _CloudFailureListenerState extends State<_CloudFailureListener> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = CloudWriteReporter.instance.failures.listen((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).cloudSaveFailed)),
        );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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

/// Disables Material 3 [StretchingOverscrollIndicator], whose fragment
/// shader (`stretch_effect.frag`) is compiled at runtime on Skia and
/// re-run over the whole viewport on every overscroll frame.
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
