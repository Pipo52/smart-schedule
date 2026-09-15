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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.assignment_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(exam.subjectName),
        subtitle: Text(
          [
            dateLabel,
            exam.examType.label(context),
            if (exam.room != null && exam.room!.isNotEmpty) exam.room!,
          ].join(' • '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
