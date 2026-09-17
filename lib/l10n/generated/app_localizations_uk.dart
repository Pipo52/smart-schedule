// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Розумний розклад';

  @override
  String get navHome => 'Сьогодні';

  @override
  String get navTasks => 'Завдання';

  @override
  String get navExams => 'Екзамени';

  @override
  String get navSettings => 'Налаштування';

  @override
  String todayHeader(String weekday, int week) {
    return 'Сьогодні: $weekday, Тиждень $week';
  }

  @override
  String weekLabel(int week) {
    return 'Тиждень $week';
  }

  @override
  String get week1Short => 'Тиждень 1';

  @override
  String get week2Short => 'Тиждень 2';

  @override
  String viewingAheadBanner(String week) {
    return 'Перегляд розкладу: $week';
  }

  @override
  String get tasksForTodaySection => 'Завдання на сьогодні / прострочені';

  @override
  String get ok => 'Гаразд';

  @override
  String get cancel => 'Скасувати';

  @override
  String get save => 'Зберегти';

  @override
  String get delete => 'Видалити';

  @override
  String get edit => 'Редагувати';

  @override
  String get add => 'Додати';

  @override
  String get close => 'Закрити';

  @override
  String get done => 'Виконано';

  @override
  String get confirm => 'Підтвердити';

  @override
  String get emptyLessonsTitle => 'Пар немає';

  @override
  String get emptyLessonsSubtitle =>
      'Насолоджуйтесь вільним днем або додайте пару до розкладу.';

  @override
  String get emptyTasksTitle => 'Завдань немає';

  @override
  String get emptyTasksSubtitle => 'Нічого термінового — все зроблено.';

  @override
  String get emptyExamsTitle => 'Екзаменів не заплановано';

  @override
  String get emptyExamsSubtitle =>
      'Додайте майбутній екзамен, щоб не забути про нього.';

  @override
  String get lessonTypeLecture => 'Лекція';

  @override
  String get lessonTypePractical => 'Практика';

  @override
  String get lessonTypeLaboratory => 'Лабораторна';

  @override
  String get priorityLow => 'Низький';

  @override
  String get priorityMedium => 'Середній';

  @override
  String get priorityHigh => 'Високий';

  @override
  String get examTypeMidterm => 'Модуль';

  @override
  String get examTypeFinal => 'Іспит';

  @override
  String get examTypeRetake => 'Перескладання';

  @override
  String get weekTypeEvery => 'Щотижня';

  @override
  String get weekTypeWeek1 => 'Лише Тиждень 1';

  @override
  String get weekTypeWeek2 => 'Лише Тиждень 2';

  @override
  String get tasksScreenTitle => 'Завдання';

  @override
  String get addTaskTitle => 'Нове завдання';

  @override
  String get editTaskTitle => 'Редагувати завдання';

  @override
  String get groupOverdue => 'Прострочено';

  @override
  String get groupToday => 'Сьогодні';

  @override
  String get groupThisWeek => 'Цього тижня';

  @override
  String get groupLater => 'Пізніше';

  @override
  String get sortByPriority => 'За пріоритетом';

  @override
  String get sortByDate => 'За датою';

  @override
  String get taskTitleField => 'Назва';

  @override
  String get taskSubjectField => 'Предмет (необов\'язково)';

  @override
  String get taskDescriptionField => 'Опис (необов\'язково)';

  @override
  String get taskDueDateField => 'Дедлайн';

  @override
  String get taskPriorityField => 'Пріоритет';

  @override
  String get taskReminderField => 'Нагадати за';

  @override
  String get reminderNone => 'Без нагадування';

  @override
  String reminderMinutesBefore(int minutes) {
    return 'за $minutes хв';
  }

  @override
  String get examsScreenTitle => 'Екзамени';

  @override
  String get addExamTitle => 'Новий екзамен';

  @override
  String get editExamTitle => 'Редагувати екзамен';

  @override
  String get examSubjectField => 'Предмет';

  @override
  String get examDateField => 'Дата й час';

  @override
  String get examRoomField => 'Аудиторія (необов\'язково)';

  @override
  String get examTypeField => 'Тип';

  @override
  String get examNotesField => 'Нотатки (необов\'язково)';

  @override
  String daysUntilExam(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Через $days днів',
      few: 'Через $days дні',
      one: 'Через 1 день',
      zero: 'Сьогодні',
    );
    return '$_temp0';
  }

  @override
  String get examPast => 'Минув';

  @override
  String get prepTasksTitle => 'Завдання для підготовки';

  @override
  String get addPrepTask => 'Додати завдання для підготовки';

  @override
  String get lessonFormAddTitle => 'Додати пару';

  @override
  String get lessonFormEditTitle => 'Редагувати пару';

  @override
  String get lessonSubjectField => 'Назва предмета';

  @override
  String get lessonRoomField => 'Аудиторія';

  @override
  String get lessonLecturerField => 'Викладач';

  @override
  String get lessonStartTimeField => 'Початок';

  @override
  String get lessonEndTimeField => 'Кінець';

  @override
  String get lessonWeekdayField => 'День тижня';

  @override
  String get lessonWeekTypeField => 'Періодичність';

  @override
  String get lessonNotesField => 'Нотатки (необов\'язково)';

  @override
  String get lessonReminderToggle => 'Нагадувати про цю пару';

  @override
  String get lessonTypeField => 'Тип';

  @override
  String get settingsScreenTitle => 'Налаштування';

  @override
  String get settingsResetData => 'Скинути всі дані';

  @override
  String get settingsResetDataConfirmTitle => 'Скинути всі дані?';

  @override
  String get settingsResetDataConfirmMessage =>
      'Усі пари, завдання та екзамени, що зберігаються на цьому пристрої, буде безповоротно видалено.';

  @override
  String get settingsCurrentWeekSection => 'Поточний тиждень';

  @override
  String get settingsManualOverride => 'Ручна корекція тижня';

  @override
  String get settingsManualOverrideOff =>
      'Автоматично (за датою початку семестру)';

  @override
  String get settingsSemesterReferenceDate =>
      'Початок семестру (понеділок Тижня 1)';

  @override
  String get settingsDefaultReminder => 'Нагадування про пари за замовчуванням';

  @override
  String settingsMinutesBefore(int minutes) {
    return 'за $minutes хв';
  }

  @override
  String get settingsDataSection => 'Дані';

  @override
  String get settingsExport => 'Експортувати дані (JSON)';

  @override
  String get settingsImport => 'Імпортувати дані (JSON)';

  @override
  String get settingsImportConfirmTitle => 'Імпортувати дані?';

  @override
  String get settingsImportConfirmMessage =>
      'Усі поточні пари, завдання та екзамени буде замінено вмістом обраного файлу.';

  @override
  String get settingsImportSuccess => 'Дані успішно імпортовано';

  @override
  String settingsImportError(String error) {
    return 'Не вдалося імпортувати файл: $error';
  }

  @override
  String get settingsExportSuccess => 'Резервну копію готово до передачі';

  @override
  String get settingsAppearanceSection => 'Вигляд';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeSystem => 'Системна';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get languageSystem => 'Системна';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get languageRussian => 'Русский';

  @override
  String get settingsAiSection => 'Функції ШІ';

  @override
  String get settingsGeminiApiKey => 'Ключ Gemini API';

  @override
  String get settingsGeminiApiKeyHint => 'Вставте ваш API-ключ';

  @override
  String get settingsGeminiApiKeyHelp =>
      'Безкоштовний ключ можна отримати в Google AI Studio';

  @override
  String get settingsGeminiApiKeySaved => 'API-ключ збережено';

  @override
  String get addLessonAction => 'Додати пару';

  @override
  String get manualEntry => 'Вручну';

  @override
  String get smartImport => 'Розумний імпорт';

  @override
  String get smartImportMissingKey =>
      'Спочатку додайте ключ Gemini API у Налаштуваннях.';

  @override
  String get smartImportLoading => 'ШІ читає ваш розклад…';

  @override
  String get smartImportEmpty => 'У файлі не знайдено пар.';

  @override
  String smartImportError(String error) {
    return 'Не вдалося розібрати розклад: $error';
  }

  @override
  String get smartImportFileTooLarge =>
      'Файл завеликий. Оберіть файл менше 15 МБ.';

  @override
  String get smartImportMalformed =>
      'ШІ повернув дані, які не вдалося прочитати. Спробуйте чіткіше фото або PDF.';

  @override
  String get smartImportNetwork =>
      'Помилка мережі. Перевірте з’єднання та API-ключ.';

  @override
  String get smartImportPreviewTitle => 'Перевірка імпортованих пар';

  @override
  String get smartImportSaveAll => 'Зберегти всі';

  @override
  String smartImportSaved(int count) {
    return 'Додано пар: $count';
  }

  @override
  String get confirmDeleteTitle => 'Видалити?';

  @override
  String get confirmDeleteLessonMessage =>
      'Цю пару та її нагадування буде видалено.';

  @override
  String get confirmDeleteTaskMessage => 'Це завдання буде видалено.';

  @override
  String get confirmDeleteExamMessage =>
      'Цей екзамен та його нагадування буде видалено.';
}
