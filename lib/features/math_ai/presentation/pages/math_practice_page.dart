import 'dart:convert';

import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class MathPracticePage extends ConsumerStatefulWidget {
  const MathPracticePage({super.key});

  @override
  ConsumerState<MathPracticePage> createState() => _MathPracticePageState();
}

class _MathPracticePageState extends ConsumerState<MathPracticePage> {
  final _answerController = TextEditingController();
  final _topicController = TextEditingController();

  String? _question;
  String? _topic;
  String? _feedback;
  bool? _correct;
  var _busy = false;

  @override
  void dispose() {
    _answerController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final hasKey =
        (ref.read(geminiApiKeyProvider).valueOrNull ?? '').trim().isNotEmpty;
    if (!hasKey) {
      AppToast.error('Cần Gemini API key.');
      if (mounted) context.push('/settings');
      return;
    }

    setState(() {
      _busy = true;
      _feedback = null;
      _correct = null;
      _question = null;
    });
    _answerController.clear();

    final topic = _topicController.text.trim().isEmpty
        ? 'theo chương trình lớp hiện tại'
        : _topicController.text.trim();

    final result = await askMathAi(
      ref,
      userMessage: '''
Hãy tạo ĐÚNG 1 bài tập Toán (chưa có đáp án) cho học sinh.
Chủ đề: $topic

Trả lời CHỈ bằng JSON thuần (không markdown):
{"topic":"...","question":"..."}
Câu hỏi dùng LaTeX \$...\$ nếu cần.
''',
      extraSystemContext:
          'Chế độ luyện tập: chỉ tạo 1 bài phù hợp lớp, vừa sức.',
    );

    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Success(:final value):
        final parsed = _parseJson(value);
        if (parsed == null) {
          AppToast.error('AI trả về định dạng không hợp lệ. Thử lại.');
          return;
        }
        setState(() {
          _topic = parsed['topic'] as String? ?? topic;
          _question = parsed['question'] as String? ?? value;
        });
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _submit() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty || _question == null || _busy) return;

    setState(() => _busy = true);
    final result = await askMathAi(
      ref,
      userMessage: '''
Chấm bài luyện tập Toán.

Đề: $_question
Bài làm học sinh: $answer

Trả lời CHỈ bằng JSON thuần (không markdown):
{"correct":true/false,"feedback":"giải thích ngắn, chỉ ra lỗi nếu sai, gợi ý bước tiếp theo. Dùng LaTeX nếu cần."}

Không đưa đáp án đầy đủ nếu học sinh sai — chỉ gợi ý trừ khi gần đúng.
''',
      extraSystemContext: 'Chế độ chấm luyện tập.',
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final value):
        final parsed = _parseJson(value);
        final correct = parsed?['correct'] == true;
        final feedback = (parsed?['feedback'] as String?) ?? value;
        final attempt = MathPracticeAttempt(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          topic: _topic ?? 'Toán',
          question: _question!,
          studentAnswer: answer,
          feedback: feedback,
          correct: correct,
          at: DateTime.now().toUtc(),
        );
        await ref.read(mathLocalStoreProvider).addAttempt(attempt);
        ref.invalidate(mathAttemptsProvider);
        ref.invalidate(mathEventsProvider);
        setState(() {
          _busy = false;
          _correct = correct;
          _feedback = feedback;
        });
      case FailureResult(:final failure):
        setState(() => _busy = false);
        AppToast.error(failure.message);
    }
  }

  Map<String, dynamic>? _parseJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceAll(RegExp(r'\s*```$'), '');
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) return decoded;
    } on Object {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Luyện tập Toán'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Chủ đề (tuỳ chọn)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      hintText: 'VD: phương trình bậc nhất, phân số…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _generate,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _question == null ? 'Tạo bài mới' : 'Đổi bài khác',
                    ),
                  ),
                ],
              ),
            ),
            if (_question != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_topic != null)
                      Text(
                        _topic!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    const SizedBox(height: 8),
                    GptMarkdown(
                      _question!,
                      useDollarSignsForLatex: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _answerController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Bài làm của em',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _submit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Nộp bài để AI chấm'),
                    ),
                  ],
                ),
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _correct == true
                              ? Icons.verified_rounded
                              : Icons.lightbulb_outline,
                          color: _correct == true
                              ? scheme.primary
                              : scheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _correct == true ? 'Đúng rồi!' : 'Cần xem lại',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GptMarkdown(
                      _feedback!,
                      useDollarSignsForLatex: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
