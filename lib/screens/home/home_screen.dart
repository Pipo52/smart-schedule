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

typedef _LessonOccurrence = ({
  Lesson lesson,
  ScheduleException? cancellation,
  ScheduleException? modification,
});

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedWeekday;
  int? _previewWeek;
  List<_LessonOccurrence> _effectiveLessons = const [];
  DateTime _targetDateCached = DateTime.now();
  int? _cachedWeekday;
  int? _cachedPreviewWeek;
  int? _cachedActualWeek;
  List<Lesson>? _cachedSourceLessons;
  List<ScheduleException>? _cachedExceptions;

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

  List<_LessonOccurrence> _computeEffectiveLessons({
    required List<Lesson> lessons,
    required ScheduleExceptionProvider exceptionProvider,
    required DateTime targetDate,
  }) {
    final effectiveLessons = <_LessonOccurrence>[];
    final dayExceptions = exceptionProvider.exceptionsForDate(targetDate);
    for (final lesson in lessons) {
      ScheduleException? cancellation;
      for (final exception in dayExceptions) {
        if (exception.lessonId == lesson.id &&
            exception.type == ExceptionType.cancelled) {
          cancellation = exception;
          break;
        }
      }
      effectiveLessons.add((
        lesson: lesson,
        cancellation: cancellation,
        modification: exceptionProvider.getModification(lesson.id, targetDate),
      ));
    }
    return effectiveLessons;
  }

  void _refreshEffectiveLessons() {
    final settings = context.read<SettingsProvider>();
    final schedule = context.read<ScheduleProvider>();
    final exceptionProvider = context.read<ScheduleExceptionProvider>();
    final actualWeek = settings.currentWeek;
    final previewWeek = _previewWeek ?? actualWeek;
    final lessons = schedule.lessonsForDay(
      weekday: _selectedWeekday,
      week: previewWeek,
    );
    final exceptions = exceptionProvider.exceptions;

    if (_cachedWeekday == _selectedWeekday &&
        _cachedPreviewWeek == previewWeek &&
        _cachedActualWeek == actualWeek &&
        identical(_cachedSourceLessons, lessons) &&
        identical(_cachedExceptions, exceptions)) {
      return;
    }

    _cachedWeekday = _selectedWeekday;
    _cachedPreviewWeek = previewWeek;
    _cachedActualWeek = actualWeek;
    _cachedSourceLessons = lessons;
    _cachedExceptions = exceptions;
    _targetDateCached = _targetDate(_selectedWeekday, previewWeek, actualWeek);
    _effectiveLessons = _computeEffectiveLessons(
      lessons: lessons,
      exceptionProvider: exceptionProvider,
      targetDate: _targetDateCached,
    );
  }

  void _selectWeek(int week) {
    setState(() {
      _previewWeek = week;
      _refreshEffectiveLessons();
    });
  }

  void _selectWeekday(int weekday) {
    setState(() {
      _selectedWeekday = weekday;
      _refreshEffectiveLessons();
    });
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

  void _showRestoreCancelledLesson(
    BuildContext context,
    ScheduleException exception,
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
              leading: const Icon(Icons.restore),
              title: Text(l10n.restoreThisClass),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await context.read<ScheduleExceptionProvider>().deleteException(
                  exception.id,
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
    context.watch<ScheduleProvider>();
    final tasks = context.watch<TaskProvider>();
    context.watch<ScheduleExceptionProvider>();
    final localeCode = Localizations.localeOf(context).toString();

    final actualWeek = settings.currentWeek;
    final previewWeek = _previewWeek ?? actualWeek;

    final todayWeekdayName = localizedWeekdayName(
      DateTime.now().weekday <= 6 ? DateTime.now().weekday : 7,
      localeCode,
    );

    final dueTasks = tasks.dueTodayOrOverdue;
    _refreshEffectiveLessons();
    final targetDate = _targetDateCached;
    final effectiveLessons = _effectiveLessons;
    final lessons = _cachedSourceLessons ?? const <Lesson>[];

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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    onChanged: _selectWeek,
                  ),
                ),
                if (previewWeek != actualWeek)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      l10n.viewingAheadBanner(
                        previewWeek == 1 ? l10n.week1Short : l10n.week2Short,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                DaySelector(
                  selectedWeekday: _selectedWeekday,
                  localeCode: localeCode,
                  onChanged: _selectWeekday,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (lessons.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.free_breakfast_outlined,
                title: l10n.emptyLessonsTitle,
                subtitle: l10n.emptyLessonsSubtitle,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = effectiveLessons[index];
                  return _LessonOccurrenceTile(
                    entry: entry,
                    cancelledLabel: l10n.cancelledBadge,
                    modifiedLabel: l10n.modifiedBadge,
                    onOpenActions: () {
                      final cancellation = entry.cancellation;
                      if (cancellation != null) {
                        _showRestoreCancelledLesson(context, cancellation);
                      } else {
                        _showLessonActions(context, entry.lesson, targetDate);
                      }
                    },
                  );
                }, childCount: effectiveLessons.length),
              ),
            ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.tasksForTodaySection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (dueTasks.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.check_circle_outline,
                title: l10n.emptyTasksTitle,
                subtitle: l10n.emptyTasksSubtitle,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = dueTasks[index];
                  return TaskTile(
                    task: task,
                    onToggleDone: () => tasks.toggleDone(task),
                  );
                }, childCount: dueTasks.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _LessonOccurrenceTile extends StatelessWidget {
  const _LessonOccurrenceTile({
    required this.entry,
    required this.cancelledLabel,
    required this.modifiedLabel,
    required this.onOpenActions,
  });

  final _LessonOccurrence entry;
  final String cancelledLabel;
  final String modifiedLabel;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final lesson = entry.modification != null
        ? entry.lesson.copyWith(
            startTime: entry.modification!.newStartTime,
            endTime: entry.modification!.newEndTime,
            room: entry.modification!.newRoom,
            lecturer: entry.modification!.newLecturer,
            notes: entry.modification!.newNotes,
          )
        : entry.lesson;

    final isCancelled = entry.cancellation != null;
    return Opacity(
      opacity: isCancelled ? 0.4 : 1.0,
      child: Stack(
        children: [
          LessonCard(lesson: lesson, onTap: onOpenActions),
          if (isCancelled)
            Positioned(
              top: 8,
              right: 12,
              child: Chip(
                label: Text(cancelledLabel),
                labelStyle: const TextStyle(fontSize: 11),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (entry.modification != null && !isCancelled)
            Positioned(
              top: 8,
              right: 12,
              child: Chip(
                label: Text(modifiedLabel),
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
  }
}
