import 'package:flutter_test/flutter_test.dart';
import 'package:smart_schedule/services/moodle_calendar.dart';

void main() {
  test('assignment deadlines are kept and other events are skipped', () {
    const ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:99@moodle.example
SUMMARY:Эссе по физике
DESCRIPTION:Курс: Физика\\nСдайте файл в Moodle
DTSTART:20261015T150000Z
URL:https://moodle.example/mod/assign/view.php?id=42
CATEGORIES:due
END:VEVENT
BEGIN:VEVENT
UID:quiz@moodle.example
SUMMARY:Тест
DTSTART:20261016T100000Z
URL:https://moodle.example/mod/quiz/view.php?id=7
CATEGORIES:close
END:VEVENT
BEGIN:VEVENT
UID:grade@moodle.example
SUMMARY:Проверить работы
DTSTART:20261020T100000Z
URL:https://moodle.example/mod/assign/view.php?id=42
CATEGORIES:gradingdue
END:VEVENT
END:VCALENDAR
''';

    final assignments = parseMoodleCalendar(ics);

    expect(assignments, hasLength(1));
    expect(assignments.single.title, 'Эссе по физике');
    expect(assignments.single.due, DateTime.utc(2026, 10, 15, 15));
    expect(assignments.single.details, 'Курс: Физика\nСдайте файл в Moodle');
    expect(
      assignments.single.description,
      'Курс: Физика\nСдайте файл в Moodle\n\n'
      'https://moodle.example/mod/assign/view.php?id=42',
    );
    expect(moodleTaskId(assignments.single.uid), 'moodle_99_moodle_example');
  });

  test('folded lines and a date-only deadline are read', () {
    const ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:long-id
SUMMARY:Длинное назван
 ие
DTSTART;VALUE=DATE:20261101
URL:https://moodle.example/mod/assign/view.php?id=9
CATEGORIES:due
END:VEVENT
END:VCALENDAR
''';

    final assignments = parseMoodleCalendar(ics);

    expect(assignments.single.title, 'Длинное название');
    expect(assignments.single.due, DateTime(2026, 11, 1, 23, 59));
  });
}
