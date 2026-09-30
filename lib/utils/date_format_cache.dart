import 'package:intl/intl.dart';

/// Global cache for [DateFormat] instances to eliminate object allocation,
/// regex compilation, and locale table lookups during list scrolling.
class DateFormatCache {
  DateFormatCache._();

  static final Map<String, DateFormat> _yMmdHmCache = <String, DateFormat>{};

  /// Returns a cached [DateFormat.yMMMd] + [add_Hm] formatter for the given [locale].
  static DateFormat yMMMdHm(String locale) {
    return _yMmdHmCache.putIfAbsent(
      locale,
      () => DateFormat.yMMMd(locale).add_Hm(),
    );
  }
}
