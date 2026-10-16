import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/features/math_games/presentation/widgets/game_result_logger.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trắc nghiệm Địa lí THCS — thay thế module giải trí / mini-game.
class MultipleChoiceQuizPage extends ConsumerStatefulWidget {
  const MultipleChoiceQuizPage({super.key});

  @override
  ConsumerState<MultipleChoiceQuizPage> createState() =>
      _MultipleChoiceQuizPageState();
}

class _MultipleChoiceQuizPageState
    extends ConsumerState<MultipleChoiceQuizPage> {
  static const _gradeOptions = <int?>[null, 6, 7, 8, 9];
  static const _countOptions = [10, 15, 20];

  int? _selectedGrade;
  int _questionCount = 10;

  var _started = false;
  var _finished = false;
  var _index = 0;
  var _correct = 0;
  String? _picked;
  bool? _lastOk;
  List<GradeQuestion> _questions = const [];

  void _startQuiz() {
    final pool = GradeQuestionBank.pickQuestions(
      count: _questionCount,
      grade: _selectedGrade,
    );
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có câu hỏi cho lựa chọn này.')),
      );
      return;
    }
    setState(() {
      _questions = pool;
      _started = true;
      _finished = false;
      _index = 0;
      _correct = 0;
      _picked = null;
      _lastOk = null;
    });
  }

  Future<void> _choose(String value) async {
    if (_finished || _picked != null || _questions.isEmpty) return;
    final q = _questions[_index];
    final ok = value == q.answer;
    HapticFeedback.selectionClick();
    setState(() {
      _picked = value;
      _lastOk = ok;
      if (ok) _correct += 1;
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    if (_index + 1 >= _questions.length) {
      setState(() {
        _finished = true;
        _started = false;
      });
      await logMathGameResult(
        ref,
        topic: 'Trắc nghiệm Địa lí',
        detail:
            'Lớp ${_selectedGrade ?? '6–9'} · đúng $_correct/${_questions.length}',
        success: _correct >= (_questions.length / 2).ceil(),
      );
      return;
    }

    setState(() {
      _index += 1;
      _picked = null;
      _lastOk = null;
    });
  }

  void _resetToSetup() {
    setState(() {
      _started = false;
      _finished = false;
      _index = 0;
      _correct = 0;
      _picked = null;
      _lastOk = null;
      _questions = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Trắc nghiệm Địa lí'),
        ),
        body: !_started && !_finished
            ? _buildSetup(scheme)
            : _finished
                ? _buildResult(scheme)
                : _buildQuiz(scheme),
      ),
    );
  }

  Widget _buildSetup(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Luyện trắc nghiệm Địa lí THCS',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn lớp và số câu. Mỗi câu có 4 đáp án. Không cần API key.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Chọn lớp',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _gradeOptions.map((g) {
            final selected = _selectedGrade == g;
            final label = g == null ? 'Tất cả 6–9' : 'Lớp $g';
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => setState(() => _selectedGrade = g),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text(
          'Số câu hỏi',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _countOptions.map((n) {
            return ChoiceChip(
              label: Text('$n câu'),
              selected: _questionCount == n,
              onSelected: (_) => setState(() => _questionCount = n),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _startQuiz,
          icon: const Icon(Icons.quiz_outlined),
          label: const Text('Bắt đầu làm bài'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }

  Widget _buildQuiz(ColorScheme scheme) {
    final q = _questions[_index];
    final progress = (_index + 1) / _questions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            Text(
              'Câu ${_index + 1}/${_questions.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            Text(
              'Đúng $_correct',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
          ),
        ),
        if (q.chapter != null) ...[
          const SizedBox(height: 12),
          Text(
            q.chapter!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Text(
            q.prompt,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(q.choices.length, (i) {
          final choice = q.choices[i];
          final letter = String.fromCharCode(65 + i); // A B C D
          Color? bg;
          Color? border;
          if (_picked != null) {
            if (choice == q.answer) {
              bg = Colors.green.withValues(alpha: 0.18);
              border = Colors.green;
            } else if (choice == _picked && _lastOk == false) {
              bg = Colors.red.withValues(alpha: 0.18);
              border = Colors.red;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _picked == null ? () => _choose(choice) : null,
                child: Ink(
                  decoration: BoxDecoration(
                    color: bg ?? scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: border ?? scheme.outlineVariant,
                      width: border != null ? 1.6 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: scheme.primary.withValues(alpha: 0.15),
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            choice,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        if (_picked != null && q.storyHint != null) ...[
          const SizedBox(height: 6),
          Text(
            'Gợi ý: ${q.storyHint}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildResult(ColorScheme scheme) {
    final total = _questions.length;
    final pct = total == 0 ? 0 : ((_correct / total) * 100).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                pct >= 70
                    ? Icons.emoji_events_rounded
                    : Icons.assignment_turned_in_outlined,
                size: 56,
                color: scheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Kết quả bài làm',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đúng $_correct / $total câu ($pct%)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedGrade == null
                    ? 'Phạm vi: Lớp 6–9'
                    : 'Phạm vi: Lớp $_selectedGrade',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _startQuiz,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Làm lại bộ câu hỏi'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _resetToSetup,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Đổi lớp / số câu'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}
