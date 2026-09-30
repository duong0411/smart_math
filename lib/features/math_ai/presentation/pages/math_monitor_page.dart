import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class MathMonitorPage extends ConsumerStatefulWidget {
  const MathMonitorPage({super.key});

  @override
  ConsumerState<MathMonitorPage> createState() => _MathMonitorPageState();
}

class _MathMonitorPageState extends ConsumerState<MathMonitorPage> {
  String? _insight;
  var _loadingInsight = false;

  Future<void> _askInsight(
    List<MathStudyEvent> events,
    List<MathPracticeAttempt> attempts,
  ) async {
    final hasKey =
        (ref.read(geminiApiKeyProvider).valueOrNull ?? '').trim().isNotEmpty;
    if (!hasKey) {
      AppToast.error('Cần Gemini API key.');
      if (mounted) context.push('/settings');
      return;
    }

    setState(() => _loadingInsight = true);

    final summary = StringBuffer();
    summary.writeln('=== Nhật ký học Toán (gần đây) ===');
    for (final e in events.take(30)) {
      summary.writeln(
        '- [${e.type.name}] ${e.topic}: ${e.detail}'
        '${e.correct == null ? '' : (e.correct! ? ' (đúng)' : ' (sai)')}'
        ' @ ${e.at.toIso8601String()}',
      );
    }
    summary.writeln('=== Bài luyện gần đây ===');
    for (final a in attempts.take(15)) {
      summary.writeln(
        '- ${a.topic}: ${a.correct ? 'ĐÚNG' : 'SAI'} | Q: ${a.question} | A: ${a.studentAnswer}',
      );
    }

    final result = await askMathAi(
      ref,
      userMessage: '''
Dựa CHỈ trên dữ liệu giám sát bên dưới, viết báo cáo ngắn bằng tiếng Việt:

1. Tổng quan mức độ học gần đây (dựa trên số phiên / đúng-sai có trong dữ liệu)
2. Chủ đề mạnh / yếu (nêu bằng chứng từ nhật ký)
3. Lỗi hay gặp (nếu có)
4. Kế hoạch ôn 5 ngày: mỗi ngày 1 mục tiêu + dạng bài cụ thể, vừa sức lớp
5. 1 lời khích lệ ngắn

Không bịa số liệu ngoài dữ liệu. Nếu thiếu dữ liệu, nói rõ cần luyện thêm thay vì suy đoán.

$summary
''',
      extraSystemContext:
          'Chế độ giám sát & báo cáo: trung thực với dữ liệu, kế hoạch ôn cụ thể theo lớp.',
    );

    if (!mounted) return;
    setState(() => _loadingInsight = false);

    switch (result) {
      case Success(:final value):
        setState(() => _insight = value);
        await ref.read(mathLocalStoreProvider).addEvent(
              MathStudyEvent(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: MathStudyEventType.monitor,
                topic: 'Báo cáo AI',
                detail: 'Đã tạo báo cáo giám sát',
                at: DateTime.now().toUtc(),
              ),
            );
        ref.invalidate(mathEventsProvider);
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(mathEventsProvider);
    final attemptsAsync = ref.watch(mathAttemptsProvider);
    final scheme = Theme.of(context).colorScheme;

    final events = eventsAsync.valueOrNull ?? [];
    final attempts = attemptsAsync.valueOrNull ?? [];

    final practice = attempts;
    final correctCount = practice.where((a) => a.correct).length;
    final accuracy = practice.isEmpty
        ? null
        : ((correctCount / practice.length) * 100).round();

    final topicStats = <String, List<bool>>{};
    for (final a in practice) {
      topicStats.putIfAbsent(a.topic, () => []).add(a.correct);
    }
    final weakTopics = topicStats.entries
        .map((e) {
          final rate =
              e.value.where((c) => c).length / e.value.length;
          return MapEntry(e.key, rate);
        })
        .where((e) => e.value < 0.7)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Giám sát học tập'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _row('Hoạt động đã ghi', '${events.length}'),
                  _row('Bài luyện', '${practice.length}'),
                  _row(
                    'Độ chính xác luyện tập',
                    accuracy == null ? 'Chưa có' : '$accuracy%',
                  ),
                  if (weakTopics.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Chủ đề cần ôn:',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in weakTopics.take(5))
                          Chip(
                            label: Text(
                              '${t.key} (${(t.value * 100).round()}%)',
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _loadingInsight
                        ? null
                        : () => _askInsight(events, attempts),
                    icon: _loadingInsight
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.psychology_alt_rounded),
                    label: const Text('AI phân tích & kế hoạch ôn'),
                  ),
                ],
              ),
            ),
            if (_insight != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Báo cáo AI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    GptMarkdown(
                      _insight!,
                      useDollarSignsForLatex: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Nhật ký gần đây',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const GlassCard(
                child: Text('Chưa có dữ liệu. Hãy chat với gia sư hoặc luyện tập.'),
              )
            else
              ...events.take(20).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              switch (e.type) {
                                MathStudyEventType.tutor =>
                                  Icons.smart_toy_outlined,
                                MathStudyEventType.practice =>
                                  Icons.fitness_center,
                                MathStudyEventType.monitor =>
                                  Icons.insights_outlined,
                                MathStudyEventType.game =>
                                  Icons.sports_esports_rounded,
                              },
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.topic,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    e.detail,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (e.correct != null)
                              Icon(
                                e.correct!
                                    ? Icons.check_circle
                                    : Icons.cancel_outlined,
                                color: e.correct!
                                    ? scheme.primary
                                    : scheme.error,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
