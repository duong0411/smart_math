import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessments_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final ownedAssessmentsProvider =
    FutureProvider.autoDispose<List<AssessmentSummary>>((ref) async {
  final result =
      await ref.watch(assessmentsRepositoryProvider).listAssessments();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

class TeacherAssessmentsPage extends ConsumerWidget {
  const TeacherAssessmentsPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String title, String subject})>(
      context: context,
      builder: (ctx) => const _CreateAssessmentDialog(),
    );
    if (result == null || result.title.isEmpty) return;

    final created =
        await ref.read(assessmentsRepositoryProvider).createAssessment(
              title: result.title,
              subject: result.subject.isEmpty ? null : result.subject,
            );
    if (!context.mounted) return;
    switch (created) {
      case Success(:final value):
        ref.invalidate(ownedAssessmentsProvider);
        context.push('/teachers/assessments/${value.id}/edit');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessments = ref.watch(ownedAssessmentsProvider);

    return FeatureListScaffold<AssessmentSummary>(
      title: 'Soạn đề',
      listHeader: 'Đề của thầy/cô',
      value: assessments,
      emptyTitle: 'Chưa có đề',
      emptySubtitle: 'Tạo đề nháp rồi thêm câu hỏi.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tạo đề'),
      ),
      onRefresh: () async {
        ref.invalidate(ownedAssessmentsProvider);
        await ref.read(ownedAssessmentsProvider.future);
      },
      itemBuilder: (context, item) {
        return DenseListRow(
          title: item.title,
          subtitle: [
            item.status.labelVi,
            if (item.subject != null) item.subject!,
          ].join(' · '),
          leadingIcon: Icons.quiz_rounded,
          onTap: () => context.push('/teachers/assessments/${item.id}/edit'),
        );
      },
    );
  }
}

class _CreateAssessmentDialog extends StatefulWidget {
  const _CreateAssessmentDialog();

  @override
  State<_CreateAssessmentDialog> createState() =>
      _CreateAssessmentDialogState();
}

class _CreateAssessmentDialogState extends State<_CreateAssessmentDialog> {
  late final TextEditingController _title;
  late final TextEditingController _subject;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _subject = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo đề mới'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
            autofocus: true,
          ),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Môn (tuỳ chọn)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (
              title: _title.text.trim(),
              subject: _subject.text.trim(),
            ),
          ),
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}
