import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/semester_period.dart';
import '../../providers/semester_period_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/week_calculator.dart';
import '../../utils/weekday_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/smart_input_sheet.dart';
import 'period_form_screen.dart';

class AcademicCalendarScreen extends StatelessWidget {
  const AcademicCalendarScreen({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final periods = context.watch<SemesterPeriodProvider>();
    final today = DateTime.now();
    final academicYearStart = WeekCalculator.academicYearSeptemberFirst(today);
    final localeCode = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: onOpenDrawer,
        ),
        title: Text(l10n.academicCalendarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            tooltip: l10n.smartInput,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const SmartInputSheet(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addPeriod,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PeriodFormScreen())),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: 13,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.periodLegend,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _PeriodLegend(),
                if (periods.periods.isEmpty)
                  EmptyState(
                    icon: Icons.date_range_outlined,
                    title: l10n.emptyPeriodsTitle,
                    subtitle: l10n.emptyPeriodsSubtitle,
                  ),
              ],
            );
          }
          final offset = index - 1;
          return RepaintBoundary(
            child: _MonthGrid(
              year:
                  academicYearStart.year +
                  ((academicYearStart.month - 1 + offset) ~/ 12),
              month: ((academicYearStart.month - 1 + offset) % 12) + 1,
              settingsProvider: settings,
              periodProvider: periods,
              localeCode: localeCode,
            ),
          );
        },
      ),
    );
  }
}

class _PeriodLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SemesterPeriodType.values
          .map(
            (type) => Chip(
              avatar: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: type.defaultColor,
                  shape: BoxShape.circle,
                ),
              ),
              label: Text(_periodTypeLabel(l10n, type)),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.year,
    required this.month,
    required this.settingsProvider,
    required this.periodProvider,
    required this.localeCode,
  });

  final int year;
  final int month;
  final SettingsProvider settingsProvider;
  final SemesterPeriodProvider periodProvider;
  final String localeCode;

  static const double _cellSize = 36;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(year, month);
    final leadingEmptyCells = firstDay.weekday - 1;
    final gridStart = firstDay.subtract(Duration(days: leadingEmptyCells));
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.MMMM(localeCode).format(firstDay),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 18),
              for (var weekday = 1; weekday <= 7; weekday++)
                SizedBox(
                  width: _cellSize,
                  child: Center(
                    child: Text(
                      localizedWeekdayName(
                        weekday,
                        localeCode,
                        abbreviated: true,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var row = 0; row < 6; row++)
            _WeekRow(
              rowStart: gridStart.add(Duration(days: row * 7)),
              month: month,
              settingsProvider: settingsProvider,
              periodProvider: periodProvider,
              today: today,
            ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.rowStart,
    required this.month,
    required this.settingsProvider,
    required this.periodProvider,
    required this.today,
  });

  final DateTime rowStart;
  final int month;
  final SettingsProvider settingsProvider;
  final SemesterPeriodProvider periodProvider;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final week = WeekCalculator.currentWeek(
      referenceMonday: settingsProvider.settings.semesterReferenceDate,
      today: rowStart,
    );

    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(
            '$week',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (var index = 0; index < 7; index++)
          _DayCell(
            date: rowStart.add(Duration(days: index)),
            month: month,
            periodProvider: periodProvider,
            today: today,
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.month,
    required this.periodProvider,
    required this.today,
  });

  final DateTime date;
  final int month;
  final SemesterPeriodProvider periodProvider;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    if (date.month != month) {
      return const SizedBox(width: 36, height: 36);
    }

    final theme = Theme.of(context);
    final periodColor = periodProvider.colorForDate(date);
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    return SizedBox(
      width: 36,
      height: 36,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: periodColor?.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(9),
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

String _periodTypeLabel(AppLocalizations l10n, SemesterPeriodType type) {
  return switch (type) {
    SemesterPeriodType.study => l10n.periodTypeStudy,
    SemesterPeriodType.exam => l10n.periodTypeExam,
    SemesterPeriodType.holiday => l10n.periodTypeHoliday,
    SemesterPeriodType.retake => l10n.periodTypeRetake,
    SemesterPeriodType.publicHoliday => l10n.periodTypePublicHoliday,
    SemesterPeriodType.other => l10n.periodTypeOther,
  };
}
