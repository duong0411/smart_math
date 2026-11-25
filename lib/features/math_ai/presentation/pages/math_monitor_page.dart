import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/study_reminder_service.dart';
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
  var _loadingInsight = false;
  var _busyReminders = false;

  Future<void> _askInsight(
    List<MathStudyEvent> events,
    List<MathPracticeAttempt> attempts,
    List<String> weakTopicNames,
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
    summary.writeln('=== Nhật ký học Ngữ văn (gần đây) ===');
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

CUỐI BÁO CÁO — BẮT BUỘC thêm đúng khối sau (không giải thích thêm ngoài khối):
<<<PLAN_JSON
[
  {"day":1,"title":"Ngày 1: ...","detail":"Việc cụ thể 20-30 phút"},
  {"day":2,"title":"Ngày 2: ...","detail":"..."},
  {"day":3,"title":"Ngày 3: ...","detail":"..."},
  {"day":4,"title":"Ngày 4: ...","detail":"..."},
  {"day":5,"title":"Ngày 5: ...","detail":"..."}
]
PLAN_JSON>>>

$summary
''',
      extraSystemContext:
          'Chế độ giám sát & báo cáo học tập EduSelf Ngữ Văn AI: '
          'Trung thực 100% với dữ liệu bài tập Ngữ văn. '
          'Chỉ nhận xét về năng lực Ngữ văn và kỹ năng đọc–viết, kế hoạch ôn 5 ngày bám sát chương trình Ngữ văn THCS. '
          'Nếu nhật ký lẫn Toán, Lý, Hóa, Sử, Địa hoặc môn khác thì bỏ qua, không tính vào điểm mạnh/yếu. '
          'Kế hoạch ôn chỉ gồm đọc hiểu, tiếng Việt và tập làm văn theo sách Kết nối tri thức. '
          'Luôn kèm khối <<<PLAN_JSON ... PLAN_JSON>>> để app tạo checklist + nhắc nhở học sinh.',
    );

    if (!mounted) return;
    setState(() => _loadingInsight = false);

    switch (result) {
      case Success(:final value):
        final plan = MathReviewPlan.fromAiReport(
          reportText: value,
          weakTopics: weakTopicNames,
        );
        await ref.read(mathLocalStoreProvider).writeReviewPlan(plan);
        await ref.read(mathLocalStoreProvider).addEvent(
              MathStudyEvent(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: MathStudyEventType.monitor,
                topic: 'Báo cáo AI',
                detail: 'Đã tạo kế hoạch ôn 5 ngày + nhắc nhở',
                at: DateTime.now().toUtc(),
              ),
            );

        final ok = await StudyReminderService.instance.requestPermissions();
        if (ok) {
          await StudyReminderService.instance.syncPlanReminders(plan);
        }

        ref.invalidate(mathEventsProvider);
        ref.invalidate(mathReviewPlanProvider);

        if (!mounted) return;
        AppToast.success(
          ok
              ? 'Đã lưu kế hoạch & bật nhắc nhở học tập'
              : 'Đã lưu kế hoạch. Hãy cấp quyền thông báo để nhận nhắc nhở.',
        );
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _toggleTask(MathReviewPlan plan, MathReviewDayTask task) async {
    final now = DateTime.now().toUtc();
    final updatedDays = [
      for (final d in plan.days)
        if (d.day == task.day)
          d.copyWith(
            done: !d.done,
            completedAt: !d.done ? now : null,
          )
        else
          d,
    ];
    final updated = plan.copyWith(days: updatedDays);
    await ref.read(mathLocalStoreProvider).writeReviewPlan(updated);
    if (!task.done) {
      await ref.read(mathLocalStoreProvider).addEvent(
            MathStudyEvent(
              id: '${plan.id}-day-${task.day}-$now',
              type: MathStudyEventType.monitor,
              topic: 'Hoàn thành ngày ${task.day}',
              detail: task.title,
              correct: true,
              at: now,
            ),
          );
      ref.invalidate(mathEventsProvider);
      await ref.read(studyStreakStoreProvider).recordMeaningfulStudy(
            reason: 'Hoàn thành ngày ôn ${task.day}',
          );
      ref.invalidate(studyStreakProvider);
    }
    await StudyReminderService.instance.syncPlanReminders(updated);
    ref.invalidate(mathReviewPlanProvider);
  }

  Future<void> _setReminders(MathReviewPlan plan, bool enabled) async {
    setState(() => _busyReminders = true);
    try {
      if (enabled) {
        final ok = await StudyReminderService.instance.requestPermissions();
        if (!ok) {
          AppToast.error('Cần cấp quyền thông báo để nhắc học sinh.');
          return;
        }
      }
      final updated = plan.copyWith(remindersEnabled: enabled);
      await ref.read(mathLocalStoreProvider).writeReviewPlan(updated);
      await StudyReminderService.instance.syncPlanReminders(updated);
      ref.invalidate(mathReviewPlanProvider);
      AppToast.success(
        enabled
            ? 'Đã bật nhắc nhở 7:30 & 18:30 mỗi ngày ôn'
            : 'Đã tắt nhắc nhở',
      );
    } finally {
      if (mounted) setState(() => _busyReminders = false);
    }
  }

  Future<void> _nudgeNow(MathReviewPlan plan) async {
    setState(() => _busyReminders = true);
    try {
      final ok = await StudyReminderService.instance.requestPermissions();
      if (!ok) {
        AppToast.error('Cần cấp quyền thông báo.');
        return;
      }
      final overdue = plan.overdueTasks;
      final today = plan.todayTask;
      final focus = overdue.isNotEmpty
          ? overdue.first
          : (today ?? (plan.days.isNotEmpty ? plan.days.first : null));
      final body = focus == null
          ? 'Em hãy mở app và ôn Ngữ văn theo kế hoạch hôm nay.'
          : (overdue.isNotEmpty
              ? 'Em đang bỏ lỡ ${overdue.length} ngày ôn. Ưu tiên: ${focus.title}'
              : 'Hôm nay: ${focus.title}. ${focus.detail}');

      await StudyReminderService.instance.sendImmediateReminder(
        title: overdue.isNotEmpty
            ? 'Cảnh báo giám sát: chưa ôn tập'
            : 'Nhắc nhở học tập Ngữ văn',
        body: body,
      );
      await ref.read(mathLocalStoreProvider).addEvent(
            MathStudyEvent(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: MathStudyEventType.reminder,
              topic: 'Nhắc học sinh',
              detail: body,
              at: DateTime.now().toUtc(),
            ),
          );
      ref.invalidate(mathEventsProvider);
      AppToast.success('Đã gửi thông báo nhắc nhở');
    } finally {
      if (mounted) setState(() => _busyReminders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(mathEventsProvider);
    final attemptsAsync = ref.watch(mathAttemptsProvider);
    final planAsync = ref.watch(mathReviewPlanProvider);
    final scheme = Theme.of(context).colorScheme;

    final events = eventsAsync.valueOrNull ?? [];
    final attempts = attemptsAsync.valueOrNull ?? [];
    final plan = planAsync.valueOrNull;

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
          final rate = e.value.where((c) => c).length / e.value.length;
          return MapEntry(e.key, rate);
        })
        .where((e) => e.value < 0.7)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakNames = [for (final t in weakTopics) t.key];

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
                        : () => _askInsight(events, attempts, weakNames),
                    icon: _loadingInsight
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.psychology_alt_rounded),
                    label: Text(
                      plan == null
                          ? 'AI phân tích & kế hoạch ôn'
                          : 'Tạo lại kế hoạch ôn + nhắc nhở',
                    ),
                  ),
                ],
              ),
            ),
            if (plan != null) ...[
              const SizedBox(height: 16),
              _ComplianceCard(
                plan: plan,
                busy: _busyReminders,
                onToggleReminders: (v) => _setReminders(plan, v),
                onNudgeNow: () => _nudgeNow(plan),
                onToggleTask: (task) => _toggleTask(plan, task),
              ),
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
                      plan.reportText,
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
                child: Text(
                  'Chưa có dữ liệu. Hãy chat với gia sư hoặc luyện tập.',
                ),
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
                                MathStudyEventType.reminder =>
                                  Icons.notifications_active_outlined,
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

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({
    required this.plan,
    required this.busy,
    required this.onToggleReminders,
    required this.onNudgeNow,
    required this.onToggleTask,
  });

  final MathReviewPlan plan;
  final bool busy;
  final ValueChanged<bool> onToggleReminders;
  final VoidCallback onNudgeNow;
  final ValueChanged<MathReviewDayTask> onToggleTask;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (plan.compliance) {
      MathReviewCompliance.behind => scheme.error,
      MathReviewCompliance.completed => const Color(0xFF059669),
      MathReviewCompliance.onTrack => scheme.primary,
      MathReviewCompliance.none => scheme.onSurfaceVariant,
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Theo dõi kế hoạch ôn',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.complianceLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tiến độ: ${plan.doneCount}/${plan.days.length} ngày · '
                  'Nhắc nhở: ${plan.remindersEnabled ? 'BẬT (7:30 & 18:30)' : 'TẮT'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (plan.overdueTasks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'HS chưa thực hiện thì kế hoạch AI không có ý nghĩa — '
                    'hãy gửi nhắc nhở và yêu cầu đánh dấu hoàn thành từng ngày.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gửi thông báo nhắc nhở HS học tập'),
            subtitle: const Text(
              'Tự nhắc buổi sáng & chiều nếu chưa hoàn thành ngày ôn',
            ),
            value: plan.remindersEnabled,
            onChanged: busy ? null : onToggleReminders,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onNudgeNow,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Nhắc ngay bây giờ'),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Checklist 5 ngày',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          for (final task in plan.days)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: task.done,
              onChanged: busy ? null : (_) => onToggleTask(task),
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: task.done ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(task.detail),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }
}
