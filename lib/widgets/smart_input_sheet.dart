import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../models/schedule_exception.dart';
import '../providers/profile_provider.dart';
import '../providers/schedule_exception_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/semester_period_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/ai_parser_service.dart';

class SmartInputSheet extends StatefulWidget {
  const SmartInputSheet({super.key});

  @override
  State<SmartInputSheet> createState() => _SmartInputSheetState();
}

class _SmartInputSheetState extends State<SmartInputSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final apiKey = context.read<SettingsProvider>().geminiApiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.smartImportMissingKey)),
      );
      return;
    }

    final profileId = context.read<ProfileProvider>().activeProfileId;
    final existingSubjects = context
        .read<ScheduleProvider>()
        .lessons
        .map((l) => l.subjectName)
        .toSet()
        .toList();

    setState(() => _isLoading = true);

    try {
      final result = await AiParserService().parseCommand(
        text: text,
        apiKey: apiKey,
        now: DateTime.now(),
        profileId: profileId,
        existingSubjects: existingSubjects,
      );

      if (!mounted) return;

      switch (result.intent) {
        case AiIntent.createTask:
          await context.read<TaskProvider>().saveTask(result.task!);
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.smartInputTaskCreated(result.task!.title)),
            ),
          );
        case AiIntent.createLesson:
          await context.read<ScheduleProvider>().saveLesson(result.lesson!);
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                l10n.smartInputLessonCreated(result.lesson!.subjectName),
              ),
            ),
          );
        case AiIntent.cancelLesson:
          if (result.cancelSubject == null || result.cancelDate == null) {
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.smartInputLessonNotFound)),
            );
            break;
          }
          // Найди пару по названию предмета.
          final allLessons = context.read<ScheduleProvider>().lessons;
          final targetLesson = allLessons.cast<Lesson?>().firstWhere(
            (l) =>
                l!.subjectName.toLowerCase() ==
                result.cancelSubject!.toLowerCase(),
            orElse: () => null,
          );
          if (targetLesson == null) {
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.smartInputLessonNotFound)),
            );
            break;
          }
          final cancelException = ScheduleException(
            id: const Uuid().v4(),
            lessonId: targetLesson.id,
            date: result.cancelDate!,
            type: ExceptionType.cancelled,
            profileId: profileId,
          );
          await context.read<ScheduleExceptionProvider>().saveException(
            cancelException,
          );
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                l10n.smartInputLessonCancelled(targetLesson.subjectName),
              ),
            ),
          );
        case AiIntent.createPeriod:
          await context.read<SemesterPeriodProvider>().savePeriod(
            result.period!,
          );
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.smartInputPeriodCreated(result.period!.name)),
            ),
          );
        case AiIntent.unknown:
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.smartInputUnknown),
              duration: const Duration(seconds: 5),
            ),
          );
      }
    } on AiParserException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.smartInputError(e.code.name))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.smartInputError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.smartInput, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: l10n.smartInputHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isLoading
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : IconButton.filled(
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
