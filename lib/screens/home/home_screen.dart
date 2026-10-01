import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/lesson.dart';
import '../../models/schedule_exception.dart';
import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/schedule_exception_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/ai_parser_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/smart_import_utils.dart';
import '../../utils/weekday_utils.dart';
import '../../widgets/break_indicator.dart';
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
  late String _localeCode;
  int? _previewWeek;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday; // 1..7
    _selectedWeekday = today >= 1 && today <= 6 ? today : 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localeCode = Localizations.localeOf(context).toString();
  }

  /// Вычисляет конкретную календарную дату для выбранного дня недели и недели.
  DateTime _targetDate(int selectedWeekday, int previewWeek, int actualWeek) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayWeekday = now.weekday; // 1=Mon..7=Sun
    int dayDiff = selectedWeekday - todayWeekday;
    if (previewWeek != actualWeek) {
      dayDiff += 7;
    }
    return today.add(Duration(days: dayDiff));
  }

  void _selectWeek(int week) {
    HapticFeedback.selectionClick();
    setState(() => _previewWeek = week);
  }

  void _selectWeekday(int weekday) {
    HapticFeedback.selectionClick();
    setState(() => _selectedWeekday = weekday);
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
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

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
      final fileNameOrPath =
          file.name.isNotEmpty ? file.name : (file.path ?? '');
      final lessons = await AiParserService().parseScheduleFromBytes(
        bytes: bytes,
        mimeType: mimeTypeForPath(fileNameOrPath),
        apiKey: apiKey,
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
    final actualWeek = context.select<SettingsProvider, int>(
      (settings) => settings.currentWeek,
    );
    final previewWeek = _previewWeek ?? actualWeek;
    final targetDate = _targetDate(_selectedWeekday, previewWeek, actualWeek);
    final todayWeekday = DateTime.now().weekday;
    final todayWeekdayName = localizedWeekdayName(
      todayWeekday <= 6 ? todayWeekday : 7,
      _localeCode,
    );

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
      body: RefreshIndicator(
        onRefresh: () => context.read<AuthProvider>().refreshFromCloud(),
        child: CustomScrollView(
          key: const Key('home_scroll_view'),
          physics: const AlwaysScrollableScrollPhysics(),
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
                  localeCode: _localeCode,
                  onChanged: _selectWeekday,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _HomeLessonsSliver(
            weekday: _selectedWeekday,
            week: previewWeek,
            targetDate: targetDate,
            cancelledLabel: l10n.cancelledBadge,
            modifiedLabel: l10n.modifiedBadge,
            emptyTitle: l10n.emptyLessonsTitle,
            emptySubtitle: l10n.emptyLessonsSubtitle,
            onOpenActions: (entry) {
              final cancellation = entry.cancellation;
              if (cancellation != null) {
                _showRestoreCancelledLesson(context, cancellation);
              } else {
                _showLessonActions(context, entry.lesson, targetDate);
              }
            },
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
          _HomeTasksSliver(
            emptyTitle: l10n.emptyTasksTitle,
            emptySubtitle: l10n.emptyTasksSubtitle,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
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
    this.isCurrent = false,
    this.remainingMinutes,
    this.progress,
  });

  final _LessonOccurrence entry;
  final String cancelledLabel;
  final String modifiedLabel;
  final VoidCallback onOpenActions;
  final bool isCurrent;
  final int? remainingMinutes;
  final double? progress;

  static const Color _lectureColor = LessonColors.lecture;
  static const Color _practicalColor = LessonColors.practical;
  static const Color _labColor = LessonColors.laboratory;

  @override
  Widget build(BuildContext context) {
    final lesson = _resolveEffectiveLesson(entry);
    final isCancelled = entry.cancellation != null;
    final isModified = entry.modification != null && !isCancelled;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    String? remainingText;
    if (isCurrent && remainingMinutes != null && remainingMinutes! > 0) {
      if (remainingMinutes! < 60) {
        remainingText = l10n.lessonTimeRemaining(remainingMinutes!);
      } else {
        final hours = remainingMinutes! ~/ 60;
        final mins = remainingMinutes! % 60;
        remainingText = mins == 0
            ? l10n.lessonTimeRemainingHoursOnly(hours)
            : l10n.lessonTimeRemainingHours(hours, mins);
      }
    }

    final typeColor = switch (lesson.type) {
      LessonType.lecture => _lectureColor,
      LessonType.practical => _practicalColor,
      LessonType.laboratory => _labColor,
    };

    final badges = <Widget>[];

    if (isCancelled) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            cancelledLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else if (isModified) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            modifiedLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (remainingText != null) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: typeColor.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                remainingText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Widget? trailingBadge = badges.isEmpty
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < badges.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                badges[i],
              ],
            ],
          );

    return LessonCard(
      lesson: lesson,
      onTap: onOpenActions,
      faded: isCancelled,
      isCurrent: isCurrent,
      progress: progress,
      trailingBadge: trailingBadge,
    );
  }
}

bool _sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<_LessonOccurrence> _occurrencesFor({
  required List<Lesson> lessons,
  required List<ScheduleException> exceptions,
  required DateTime targetDate,
}) {
  final dayExceptions = <ScheduleException>[];
  for (final exception in exceptions) {
    if (_sameCalendarDay(exception.date, targetDate)) {
      dayExceptions.add(exception);
    }
  }

  final effective = <_LessonOccurrence>[];
  for (final lesson in lessons) {
    ScheduleException? cancellation;
    ScheduleException? modification;
    for (final exception in dayExceptions) {
      if (exception.lessonId != lesson.id) continue;
      if (exception.type == ExceptionType.cancelled) {
        cancellation = exception;
      } else if (exception.type == ExceptionType.modified) {
        modification = exception;
      }
    }
    effective.add((
      lesson: lesson,
      cancellation: cancellation,
      modification: modification,
    ));
  }
  return effective;
}

