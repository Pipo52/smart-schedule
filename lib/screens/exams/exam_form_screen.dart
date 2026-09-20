import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/exam.dart';
import '../../providers/exam_provider.dart';
import '../../models/task.dart';
import '../../providers/profile_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/enum_labels.dart';
import '../tasks/task_form_screen.dart';

class ExamFormScreen extends StatefulWidget {
  const ExamFormScreen({super.key, this.exam});

  final Exam? exam;

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _subjectController;
  late TextEditingController _roomController;
  late TextEditingController _notesController;

  late DateTime _date;
  late ExamType _examType;

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;
    _subjectController = TextEditingController(text: exam?.subjectName ?? '');
    _roomController = TextEditingController(text: exam?.room ?? '');
    _notesController = TextEditingController(text: exam?.notes ?? '');
    _date = exam?.date ?? DateTime.now().add(const Duration(days: 7));
    _examType = exam?.examType ?? ExamType.midterm;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null) return;
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<Exam> _persistExam() async {
    final exam = Exam(
      id: widget.exam?.id ?? const Uuid().v4(),
      subjectName: _subjectController.text.trim(),
      date: _date,
      room: _roomController.text.trim().isEmpty
          ? null
          : _roomController.text.trim(),
      examType: _examType,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      revisionTasks: widget.exam?.revisionTasks ?? const [],
      profileId:
          widget.exam?.profileId ??
          context.read<ProfileProvider>().activeProfileId,
    );
    await context.read<ExamProvider>().saveExam(exam);
    return exam;
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _persistExam();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addPrepTask() async {
    if (!_formKey.currentState!.validate()) return;
    final exam = await _persistExam();
    if (!mounted) return;
    final createdTask = await Navigator.of(context).push<Task>(
      MaterialPageRoute<Task>(
        builder: (_) => TaskFormScreen(
          linkedExamId: exam.id,
          presetSubject: exam.subjectName,
        ),
      ),
    );
    if (createdTask != null && mounted) {
      await context.read<ExamProvider>().linkTask(exam.id, createdTask.id);
      setState(() {}); // refresh revisionTasks count shown on this screen
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteExamMessage),
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
      await context.read<ExamProvider>().deleteExam(widget.exam!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final taskProvider = context.watch<TaskProvider>();
    final dateLabel =
        '${MaterialLocalizations.of(context).formatMediumDate(_date)} '
        '${TimeOfDay.fromDateTime(_date).format(context)}';

    final List<Task> linkedTasks = widget.exam == null
        ? const []
        : taskProvider.tasksForExam(widget.exam!.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editExamTitle : l10n.addExamTitle),
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
              decoration: InputDecoration(labelText: l10n.examSubjectField),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickDate,
              child: Text('${l10n.examDateField}: $dateLabel'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomController,
              decoration: InputDecoration(labelText: l10n.examRoomField),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExamType>(
              initialValue: _examType,
              decoration: InputDecoration(labelText: l10n.examTypeField),
              items: ExamType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label(context)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _examType = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.examNotesField),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
            const SizedBox(height: 24),
            Text(
              l10n.prepTasksTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final task in linkedTasks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(
                  value: task.isDone,
                  onChanged: (_) => taskProvider.toggleDone(task),
                ),
                title: Text(task.title),
              ),
            OutlinedButton.icon(
              onPressed: _addPrepTask,
              icon: const Icon(Icons.add_task),
              label: Text(l10n.addPrepTask),
            ),
          ],
        ),
      ),
    );
  }
}
