import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/weekday_utils.dart';
import '../../widgets/day_selector.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/week_badge.dart';
import '../schedule/lesson_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final schedule = context.watch<ScheduleProvider>();
    final tasks = context.watch<TaskProvider>();
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const LessonFormScreen())),
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
                children: lessons
                    .map(
                      (lesson) => LessonCard(
                        lesson: lesson,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LessonFormScreen(lesson: lesson),
                          ),
                        ),
                      ),
                    )
                    .toList(),
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
