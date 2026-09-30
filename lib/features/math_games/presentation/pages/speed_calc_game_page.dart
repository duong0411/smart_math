import 'dart:async';

import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/features/math_games/domain/math_game_engine.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpeedCalcGamePage extends ConsumerStatefulWidget {
  const SpeedCalcGamePage({super.key});

  @override
  ConsumerState<SpeedCalcGamePage> createState() => _SpeedCalcGamePageState();
}

class _SpeedCalcGamePageState extends ConsumerState<SpeedCalcGamePage>
    with SingleTickerProviderStateMixin {
  static const _roundSeconds = 45;

  late MathGameDifficulty _difficulty;
  MathQuestion? _question;
  var _score = 0;
  var _combo = 0;
  var _bestCombo = 0;
  var _correct = 0;
  var _wrong = 0;
  var _secondsLeft = _roundSeconds;
  var _playing = false;
  var _finished = false;
  Timer? _timer;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      lowerBound: 0.96,
      upperBound: 1.06,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final grade = ref.read(mathProfileProvider).valueOrNull?.gradeLevel;
      _difficulty = MathGameEngine.difficultyForGrade(grade);
      setState(() {});
    });
    _difficulty = MathGameDifficulty.medium;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _correct = 0;
      _wrong = 0;
      _secondsLeft = _roundSeconds;
      _playing = true;
      _finished = false;
      _question = MathGameEngine.nextQuestion(_difficulty);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        _endRound();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _endRound() async {
    setState(() {
      _playing = false;
      _finished = true;
      _question = null;
    });
    HapticFeedback.mediumImpact();
    await ref.read(mathLocalStoreProvider).addEvent(
          MathStudyEvent(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: MathStudyEventType.game,
            topic: 'Tính siêu tốc',
            detail: 'Điểm $_score · đúng $_correct · combo $_bestCombo',
            correct: _correct >= _wrong,
            at: DateTime.now().toUtc(),
          ),
        );
    ref.invalidate(mathEventsProvider);
  }

  void _pick(int value) {
    if (!_playing || _question == null) return;
    final ok = value == _question!.answer;
    if (ok) {
      HapticFeedback.lightImpact();
      _pulse.forward(from: 0);
      setState(() {
        _combo += 1;
        if (_combo > _bestCombo) _bestCombo = _combo;
        _correct += 1;
        _score += 10 + (_combo * 2);
        _question = MathGameEngine.nextQuestion(_difficulty);
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _combo = 0;
        _wrong += 1;
        _score = (_score - 5).clamp(0, 99999);
        _question = MathGameEngine.nextQuestion(_difficulty);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _secondsLeft / _roundSeconds;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Tính siêu tốc'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _Pill(label: 'Điểm', value: '$_score', color: scheme.primary),
                    const SizedBox(width: 8),
                    _Pill(
                      label: 'Combo',
                      value: 'x$_combo',
                      color: const Color(0xFFE85D04),
                    ),
                    const Spacer(),
                    _Pill(
                      label: 'Giây',
                      value: '$_secondsLeft',
                      color: _secondsLeft <= 10
                          ? scheme.error
                          : scheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _playing || _finished ? progress : 1,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: _secondsLeft <= 10
                        ? scheme.error
                        : const Color(0xFFE85D04),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final d in MathGameDifficulty.values)
                        ChoiceChip(
                          label: Text(_labelDiff(d)),
                          selected: _difficulty == d,
                          onSelected: _playing
                              ? null
                              : (_) => setState(() => _difficulty = d),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: !_playing && !_finished
                            ? _Idle(
                                key: const ValueKey('idle'),
                                onStart: _start,
                              )
                            : _finished
                                ? _Result(
                                    key: const ValueKey('result'),
                                    score: _score,
                                    correct: _correct,
                                    wrong: _wrong,
                                    bestCombo: _bestCombo,
                                    onAgain: _start,
                                  )
                                : ScaleTransition(
                                    key: ValueKey(_question?.prompt),
                                    scale: Tween(begin: 1.0, end: 1.05)
                                        .animate(_pulse),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _question?.prompt ?? '',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .displaySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -1,
                                              ),
                                        ),
                                        const SizedBox(height: 28),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            for (final c
                                                in _question?.choices ??
                                                    const <int>[])
                                              _AnswerButton(
                                                value: c,
                                                onTap: () => _pick(c),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelDiff(MathGameDifficulty d) => switch (d) {
        MathGameDifficulty.easy => 'Dễ',
        MathGameDifficulty.medium => 'Vừa',
        MathGameDifficulty.hard => 'Khó',
      };
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.value, required this.onTap});
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 140,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        onPressed: onTap,
        child: Text('$value'),
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('⚡', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          'Trả lời đúng càng nhiều trong 45 giây!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Combo liên tiếp sẽ nhân điểm thưởng.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.bolt_rounded),
          label: const Text('Bắt đầu'),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    super.key,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.bestCombo,
    required this.onAgain,
  });

  final int score;
  final int correct;
  final int wrong;
  final int bestCombo;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hết giờ!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          '$score điểm',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFFE85D04),
              ),
        ),
        const SizedBox(height: 16),
        Text('Đúng $correct · Sai $wrong · Combo cao nhất x$bestCombo'),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onAgain,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Chơi lại'),
        ),
      ],
    );
  }
}
