import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

/// Cold-start / first-layout frames to drop before computing stats.
const _warmupFrames = 5;

/// 60 Hz frame budget in microseconds.
const _frameBudgetMicros = 16666;

Future<void> main() {
  return integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (data == null) return;

      final raw = data['scrolling_summary'] ?? data;
      Map<String, dynamic> out;
      if (raw is Map && raw.containsKey('traceEvents')) {
        final timeline = Timeline.fromJson(Map<String, dynamic>.from(raw));
        out = TimelineSummary.summarize(timeline).summaryJson;
      } else if (raw is Map) {
        out = Map<String, dynamic>.from(raw);
      } else {
        out = data;
      }

      out = _dropWarmupFrames(out);

      final file = File('build/scroll_perf_summary.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(out),
      );
    },
  );
}

Map<String, dynamic> _dropWarmupFrames(Map<String, dynamic> summary) {
  final buildTimes = _intList(summary['frame_build_times']);
  final rasterTimes = _intList(summary['frame_rasterizer_times']);
  final beginTimes = _intList(summary['frame_begin_times']);
  final rasterBeginTimes = _intList(summary['frame_rasterizer_begin_times']);

  if (buildTimes.length <= _warmupFrames) return summary;

  final trimmedBuild = buildTimes.sublist(_warmupFrames);
  final trimmedRaster = rasterTimes.length > _warmupFrames
      ? rasterTimes.sublist(_warmupFrames)
      : rasterTimes;
  final trimmedBegin = beginTimes.length > _warmupFrames
      ? beginTimes.sublist(_warmupFrames)
      : beginTimes;
  final trimmedRasterBegin = rasterBeginTimes.length > _warmupFrames
      ? rasterBeginTimes.sublist(_warmupFrames)
      : rasterBeginTimes;

  return {
    ...summary,
    'warmup_frames_dropped': _warmupFrames,
    'average_frame_build_time_millis': _averageMillis(trimmedBuild),
    '90th_percentile_frame_build_time_millis': _percentileMillis(
      trimmedBuild,
      90,
    ),
    '99th_percentile_frame_build_time_millis': _percentileMillis(
      trimmedBuild,
      99,
    ),
    'worst_frame_build_time_millis': _maxMillis(trimmedBuild),
    'missed_frame_build_budget_count': trimmedBuild
        .where((micros) => micros > _frameBudgetMicros)
        .length,
    'average_frame_rasterizer_time_millis': _averageMillis(trimmedRaster),
    '90th_percentile_frame_rasterizer_time_millis': _percentileMillis(
      trimmedRaster,
      90,
    ),
    '99th_percentile_frame_rasterizer_time_millis': _percentileMillis(
      trimmedRaster,
      99,
    ),
    'worst_frame_rasterizer_time_millis': _maxMillis(trimmedRaster),
    'missed_frame_rasterizer_budget_count': trimmedRaster
        .where((micros) => micros > _frameBudgetMicros)
        .length,
    'frame_count': trimmedBuild.length,
    'frame_rasterizer_count': trimmedRaster.length,
    'frame_build_times': trimmedBuild,
    'frame_rasterizer_times': trimmedRaster,
    'frame_begin_times': trimmedBegin,
    'frame_rasterizer_begin_times': trimmedRasterBegin,
  };
}

List<int> _intList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => (item as num).toInt()).toList();
}

double _averageMillis(List<int> micros) {
  if (micros.isEmpty) return 0;
  return micros.reduce((a, b) => a + b) / micros.length / 1000.0;
}

double _maxMillis(List<int> micros) {
  if (micros.isEmpty) return 0;
  return micros.reduce(max) / 1000.0;
}

double _percentileMillis(List<int> micros, int percentile) {
  if (micros.isEmpty) return 0;
  final sorted = List<int>.from(micros)..sort();
  final rank = ((percentile / 100.0) * (sorted.length - 1)).round();
  return sorted[rank] / 1000.0;
}
