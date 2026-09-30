import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/app_settings.dart';
import 'hive_service.dart';
import 'schedule_widget_data.dart';

class ScheduleWidgetService {
  static const _channel = MethodChannel('smart_schedule/widget');
  static const Duration _debounce = Duration(milliseconds: 300);

  static Timer? _debounceTimer;
  static String? _queuedProfileId;
  static String? _lastPayload;

  static Future<void> refresh(String profileId) async {
    if (kIsWeb || !Platform.isAndroid) return;
    _queuedProfileId = profileId;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      final id = _queuedProfileId;
      if (id != null) unawaited(_push(id));
    });
  }

  static Future<void> _push(String profileId) async {
    try {
      if (!Hive.isBoxOpen(HiveService.lessonsBoxName) ||
          !Hive.isBoxOpen(HiveService.exceptionsBoxName) ||
          !Hive.isBoxOpen(HiveService.settingsBoxName)) {
        return;
      }
      final settings = HiveService.loadOrCreateSettings();
      final localeCode = _localeCode(settings);
      final l10n = lookupAppLocalizations(Locale(localeCode));
      final entries = upcomingWidgetLessons(
        lessons: HiveService.lessonsBox.values,
        exceptions: HiveService.exceptionsBox.values,
        profileId: profileId,
        referenceMonday: settings.semesterReferenceDate,
        manualOverride: settings.manualWeekOverride,
        from: DateTime.now(),
        localeCode: localeCode,
      );
      final payload = jsonEncode({
        'empty': l10n.widgetEmpty,
        'now': l10n.widgetNow,
        'today': l10n.widgetToday,
        'tomorrow': l10n.widgetTomorrow,
        'next': l10n.widgetNext,
        'lessons': [for (final entry in entries) entry.toJson()],
      });
      if (payload == _lastPayload) return;
      await _channel.invokeMethod<void>('update', {'payload': payload});
      _lastPayload = payload;
    } catch (_) {}
  }

  static String _localeCode(AppSettings settings) {
    final chosen = settings.appLocale;
    if (chosen == 'en' || chosen == 'ru' || chosen == 'uk') {
      return chosen as String;
    }
    final system =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (system == 'en' || system == 'ru' || system == 'uk') return system;
    return 'en';
  }
}
