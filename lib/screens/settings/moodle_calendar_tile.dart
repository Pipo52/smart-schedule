import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/moodle_sync_service.dart';

class MoodleCalendarTile extends StatefulWidget {
  const MoodleCalendarTile({super.key});

  @override
  State<MoodleCalendarTile> createState() => _MoodleCalendarTileState();
}

class _MoodleCalendarTileState extends State<MoodleCalendarTile> {
  late final TextEditingController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<SettingsProvider>().moodleCalendarUrl ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    await context.read<SettingsProvider>().setMoodleCalendarUrl(
      _controller.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.settingsMoodleSaved)));
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<SettingsProvider>().setMoodleCalendarUrl(url);
      final assignments = await const MoodleSyncService().fetchAssignments(url);
      if (!mounted) return;
      if (assignments.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsMoodleEmpty)),
        );
        return;
      }
      final result = await context.read<TaskProvider>().importMoodleAssignments(
        assignments,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.settingsMoodleResult(result.added, result.updated),
          ),
        ),
      );
    } on MoodleCalendarException catch (error) {
      if (!mounted) return;
      final message = switch (error.reason) {
        'https' => l10n.settingsMoodleErrorHttps,
        'network' => l10n.settingsMoodleErrorNetwork,
        _ => l10n.settingsMoodleErrorStatus,
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.settingsMoodleUrl,
              hintText: l10n.settingsMoodleUrlHint,
              suffixIcon: IconButton(
                tooltip: l10n.save,
                onPressed: _loading ? null : _save,
                icon: const Icon(Icons.save_outlined),
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsMoodleHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _loading ? null : _load,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(l10n.settingsMoodleLoad),
            ),
          ),
        ],
      ),
    );
  }
}
