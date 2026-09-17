import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/exam_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/exam_tile.dart';
import 'exam_form_screen.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final examProvider = context.watch<ExamProvider>();
    final exams = examProvider.exams;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: onOpenDrawer,
        ),
        title: Text(l10n.examsScreenTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ExamFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: exams.isEmpty
          ? EmptyState(
              icon: Icons.event_note_outlined,
              title: l10n.emptyExamsTitle,
              subtitle: l10n.emptyExamsSubtitle,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return ExamTile(
                  exam: exam,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExamFormScreen(exam: exam),
                    ),
                  ),
                  onDelete: () => examProvider.deleteExam(exam.id),
                );
              },
            ),
    );
  }
}
