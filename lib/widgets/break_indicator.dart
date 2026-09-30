import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Lightweight, visually appealing indicator for breaks or windows ("перерви / вікна")
/// between consecutive classes.
///
/// Designed with minimal layout and painting overhead (no blur filters, no complex paths).
/// Wrapped in [RepaintBoundary] for optimal scrolling performance.
class BreakIndicator extends StatelessWidget {
  const BreakIndicator({
    super.key,
    required this.durationMinutes,
  });

  /// Duration of the break in minutes.
  final int durationMinutes;

  @override
  Widget build(BuildContext context) {
    if (durationMinutes <= 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String label;
    final IconData icon;

    if (durationMinutes < 60) {
      label = l10n.breakShort(durationMinutes);
      icon = Icons.coffee_outlined;
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      label = minutes == 0
          ? l10n.breakHoursOnly(hours)
          : l10n.breakLong(hours, minutes);
      icon = Icons.hourglass_top_rounded;
    }

    final dividerColor = colorScheme.outlineVariant.withValues(alpha: 0.35);
    final chipBg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final contentColor = colorScheme.onSurfaceVariant;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                color: dividerColor,
                thickness: 1,
                endIndent: 10,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: contentColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: contentColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Divider(
                color: dividerColor,
                thickness: 1,
                indent: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
