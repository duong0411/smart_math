import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/domain/format_attempt_response.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessments_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AssessmentResultPage extends ConsumerWidget {
  const AssessmentResultPage({super.key, required this.attemptId});

  final int attemptId;

  String _formatScore(double? score, double? maxScore) {
    if (score == null) return '—';
    final scoreText = score.toStringAsFixed(score % 1 == 0 ? 0 : 1);
    if (maxScore == null) return scoreText;
    return '$scoreText / ${maxScore.toStringAsFixed(maxScore % 1 == 0 ? 0 : 1)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptAsync = ref.watch(assessmentAttemptResultProvider(attemptId));
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Kết quả bài làm'),
        ),
        drawer: const AppDrawer(),
        body: attemptAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (attempt) {
            final detailAsync =
                ref.watch(assessmentDetailProvider(attempt.assessmentId));
            final itemsById = <int, AssessmentItem>{
              for (final item in detailAsync.valueOrNull?.items ?? const [])
                item.id: item,
            };
            final orderedAnswers = [...attempt.answers]..sort((a, b) {
                final ao = itemsById[a.itemId]?.sortOrder ?? a.itemId;
                final bo = itemsById[b.itemId]?.sortOrder ?? b.itemId;
                return ao.compareTo(bo);
              });

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      Icon(
                        attempt.status == AttemptStatus.graded
                            ? Icons.emoji_events_rounded
                            : Icons.hourglass_bottom_rounded,
                        size: 48,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        attempt.status.labelVi,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Điểm: ${_formatScore(attempt.score, attempt.maxScore)}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (attempt.status == AttemptStatus.submitted) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Còn câu tự luận đang chờ thầy/cô chấm.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go(
                          '/assessments/${attempt.assessmentId}',
                        ),
                        child: const Text('Về đề kiểm tra'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DenseListCard(
                  header: 'Chi tiết từng câu',
                  count: orderedAnswers.length,
                  emptyLabel: 'Chưa có đáp án đã lưu.',
                  children: [
                    for (var i = 0; i < orderedAnswers.length; i++)
                      _AnswerResultRow(
                        index: i,
                        answer: orderedAnswers[i],
                        item: itemsById[orderedAnswers[i].itemId],
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnswerResultRow extends StatelessWidget {
  const _AnswerResultRow({
    required this.index,
    required this.answer,
    required this.item,
  });

  final int index;
  final AttemptAnswer answer;
  final AssessmentItem? item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCorrect = answer.isCorrect;
    final resultLabel = formatAnswerResultLabelVi(isCorrect);
    final points = answer.pointsAwarded;
    final maxPoints = item?.points;
    final pointsText = points == null
        ? null
        : maxPoints == null
            ? '${points.toStringAsFixed(points % 1 == 0 ? 0 : 1)} điểm'
            : '${points.toStringAsFixed(points % 1 == 0 ? 0 : 1)} / '
                '${maxPoints.toStringAsFixed(maxPoints % 1 == 0 ? 0 : 1)} điểm';

    final meta = [
      ?item?.itemType.labelVi,
      resultLabel,
      ?pointsText,
    ].join(' · ');

    final answerText = formatAttemptResponseVi(answer.response, item: item);
    final subtitleParts = [
      meta,
      answerText,
      if (answer.feedback != null && answer.feedback!.trim().isNotEmpty)
        'Nhận xét: ${answer.feedback!.trim()}',
    ];

    final iconColor = isCorrect == true
        ? scheme.primary
        : isCorrect == false
            ? scheme.error
            : scheme.tertiary;
    final iconBg = iconColor.withValues(alpha: 0.12);
    final iconData = isCorrect == true
        ? Icons.check_rounded
        : isCorrect == false
            ? Icons.close_rounded
            : Icons.schedule_rounded;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minVerticalPadding: 6,
      isThreeLine: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: iconBg,
        foregroundColor: iconColor,
        child: Icon(iconData, size: 16),
      ),
      title: Text(
        item != null
            ? 'Câu ${index + 1}: ${item!.prompt}'
            : 'Câu ${index + 1}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        subtitleParts.join('\n'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
      ),
    );
  }
}
