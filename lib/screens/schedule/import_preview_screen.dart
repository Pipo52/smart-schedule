import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/lesson.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/lesson_card.dart';

class ImportPreviewScreen extends StatefulWidget {
  const ImportPreviewScreen({super.key, required this.parsedLessons});

  final List<Lesson> parsedLessons;

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  bool _saving = false;

  Future<void> _saveAll() async {
    if (_saving) return;
    setState(() => _saving = true);
    final schedule = context.read<ScheduleProvider>();
    try {
      await schedule.saveLessons(widget.parsedLessons);
      if (!mounted) return;
      Navigator.of(context).pop(widget.parsedLessons.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.smartImportError('save failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lessons = widget.parsedLessons;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.smartImportPreviewTitle)),
      body: lessons.isEmpty
          ? Center(child: Text(l10n.smartImportEmpty))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: lessons.length,
              itemBuilder: (context, index) =>
                  LessonCard(lesson: lessons[index]),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: lessons.isEmpty || _saving ? null : _saveAll,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(l10n.smartImportSaveAll),
          ),
        ),
      ),
    );
  }
}
