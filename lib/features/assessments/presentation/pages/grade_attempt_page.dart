import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessments_providers.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/classroom_summary.dart';
import 'package:eduself_study_app/features/classrooms/presentation/providers/classrooms_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherGradingPage extends ConsumerWidget {
  const TeacherGradingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classrooms = ref.watch(classroomsProvider);

    return FeatureListScaffold<ClassroomSummary>(
      title: 'Chấm bài',
      value: classrooms,
      emptyTitle: 'Chưa có lớp',
      emptySubtitle: 'Tạo lớp và giao đề trước khi chấm bài.',
      onRefresh: () async {
        ref.invalidate(classroomsProvider);
        await ref.read(classroomsProvider.future);
      },
      itemBuilder: (context, room) {
        return DenseListRow(
          title: room.name,
          subtitle: 'Chọn đề đã giao để xem tiến độ / chấm',
          leadingIcon: Icons.grading_rounded,
          onTap: () => context.push('/classrooms/${room.id}'),
        );
      },
    );
  }
}

class GradeAttemptPage extends ConsumerStatefulWidget {
  const GradeAttemptPage({super.key, required this.attemptId});

  final int attemptId;

  @override
  ConsumerState<GradeAttemptPage> createState() => _GradeAttemptPageState();
}

class _GradeAttemptPageState extends ConsumerState<GradeAttemptPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final attemptAsync =
        ref.watch(assessmentAttemptResultProvider(widget.attemptId));

    return AtmosphericBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Chấm bài làm'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Quay lại',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/teachers/grading');
              }
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: attemptAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (attempt) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GlassCard(
                  child: Text(
                    'Điểm: ${attempt.score?.toStringAsFixed(1) ?? '—'}'
                    ' / ${attempt.maxScore?.toStringAsFixed(1) ?? '—'}'
                    '\n${attempt.status.labelVi}',
                  ),
                ),
                const SizedBox(height: 12),
                for (final answer in attempt.answers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Câu #${answer.itemId}'),
                          Text('Trả lời: ${answer.response}'),
                          Text(
                            'Điểm: ${answer.pointsAwarded?.toStringAsFixed(1) ?? 'chưa chấm'}',
                          ),
                          if (answer.feedback != null)
                            Text('Nhận xét: ${answer.feedback}'),
                          if (answer.pointsAwarded == null) ...[
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: () => _grade(answer),
                              child: const Text('Chấm điểm'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _grade(AttemptAnswer answer) async {
    final result = await showDialog<({double points, String feedback})>(
      context: context,
      builder: (ctx) => const _GradeAnswerDialog(),
    );
    if (result == null) return;

    final graded = await ref.read(assessmentsRepositoryProvider).gradeAnswer(
          attemptId: widget.attemptId,
          answerId: answer.id,
          pointsAwarded: result.points,
          feedback: result.feedback.isEmpty ? null : result.feedback,
        );
    switch (graded) {
      case Success():
        ref.invalidate(assessmentAttemptResultProvider(widget.attemptId));
        AppToast.success('Đã chấm');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }
}

class _GradeAnswerDialog extends StatefulWidget {
  const _GradeAnswerDialog();

  @override
  State<_GradeAnswerDialog> createState() => _GradeAnswerDialogState();
}

class _GradeAnswerDialogState extends State<_GradeAnswerDialog> {
  late final TextEditingController _points;
  late final TextEditingController _feedback;

  @override
  void initState() {
    super.initState();
    _points = TextEditingController();
    _feedback = TextEditingController();
  }

  @override
  void dispose() {
    _points.dispose();
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chấm câu hỏi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _points,
            decoration: const InputDecoration(labelText: 'Điểm'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          TextField(
            controller: _feedback,
            decoration: const InputDecoration(labelText: 'Nhận xét'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () {
            final points = double.tryParse(_points.text.trim());
            if (points == null) return;
            Navigator.pop(
              context,
              (points: points, feedback: _feedback.text.trim()),
            );
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
