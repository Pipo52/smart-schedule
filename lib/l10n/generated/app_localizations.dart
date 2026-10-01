import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uk'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Smart Schedule'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navHome;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navExams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get navExams;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @todayHeader.
  ///
  /// In en, this message translates to:
  /// **'Today: {weekday}, Week {week}'**
  String todayHeader(String weekday, int week);

  /// No description provided for @weekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String weekLabel(int week);

  /// No description provided for @week1Short.
  ///
  /// In en, this message translates to:
  /// **'Week 1'**
  String get week1Short;

  /// No description provided for @week2Short.
  ///
  /// In en, this message translates to:
  /// **'Week 2'**
  String get week2Short;

  /// No description provided for @viewingAheadBanner.
  ///
  /// In en, this message translates to:
  /// **'Viewing schedule for {week}'**
  String viewingAheadBanner(String week);

  /// No description provided for @tasksForTodaySection.
  ///
  /// In en, this message translates to:
  /// **'Tasks for today / overdue'**
  String get tasksForTodaySection;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get fieldRequired;

  /// No description provided for @emptyLessonsTitle.
  ///
  /// In en, this message translates to:
  /// **'No lessons'**
  String get emptyLessonsTitle;

  /// No description provided for @emptyLessonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your free day, or add a lesson to the schedule.'**
  String get emptyLessonsSubtitle;

  /// No description provided for @emptyTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get emptyTasksTitle;

  /// No description provided for @emptyTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing due — you\'re all caught up.'**
  String get emptyTasksSubtitle;

  /// No description provided for @emptyExamsTitle.
  ///
  /// In en, this message translates to:
  /// **'No exams scheduled'**
  String get emptyExamsTitle;

  /// No description provided for @emptyExamsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an upcoming exam to keep track of it.'**
  String get emptyExamsSubtitle;

  /// No description provided for @lessonTypeLecture.
  ///
  /// In en, this message translates to:
  /// **'Lecture'**
  String get lessonTypeLecture;

  /// No description provided for @lessonTypePractical.
  ///
  /// In en, this message translates to:
  /// **'Practical'**
  String get lessonTypePractical;

  /// No description provided for @lessonTypeLaboratory.
  ///
  /// In en, this message translates to:
  /// **'Laboratory'**
  String get lessonTypeLaboratory;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @examTypeMidterm.
  ///
  /// In en, this message translates to:
  /// **'Midterm'**
  String get examTypeMidterm;

  /// No description provided for @examTypeFinal.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get examTypeFinal;

  /// No description provided for @examTypeRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get examTypeRetake;

  /// No description provided for @weekTypeEvery.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get weekTypeEvery;

  /// No description provided for @weekTypeWeek1.
  ///
  /// In en, this message translates to:
  /// **'Week 1 only'**
  String get weekTypeWeek1;

  /// No description provided for @weekTypeWeek2.
  ///
  /// In en, this message translates to:
  /// **'Week 2 only'**
  String get weekTypeWeek2;

  /// No description provided for @tasksScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksScreenTitle;

  /// No description provided for @addTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTaskTitle;

  /// No description provided for @editTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTaskTitle;

  /// No description provided for @groupOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get groupOverdue;

  /// No description provided for @groupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get groupToday;

  /// No description provided for @groupThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get groupThisWeek;

  /// No description provided for @groupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get groupLater;

  /// No description provided for @sortByPriority.
  ///
  /// In en, this message translates to:
  /// **'By priority'**
  String get sortByPriority;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get sortByDate;

  /// No description provided for @taskTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitleField;

  /// No description provided for @taskSubjectField.
  ///
  /// In en, this message translates to:
  /// **'Subject (optional)'**
  String get taskSubjectField;

  /// No description provided for @taskDescriptionField.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get taskDescriptionField;

  /// No description provided for @taskDueDateField.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskDueDateField;

  /// No description provided for @taskPriorityField.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskPriorityField;

  /// No description provided for @taskReminderField.
  ///
  /// In en, this message translates to:
  /// **'Remind me before'**
  String get taskReminderField;

  /// No description provided for @reminderNone.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get reminderNone;

  /// No description provided for @reminderMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String reminderMinutesBefore(int minutes);

  /// No description provided for @examsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get examsScreenTitle;

  /// No description provided for @addExamTitle.
  ///
  /// In en, this message translates to:
  /// **'Add exam'**
  String get addExamTitle;

  /// No description provided for @editExamTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit exam'**
  String get editExamTitle;

  /// No description provided for @examSubjectField.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get examSubjectField;

  /// No description provided for @examDateField.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get examDateField;

  /// No description provided for @examRoomField.
  ///
  /// In en, this message translates to:
  /// **'Room (optional)'**
  String get examRoomField;

  /// No description provided for @examTypeField.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get examTypeField;

  /// No description provided for @examNotesField.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get examNotesField;

  /// No description provided for @daysUntilExam.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Today} =1{In 1 day} other{In {days} days}}'**
  String daysUntilExam(int days);

  /// No description provided for @examPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get examPast;

  /// No description provided for @prepTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparation tasks'**
  String get prepTasksTitle;

  /// No description provided for @addPrepTask.
  ///
  /// In en, this message translates to:
  /// **'Add preparation task'**
  String get addPrepTask;

  /// No description provided for @lessonFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add lesson'**
  String get lessonFormAddTitle;

  /// No description provided for @lessonFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit lesson'**
  String get lessonFormEditTitle;

  /// No description provided for @lessonSubjectField.
  ///
  /// In en, this message translates to:
  /// **'Subject name'**
  String get lessonSubjectField;

  /// No description provided for @lessonRoomField.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get lessonRoomField;

  /// No description provided for @lessonLecturerField.
  ///
  /// In en, this message translates to:
  /// **'Lecturer'**
  String get lessonLecturerField;

  /// No description provided for @lessonStartTimeField.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get lessonStartTimeField;

  /// No description provided for @lessonEndTimeField.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get lessonEndTimeField;

  /// No description provided for @lessonWeekdayField.
  ///
  /// In en, this message translates to:
  /// **'Day of week'**
  String get lessonWeekdayField;

  /// No description provided for @lessonWeekTypeField.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get lessonWeekTypeField;

  /// No description provided for @lessonNotesField.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get lessonNotesField;

  /// No description provided for @lessonReminderToggle.
  ///
  /// In en, this message translates to:
  /// **'Remind me before this lesson'**
  String get lessonReminderToggle;

  /// No description provided for @lessonTypeField.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get lessonTypeField;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @settingsResetData.
  ///
  /// In en, this message translates to:
  /// **'Reset all data'**
  String get settingsResetData;

  /// No description provided for @settingsResetDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all data?'**
  String get settingsResetDataConfirmTitle;

  /// No description provided for @settingsResetDataConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all lessons, tasks and exams stored on this device. This cannot be undone.'**
  String get settingsResetDataConfirmMessage;

  /// No description provided for @settingsCurrentWeekSection.
  ///
  /// In en, this message translates to:
  /// **'Current week'**
  String get settingsCurrentWeekSection;

  /// No description provided for @settingsManualOverride.
  ///
  /// In en, this message translates to:
  /// **'Manual week override'**
  String get settingsManualOverride;

  /// No description provided for @settingsManualOverrideOff.
  ///
  /// In en, this message translates to:
  /// **'Automatic (from semester start date)'**
  String get settingsManualOverrideOff;

  /// No description provided for @settingsSemesterReferenceDate.
  ///
  /// In en, this message translates to:
  /// **'Semester start date (Monday of Week 1)'**
  String get settingsSemesterReferenceDate;

  /// No description provided for @settingsDefaultReminder.
  ///
  /// In en, this message translates to:
  /// **'Default lesson reminder'**
  String get settingsDefaultReminder;

  /// No description provided for @settingsMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String settingsMinutesBefore(int minutes);

  /// No description provided for @settingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsDataSection;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export data (JSON)'**
  String get settingsExport;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import data (JSON)'**
  String get settingsImport;

  /// No description provided for @settingsImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import data?'**
  String get settingsImportConfirmTitle;

  /// No description provided for @settingsImportConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current lessons, tasks and exams with the contents of the selected file.'**
  String get settingsImportConfirmMessage;

  /// No description provided for @settingsImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully'**
  String get settingsImportSuccess;

  /// No description provided for @settingsImportError.
  ///
  /// In en, this message translates to:
  /// **'Could not import file: {error}'**
  String settingsImportError(String error);

  /// No description provided for @settingsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup ready to share'**
  String get settingsExportSuccess;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUkrainian.
  ///
  /// In en, this message translates to:
  /// **'Українська'**
  String get languageUkrainian;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @settingsMoodleSection.
  ///
  /// In en, this message translates to:
  /// **'Moodle'**
  String get settingsMoodleSection;

  /// No description provided for @settingsMoodleUrl.
  ///
  /// In en, this message translates to:
  /// **'Calendar link'**
  String get settingsMoodleUrl;

  /// No description provided for @settingsMoodleUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://…/calendar/export_execute.php?…'**
  String get settingsMoodleUrlHint;

  /// No description provided for @settingsMoodleHelp.
  ///
  /// In en, this message translates to:
  /// **'In Moodle open Calendar → Export calendar and paste the link. Assignment names and due dates become tasks. The files stay on the assignment page; its link is saved in the task.'**
  String get settingsMoodleHelp;

  /// No description provided for @settingsMoodleSaved.
  ///
  /// In en, this message translates to:
  /// **'Moodle link saved'**
  String get settingsMoodleSaved;

  /// No description provided for @settingsMoodleLoad.
  ///
  /// In en, this message translates to:
  /// **'Load assignments'**
  String get settingsMoodleLoad;

  /// No description provided for @settingsMoodleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assignment deadlines were found in this calendar.'**
  String get settingsMoodleEmpty;

  /// No description provided for @settingsMoodleResult.
  ///
  /// In en, this message translates to:
  /// **'Added {added}, updated {updated}'**
  String settingsMoodleResult(int added, int updated);

  /// No description provided for @settingsMoodleErrorHttps.
  ///
  /// In en, this message translates to:
  /// **'The link has to start with https.'**
  String get settingsMoodleErrorHttps;

  /// No description provided for @settingsMoodleErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the calendar. Check the link and your connection.'**
  String get settingsMoodleErrorNetwork;

  /// No description provided for @settingsMoodleErrorStatus.
  ///
  /// In en, this message translates to:
  /// **'Moodle refused the link. Create a new calendar link and try again.'**
  String get settingsMoodleErrorStatus;

  /// No description provided for @settingsAiSection.
  ///
  /// In en, this message translates to:
  /// **'AI features'**
  String get settingsAiSection;

  /// No description provided for @settingsGeminiApiKey.
  ///
  /// In en, this message translates to:
  /// **'Gemini API key'**
  String get settingsGeminiApiKey;

  /// No description provided for @settingsGeminiApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your API key'**
  String get settingsGeminiApiKeyHint;

  /// No description provided for @settingsGeminiApiKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Get your free API key at Google AI Studio'**
  String get settingsGeminiApiKeyHelp;

  /// No description provided for @settingsGeminiApiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved'**
  String get settingsGeminiApiKeySaved;

  /// No description provided for @addLessonAction.
  ///
  /// In en, this message translates to:
  /// **'Add lesson'**
  String get addLessonAction;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get manualEntry;

  /// No description provided for @smartImport.
  ///
  /// In en, this message translates to:
  /// **'Smart Import'**
  String get smartImport;

  /// No description provided for @smartImportMissingKey.
  ///
  /// In en, this message translates to:
  /// **'Add a Gemini API key in Settings first.'**
  String get smartImportMissingKey;

  /// No description provided for @smartImportLoading.
  ///
  /// In en, this message translates to:
  /// **'AI is reading your schedule…'**
  String get smartImportLoading;

  /// No description provided for @smartImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lessons were found in this file.'**
  String get smartImportEmpty;

  /// No description provided for @smartImportError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse the schedule: {error}'**
  String smartImportError(String error);

  /// No description provided for @smartImportFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large. Please use a file under 15 MB.'**
  String get smartImportFileTooLarge;

  /// No description provided for @smartImportMalformed.
  ///
  /// In en, this message translates to:
  /// **'The AI returned data we could not read. Try a clearer photo or PDF.'**
  String get smartImportMalformed;

  /// No description provided for @smartImportNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and API key.'**
  String get smartImportNetwork;

  /// No description provided for @smartImportPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review imported lessons'**
  String get smartImportPreviewTitle;

  /// No description provided for @smartImportSaveAll.
  ///
  /// In en, this message translates to:
  /// **'Save all'**
  String get smartImportSaveAll;

  /// No description provided for @smartImportSaved.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons added to your schedule'**
  String smartImportSaved(int count);

  /// Menu option for AI text input
  ///
  /// In en, this message translates to:
  /// **'Smart input'**
  String get smartInput;

  /// No description provided for @smartInputHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need…'**
  String get smartInputHint;

  /// No description provided for @smartInputLoading.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get smartInputLoading;

  /// No description provided for @smartInputTaskCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created: {title}'**
  String smartInputTaskCreated(String title);

  /// No description provided for @smartInputLessonCreated.
  ///
  /// In en, this message translates to:
  /// **'Lesson added: {subject}'**
  String smartInputLessonCreated(String subject);

  /// No description provided for @smartInputUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t understand the request. Try: \"Remind me to do the physics homework by Friday\" or \"Add a math lecture Mon 9:00-10:30\"'**
  String get smartInputUnknown;

  /// No description provided for @smartInputError.
  ///
  /// In en, this message translates to:
  /// **'AI error: {error}'**
  String smartInputError(String error);

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @academicCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic Calendar'**
  String get academicCalendarTitle;

  /// No description provided for @addPeriod.
  ///
  /// In en, this message translates to:
  /// **'Add period'**
  String get addPeriod;

  /// No description provided for @editPeriod.
  ///
  /// In en, this message translates to:
  /// **'Edit period'**
  String get editPeriod;

  /// No description provided for @periodNameField.
  ///
  /// In en, this message translates to:
  /// **'Period name'**
  String get periodNameField;

  /// No description provided for @periodTypeField.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get periodTypeField;

  /// No description provided for @periodStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get periodStartDate;

  /// No description provided for @periodEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get periodEndDate;

  /// No description provided for @periodTypeStudy.
  ///
  /// In en, this message translates to:
  /// **'Study weeks'**
  String get periodTypeStudy;

  /// No description provided for @periodTypeExam.
  ///
  /// In en, this message translates to:
  /// **'Exam session'**
  String get periodTypeExam;

  /// No description provided for @periodTypeHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get periodTypeHoliday;

  /// No description provided for @periodTypeRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake weeks'**
  String get periodTypeRetake;

  /// No description provided for @periodTypePublicHoliday.
  ///
  /// In en, this message translates to:
  /// **'Public holiday'**
  String get periodTypePublicHoliday;

  /// No description provided for @periodTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get periodTypeOther;

  /// No description provided for @emptyPeriodsTitle.
  ///
  /// In en, this message translates to:
  /// **'No periods defined'**
  String get emptyPeriodsTitle;

  /// No description provided for @emptyPeriodsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add semester periods to see your academic year at a glance.'**
  String get emptyPeriodsSubtitle;

  /// No description provided for @periodLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get periodLegend;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Schedule name'**
  String get profileName;

  /// No description provided for @createSchedule.
  ///
  /// In en, this message translates to:
  /// **'Create schedule'**
  String get createSchedule;

  /// No description provided for @renameSchedule.
  ///
  /// In en, this message translates to:
  /// **'Rename schedule'**
  String get renameSchedule;

  /// No description provided for @createNewSchedule.
  ///
  /// In en, this message translates to:
  /// **'Create new schedule'**
  String get createNewSchedule;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @deleteScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule?'**
  String get deleteScheduleTitle;

  /// No description provided for @deleteScheduleMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{name}\" and all its lessons, tasks and exams.'**
  String deleteScheduleMessage(String name);

  /// No description provided for @cannotDeleteLastSchedule.
  ///
  /// In en, this message translates to:
  /// **'The last schedule cannot be deleted.'**
  String get cannotDeleteLastSchedule;

  /// No description provided for @settingsStartupSection.
  ///
  /// In en, this message translates to:
  /// **'Open on startup'**
  String get settingsStartupSection;

  /// No description provided for @startupDefaultSchedule.
  ///
  /// In en, this message translates to:
  /// **'Default schedule'**
  String get startupDefaultSchedule;

  /// No description provided for @startupLastOpened.
  ///
  /// In en, this message translates to:
  /// **'Last opened'**
  String get startupLastOpened;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteLessonMessage.
  ///
  /// In en, this message translates to:
  /// **'This lesson and its reminders will be removed.'**
  String get confirmDeleteLessonMessage;

  /// No description provided for @confirmDeleteTaskMessage.
  ///
  /// In en, this message translates to:
  /// **'This task will be removed.'**
  String get confirmDeleteTaskMessage;

  /// No description provided for @confirmDeleteExamMessage.
  ///
  /// In en, this message translates to:
  /// **'This exam and its reminders will be removed.'**
  String get confirmDeleteExamMessage;

  /// No description provided for @cancelThisClass.
  ///
  /// In en, this message translates to:
  /// **'Cancel this class'**
  String get cancelThisClass;

  /// No description provided for @editThisOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Edit this occurrence'**
  String get editThisOccurrence;

  /// No description provided for @editRecurringLesson.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring lesson'**
  String get editRecurringLesson;

  /// No description provided for @lessonCancelled.
  ///
  /// In en, this message translates to:
  /// **'{subject} cancelled for {date}'**
  String lessonCancelled(String subject, String date);

  /// No description provided for @restoreLesson.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreLesson;

  /// No description provided for @restoreThisClass.
  ///
  /// In en, this message translates to:
  /// **'Restore class'**
  String get restoreThisClass;

  /// No description provided for @cancelledBadge.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledBadge;

  /// No description provided for @modifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modifiedBadge;

  /// No description provided for @occurrenceFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit this occurrence'**
  String get occurrenceFormTitle;

  /// No description provided for @smartInputPeriodCreated.
  ///
  /// In en, this message translates to:
  /// **'Period added: {name}'**
  String smartInputPeriodCreated(String name);

  /// No description provided for @smartInputLessonCancelled.
  ///
  /// In en, this message translates to:
  /// **'Lesson cancelled: {subject}'**
  String smartInputLessonCancelled(String subject);

  /// No description provided for @smartInputLessonNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find a matching lesson to cancel'**
  String get smartInputLessonNotFound;

  /// No description provided for @nothingChanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed'**
  String get nothingChanged;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpTitle;

  /// No description provided for @authEmailField.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailField;

  /// No description provided for @authPasswordField.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordField;

  /// No description provided for @authSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInButton;

  /// No description provided for @authSignUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUpButton;

  /// No description provided for @authSwitchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authSwitchToSignUp;

  /// No description provided for @authSwitchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authSwitchToSignIn;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authConfirmPasswordField.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordField;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get authErrorEmailAlreadyInUse;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak (minimum 6 characters)'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again later'**
  String get authErrorGeneric;

  /// No description provided for @settingsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// No description provided for @settingsSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String settingsSignedInAs(String email);

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @authOrDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authOrDivider;

  /// No description provided for @authSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authSignInWithGoogle;

  /// No description provided for @breakShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min break'**
  String breakShort(int minutes);

  /// No description provided for @breakLong.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m window'**
  String breakLong(int hours, int minutes);

  /// No description provided for @breakHoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours}h window'**
  String breakHoursOnly(int hours);

  /// No description provided for @lessonTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String lessonTimeRemaining(int minutes);

  /// No description provided for @lessonTimeRemainingHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left'**
  String lessonTimeRemainingHours(int hours, int minutes);

  /// No description provided for @lessonTimeRemainingHoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours}h left'**
  String lessonTimeRemainingHoursOnly(int hours);

  /// No description provided for @cloudSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save to the cloud. Try again.'**
  String get cloudSaveFailed;

  /// No description provided for @cloudOutOfDate.
  ///
  /// In en, this message translates to:
  /// **'Not in the cloud yet. These changes are still on this device.'**
  String get cloudOutOfDate;

  /// No description provided for @cloudSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get cloudSendNow;

  /// No description provided for @settingsUploadToCloud.
  ///
  /// In en, this message translates to:
  /// **'Send to the cloud'**
  String get settingsUploadToCloud;

  /// No description provided for @settingsUploadToCloudSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sends changes that are still only on this device.'**
  String get settingsUploadToCloudSubtitle;

  /// No description provided for @reminderWindowEnding.
  ///
  /// In en, this message translates to:
  /// **'Lesson reminders run out soon. Open the app to refresh them.'**
  String get reminderWindowEnding;

  /// No description provided for @settingsBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Let reminders run in the background'**
  String get settingsBatteryTitle;

  /// No description provided for @settingsBatterySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Battery saving on this phone can stop lesson alarms. Turn off optimization for Smart Schedule.'**
  String get settingsBatterySubtitle;

  /// No description provided for @widgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming classes'**
  String get widgetEmpty;

  /// No description provided for @widgetNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get widgetNow;

  /// No description provided for @widgetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get widgetToday;

  /// No description provided for @widgetTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get widgetTomorrow;

  /// No description provided for @widgetNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get widgetNext;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
