import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/cloud_write_reporter.dart';
import '../models/schedule_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'calendar/academic_calendar_screen.dart';
import 'exams/exams_screen.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';
import 'tasks/tasks_screen.dart';

/// Bottom-navigation shell hosting the four top-level screens.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Future<String?> _promptForProfileName(
    BuildContext context, {
    String initialValue = '',
    required String title,
  }) async {
    var value = initialValue;
    final l10n = AppLocalizations.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initialValue,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.profileName),
          onChanged: (newValue) => value = newValue,
          onFieldSubmitted: (submittedValue) =>
              Navigator.of(dialogContext).pop(submittedValue.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(value.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    return name == null || name.isEmpty ? null : name;
  }

  Future<void> _createProfile(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptForProfileName(
      context,
      title: l10n.createSchedule,
    );
    if (name == null || !context.mounted) return;
    await context.read<ProfileProvider>().createProfile(name);
  }

  Future<void> _renameProfile(
    BuildContext context,
    ScheduleProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptForProfileName(
      context,
      initialValue: profile.name,
      title: l10n.renameSchedule,
    );
    if (name == null || !context.mounted) return;
    await context.read<ProfileProvider>().renameProfile(profile.id, name);
  }

  Future<void> _deleteProfile(
    BuildContext context,
    ScheduleProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteScheduleTitle),
        content: Text(l10n.deleteScheduleMessage(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<ProfileProvider>().deleteProfile(profile.id);
    } on StateError {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.cannotDeleteLastSchedule)));
    }
  }

  Future<void> _handleProfileAction(
    BuildContext context,
    ScheduleProfile profile,
    _ProfileAction action,
  ) async {
    switch (action) {
      case _ProfileAction.rename:
        await _renameProfile(context, profile);
      case _ProfileAction.setDefault:
        await context.read<ProfileProvider>().setDefaultProfile(profile.id);
      case _ProfileAction.delete:
        await _deleteProfile(context, profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final activeProfile = profileProvider.activeProfile;
    final screens = [
      HomeScreen(onOpenDrawer: _openDrawer),
      TasksScreen(onOpenDrawer: _openDrawer),
      ExamsScreen(onOpenDrawer: _openDrawer),
      AcademicCalendarScreen(onOpenDrawer: _openDrawer),
      const SettingsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeProfile?.name ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final profile in profileProvider.profiles)
                      ListTile(
                        leading: Icon(
                          profile.isDefault
                              ? Icons.star_rounded
                              : Icons.calendar_today_outlined,
                        ),
                        title: Text(profile.name),
                        selected: profile.id == profileProvider.activeProfileId,
                        onTap: () async {
                          await profileProvider.switchProfile(profile.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        trailing: PopupMenuButton<_ProfileAction>(
                          onSelected: (action) =>
                              _handleProfileAction(context, profile, action),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: _ProfileAction.rename,
                              child: Text(l10n.rename),
                            ),
                            PopupMenuItem(
                              value: _ProfileAction.setDefault,
                              child: Text(l10n.setAsDefault),
                            ),
                            PopupMenuItem(
                              value: _ProfileAction.delete,
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add_rounded),
                title: Text(l10n.createNewSchedule),
                onTap: () => _createProfile(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: IndexedStack(index: _index, children: screens),
            ),
          ),
          const Align(
            alignment: Alignment.topRight,
            child: SafeArea(child: _CloudSyncIndicator()),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CloudOutOfDateBanner(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.today_outlined),
                selectedIcon: const Icon(Icons.today),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.checklist_outlined),
                selectedIcon: const Icon(Icons.checklist),
                label: l10n.navTasks,
              ),
              NavigationDestination(
                icon: const Icon(Icons.event_note_outlined),
                selectedIcon: const Icon(Icons.event_note),
                label: l10n.navExams,
              ),
              NavigationDestination(
                icon: const Icon(Icons.date_range_outlined),
                selectedIcon: const Icon(Icons.date_range),
                label: l10n.navCalendar,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l10n.navSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloudOutOfDateBanner extends StatelessWidget {
  const _CloudOutOfDateBanner();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ListenableBuilder(
      listenable: CloudWriteReporter.instance,
      builder: (context, _) {
        final signedIn = auth.currentUser != null;
        final show =
            signedIn &&
            !auth.isSyncing &&
            (!auth.isSynced || CloudWriteReporter.instance.hasPendingFailure);
        if (!show) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context);
        return Material(
          color: colors.errorContainer,
          child: InkWell(
            onTap: () => context.read<AuthProvider>().sendToCloud(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    color: colors.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.cloudOutOfDate,
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.cloudSendNow,
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _ProfileAction { rename, setDefault, delete }

class _CloudSyncIndicator extends StatelessWidget {
  const _CloudSyncIndicator();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.currentUser == null || !auth.isSyncing) {
          return const SizedBox.shrink();
        }
        return const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}
