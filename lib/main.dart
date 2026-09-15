import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/generated/app_localizations.dart';
import 'providers/exam_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'screens/root_shell.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService.instance.init();

  runApp(const SmartScheduleApp());
}

class SmartScheduleApp extends StatelessWidget {
  const SmartScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, ScheduleProvider>(
          create: (context) =>
              ScheduleProvider(settings: context.read<SettingsProvider>()),
          update: (context, settings, previous) {
            final provider = previous ?? ScheduleProvider(settings: settings);
            provider.updateSettings(settings);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
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
      context.read<ScheduleProvider>().rescheduleAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      themeMode: settings.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RootShell(),
    );
  }
}
