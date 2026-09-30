import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tells the UI that a Firestore write failed after the local Hive save.
/// The local row stays; a later sync uploads the newer copy.
class CloudWriteReporter extends ChangeNotifier {
  CloudWriteReporter._();

  static final CloudWriteReporter instance = CloudWriteReporter._();

  final StreamController<void> _failures = StreamController<void>.broadcast();
  DateTime? _lastReport;
  bool _pending = false;

  Stream<void> get failures => _failures.stream;

  /// Stays true from the first failed write until a later sync succeeds.
  bool get hasPendingFailure => _pending;

  void report(Object error) {
    debugPrint('Firestore write failed: $error');
    if (!_pending) {
      _pending = true;
      notifyListeners();
    }
    final now = DateTime.now();
    if (_lastReport != null &&
        now.difference(_lastReport!) < const Duration(seconds: 4)) {
      return;
    }
    _lastReport = now;
    if (!_failures.isClosed) {
      _failures.add(null);
    }
  }

  /// Call after a sync that uploaded the newer local copy.
  void clearPending() {
    if (!_pending) return;
    _pending = false;
    notifyListeners();
  }
}
