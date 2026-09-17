import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/exam.dart';
import '../utils/enum_labels.dart';

class ExamTile extends StatelessWidget {
  const ExamTile({super.key, required this.exam, this.onTap, this.onDelete});

  final Exam exam;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMd(localeCode).add_Hm().format(exam.date);

    final now = DateTime.now();
    final isPast = exam.date.isBefore(now);
    final daysUntil = DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.assignment_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.subjectName,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          dateLabel,
                          exam.examType.label(context),
                          if (exam.room != null && exam.room!.isNotEmpty)
                            exam.room!,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isPast ? l10n.examPast : l10n.daysUntilExam(daysUntil),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isPast
                            ? theme.colorScheme.outline
                            : theme.colorScheme.primary,
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        iconSize: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
