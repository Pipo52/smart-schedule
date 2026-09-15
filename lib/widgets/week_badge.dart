import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Small pill badge + toggle used to show/switch between Week 1 and Week 2
/// on the home screen.
class WeekSwitcher extends StatelessWidget {
  const WeekSwitcher({
    super.key,
    required this.selectedWeek,
    required this.actualWeek,
    required this.onChanged,
  });

  final int selectedWeek;
  final int actualWeek;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 1, label: Text(l10n.week1Short)),
        ButtonSegment(value: 2, label: Text(l10n.week2Short)),
      ],
      selected: {selectedWeek},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

class WeekBadge extends StatelessWidget {
  const WeekBadge({super.key, required this.week});

  final int week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        l10n.weekLabel(week),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
