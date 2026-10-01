import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../theme/app_theme.dart';
import '../utils/enum_labels.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
    this.onDelete,
    this.faded = false,
    this.isCurrent = false,
    this.progress,
    this.trailingBadge,
  });

  final Lesson lesson;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool faded;
  final bool isCurrent;
  final double? progress;
  final Widget? trailingBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fade = faded ? 0.45 : 1.0;
    final typeColor = (switch (lesson.type) {
      LessonType.lecture => LessonColors.lecture,
      LessonType.practical => LessonColors.practical,
      LessonType.laboratory => LessonColors.laboratory,
    }).withValues(alpha: fade);
    final onSurface = theme.colorScheme.onSurface.withValues(alpha: fade);
    final onVariant = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: fade,
    );
    final outline = theme.colorScheme.outlineVariant.withValues(
      alpha: faded ? 0.25 : 0.45,
    );
    final borderColor = isCurrent
        ? typeColor.withValues(alpha: 0.85)
        : outline;
    final borderWidth = isCurrent ? 1.5 : 1.0;
    final hasProgress = isCurrent && progress != null;

    final metadata = [
      if (lesson.room.isNotEmpty) lesson.room,
      if (lesson.lecturer.isNotEmpty) lesson.lecturer,
    ].join(' • ');

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: hasProgress
                    ? const BorderRadius.vertical(top: Radius.circular(15))
                    : BorderRadius.circular(15),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 13, 10, 13),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                    height: 42,
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.startTime,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      lesson.endTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            lesson.subjectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                        ),
                        if (trailingBadge != null) ...[
                          const SizedBox(width: 8),
                          trailingBadge!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(lesson.type.icon, size: 15, color: typeColor),
                        const SizedBox(width: 5),
                        Text(
                          lesson.type.label(context),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metadata,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onVariant,
                        ),
                      ),
                    ],
                  ],
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
      if (hasProgress)
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
          child: LinearProgressIndicator(
            value: progress!.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation<Color>(typeColor),
          ),
        ),
    ],
  ),
),
      ),
    );
  }
}
