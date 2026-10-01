import 'dart:async';

import 'package:flutter/foundation.dart';

/// One Firestore write that did not finish. A later attempt reads Hive again,
/// so a newer local edit is what gets sent.
class PendingCloudWrite {
  const PendingCloudWrite(this.kind, this.id, {this.delete = false});

  static const String lesson = 'lesson';
  static const String task = 'task';
  static const String exam = 'exam';
  static const String period = 'period';
  static const String exception = 'exception';
  static const String profile = 'profile';
  static const String settings = 'settings';

  final String kind;
  final String id;
  final bool delete;

  String get key => '$kind:$id';
}

/// Tells the UI that a Firestore write failed after the local Hive save.
/// The local row stays. The failed write is retried once on its own, and
/// the user can send it again from the banner or from settings.
class CloudWriteReporter extends ChangeNotifier {
  CloudWriteReporter._();

  static final CloudWriteReporter instance = CloudWriteReporter._();

  @visibleForTesting
  static Duration retryDelay = const Duration(seconds: 3);

  final StreamController<void> _failures = StreamController<void>.broadcast();
  final Map<String, PendingCloudWrite> _queue = {};
  DateTime? _lastReport;
  Timer? _retryTimer;
  bool _pending = false;
  bool _retryRunning = false;

  /// Set by [AuthProvider] so a failed write can be sent again without a
  /// full download.
  Future<void> Function()? onAutoRetry;

  Stream<void> get failures => _failures.stream;

  /// Stays true from the first failed write until a later send succeeds.
  bool get hasPendingFailure => _pending;

  List<PendingCloudWrite> get queued => List.unmodifiable(_queue.values);

  /// Runs [write]. On success, drops any queued retry for the same record.
  /// On failure, keeps the latest operation and schedules one retry.
  Future<void> guard(
    PendingCloudWrite op,
    Future<void> Function() write, {
    bool scheduleRetry = true,
  }) async {
    try {
      await write();
      _complete(op.key);
    } catch (e) {
      _queue[op.key] = op;
      _fail(e, scheduleRetry: scheduleRetry);
    }
  }

  void report(Object error) {
    _fail(error, scheduleRetry: true);
  }

  /// The whole sync failed, and there is no single record to resend.
  void markOutOfDate() {
    if (!_pending) {
      _pending = true;
      notifyListeners();
    }
    _scheduleAutoRetry();
  }

  /// Call after a sync that uploaded the newer local copy.
  void clearPending() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _queue.clear();
    if (!_pending) return;
    _pending = false;
    notifyListeners();
  }

  void _complete(String key) {
    _queue.remove(key);
    if (_queue.isNotEmpty || !_pending) return;
    _pending = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    notifyListeners();
  }

  void _fail(Object error, {required bool scheduleRetry}) {
    debugPrint('Firestore write failed: $error');
    final wasPending = _pending;
    _pending = true;
    if (!wasPending) notifyListeners();
    if (!scheduleRetry) return;
    final now = DateTime.now();
    if (_lastReport == null ||
        now.difference(_lastReport!) >= const Duration(seconds: 4)) {
      _lastReport = now;
      if (!_failures.isClosed) _failures.add(null);
    }
    _scheduleAutoRetry();
  }

  void _scheduleAutoRetry() {
    if (_retryTimer != null || _retryRunning || onAutoRetry == null) return;
    _retryTimer = Timer(retryDelay, () {
      _retryTimer = null;
      final retry = onAutoRetry;
      if (retry == null) return;
      _retryRunning = true;
      unawaited(() async {
        try {
          await retry();
        } finally {
          _retryRunning = false;
        }
      }());
    });
  }
}
