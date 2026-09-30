import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/task.dart';
import '../utils/date_format_cache.dart';

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
    final dueDateLabel = DateFormatCache.yMMMdHm(localeCode).format(task.dueDate);
    final priorityColor = switch (task.priority) {
      Priority.low => const Color(0xFF64748B),
      Priority.medium => const Color(0xFFF59E0B),
      Priority.high => const Color(0xFFEF4444),
    };

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: task.isDone ? 0.25 : 0.45,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
          child: Row(
            children: [
              Checkbox(
                value: task.isDone,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  onToggleDone();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: task.isDone
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              )
                            : null,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        dueDateLabel,
                        if (task.linkedSubject != null &&
                            task.linkedSubject!.isNotEmpty)
                          task.linkedSubject!,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: task.isDone ? 0.45 : 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(
                    alpha: task.isDone ? 0.45 : 1,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                  tooltip: MaterialLocalizations.of(context)
                      .deleteButtonTooltip,
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
