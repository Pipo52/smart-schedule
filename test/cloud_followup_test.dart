import 'package:flutter_test/flutter_test.dart';
import 'package:smart_schedule/services/cloud_write_reporter.dart';
import 'package:smart_schedule/services/firestore_service.dart';

void main() {
  test('a failed cloud write stays pending until sync clears it', () {
    final reporter = CloudWriteReporter.instance;
    reporter.clearPending();
    reporter.report('offline');
    expect(reporter.hasPendingFailure, isTrue);
    reporter.report('offline again');
    expect(reporter.hasPendingFailure, isTrue);
    reporter.clearPending();
    expect(reporter.hasPendingFailure, isFalse);
  });

  test('an old deletion keeps its time and drops the lesson body', () {
    final marker = FirestoreService.retainedTombstone({
      'isDeleted': true,
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'subjectName': 'Algebra',
      'room': '101',
    }, DateTime.utc(2026, 9, 1));

    expect(marker.keys.toSet(), {'isDeleted', 'updatedAt'});
    expect(marker['isDeleted'], isTrue);
    expect(marker['updatedAt'], '2026-01-01T00:00:00.000Z');
    expect(FirestoreService.isMinimalTombstone(marker), isTrue);
  });

  test('a deletion without a time still leaves a marker', () {
    final fallback = DateTime.utc(2026, 9, 1);
    final marker = FirestoreService.retainedTombstone({
      'isDeleted': true,
      'subjectName': 'Algebra',
    }, fallback);

    expect(marker['updatedAt'], fallback.toIso8601String());
    expect(FirestoreService.isMinimalTombstone(marker), isTrue);
    expect(
      FirestoreService.isMinimalTombstone({
        'isDeleted': true,
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'subjectName': 'Algebra',
      }),
      isFalse,
    );
  });
}
