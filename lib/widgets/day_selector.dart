import 'package:flutter/material.dart';

import '../utils/weekday_utils.dart';

/// Horizontal Mon..Sat day-of-week selector.
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.selectedWeekday,
    required this.onChanged,
    required this.localeCode,
  });

  final int selectedWeekday;
  final ValueChanged<int> onChanged;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final weekday = index + 1;
          final selected = weekday == selectedWeekday;
          final label = localizedWeekdayName(
            weekday,
            localeCode,
            abbreviated: true,
          );
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            labelStyle: TextStyle(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: theme.colorScheme.primary,
            onSelected: (_) => onChanged(weekday),
          );
        },
      ),
    );
  }
}
