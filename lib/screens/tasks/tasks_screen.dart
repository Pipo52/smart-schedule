import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/task_tile.dart';
import 'task_form_screen.dart';

enum _SortMode { date, priority }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _SortMode _sortMode = _SortMode.date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final taskProvider = context.watch<TaskProvider>();
    final tasks = List<Task>.from(taskProvider.tasks);

    if (_sortMode == _SortMode.priority) {
      tasks.sort((a, b) {
        final byPriority = b.priority.index.compareTo(a.priority.index);
        return byPriority != 0 ? byPriority : a.dueDate.compareTo(b.dueDate);
      });
    } else {
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final endOfWeek = startOfToday.add(const Duration(days: 7));

    final overdue = <Task>[];
    final today = <Task>[];
    final thisWeek = <Task>[];
    final later = <Task>[];

    for (final task in tasks.where((t) => !t.isDone)) {
      if (task.dueDate.isBefore(startOfToday)) {
        overdue.add(task);
      } else if (task.dueDate.isBefore(endOfToday)) {
        today.add(task);
      } else if (task.dueDate.isBefore(endOfWeek)) {
        thisWeek.add(task);
      } else {
        later.add(task);
      }
    }
    final done = tasks.where((t) => t.isDone).toList();

    final allEmpty =
        overdue.isEmpty &&
        today.isEmpty &&
        thisWeek.isEmpty &&
        later.isEmpty &&
        done.isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: widget.onOpenDrawer,
        ),
        title: Text(l10n.tasksScreenTitle),
        actions: [
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort),
            initialValue: _sortMode,
            onSelected: (mode) => setState(() => _sortMode = mode),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _SortMode.date,
                child: Text(l10n.sortByDate),
              ),
              PopupMenuItem(
                value: _SortMode.priority,
                child: Text(l10n.sortByPriority),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const TaskFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: allEmpty
          ? EmptyState(
              icon: Icons.checklist_outlined,
              title: l10n.emptyTasksTitle,
              subtitle: l10n.emptyTasksSubtitle,
            )
          : ListView(
              children: [
                if (overdue.isNotEmpty) ...[
                  SectionHeader(l10n.groupOverdue),
                  ..._tiles(context, overdue, taskProvider),
                ],
                if (today.isNotEmpty) ...[
                  SectionHeader(l10n.groupToday),
                  ..._tiles(context, today, taskProvider),
                ],
                if (thisWeek.isNotEmpty) ...[
                  SectionHeader(l10n.groupThisWeek),
                  ..._tiles(context, thisWeek, taskProvider),
                ],
                if (later.isNotEmpty) ...[
                  SectionHeader(l10n.groupLater),
                  ..._tiles(context, later, taskProvider),
                ],
                if (done.isNotEmpty) ...[
                  SectionHeader(l10n.done),
                  ..._tiles(context, done, taskProvider),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  List<Widget> _tiles(
    BuildContext context,
    List<Task> tasks,
    TaskProvider provider,
  ) {
    return tasks
        .map(
          (task) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TaskTile(
              task: task,
              onToggleDone: () => provider.toggleDone(task),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
              ),
              onDelete: () => provider.deleteTask(task.id),
            ),
          ),
        )
        .toList();
  }
}
