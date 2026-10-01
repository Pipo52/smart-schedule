import 'package:http/http.dart' as http;

import 'moodle_calendar.dart';

class MoodleCalendarException implements Exception {
  const MoodleCalendarException(this.reason);

  final String reason;

  @override
  String toString() => reason;
}

/// Downloads a secret Moodle calendar link. The link itself is a password:
/// callers keep it in secure storage and do not upload it.
class MoodleSyncService {
  const MoodleSyncService();

  Future<List<MoodleAssignment>> fetchAssignments(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const MoodleCalendarException('https');
    }
    final http.Response response;
    try {
      response = await http
          .get(uri, headers: const {'Accept': 'text/calendar, text/plain, */*'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const MoodleCalendarException('network');
    }
    if (response.statusCode != 200) {
      throw MoodleCalendarException('status ${response.statusCode}');
    }
    return parseMoodleCalendar(response.body);
  }
}
