import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessments_providers.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AssessmentDetailPage extends ConsumerWidget {
  const AssessmentDetailPage({super.key, required this.assessmentId});

  final int assessmentId;

  String _formatScore(AssessmentAttempt attempt) {
    if (attempt.score == null) return '—';
    final score = attempt.score!;
    final scoreText = score.toStringAsFixed(score % 1 == 0 ? 0 : 1);
    if (attempt.maxScore == null) return scoreText;
    final max = attempt.maxScore!;
    return '$scoreText / ${max.toStringAsFixed(max % 1 == 0 ? 0 : 1)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(assessmentDetailProvider(assessmentId));
    final myAttemptAsync =
        ref.watch(myAssessmentAttemptProvider(assessmentId));
    final user = ref.watch(authSessionProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final isStudent = user?.role == UserRole.student;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Chi tiết đề'),
        ),
        drawer: const AppDrawer(),
        body: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    Text('$error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        ref.invalidate(assessmentDetailProvider(assessmentId));
                        ref.invalidate(
                          myAssessmentAttemptProvider(assessmentId),
                        );
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (detail) {
            final isOwner = user != null && detail.ownerId == user.id;
            final myAttempt = isStudent ? myAttemptAsync.valueOrNull : null;
            final submittedAttempt = myAttempt != null &&
                    myAttempt.status != AttemptStatus.inProgress
                ? myAttempt
                : null;
            final canTake = isStudent &&
                detail.status == AssessmentStatus.published &&
                detail.items.isNotEmpty &&
                submittedAttempt == null;
            final canContinue = isStudent &&
                myAttempt?.status == AttemptStatus.inProgress;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        detail.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (detail.subject != null) detail.subject!,
                          if (detail.gradeLevel != null)
                            'Lớp ${detail.gradeLevel}',
                          detail.status.labelVi,
                          '${detail.items.length} câu',
                        ].join(' · '),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      if (isStudent && myAttemptAsync.isLoading) ...[
                        const SizedBox(height: 20),
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ] else if (submittedAttempt != null) ...[
                        const SizedBox(height: 20),
                        _StudentAttemptStatusCard(
                          attempt: submittedAttempt,
                          scoreText: _formatScore(submittedAttempt),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        if (isStudent && !isOwner)
                          Text(
                            'Đề này chỉ mở khi em là thành viên lớp được giao.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.primary),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Em làm lần lượt từng câu. Hệ thống tự lưu đáp án. '
                          'Với câu tự luận, thầy/cô sẽ chấm sau khi em nộp.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: !(canTake || canContinue)
                              ? null
                              : () async {
                                  final start = await ref
                                      .read(startAssessmentAttemptProvider)(
                                    assessmentId,
                                  );
                                  if (!context.mounted) return;
                                  switch (start) {
                                    case FailureResult(:final failure):
                                      AppToast.error(failure.message);
                                      if (failure.message.contains('lớp học')) {
                                        context.push('/classrooms');
                                      }
                                    case Success(:final value):
                                      ref.invalidate(
                                        myAssessmentAttemptProvider(
                                          assessmentId,
                                        ),
                                      );
                                      if (value.status !=
                                          AttemptStatus.inProgress) {
                                        context.push(
                                          '/assessments/attempts/${value.id}/result',
                                        );
                                      } else {
                                        context.push(
                                          '/assessments/$assessmentId/attempt',
                                        );
                                      }
                                  }
                                },
                          icon: Icon(
                            canContinue
                                ? Icons.play_circle_outline_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            !isStudent
                                ? 'Chỉ học sinh mới làm bài được'
                                : canContinue
                                    ? 'Tiếp tục làm bài'
                                    : 'Bắt đầu làm bài',
                          ),
                        ),
                        if (detail.status != AssessmentStatus.published)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Đề chưa xuất bản.',
                              style: TextStyle(color: scheme.error),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                if (submittedAttempt == null) ...[
                  const SizedBox(height: 20),
                  DenseListCard(
                    header: 'Danh sách câu hỏi',
                    count: detail.items.length,
                    emptyLabel: 'Đề chưa có câu hỏi.',
                    children: [
                      for (var i = 0; i < detail.items.length; i++)
                        DenseListRow(
                          title: detail.items[i].prompt,
                          subtitle:
                              '${detail.items[i].itemType.labelVi} · ${detail.items[i].points} điểm',
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                scheme.primary.withValues(alpha: 0.12),
                            foregroundColor: scheme.primary,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StudentAttemptStatusCard extends StatelessWidget {
  const _StudentAttemptStatusCard({
    required this.attempt,
    required this.scoreText,
  });

  final AssessmentAttempt attempt;
  final String scoreText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final graded = attempt.status == AttemptStatus.graded;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              graded
                  ? Icons.emoji_events_rounded
                  : Icons.hourglass_bottom_rounded,
              size: 40,
              color: graded ? scheme.primary : scheme.tertiary,
            ),
            const SizedBox(height: 10),
            Text(
              graded ? 'Đã chấm xong' : 'Chưa chấm xong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              graded
                  ? 'Thầy/cô đã chấm bài của em.'
                  : 'Em đã nộp bài. Thầy/cô đang chấm hoặc còn câu tự luận chờ chấm.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            if (graded) ...[
              const SizedBox(height: 12),
              Text(
                'Điểm: $scoreText',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Trạng thái: ${attempt.status.labelVi}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (attempt.score != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Điểm tạm thời: $scoreText',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push(
                '/assessments/attempts/${attempt.id}/result',
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(graded ? 'Xem kết quả đã chấm' : 'Xem bài đã nộp'),
            ),
          ],
        ),
      ),
    );
  }
}
