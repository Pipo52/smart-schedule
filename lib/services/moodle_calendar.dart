/// One assignment deadline taken from a Moodle calendar export.
class MoodleAssignment {
  const MoodleAssignment({
    required this.uid,
    required this.title,
    required this.due,
    this.details,
    this.url,
  });

  final String uid;
  final String title;

  /// Due instant. Date-only events use 23:59 in local time. UTC events stay
  /// UTC until the caller converts them.
  final DateTime due;
  final String? details;
  final String? url;

  String get description {
    final parts = <String>[
      if (details != null && details!.trim().isNotEmpty) details!.trim(),
      if (url != null && url!.trim().isNotEmpty) url!.trim(),
    ];
    return parts.join('\n\n');
  }
}

/// Hive and Firestore id for one Moodle event. Stable across imports.
String moodleTaskId(String uid) {
  final cleaned = uid.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final id = 'moodle_$cleaned';
  if (id.length <= 120 && cleaned.isNotEmpty) return id;
  var hash = 0x811c9dc5;
  for (final unit in uid.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return 'moodle_${hash.toRadixString(16)}';
}

/// Reads a Moodle iCalendar export and keeps assignment deadlines.
///
/// Quiz closes, teacher grading dates and ordinary course events are left out.
/// The feed does not contain the assignment files; [MoodleAssignment.url]
/// points at the page where those files are.
List<MoodleAssignment> parseMoodleCalendar(String ics) {
  final unfolded = ics
      .replaceAll('\r\n', '\n')
      .replaceAll(RegExp(r'\n[ \t]'), '');
  final beginEvent = RegExp(r'^BEGIN:VEVENT\s*$', multiLine: true);
  final endEvent = RegExp(r'^END:VEVENT\s*$', multiLine: true);
  final events = <MoodleAssignment>[];
  final blocks = unfolded.split(beginEvent);
  for (final block in blocks.skip(1)) {
    final endMatch = endEvent.firstMatch(block);
    final body = endMatch == null
        ? block
        : block.substring(0, endMatch.start);
    final props = <String, String>{};
    final params = <String, String>{};
    for (final rawLine in body.split('\n')) {
      final line = rawLine.trimRight();
      if (line.isEmpty) continue;
      final split = line.indexOf(':');
      if (split <= 0) continue;
      final left = line.substring(0, split);
      final value = _unescape(line.substring(split + 1));
      final name = left.split(';').first.toUpperCase();
      props[name] = value;
      params[name] = left;
    }
    final assignment = _assignmentFrom(props, params);
    if (assignment != null) events.add(assignment);
  }
  return events;
}

MoodleAssignment? _assignmentFrom(
  Map<String, String> props,
  Map<String, String> params,
) {
  final url = props['URL']?.trim();
  final categories = (props['CATEGORIES'] ?? '').toLowerCase();
  final urlLower = (url ?? '').toLowerCase();
  final isAssignPage = urlLower.contains('/mod/assign/');
  final isGrading = categories.contains('gradingdue');
  final isDue = categories == 'due' || categories.contains('due');
  if (isGrading || !isAssignPage && !isDue) return null;
  if (!isAssignPage && urlLower.contains('/mod/')) return null;

  final uid = props['UID']?.trim();
  final summary = _plain(props['SUMMARY'] ?? '').trim();
  final due = _parseDate(props['DTSTART'], params['DTSTART'] ?? '');
  if (uid == null || uid.isEmpty || summary.isEmpty || due == null) {
    return null;
  }
  final details = _plain(props['DESCRIPTION'] ?? '').trim();
  return MoodleAssignment(
    uid: uid,
    title: summary,
    due: due,
    details: details.isEmpty ? null : details,
    url: url == null || url.isEmpty ? null : url,
  );
}

String _unescape(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char == '\\' && i + 1 < value.length) {
      final next = value[i + 1];
      switch (next) {
        case 'n':
        case 'N':
          buffer.write('\n');
        case '\\':
          buffer.write('\\');
        case ',':
          buffer.write(',');
        case ';':
          buffer.write(';');
        default:
          buffer.write(next);
      }
      i++;
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

String _plain(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

DateTime? _parseDate(String? raw, String paramText) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.length < 8) return null;
  final year = int.tryParse(value.substring(0, 4));
  final month = int.tryParse(value.substring(4, 6));
  final day = int.tryParse(value.substring(6, 8));
  if (year == null || month == null || day == null) return null;
  final dateOnly =
      paramText.toUpperCase().contains('VALUE=DATE') || !value.contains('T');
  if (dateOnly) {
    return DateTime(year, month, day, 23, 59);
  }
  if (value.length < 15) return null;
  final hour = int.tryParse(value.substring(9, 11));
  final minute = int.tryParse(value.substring(11, 13));
  final second = int.tryParse(value.substring(13, 15));
  if (hour == null || minute == null || second == null) return null;
  if (value.endsWith('Z')) {
    return DateTime.utc(year, month, day, hour, minute, second);
  }
  return DateTime(year, month, day, hour, minute, second);
}
