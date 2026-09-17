import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/lesson.dart';
import '../../models/schedule_exception.dart';
import '../../providers/schedule_exception_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/ai_parser_service.dart';
import '../../utils/smart_import_utils.dart';
import '../../utils/weekday_utils.dart';
import '../../widgets/day_selector.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/smart_input_sheet.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/week_badge.dart';
import '../schedule/import_preview_screen.dart';
import '../schedule/lesson_form_screen.dart';
import '../schedule/occurrence_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedWeekday;
  int? _previewWeek;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday; // 1..7
    _selectedWeekday = today >= 1 && today <= 6 ? today : 1;
  }

  /// Вычисляет конкретную календарную дату для выбранного дня недели и недели.
  DateTime _targetDate(int selectedWeekday, int previewWeek, int actualWeek) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayWeekday = now.weekday; // 1=Mon..7=Sun
    int dayDiff = selectedWeekday - todayWeekday;
    // Если смотрим другую неделю — смещение на 7 дней.
    if (previewWeek != actualWeek) {
      dayDiff += 7;
    }
    return today.add(Duration(days: dayDiff));
  }

  void _showLessonActions(
    BuildContext context,
    Lesson lesson,
    DateTime targetDate,
  ) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: Text(l10n.cancelThisClass),
              subtitle: Text(
                MaterialLocalizations.of(context).formatMediumDate(targetDate),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final exception = ScheduleException(
                  id: const Uuid().v4(),
                  lessonId: lesson.id,
                  date: targetDate,
                  type: ExceptionType.cancelled,
                  profileId: lesson.profileId,
                );
                await context.read<ScheduleExceptionProvider>().saveException(
                  exception,
                );
                if (context.mounted) {
                  final dateStr = MaterialLocalizations.of(context)
                      .formatMediumDate(targetDate);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.lessonCancelled(lesson.subjectName, dateStr),
                      ),
                      action: SnackBarAction(
                        label: l10n.restoreLesson,
                        onPressed: () => context
                            .read<ScheduleExceptionProvider>()
                            .deleteException(exception.id),
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: Text(l10n.editThisOccurrence),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OccurrenceFormScreen(lesson: lesson, date: targetDate),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editRecurringLesson),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LessonFormScreen(lesson: lesson),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddOptions() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: Text(l10n.smartInput),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const SmartInputSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.manualEntry),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LessonFormScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: Text(l10n.smartImport),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _smartImport();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _smartImport() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final apiKey = context.read<SettingsProvider>().geminiApiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.smartImportMissingKey)),
      );
      return;
    }

    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (files.isEmpty || !mounted) return;
    final path = files.first.path;
    if (path == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(l10n.smartImportLoading)),
              ],
            ),
          ),
        );
      },
    );

    try {
      final lessons = await AiParserService().parseScheduleFromFile(
        path,
        mimeTypeForPath(path),
        apiKey,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final savedCount = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => ImportPreviewScreen(parsedLessons: lessons),
        ),
      );
      if (!mounted || savedCount == null) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.smartImportSaved(savedCount))),
      );
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(messageForAiParserError(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final schedule = context.watch<ScheduleProvider>();
    final tasks = context.watch<TaskProvider>();
    final exceptionProvider = context.watch<ScheduleExceptionProvider>();
    final localeCode = Localizations.localeOf(context).toString();

    final actualWeek = settings.currentWeek;
    final previewWeek = _previewWeek ?? actualWeek;

    final todayWeekdayName = localizedWeekdayName(
      DateTime.now().weekday <= 6 ? DateTime.now().weekday : 7,
      localeCode,
    );

    final lessons = schedule.lessonsForDay(
      weekday: _selectedWeekday,
      week: previewWeek,
    );
    final dueTasks = tasks.dueTodayOrOverdue;

    final targetDate = _targetDate(_selectedWeekday, previewWeek, actualWeek);
    final effectiveLessons =
        <
          ({Lesson lesson, bool isCancelled, ScheduleException? modification})
        >[];
    for (final lesson in lessons) {
      final cancelled = exceptionProvider.isCancelled(lesson.id, targetDate);
      final mod = exceptionProvider.getModification(lesson.id, targetDate);
      effectiveLessons.add((
        lesson: lesson,
        isCancelled: cancelled,
        modification: mod,
      ));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: widget.onOpenDrawer,
        ),
        title: Text(l10n.appTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.todayHeader(todayWeekdayName, actualWeek),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                WeekBadge(week: actualWeek),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WeekSwitcher(
              selectedWeek: previewWeek,
              actualWeek: actualWeek,
              onChanged: (week) => setState(() => _previewWeek = week),
            ),
          ),
          if (previewWeek != actualWeek)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.viewingAheadBanner(
                  previewWeek == 1 ? l10n.week1Short : l10n.week2Short,
                ),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          const SizedBox(height: 12),
          DaySelector(
            selectedWeekday: _selectedWeekday,
            localeCode: localeCode,
            onChanged: (weekday) => setState(() => _selectedWeekday = weekday),
          ),
          const SizedBox(height: 8),
          if (lessons.isEmpty)
            EmptyState(
              icon: Icons.free_breakfast_outlined,
              title: l10n.emptyLessonsTitle,
              subtitle: l10n.emptyLessonsSubtitle,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: effectiveLessons.map((entry) {
                  final lesson = entry.modification != null
                      ? entry.lesson.copyWith(
                          startTime: entry.modification!.newStartTime,
                          endTime: entry.modification!.newEndTime,
                          room: entry.modification!.newRoom,
                          lecturer: entry.modification!.newLecturer,
                          notes: entry.modification!.newNotes,
                        )
                      : entry.lesson;

                  return Opacity(
                    opacity: entry.isCancelled ? 0.4 : 1.0,
                    child: Stack(
                      children: [
                        LessonCard(
                          lesson: lesson,
                          onTap: entry.isCancelled
                              ? null
                              : () => _showLessonActions(
                                  context,
                                  entry.lesson,
                                  targetDate,
                                ),
                        ),
                        if (entry.isCancelled)
                          Positioned(
                            top: 8,
                            right: 12,
                            child: Chip(
                              label: Text(l10n.cancelledBadge),
                              labelStyle: const TextStyle(fontSize: 11),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        if (entry.modification != null && !entry.isCancelled)
                          Positioned(
                            top: 8,
                            right: 12,
                            child: Chip(
                              label: Text(l10n.modifiedBadge),
                              labelStyle: const TextStyle(fontSize: 11),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.tasksForTodaySection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          if (dueTasks.isEmpty)
            EmptyState(
              icon: Icons.check_circle_outline,
              title: l10n.emptyTasksTitle,
              subtitle: l10n.emptyTasksSubtitle,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: dueTasks
                    .map(
                      (task) => TaskTile(
                        task: task,
                        onToggleDone: () => tasks.toggleDone(task),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
