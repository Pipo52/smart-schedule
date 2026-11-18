# Smart Schedule

A Flutter app for university timetables. You can keep lessons, tasks and exams, switch between Week 1 and Week 2, and import a timetable from a photo or PDF with Gemini.

The interface language can be English, Russian or Ukrainian.

## Features

- **Today’s schedule**, with a Week 1 / Week 2 rotation based on the semester start date (or a manual override).
- **Lessons** (lecture, practical, laboratory), with reminders. You can cancel or edit a single occurrence without changing the recurring lesson.
- **Tasks** with a due date, priority and optional reminder, grouped as overdue, today, this week or later.
- **Exams** (midterm, final, retake), with optional preparation tasks.
- **Academic calendar** for study weeks, exam sessions, holidays and retake weeks.
- **Several named schedules** (for example, two programmes or two semesters).
- **Smart Import.** Send a timetable photo or PDF (under 15 MB) to Gemini, then review the lessons before saving.
- **Smart input.** Describe a task, a lesson, a cancellation or a calendar period in plain language.
- **Moodle.** Paste a Moodle calendar export link to load assignment deadlines as tasks.
- **Accounts.** Sign in with email or Google. Data is stored locally with Hive and can be synced to Firestore. You can also export or import a JSON backup.
- **Android home-screen widget** for upcoming classes.
- Light and dark themes, and local notifications for lessons and tasks.

## Tech stack

- Flutter and Dart, with Provider for state and Hive for local storage
- Firebase Authentication and Cloud Firestore (configured for **Android** and **web**)
- Gemini (`google_generative_ai`) for Smart Import and Smart input — you paste your own API key in Settings
- `flutter_local_notifications` for reminders

The repository also has an `ios/` project, but Firebase is not configured for iOS yet, so cloud sign-in is not set up on that platform.

## Run locally

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter run            # pick a device or an emulator
flutter run -d chrome  # web
```

## Testing

```bash
flutter test
```

There are **59 tests** in `test/` (48 unit tests and 11 widget tests). There is also one integration test, `integration_test/scroll_perf_test.dart`, which measures scroll performance on the home screen.

## How this was built

Most of the code was written with AI tools (Cursor, Claude, Gemini/Antigravity) under my direction. I planned the features, wrote the specs, reviewed every change and tested the result.

---

Rostyslav Perlyk, 2nd-year IT student at VILNIUS TECH.
