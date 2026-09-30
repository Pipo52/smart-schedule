import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/exam.dart';
import '../../providers/auth_provider.dart';
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
    final exams = context.select<ExamProvider, List<Exam>>(
      (provider) => provider.exams,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: onOpenDrawer,
        ),
        title: Text(l10n.examsScreenTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ExamFormScreen())),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AuthProvider>().refreshFromCloud(),
        child: exams.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: EmptyState(
                      icon: Icons.event_note_outlined,
                      title: l10n.emptyExamsTitle,
                      subtitle: l10n.emptyExamsSubtitle,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: exams.length,
                addAutomaticKeepAlives: false,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return ExamTile(
                  exam: exam,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExamFormScreen(exam: exam),
                    ),
                  ),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(l10n.confirmDeleteTitle),
                        content: Text(l10n.confirmDeleteExamMessage),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await context.read<ExamProvider>().deleteExam(exam.id);
                    }
                  },
                );
              },
            ),
      ),
    );
  }
}
