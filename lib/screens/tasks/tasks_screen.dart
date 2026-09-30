import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/task_tile.dart';
import 'task_form_screen.dart';

enum _SortMode { date, priority }

enum _TasksRowKind { header, task, spacer }

class _TasksRow {
  const _TasksRow.header(this.title) : kind = _TasksRowKind.header, task = null;

  const _TasksRow.task(this.task) : kind = _TasksRowKind.task, title = null;

  const _TasksRow.spacer()
    : kind = _TasksRowKind.spacer,
      title = null,
      task = null;

  final _TasksRowKind kind;
  final String? title;
  final Task? task;
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _SortMode _sortMode = _SortMode.date;
  List<Task>? _cachedTasks;
  _SortMode? _cachedSortMode;
  String? _cachedLocale;
  int? _cachedDay;
  List<_TasksRow> _cachedRows = const [];

  List<_TasksRow> _computeRows({
    required List<Task> sourceTasks,
    required _SortMode sortMode,
    required AppLocalizations l10n,
    required String localeCode,
  }) {
    final now = DateTime.now();
    if (identical(_cachedTasks, sourceTasks) &&
        _cachedSortMode == sortMode &&
        _cachedLocale == localeCode &&
        _cachedDay == now.day) {
      return _cachedRows;
    }

    final tasks = List<Task>.from(sourceTasks);
    if (sortMode == _SortMode.priority) {
      tasks.sort((a, b) {
        final byPriority = b.priority.index.compareTo(a.priority.index);
        return byPriority != 0 ? byPriority : a.dueDate.compareTo(b.dueDate);
      });
    } else {
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }

    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final endOfWeek = startOfToday.add(const Duration(days: 7));

    final overdue = <Task>[];
    final today = <Task>[];
    final thisWeek = <Task>[];
    final later = <Task>[];
    final done = <Task>[];

    for (final task in tasks) {
      if (task.isDone) {
        done.add(task);
        continue;
      }
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

    final rows = <_TasksRow>[];
    void addSection(String title, List<Task> sectionTasks) {
      if (sectionTasks.isEmpty) return;
      rows.add(_TasksRow.header(title));
      for (final task in sectionTasks) {
        rows.add(_TasksRow.task(task));
      }
    }

    addSection(l10n.groupOverdue, overdue);
    addSection(l10n.groupToday, today);
    addSection(l10n.groupThisWeek, thisWeek);
    addSection(l10n.groupLater, later);
    addSection(l10n.done, done);
    if (rows.isNotEmpty) {
      rows.add(const _TasksRow.spacer());
    }

    _cachedTasks = sourceTasks;
    _cachedSortMode = sortMode;
    _cachedLocale = localeCode;
    _cachedDay = now.day;
    _cachedRows = rows;

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).toString();
    final tasks = context.select<TaskProvider, List<Task>>((p) => p.tasks);
    final rows = _computeRows(
      sourceTasks: tasks,
      sortMode: _sortMode,
      l10n: l10n,
      localeCode: localeCode,
    );

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const TaskFormScreen())),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AuthProvider>().refreshFromCloud(),
        child: rows.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: EmptyState(
                      icon: Icons.checklist_outlined,
                      title: l10n.emptyTasksTitle,
                      subtitle: l10n.emptyTasksSubtitle,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: rows.length,
                addAutomaticKeepAlives: false,
              itemBuilder: (context, index) {
                final row = rows[index];
                switch (row.kind) {
                  case _TasksRowKind.header:
                    return SectionHeader(row.title!);
                  case _TasksRowKind.spacer:
                    return const SizedBox(height: 24);
                  case _TasksRowKind.task:
                    final task = row.task!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TaskTile(
                        task: task,
                        onToggleDone: () =>
                            context.read<TaskProvider>().toggleDone(task),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskFormScreen(task: task),
                          ),
                        ),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(l10n.confirmDeleteTitle),
                              content: Text(l10n.confirmDeleteTaskMessage),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: Text(l10n.delete),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await context.read<TaskProvider>().deleteTask(task.id);
                          }
                        },
                      ),
                    );
                }
              },
            ),
      ),
    );
  }
}
