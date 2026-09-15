import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../utils/enum_labels.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
    this.onDelete,
  });

  final Lesson lesson;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = lesson.type.color(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: typeColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.startTime,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            lesson.endTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.subjectName,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  lesson.type.icon,
                                  size: 16,
                                  color: typeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lesson.type.label(context),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            if (lesson.room.isNotEmpty ||
                                lesson.lecturer.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  [
                                    if (lesson.room.isNotEmpty) lesson.room,
                                    if (lesson.lecturer.isNotEmpty)
                                      lesson.lecturer,
                                  ].join(' • '),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
