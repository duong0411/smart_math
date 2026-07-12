import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessment_attempt_notifier.dart';
import 'package:eduself_study_app/features/assessments/presentation/widgets/assessment_item_card.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AssessmentAttemptPage extends ConsumerStatefulWidget {
  const AssessmentAttemptPage({super.key, required this.assessmentId});

  final int assessmentId;

  @override
  ConsumerState<AssessmentAttemptPage> createState() =>
      _AssessmentAttemptPageState();
}

class _AssessmentAttemptPageState extends ConsumerState<AssessmentAttemptPage> {
  var _index = 0;
  var _handledAutoSubmit = false;

  bool _hasAnswer(Map<String, dynamic>? response) {
    if (response == null || response.isEmpty) return false;
    for (final value in response.values) {
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      if (value is Map && value.isEmpty) continue;
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final session =
        ref.watch(assessmentAttemptSessionProvider(widget.assessmentId));
    final scheme = Theme.of(context).colorScheme;

    ref.listen(assessmentAttemptSessionProvider(widget.assessmentId), (
      _,
      next,
    ) {
      final data = next.valueOrNull;
      if (data == null || !data.autoSubmitted || _handledAutoSubmit) return;
      _handledAutoSubmit = true;
      AppToast.success('Hết giờ — bài đã được nộp');
      if (!mounted) return;
      context.go('/assessments/attempts/${data.attempt.id}/result');
    });

    final remaining = session.valueOrNull?.remaining;
    final countdownUrgent =
        remaining != null && remaining <= const Duration(minutes: 5);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(session.valueOrNull?.detail.title ?? 'Làm bài'),
          actions: [
            if (remaining != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    formatAttemptCountdown(remaining),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: countdownUrgent
                              ? scheme.error
                              : scheme.onSurface,
                        ),
                  ),
                ),
              ),
            if (session.valueOrNull?.saving == true)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
        drawer: const AppDrawer(),
        body: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (state) {
            if (state.attempt.status != AttemptStatus.inProgress) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        Text(
                          'Bài này đã nộp (${state.attempt.status.labelVi}).',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.go(
                            '/assessments/attempts/${state.attempt.id}/result',
                          ),
                          child: const Text('Xem kết quả'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final items = state.detail.items;
            if (items.isEmpty) {
              return const Center(child: Text('Đề chưa có câu hỏi.'));
            }
            final safeIndex = _index.clamp(0, items.length - 1);
            final item = items[safeIndex];

            return Column(
              children: [
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: scheme.error, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    children: [
                      DenseListCard(
                        header: 'Danh sách câu hỏi',
                        count: items.length,
                        children: [
                          for (var i = 0; i < items.length; i++)
                            _QuestionNavRow(
                              index: i,
                              item: items[i],
                              selected: i == safeIndex,
                              answered: _hasAnswer(state.responses[items[i].id]),
                              onTap: () => setState(() => _index = i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AssessmentItemCard(
                        index: safeIndex,
                        item: item,
                        response: state.responses[item.id],
                        onChanged: (response) {
                          ref
                              .read(
                                assessmentAttemptSessionProvider(
                                  widget.assessmentId,
                                ).notifier,
                              )
                              .setResponse(item.id, response);
                        },
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: safeIndex <= 0
                                ? null
                                : () => setState(() => _index = safeIndex - 1),
                            child: const Text('Trước'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (safeIndex < items.length - 1)
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  setState(() => _index = safeIndex + 1),
                              child: const Text('Sau'),
                            ),
                          )
                        else
                          Expanded(
                            child: FilledButton(
                              onPressed: state.submitting
                                  ? null
                                  : () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Nộp bài?'),
                                          content: const Text(
                                            'Em kiểm tra lại rồi nộp nhé. '
                                            'Sau khi nộp sẽ không sửa được nữa.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Hủy'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Nộp bài'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed != true || !mounted) return;
                                      final attempt = await ref
                                          .read(
                                            assessmentAttemptSessionProvider(
                                              widget.assessmentId,
                                            ).notifier,
                                          )
                                          .submit();
                                      if (!mounted) return;
                                      if (attempt == null) {
                                        AppToast.error(
                                          state.error ?? 'Không nộp được bài.',
                                        );
                                        return;
                                      }
                                      AppToast.success('Đã nộp bài');
                                      if (!context.mounted) return;
                                      context.go(
                                        '/assessments/attempts/${attempt.id}/result',
                                      );
                                    },
                              child: state.submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Nộp bài'),
                            ),
                          ),
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
}

class _QuestionNavRow extends StatelessWidget {
  const _QuestionNavRow({
    required this.index,
    required this.item,
    required this.selected,
    required this.answered,
    required this.onTap,
  });

  final int index;
  final AssessmentItem item;
  final bool selected;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = answered ? 'Đã trả lời' : 'Chưa trả lời';

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: DenseListRow(
        title: item.prompt,
        subtitle: 'Câu ${index + 1} · ${item.itemType.labelVi} · $status',
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: selected
              ? scheme.primary
              : answered
                  ? scheme.primary.withValues(alpha: 0.16)
                  : scheme.surfaceContainerHighest,
          foregroundColor: selected
              ? scheme.onPrimary
              : answered
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
          child: Text(
            '${index + 1}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        trailing: Icon(
          answered ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 18,
          color: answered ? scheme.primary : scheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
