import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../utils/enum_labels.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleDone,
    this.onTap,
    this.onDelete,
  });

  final Task task;
  final VoidCallback onToggleDone;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).toString();
    final dueDateLabel = DateFormat.yMMMd(localeCode)
        .add_Hm()
        .format(task.dueDate);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: task.isDone, onChanged: (_) => onToggleDone()),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? theme.colorScheme.outline : null,
          ),
        ),
        subtitle: Text(
          [
            dueDateLabel,
            if (task.linkedSubject != null && task.linkedSubject!.isNotEmpty)
              task.linkedSubject!,
          ].join(' • '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: task.priority.color(context),
                shape: BoxShape.circle,
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
