import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/semester_period.dart';
import '../../providers/profile_provider.dart';
import '../../providers/semester_period_provider.dart';

class PeriodFormScreen extends StatefulWidget {
  const PeriodFormScreen({super.key, this.period});

  final SemesterPeriod? period;

  @override
  State<PeriodFormScreen> createState() => _PeriodFormScreenState();
}

class _PeriodFormScreenState extends State<PeriodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;
  late SemesterPeriodType _type;

  bool get _isEditing => widget.period != null;

  @override
  void initState() {
    super.initState();
    final period = widget.period;
    _nameController = TextEditingController(text: period?.name ?? '');
    _startDate = _dateOnly(period?.startDate ?? DateTime.now());
    _endDate = _dateOnly(period?.endDate ?? _startDate);
    _type = period?.type ?? SemesterPeriodType.study;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final selectedDate = isStartDate ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    setState(() {
      if (isStartDate) {
        _startDate = _dateOnly(pickedDate);
      } else {
        _endDate = _dateOnly(pickedDate);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).periodEndDate)),
      );
      return;
    }

    final profileId = context.read<ProfileProvider>().activeProfileId;
    final period =
        widget.period?.copyWith(
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          type: _type,
          profileId: profileId,
        ) ??
        SemesterPeriod(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          type: _type,
          profileId: profileId,
        );
    await context.read<SemesterPeriodProvider>().savePeriod(period);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(widget.period!.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<SemesterPeriodProvider>().deletePeriod(
      widget.period!.id,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormatter = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editPeriod : l10n.addPeriod),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
              onPressed: _delete,
            ),
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
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.periodNameField),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.periodNameField
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SemesterPeriodType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.periodTypeField),
              items: SemesterPeriodType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: _PeriodTypeOption(type: type),
                    ),
                  )
                  .toList(),
              onChanged: (type) => setState(() => _type = type!),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.periodStartDate),
              subtitle: Text(dateFormatter.formatMediumDate(_startDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isStartDate: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.periodEndDate),
              subtitle: Text(dateFormatter.formatMediumDate(_endDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isStartDate: false),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}

class _PeriodTypeOption extends StatelessWidget {
  const _PeriodTypeOption({required this.type});

  final SemesterPeriodType type;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: type.defaultColor),
        const SizedBox(width: 8),
        Text(_periodTypeLabel(AppLocalizations.of(context), type)),
      ],
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _periodTypeLabel(AppLocalizations l10n, SemesterPeriodType type) {
  return switch (type) {
    SemesterPeriodType.study => l10n.periodTypeStudy,
    SemesterPeriodType.exam => l10n.periodTypeExam,
    SemesterPeriodType.holiday => l10n.periodTypeHoliday,
    SemesterPeriodType.retake => l10n.periodTypeRetake,
    SemesterPeriodType.publicHoliday => l10n.periodTypePublicHoliday,
    SemesterPeriodType.other => l10n.periodTypeOther,
  };
}
