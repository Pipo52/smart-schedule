// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Schedule';

  @override
  String get navHome => 'Today';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navExams => 'Exams';

  @override
  String get navSettings => 'Settings';

  @override
  String todayHeader(String weekday, int week) {
    return 'Today: $weekday, Week $week';
  }

  @override
  String weekLabel(int week) {
    return 'Week $week';
  }

  @override
  String get week1Short => 'Week 1';

  @override
  String get week2Short => 'Week 2';

  @override
  String viewingAheadBanner(String week) {
    return 'Viewing schedule for $week';
  }

  @override
  String get tasksForTodaySection => 'Tasks for today / overdue';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get confirm => 'Confirm';

  @override
  String get emptyLessonsTitle => 'No lessons';

  @override
  String get emptyLessonsSubtitle =>
      'Enjoy your free day, or add a lesson to the schedule.';

  @override
  String get emptyTasksTitle => 'No tasks';

  @override
  String get emptyTasksSubtitle => 'Nothing due — you\'re all caught up.';

  @override
  String get emptyExamsTitle => 'No exams scheduled';

  @override
  String get emptyExamsSubtitle => 'Add an upcoming exam to keep track of it.';

  @override
  String get lessonTypeLecture => 'Lecture';

  @override
  String get lessonTypePractical => 'Practical';

  @override
  String get lessonTypeLaboratory => 'Laboratory';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get examTypeMidterm => 'Midterm';

  @override
  String get examTypeFinal => 'Final';

  @override
  String get examTypeRetake => 'Retake';

  @override
  String get weekTypeEvery => 'Every week';

  @override
  String get weekTypeWeek1 => 'Week 1 only';

  @override
  String get weekTypeWeek2 => 'Week 2 only';

  @override
  String get tasksScreenTitle => 'Tasks';

  @override
  String get addTaskTitle => 'Add task';

  @override
  String get editTaskTitle => 'Edit task';

  @override
  String get groupOverdue => 'Overdue';

  @override
  String get groupToday => 'Today';

  @override
  String get groupThisWeek => 'This week';

  @override
  String get groupLater => 'Later';

  @override
  String get sortByPriority => 'By priority';

  @override
  String get sortByDate => 'By date';

  @override
  String get taskTitleField => 'Title';

  @override
  String get taskSubjectField => 'Subject (optional)';

  @override
  String get taskDescriptionField => 'Description (optional)';

  @override
  String get taskDueDateField => 'Due date';

  @override
  String get taskPriorityField => 'Priority';

  @override
  String get taskReminderField => 'Remind me before';

  @override
  String get reminderNone => 'No reminder';

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes min before';
  }

  @override
  String get examsScreenTitle => 'Exams';

  @override
  String get addExamTitle => 'Add exam';

  @override
  String get editExamTitle => 'Edit exam';

  @override
  String get examSubjectField => 'Subject';

  @override
  String get examDateField => 'Date & time';

  @override
  String get examRoomField => 'Room (optional)';

  @override
  String get examTypeField => 'Type';

  @override
  String get examNotesField => 'Notes (optional)';

  @override
  String daysUntilExam(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days days',
      one: 'In 1 day',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get examPast => 'Past';

  @override
  String get prepTasksTitle => 'Preparation tasks';

  @override
  String get addPrepTask => 'Add preparation task';

  @override
  String get lessonFormAddTitle => 'Add lesson';

  @override
  String get lessonFormEditTitle => 'Edit lesson';

  @override
  String get lessonSubjectField => 'Subject name';

  @override
  String get lessonRoomField => 'Room';

  @override
  String get lessonLecturerField => 'Lecturer';

  @override
  String get lessonStartTimeField => 'Start time';

  @override
  String get lessonEndTimeField => 'End time';

  @override
  String get lessonWeekdayField => 'Day of week';

  @override
  String get lessonWeekTypeField => 'Recurrence';

  @override
  String get lessonNotesField => 'Notes (optional)';

  @override
  String get lessonReminderToggle => 'Remind me before this lesson';

  @override
  String get lessonTypeField => 'Type';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsResetData => 'Reset all data';

  @override
  String get settingsResetDataConfirmTitle => 'Reset all data?';

  @override
  String get settingsResetDataConfirmMessage =>
      'This will permanently delete all lessons, tasks and exams stored on this device. This cannot be undone.';

  @override
  String get settingsCurrentWeekSection => 'Current week';

  @override
  String get settingsManualOverride => 'Manual week override';

  @override
  String get settingsManualOverrideOff =>
      'Automatic (from semester start date)';

  @override
  String get settingsSemesterReferenceDate =>
      'Semester start date (Monday of Week 1)';

  @override
  String get settingsDefaultReminder => 'Default lesson reminder';

  @override
  String settingsMinutesBefore(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String get settingsDataSection => 'Data';

  @override
  String get settingsExport => 'Export data (JSON)';

  @override
  String get settingsImport => 'Import data (JSON)';

  @override
  String get settingsImportConfirmTitle => 'Import data?';

  @override
  String get settingsImportConfirmMessage =>
      'This will replace all current lessons, tasks and exams with the contents of the selected file.';

  @override
  String get settingsImportSuccess => 'Data imported successfully';

  @override
  String settingsImportError(String error) {
    return 'Could not import file: $error';
  }

  @override
  String get settingsExportSuccess => 'Backup ready to share';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get languageRussian => 'Русский';

  @override
  String get settingsAiSection => 'AI features';

  @override
  String get settingsGeminiApiKey => 'Gemini API key';

  @override
  String get settingsGeminiApiKeyHint => 'Paste your API key';

  @override
  String get settingsGeminiApiKeyHelp =>
      'Get your free API key at Google AI Studio';

  @override
  String get settingsGeminiApiKeySaved => 'API key saved';

  @override
  String get addLessonAction => 'Add lesson';

  @override
  String get manualEntry => 'Manual entry';

  @override
  String get smartImport => 'Smart Import';

  @override
  String get smartImportMissingKey => 'Add a Gemini API key in Settings first.';

  @override
  String get smartImportLoading => 'AI is reading your schedule…';

  @override
  String get smartImportEmpty => 'No lessons were found in this file.';

  @override
  String smartImportError(String error) {
    return 'Could not parse the schedule: $error';
  }

  @override
  String get smartImportFileTooLarge =>
      'This file is too large. Please use a file under 15 MB.';

  @override
  String get smartImportMalformed =>
      'The AI returned data we could not read. Try a clearer photo or PDF.';

  @override
  String get smartImportNetwork =>
      'Network error. Check your connection and API key.';

  @override
  String get smartImportPreviewTitle => 'Review imported lessons';

  @override
  String get smartImportSaveAll => 'Save all';

  @override
  String smartImportSaved(int count) {
    return '$count lessons added to your schedule';
  }

  @override
  String get confirmDeleteTitle => 'Delete?';

  @override
  String get confirmDeleteLessonMessage =>
      'This lesson and its reminders will be removed.';

  @override
  String get confirmDeleteTaskMessage => 'This task will be removed.';

  @override
  String get confirmDeleteExamMessage =>
      'This exam and its reminders will be removed.';
}
