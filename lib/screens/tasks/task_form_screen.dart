import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/enum_labels.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({
    super.key,
    this.task,
    this.linkedExamId,
    this.presetSubject,
  });

  final Task? task;

  /// Set when creating a "preparation task" from the Exam screen.
  final String? linkedExamId;
  final String? presetSubject;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _descriptionController;

  late DateTime _dueDate;
  late Priority _priority;
  int? _reminderOffsetMinutes;

  bool get _isEditing => widget.task != null;

  static const List<int?> _reminderOptions = [null, 10, 30, 60, 24 * 60];

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _subjectController = TextEditingController(
      text: task?.linkedSubject ?? widget.presetSubject ?? '',
    );
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _priority = task?.priority ?? Priority.medium;
    _reminderOffsetMinutes = task?.reminderOffsetMinutes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (time == null) return;
    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      id: widget.task?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      linkedSubject: _subjectController.text.trim().isEmpty
          ? null
          : _subjectController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      isDone: widget.task?.isDone ?? false,
      reminderOffsetMinutes: _reminderOffsetMinutes,
      linkedExamId: widget.task?.linkedExamId ?? widget.linkedExamId,
    );

    context.read<TaskProvider>().saveTask(task);
    Navigator.of(context).pop(task);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteTaskMessage),
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
      await context.read<TaskProvider>().deleteTask(widget.task!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  String _reminderLabel(AppLocalizations l10n, int? minutes) {
    if (minutes == null) return l10n.reminderNone;
    return l10n.reminderMinutesBefore(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dueDateLabel =
        '${MaterialLocalizations.of(context).formatMediumDate(_dueDate)} '
        '${TimeOfDay.fromDateTime(_dueDate).format(context)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editTaskTitle : l10n.addTaskTitle),
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
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.taskTitleField),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.taskTitleField : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: l10n.taskSubjectField),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.taskDescriptionField),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickDueDate,
              child: Text('${l10n.taskDueDateField}: $dueDateLabel'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              initialValue: _priority,
              decoration: InputDecoration(labelText: l10n.taskPriorityField),
              items: Priority.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.label(context)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _reminderOffsetMinutes,
              decoration: InputDecoration(labelText: l10n.taskReminderField),
              items: _reminderOptions
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(_reminderLabel(l10n, m)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _reminderOffsetMinutes = v),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