sealed class _ScheduleTimelineItem {
  const _ScheduleTimelineItem();
}

class _LessonTimelineItem extends _ScheduleTimelineItem {
  const _LessonTimelineItem(this.entry);
  final _LessonOccurrence entry;
}

class _BreakTimelineItem extends _ScheduleTimelineItem {
  const _BreakTimelineItem(this.durationMinutes);
  final int durationMinutes;
}

Lesson _resolveEffectiveLesson(_LessonOccurrence entry) {
  final mod = entry.modification;
  if (mod == null) return entry.lesson;
  return entry.lesson.copyWith(
    startTime: mod.newStartTime,
    endTime: mod.newEndTime,
    room: mod.newRoom,
    lecturer: mod.newLecturer,
    notes: mod.newNotes,
  );
}

List<_ScheduleTimelineItem> _buildTimeline(List<_LessonOccurrence> occurrences) {
  if (occurrences.isEmpty) return const [];
  final items = <_ScheduleTimelineItem>[];
  for (var i = 0; i < occurrences.length; i++) {
    final currentEntry = occurrences[i];
    items.add(_LessonTimelineItem(currentEntry));

    if (i < occurrences.length - 1) {
      final nextEntry = occurrences[i + 1];
      final currentLesson = _resolveEffectiveLesson(currentEntry);
      final nextLesson = _resolveEffectiveLesson(nextEntry);

      final breakMinutes = nextLesson.startMinutes - currentLesson.endMinutes;
      if (breakMinutes > 0) {
        items.add(_BreakTimelineItem(breakMinutes));
      }
    }
  }
  return items;
}

class _HomeLessonsSliver extends StatefulWidget {
  const _HomeLessonsSliver({
    required this.weekday,
    required this.week,
    required this.targetDate,
    required this.cancelledLabel,
    required this.modifiedLabel,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onOpenActions,
  });

  final int weekday;
  final int week;
  final DateTime targetDate;
  final String cancelledLabel;
  final String modifiedLabel;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<_LessonOccurrence> onOpenActions;

  @override
  State<_HomeLessonsSliver> createState() => _HomeLessonsSliverState();
}

class _HomeLessonsSliverState extends State<_HomeLessonsSliver> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(_HomeLessonsSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameCalendarDay(widget.targetDate, oldWidget.targetDate)) {
      _startTickerIfNeeded();
    }
  }

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    if (_sameCalendarDay(widget.targetDate, DateTime.now())) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = context.select<ScheduleProvider, List<Lesson>>(
      (schedule) => schedule.lessonsForDay(
        weekday: widget.weekday,
        week: widget.week,
      ),
    );
    final exceptions = context
        .select<ScheduleExceptionProvider, List<ScheduleException>>(
          (provider) => provider.exceptions,
        );
    if (lessons.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.free_breakfast_outlined,
          title: widget.emptyTitle,
          subtitle: widget.emptySubtitle,
        ),
      );
    }

    final effectiveLessons = _occurrencesFor(
      lessons: lessons,
      exceptions: exceptions,
      targetDate: widget.targetDate,
    );
    final timelineItems = _buildTimeline(effectiveLessons);

    final now = DateTime.now();
    final isToday = _sameCalendarDay(widget.targetDate, now);
    final nowMinutes = now.hour * 60 + now.minute;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = timelineItems[index];
            return switch (item) {
              _LessonTimelineItem(:final entry) => () {
                  final lesson = _resolveEffectiveLesson(entry);
                  final isCancelled = entry.cancellation != null;
                  final isCurrent = isToday &&
                      !isCancelled &&
                      nowMinutes >= lesson.startMinutes &&
                      nowMinutes < lesson.endMinutes;
                  final remainingMinutes = isCurrent
                      ? lesson.endMinutes - nowMinutes
                      : null;
                  final totalDuration = lesson.endMinutes - lesson.startMinutes;
                  final progress = isCurrent && totalDuration > 0
                      ? ((nowMinutes - lesson.startMinutes) / totalDuration)
                          .clamp(0.0, 1.0)
                      : null;

                  return _LessonOccurrenceTile(
                    entry: entry,
                    cancelledLabel: widget.cancelledLabel,
                    modifiedLabel: widget.modifiedLabel,
                    isCurrent: isCurrent,
                    remainingMinutes: remainingMinutes,
                    progress: progress,
                    onOpenActions: () => widget.onOpenActions(entry),
                  );
                }(),
              _BreakTimelineItem(:final durationMinutes) => BreakIndicator(
                  durationMinutes: durationMinutes,
                ),
            };
          },
          childCount: timelineItems.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
        ),
      ),
    );
  }
}

class _HomeTasksSliver extends StatelessWidget {
  const _HomeTasksSliver({
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final dueTasks = context.select<TaskProvider, List<Task>>(
      (tasks) => tasks.dueTodayOrOverdue,
    );
    if (dueTasks.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.check_circle_outline,
          title: emptyTitle,
          subtitle: emptySubtitle,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final task = dueTasks[index];
            return TaskTile(
              task: task,
              onToggleDone: () => context.read<TaskProvider>().toggleDone(task),
            );
          },
          childCount: dueTasks.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
        ),
      ),
    );
  }
}
