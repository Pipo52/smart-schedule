import 'package:intl/intl.dart';

/// Cache of localized weekday names: key = "$localeCode/$weekday/$abbreviated"
final Map<String, String> _weekdayNameCache = {};

/// Cache of localized month names: key = "$localeCode/$month/$year"
final Map<String, String> _monthNameCache = {};

/// Returns the localized name of [weekday] (1 = Monday ... 7 = Sunday) using
/// `intl`'s `DateFormat`, so weekday names always follow the current app
/// locale instead of a hardcoded English list.
/// Results are memoized to avoid constructing a new [DateFormat] on every build.
String localizedWeekdayName(
  int weekday,
  String localeCode, {
  bool abbreviated = false,
}) {
  final cacheKey = '$localeCode/$weekday/$abbreviated';
  return _weekdayNameCache.putIfAbsent(cacheKey, () {
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
  });
}

/// Returns the localized month name for [month] (1–12) in [year].
/// Results are memoized so a month grid does not build a new [DateFormat]
/// on every render.
String localizedMonthName(String localeCode, int month, int year) {
  final cacheKey = '$localeCode/$month/$year';
  return _monthNameCache.putIfAbsent(cacheKey, () {
    return DateFormat.MMMM(localeCode).format(DateTime(year, month));
  });
}
