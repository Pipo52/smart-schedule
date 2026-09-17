import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/lesson.dart';
import '../../providers/profile_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/enum_labels.dart';
import '../../utils/weekday_utils.dart';

class LessonFormScreen extends StatefulWidget {
  const LessonFormScreen({super.key, this.lesson});

  /// If non-null, the form edits this lesson instead of creating a new one.
  final Lesson? lesson;

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _subjectController;
  late TextEditingController _roomController;
  late TextEditingController _lecturerController;
  late TextEditingController _notesController;

  late LessonType _type;
  late int _weekday;
  late WeekType _weekType;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _reminderEnabled;

  bool get _isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    _subjectController = TextEditingController(text: lesson?.subjectName ?? '');
    _roomController = TextEditingController(text: lesson?.room ?? '');
    _lecturerController = TextEditingController(text: lesson?.lecturer ?? '');
    _notesController = TextEditingController(text: lesson?.notes ?? '');
    _type = lesson?.type ?? LessonType.lecture;
    final todayWeekday = DateTime.now().weekday;
    _weekday = lesson?.weekday ?? (todayWeekday > 6 ? 1 : todayWeekday);
    _weekType = lesson?.weekType ?? WeekType.every;
    _startTime =
        _parseTime(lesson?.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime =
        _parseTime(lesson?.endTime) ?? const TimeOfDay(hour: 10, minute: 30);
    _reminderEnabled = lesson?.reminderEnabled ?? true;
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _lecturerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final lesson = Lesson(
      id: widget.lesson?.id ?? const Uuid().v4(),
      subjectName: _subjectController.text.trim(),
      type: _type,
      room: _roomController.text.trim(),
      lecturer: _lecturerController.text.trim(),
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      weekday: _weekday,
      weekType: _weekType,
      profileId:
          widget.lesson?.profileId ??
          context.read<ProfileProvider>().activeProfileId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      reminderEnabled: _reminderEnabled,
    );

    context.read<ScheduleProvider>().saveLesson(lesson);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteLessonMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ScheduleProvider>().deleteLesson(widget.lesson!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.lessonFormEditTitle : l10n.lessonFormAddTitle,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: l10n.lessonSubjectField),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.lessonSubjectField
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LessonType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.lessonTypeField),
              items: LessonType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label(context)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomController,
              decoration: InputDecoration(labelText: l10n.lessonRoomField),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lecturerController,
              decoration: InputDecoration(labelText: l10n.lessonLecturerField),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: true),
                    child: Text(
                      '${l10n.lessonStartTimeField}: ${_formatTime(_startTime)}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: false),
                    child: Text(
                      '${l10n.lessonEndTimeField}: ${_formatTime(_endTime)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _weekday,
              decoration: InputDecoration(labelText: l10n.lessonWeekdayField),
              items: List.generate(6, (i) => i + 1)
                  .map(
                    (weekday) => DropdownMenuItem(
                      value: weekday,
                      child: Text(localizedWeekdayName(weekday, localeCode)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _weekday = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WeekType>(
              initialValue: _weekType,
              decoration: InputDecoration(labelText: l10n.lessonWeekTypeField),
              items: WeekType.values
                  .map(
                    (weekType) => DropdownMenuItem(
                      value: weekType,
                      child: Text(weekType.label(context)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _weekType = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.lessonNotesField),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.lessonReminderToggle),
              value: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
