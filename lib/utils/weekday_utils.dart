import 'package:intl/intl.dart';

/// Returns the localized name of [weekday] (1 = Monday ... 7 = Sunday) using
/// `intl`'s `DateFormat`, so weekday names always follow the current app
/// locale instead of a hardcoded English list.
String localizedWeekdayName(
  int weekday,
  String localeCode, {
  bool abbreviated = false,
}) {
  // 2024-01-01 is a known Monday; used as a stable calendar anchor so we
  // never depend on `DateTime.now()` (and its local timezone/DST quirks)
  // just to look up a weekday name.
  final anchor = DateTime.utc(2024, 1, 1);
  final date = DateTime.utc(
    anchor.year,
    anchor.month,
    anchor.day + (weekday - 1),
  );
  final pattern = abbreviated ? 'EEE' : 'EEEE';
  final formatted = DateFormat(pattern, localeCode).format(date);
  if (formatted.isEmpty) return formatted;
  return formatted[0].toUpperCase() + formatted.substring(1);
}
