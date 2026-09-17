import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/app_settings.dart';
import '../../providers/exam_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/backup_service.dart';
import 'gemini_api_key_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsResetDataConfirmTitle),
        content: Text(l10n.settingsResetDataConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<SettingsProvider>().resetAllData();
    if (!context.mounted) return;
    context.read<ScheduleProvider>().reloadFromBox();
    context.read<TaskProvider>().reloadFromBox();
    context.read<ExamProvider>().reloadFromBox();
  }

  Future<void> _pickReferenceDate(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final date = await showDatePicker(
      context: context,
      initialDate: settings.settings.semesterReferenceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date != null) {
      await settings.setSemesterReferenceDate(date);
    }
  }

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackupService.shareExport();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportSuccess)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsImportError(e.toString()))),
      );
    }
  }

  Future<void> _import(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsImportConfirmTitle),
        content: Text(l10n.settingsImportConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final imported = await BackupService.pickAndImport();
      if (!context.mounted) return;
      if (imported) {
        context.read<ScheduleProvider>().reloadFromBox();
        context.read<TaskProvider>().reloadFromBox();
        context.read<ExamProvider>().reloadFromBox();
        context.read<SettingsProvider>().reloadFromBox();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsImportSuccess)),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsImportError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final current = settings.settings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: ListView(
        children: [
          _SectionLabel(l10n.settingsCurrentWeekSection),
          ListTile(
            title: Text(l10n.settingsManualOverride),
            subtitle: Text(
              current.manualWeekOverride == null
                  ? l10n.settingsManualOverrideOff
                  : l10n.weekLabel(current.manualWeekOverride!),
            ),
            trailing: DropdownButton<int?>(
              value: current.manualWeekOverride,
              hint: const Icon(Icons.auto_mode),
              selectedItemBuilder: (context) => [
                const Icon(Icons.auto_mode),
                Text(l10n.week1Short),
                Text(l10n.week2Short),
              ],
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.settingsManualOverrideOff),
                ),
                DropdownMenuItem(value: 1, child: Text(l10n.week1Short)),
                DropdownMenuItem(value: 2, child: Text(l10n.week2Short)),
              ],
              onChanged: (value) => settings.setManualWeekOverride(value),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsSemesterReferenceDate),
            subtitle: Text(
              MaterialLocalizations.of(context)
                  .formatMediumDate(current.semesterReferenceDate),
            ),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () => _pickReferenceDate(context),
          ),
          ListTile(
            title: Text(l10n.settingsDefaultReminder),
            trailing: DropdownButton<int>(
              value: current.defaultLessonReminderMinutes,
              items: const [5, 10, 15, 30, 60]
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  settings.setDefaultLessonReminderMinutes(value);
                }
              },
            ),
            subtitle: Text(
              l10n.settingsMinutesBefore(current.defaultLessonReminderMinutes),
            ),
          ),
          const Divider(),
          _SectionLabel(l10n.settingsDataSection),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: Text(l10n.settingsExport),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.settingsImport),
            onTap: () => _import(context),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.settingsResetData,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmReset(context),
          ),
          const Divider(),
          _SectionLabel(l10n.settingsAppearanceSection),
          ListTile(
            title: Text(l10n.settingsTheme),
            trailing: DropdownButton<AppThemeMode>(
              value: current.themeMode,
              items: [
                DropdownMenuItem(
                  value: AppThemeMode.system,
                  child: Text(l10n.themeSystem),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.light,
                  child: Text(l10n.themeLight),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.dark,
                  child: Text(l10n.themeDark),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) settings.setThemeMode(mode);
              },
            ),
          ),
          ListTile(
            title: Text(l10n.settingsLanguage),
            trailing: DropdownButton<String?>(
              value: current.appLocale,
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.languageSystem)),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.languageEnglish),
                ),
                DropdownMenuItem(
                  value: 'uk',
                  child: Text(l10n.languageUkrainian),
                ),
                DropdownMenuItem(
                  value: 'ru',
                  child: Text(l10n.languageRussian),
                ),
              ],
              onChanged: (code) => settings.setAppLocale(code),
            ),
          ),
          const Divider(),
          _SectionLabel(l10n.settingsAiSection),
          const GeminiApiKeyTile(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
