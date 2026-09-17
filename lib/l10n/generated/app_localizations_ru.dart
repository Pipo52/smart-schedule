// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Умное расписание';

  @override
  String get navHome => 'Сегодня';

  @override
  String get navTasks => 'Задания';

  @override
  String get navExams => 'Экзамены';

  @override
  String get navSettings => 'Настройки';

  @override
  String todayHeader(String weekday, int week) {
    return 'Сегодня: $weekday, Неделя $week';
  }

  @override
  String weekLabel(int week) {
    return 'Неделя $week';
  }

  @override
  String get week1Short => 'Неделя 1';

  @override
  String get week2Short => 'Неделя 2';

  @override
  String viewingAheadBanner(String week) {
    return 'Просмотр расписания: $week';
  }

  @override
  String get tasksForTodaySection => 'Задачи на сегодня / просроченные';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get add => 'Добавить';

  @override
  String get close => 'Закрыть';

  @override
  String get done => 'Выполнено';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get emptyLessonsTitle => 'Пар нет';

  @override
  String get emptyLessonsSubtitle =>
      'Наслаждайтесь свободным днём или добавьте пару в расписание.';

  @override
  String get emptyTasksTitle => 'Заданий нет';

  @override
  String get emptyTasksSubtitle => 'Ничего срочного — всё сделано.';

  @override
  String get emptyExamsTitle => 'Экзамены не запланированы';

  @override
  String get emptyExamsSubtitle =>
      'Добавьте предстоящий экзамен, чтобы не забыть о нём.';

  @override
  String get lessonTypeLecture => 'Лекция';

  @override
  String get lessonTypePractical => 'Практика';

  @override
  String get lessonTypeLaboratory => 'Лабораторная';

  @override
  String get priorityLow => 'Низкий';

  @override
  String get priorityMedium => 'Средний';

  @override
  String get priorityHigh => 'Высокий';

  @override
  String get examTypeMidterm => 'Модуль';

  @override
  String get examTypeFinal => 'Экзамен';

  @override
  String get examTypeRetake => 'Пересдача';

  @override
  String get weekTypeEvery => 'Каждую неделю';

  @override
  String get weekTypeWeek1 => 'Только Неделя 1';

  @override
  String get weekTypeWeek2 => 'Только Неделя 2';

  @override
  String get tasksScreenTitle => 'Задания';

  @override
  String get addTaskTitle => 'Новое задание';

  @override
  String get editTaskTitle => 'Редактировать задание';

  @override
  String get groupOverdue => 'Просрочено';

  @override
  String get groupToday => 'Сегодня';

  @override
  String get groupThisWeek => 'Эта неделя';

  @override
  String get groupLater => 'Позже';

  @override
  String get sortByPriority => 'По приоритету';

  @override
  String get sortByDate => 'По дате';

  @override
  String get taskTitleField => 'Название';

  @override
  String get taskSubjectField => 'Предмет (необязательно)';

  @override
  String get taskDescriptionField => 'Описание (необязательно)';

  @override
  String get taskDueDateField => 'Дедлайн';

  @override
  String get taskPriorityField => 'Приоритет';

  @override
  String get taskReminderField => 'Напомнить за';

  @override
  String get reminderNone => 'Без напоминания';

  @override
  String reminderMinutesBefore(int minutes) {
    return 'за $minutes мин';
  }

  @override
  String get examsScreenTitle => 'Экзамены';

  @override
  String get addExamTitle => 'Новый экзамен';

  @override
  String get editExamTitle => 'Редактировать экзамен';

  @override
  String get examSubjectField => 'Предмет';

  @override
  String get examDateField => 'Дата и время';

  @override
  String get examRoomField => 'Кабинет (необязательно)';

  @override
  String get examTypeField => 'Тип';

  @override
  String get examNotesField => 'Заметки (необязательно)';

  @override
  String daysUntilExam(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Через $days дней',
      few: 'Через $days дня',
      one: 'Через 1 день',
      zero: 'Сегодня',
    );
    return '$_temp0';
  }

  @override
  String get examPast => 'Прошёл';

  @override
  String get prepTasksTitle => 'Задачи для подготовки';

  @override
  String get addPrepTask => 'Добавить задачу для подготовки';

  @override
  String get lessonFormAddTitle => 'Добавить пару';

  @override
  String get lessonFormEditTitle => 'Редактировать пару';

  @override
  String get lessonSubjectField => 'Название предмета';

  @override
  String get lessonRoomField => 'Кабинет';

  @override
  String get lessonLecturerField => 'Преподаватель';

  @override
  String get lessonStartTimeField => 'Начало';

  @override
  String get lessonEndTimeField => 'Конец';

  @override
  String get lessonWeekdayField => 'День недели';

  @override
  String get lessonWeekTypeField => 'Периодичность';

  @override
  String get lessonNotesField => 'Заметки (необязательно)';

  @override
  String get lessonReminderToggle => 'Напоминать об этой паре';

  @override
  String get lessonTypeField => 'Тип';

  @override
  String get settingsScreenTitle => 'Настройки';

  @override
  String get settingsResetData => 'Сбросить все данные';

  @override
  String get settingsResetDataConfirmTitle => 'Сбросить все данные?';

  @override
  String get settingsResetDataConfirmMessage =>
      'Все пары, задания и экзамены, хранящиеся на этом устройстве, будут безвозвратно удалены.';

  @override
  String get settingsCurrentWeekSection => 'Текущая неделя';

  @override
  String get settingsManualOverride => 'Ручная коррекция недели';

  @override
  String get settingsManualOverrideOff =>
      'Автоматически (по дате начала семестра)';

  @override
  String get settingsSemesterReferenceDate =>
      'Начало семестра (понедельник Недели 1)';

  @override
  String get settingsDefaultReminder => 'Напоминание о парах по умолчанию';

  @override
  String settingsMinutesBefore(int minutes) {
    return 'за $minutes мин';
  }

  @override
  String get settingsDataSection => 'Данные';

  @override
  String get settingsExport => 'Экспортировать данные (JSON)';

  @override
  String get settingsImport => 'Импортировать данные (JSON)';

  @override
  String get settingsImportConfirmTitle => 'Импортировать данные?';

  @override
  String get settingsImportConfirmMessage =>
      'Все текущие пары, задания и экзамены будут заменены содержимым выбранного файла.';

  @override
  String get settingsImportSuccess => 'Данные успешно импортированы';

  @override
  String settingsImportError(String error) {
    return 'Не удалось импортировать файл: $error';
  }

  @override
  String get settingsExportSuccess => 'Резервная копия готова к передаче';

  @override
  String get settingsAppearanceSection => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get languageRussian => 'Русский';

  @override
  String get settingsAiSection => 'Функции ИИ';

  @override
  String get settingsGeminiApiKey => 'Ключ Gemini API';

  @override
  String get settingsGeminiApiKeyHint => 'Вставьте ваш API-ключ';

  @override
  String get settingsGeminiApiKeyHelp =>
      'Бесплатный ключ можно получить в Google AI Studio';

  @override
  String get settingsGeminiApiKeySaved => 'API-ключ сохранён';

  @override
  String get addLessonAction => 'Добавить пару';

  @override
  String get manualEntry => 'Вручную';

  @override
  String get smartImport => 'Умный импорт';

  @override
  String get smartImportMissingKey =>
      'Сначала добавьте ключ Gemini API в Настройках.';

  @override
  String get smartImportLoading => 'ИИ читает ваше расписание…';

  @override
  String get smartImportEmpty => 'В файле не найдено пар.';

  @override
  String smartImportError(String error) {
    return 'Не удалось разобрать расписание: $error';
  }

  @override
  String get smartImportFileTooLarge =>
      'Файл слишком большой. Выберите файл меньше 15 МБ.';

  @override
  String get smartImportMalformed =>
      'ИИ вернул данные, которые не удалось прочитать. Попробуйте более чёткое фото или PDF.';

  @override
  String get smartImportNetwork =>
      'Ошибка сети. Проверьте соединение и API-ключ.';

  @override
  String get smartImportPreviewTitle => 'Проверка импортированных пар';

  @override
  String get smartImportSaveAll => 'Сохранить все';

  @override
  String smartImportSaved(int count) {
    return 'Добавлено пар: $count';
  }

  @override
  String get smartInput => 'Умный ввод';

  @override
  String get smartInputHint => 'Опишите задачу или пару…';

  @override
  String get smartInputLoading => 'Думаю…';

  @override
  String smartInputTaskCreated(String title) {
    return 'Задача создана: $title';
  }

  @override
  String smartInputLessonCreated(String subject) {
    return 'Пара добавлена: $subject';
  }

  @override
  String get smartInputUnknown =>
      'Не удалось понять запрос. Попробуйте: «Напомни сделать лабу по физике к пятнице» или «Добавь лекцию по математике Пн 9:00-10:30»';

  @override
  String smartInputError(String error) {
    return 'Ошибка ИИ: $error';
  }

  @override
  String get navCalendar => 'Календарь';

  @override
  String get academicCalendarTitle => 'Академический календарь';

  @override
  String get addPeriod => 'Добавить период';

  @override
  String get editPeriod => 'Редактировать период';

  @override
  String get periodNameField => 'Название периода';

  @override
  String get periodTypeField => 'Тип';

  @override
  String get periodStartDate => 'Дата начала';

  @override
  String get periodEndDate => 'Дата окончания';

  @override
  String get periodTypeStudy => 'Учебные недели';

  @override
  String get periodTypeExam => 'Сессия';

  @override
  String get periodTypeHoliday => 'Каникулы';

  @override
  String get periodTypeRetake => 'Пересдачи';

  @override
  String get periodTypePublicHoliday => 'Государственный праздник';

  @override
  String get periodTypeOther => 'Другое';

  @override
  String get emptyPeriodsTitle => 'Периоды не заданы';

  @override
  String get emptyPeriodsSubtitle =>
      'Добавьте периоды семестра, чтобы увидеть учебный год целиком.';

  @override
  String get periodLegend => 'Легенда';

  @override
  String get profileName => 'Название расписания';

  @override
  String get createSchedule => 'Создать расписание';

  @override
  String get renameSchedule => 'Переименовать расписание';

  @override
  String get createNewSchedule => 'Создать новое расписание';

  @override
  String get rename => 'Переименовать';

  @override
  String get setAsDefault => 'Сделать основным';

  @override
  String get deleteScheduleTitle => 'Удалить расписание?';

  @override
  String deleteScheduleMessage(String name) {
    return 'Расписание «$name» и все его пары, задачи и экзамены будут удалены без возможности восстановления.';
  }

  @override
  String get cannotDeleteLastSchedule => 'Последнее расписание нельзя удалить.';

  @override
  String get settingsStartupSection => 'Открывать при запуске';

  @override
  String get startupDefaultSchedule => 'Основное расписание';

  @override
  String get startupLastOpened => 'Последнее открытое';

  @override
  String get confirmDeleteTitle => 'Удалить?';

  @override
  String get confirmDeleteLessonMessage =>
      'Эта пара и её напоминания будут удалены.';

  @override
  String get confirmDeleteTaskMessage => 'Это задание будет удалено.';

  @override
  String get confirmDeleteExamMessage =>
      'Этот экзамен и его напоминания будут удалены.';

  @override
  String get cancelThisClass => 'Отменить эту пару';

  @override
  String get editThisOccurrence => 'Изменить эту пару';

  @override
  String get editRecurringLesson => 'Редактировать расписание';

  @override
  String lessonCancelled(String subject, String date) {
    return '$subject отменена на $date';
  }

  @override
  String get restoreLesson => 'Восстановить';

  @override
  String get cancelledBadge => 'Отменена';

  @override
  String get modifiedBadge => 'Изменена';

  @override
  String get occurrenceFormTitle => 'Изменить эту пару';

  @override
  String smartInputPeriodCreated(String name) {
    return 'Период добавлен: $name';
  }

  @override
  String smartInputLessonCancelled(String subject) {
    return 'Пара отменена: $subject';
  }

  @override
  String get smartInputLessonNotFound =>
      'Не удалось найти подходящую пару для отмены';

  @override
  String get nothingChanged => 'Ничего не изменено';
}
