import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/exam.dart';
import '../models/lesson.dart';
import '../models/task.dart';

/// Localized display labels for model enums. Kept separate from the models
/// themselves so `models/` stays free of any Flutter/UI dependency.
extension LessonTypeLabel on LessonType {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case LessonType.lecture:
        return l10n.lessonTypeLecture;
      case LessonType.practical:
        return l10n.lessonTypePractical;
      case LessonType.laboratory:
        return l10n.lessonTypeLaboratory;
    }
  }

  IconData get icon {
    switch (this) {
      case LessonType.lecture:
        return Icons.menu_book_outlined;
      case LessonType.practical:
        return Icons.edit_outlined;
      case LessonType.laboratory:
        return Icons.science_outlined;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case LessonType.lecture:
        return Colors.blue;
      case LessonType.practical:
        return Colors.green;
      case LessonType.laboratory:
        return Colors.orange;
    }
  }
}

extension WeekTypeLabel on WeekType {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case WeekType.every:
        return l10n.weekTypeEvery;
      case WeekType.week1:
        return l10n.weekTypeWeek1;
      case WeekType.week2:
        return l10n.weekTypeWeek2;
    }
  }
}

extension PriorityLabel on Priority {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case Priority.low:
        return l10n.priorityLow;
      case Priority.medium:
        return l10n.priorityMedium;
      case Priority.high:
        return l10n.priorityHigh;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }
}

extension ExamTypeLabel on ExamType {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case ExamType.midterm:
        return l10n.examTypeMidterm;
      case ExamType.finalExam:
        return l10n.examTypeFinal;
      case ExamType.retake:
        return l10n.examTypeRetake;
    }
  }
}
