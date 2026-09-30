import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BatteryOptimization {
  static const _channel = MethodChannel('smart_schedule/battery');

  /// True when Android is allowed to defer this app, which drops exact alarms.
  static Future<bool> isRestricted() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final ignoring = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return ignoring != true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    await _channel.invokeMethod<void>('openBatterySettings');
  }
}
