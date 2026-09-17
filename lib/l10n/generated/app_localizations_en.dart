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
  String get smartInput => 'Smart input';

  @override
  String get smartInputHint => 'Describe what you need…';

  @override
  String get smartInputLoading => 'Thinking…';

  @override
  String smartInputTaskCreated(String title) {
    return 'Task created: $title';
  }

  @override
  String smartInputLessonCreated(String subject) {
    return 'Lesson added: $subject';
  }

  @override
  String get smartInputUnknown =>
      'Couldn\'t understand the request. Try: \"Remind me to do the physics homework by Friday\" or \"Add a math lecture Mon 9:00-10:30\"';

  @override
  String smartInputError(String error) {
    return 'AI error: $error';
  }

  @override
  String get navCalendar => 'Calendar';

  @override
  String get academicCalendarTitle => 'Academic Calendar';

  @override
  String get addPeriod => 'Add period';

  @override
  String get editPeriod => 'Edit period';

  @override
  String get periodNameField => 'Period name';

  @override
  String get periodTypeField => 'Type';

  @override
  String get periodStartDate => 'Start date';

  @override
  String get periodEndDate => 'End date';

  @override
  String get periodTypeStudy => 'Study weeks';

  @override
  String get periodTypeExam => 'Exam session';

  @override
  String get periodTypeHoliday => 'Holidays';

  @override
  String get periodTypeRetake => 'Retake weeks';

  @override
  String get periodTypePublicHoliday => 'Public holiday';

  @override
  String get periodTypeOther => 'Other';

  @override
  String get emptyPeriodsTitle => 'No periods defined';

  @override
  String get emptyPeriodsSubtitle =>
      'Add semester periods to see your academic year at a glance.';

  @override
  String get periodLegend => 'Legend';

  @override
  String get profileName => 'Schedule name';

  @override
  String get createSchedule => 'Create schedule';

  @override
  String get renameSchedule => 'Rename schedule';

  @override
  String get createNewSchedule => 'Create new schedule';

  @override
  String get rename => 'Rename';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get deleteScheduleTitle => 'Delete schedule?';

  @override
  String deleteScheduleMessage(String name) {
    return 'This will permanently delete \"$name\" and all its lessons, tasks and exams.';
  }

  @override
  String get cannotDeleteLastSchedule => 'The last schedule cannot be deleted.';

  @override
  String get settingsStartupSection => 'Open on startup';

  @override
  String get startupDefaultSchedule => 'Default schedule';

  @override
  String get startupLastOpened => 'Last opened';

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

  @override
  String get cancelThisClass => 'Cancel this class';

  @override
  String get editThisOccurrence => 'Edit this occurrence';

  @override
  String get editRecurringLesson => 'Edit recurring lesson';

  @override
  String lessonCancelled(String subject, String date) {
    return '$subject cancelled for $date';
  }

  @override
  String get restoreLesson => 'Restore';

  @override
  String get cancelledBadge => 'Cancelled';

  @override
  String get modifiedBadge => 'Modified';

  @override
  String get occurrenceFormTitle => 'Edit this occurrence';

  @override
  String smartInputPeriodCreated(String name) {
    return 'Period added: $name';
  }

  @override
  String smartInputLessonCancelled(String subject) {
    return 'Lesson cancelled: $subject';
  }

  @override
  String get smartInputLessonNotFound =>
      'Could not find a matching lesson to cancel';

  @override
  String get nothingChanged => 'Nothing changed';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authEmailField => 'Email';

  @override
  String get authPasswordField => 'Password';

  @override
  String get authSignInButton => 'Sign in';

  @override
  String get authSignUpButton => 'Sign up';

  @override
  String get authSwitchToSignUp => 'Don\'t have an account? Sign up';

  @override
  String get authSwitchToSignIn => 'Already have an account? Sign in';

  @override
  String get authEmailRequired => 'Enter your email';

  @override
  String get authPasswordRequired => 'Enter your password';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String settingsSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get settingsSignOut => 'Sign out';
}
