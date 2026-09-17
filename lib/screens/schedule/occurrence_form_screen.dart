import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/lesson.dart';
import '../../models/schedule_exception.dart';
import '../../providers/schedule_exception_provider.dart';

/// Форма для изменения ОДНОГО конкретного экземпляра повторяющейся пары.
///
/// В отличие от [LessonFormScreen], сохранение здесь не трогает исходную
/// [Lesson] — вместо этого создаётся точечное [ScheduleException] с
/// type == modified, действующее только для указанной даты.
class OccurrenceFormScreen extends StatefulWidget {
  const OccurrenceFormScreen({
    super.key,
    required this.lesson,
    required this.date,
  });

  final Lesson lesson;
  final DateTime date;

  @override
  State<OccurrenceFormScreen> createState() => _OccurrenceFormScreenState();
}

class _OccurrenceFormScreenState extends State<OccurrenceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _roomController;
  late TextEditingController _lecturerController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _startTime = _parseTime(widget.lesson.startTime);
    _endTime = _parseTime(widget.lesson.endTime);
    _roomController = TextEditingController(text: widget.lesson.room);
    _lecturerController = TextEditingController(text: widget.lesson.lecturer);
    _notesController = TextEditingController(text: widget.lesson.notes ?? '');
  }

  @override
  void dispose() {
    _roomController.dispose();
    _lecturerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    final newStartTime = _formatTime(_startTime);
    final newEndTime = _formatTime(_endTime);
    final newRoom = _roomController.text.trim();
    final newLecturer = _lecturerController.text.trim();
    final newNotes = _notesController.text.trim();

    final startTime = newStartTime == widget.lesson.startTime
        ? null
        : newStartTime;
    final endTime = newEndTime == widget.lesson.endTime ? null : newEndTime;
    final room = newRoom == widget.lesson.room ? null : newRoom;
    final lecturer = newLecturer == widget.lesson.lecturer ? null : newLecturer;
    final notes = newNotes == (widget.lesson.notes ?? '') ? null : newNotes;

    if (startTime == null &&
        endTime == null &&
        room == null &&
        lecturer == null &&
        notes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.nothingChanged)));
      return;
    }

    final exception = ScheduleException(
      id: const Uuid().v4(),
      lessonId: widget.lesson.id,
      date: widget.date,
      type: ExceptionType.modified,
      profileId: widget.lesson.profileId,
      newStartTime: startTime,
      newEndTime: endTime,
      newRoom: room,
      newLecturer: lecturer,
      newNotes: notes,
    );
    await context.read<ScheduleExceptionProvider>().saveException(exception);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateLabel = MaterialLocalizations.of(context)
        .formatMediumDate(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.occurrenceFormTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              dateLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: l10n.save,
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.lessonNotesField),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
