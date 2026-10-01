import 'dart:async';
import 'dart:math';

import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/features/math_games/presentation/widgets/game_result_logger.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fill the rocket fuel before countdown ends — grade-scaled questions.
class RocketRushGamePage extends ConsumerStatefulWidget {
  const RocketRushGamePage({super.key, required this.grade});

  final int grade;

  @override
  ConsumerState<RocketRushGamePage> createState() => _RocketRushGamePageState();
}

class _RocketRushGamePageState extends ConsumerState<RocketRushGamePage>
    with SingleTickerProviderStateMixin {
  static const _fuelTarget = 100;
  static const _seconds = 50;

  var _fuel = 0;
  var _secondsLeft = _seconds;
  var _streak = 0;
  var _playing = false;
  var _launched = false;
  var _failed = false;
  GradeQuestion? _q;
  Timer? _timer;
  late final AnimationController _lift;

  @override
  void initState() {
    super.initState();
    _lift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lift.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _lift.reset();
    setState(() {
      _fuel = 0;
      _secondsLeft = _seconds;
      _streak = 0;
      _playing = true;
      _launched = false;
      _failed = false;
      _q = GradeQuestionBank.next(widget.grade);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_playing) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        _fail();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _fail() async {
    setState(() {
      _playing = false;
      _failed = true;
      _q = null;
    });
    await logMathGameResult(
      ref,
      topic: 'Phóng Tên Lửa',
      detail: 'Lớp ${widget.grade} · hết giờ · nhiên liệu $_fuel%',
      success: false,
    );
  }

  Future<void> _answer(int value) async {
    if (!_playing || _q == null) return;
    final ok = value == _q!.answer;
    if (ok) {
      HapticFeedback.lightImpact();
      final gain = 12 + _streak * 2 + Random().nextInt(4);
      setState(() {
        _streak += 1;
        _fuel = (_fuel + gain).clamp(0, _fuelTarget);
        if (_fuel >= _fuelTarget) {
          _playing = false;
          _launched = true;
          _q = null;
          _timer?.cancel();
        } else {
          _q = GradeQuestionBank.next(widget.grade);
        }
      });
      if (_launched) {
        _lift.forward(from: 0);
        await logMathGameResult(
          ref,
          topic: 'Phóng Tên Lửa',
          detail: 'Lớp ${widget.grade} · phóng thành công · ${_seconds - _secondsLeft}s',
          success: true,
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _streak = 0;
        _fuel = (_fuel - 8).clamp(0, _fuelTarget);
        _q = GradeQuestionBank.next(widget.grade);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fuelRatio = _fuel / _fuelTarget;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Phóng Tên Lửa · Lớp ${widget.grade}'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '⏱️ $_secondsLeft s',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _secondsLeft <= 10 ? scheme.error : null,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '🔥 Streak x$_streak',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nhiên liệu $_fuel%',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: fuelRatio,
                                minHeight: 14,
                                color: const Color(0xFF4CC9F0),
                                backgroundColor:
                                    scheme.surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset.zero,
                          end: const Offset(0, -1.2),
                        ).animate(
                          CurvedAnimation(
                            parent: _lift,
                            curve: Curves.easeInCubic,
                          ),
                        ),
                        child: Text(
                          _launched ? '🚀' : '🛸',
                          style: const TextStyle(fontSize: 42),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: !_playing && !_launched && !_failed
                          ? _RocketIntro(key: const ValueKey('ri'), onStart: _start)
                          : _launched
                              ? _RocketEnd(
                                  key: const ValueKey('rw'),
                                  title: 'Phóng thành công!',
                                  subtitle:
                                      'Tên lửa lớp ${widget.grade} đã lên quỹ đạo. Tuyệt vời!',
                                  emoji: '🌌',
                                  onAgain: _start,
                                )
                              : _failed
                                  ? _RocketEnd(
                                      key: const ValueKey('rf'),
                                      title: 'Chưa đủ nhiên liệu…',
                                      subtitle:
                                          'Hết giờ ở mức $_fuel%. Streak giúp nạp nhanh hơn!',
                                      emoji: '💨',
                                      onAgain: _start,
                                    )
                                  : _RocketAsk(
                                      key: ValueKey(_q?.prompt),
                                      question: _q!,
                                      onPick: _answer,
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
}

class _RocketIntro extends StatelessWidget {
  const _RocketIntro({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🚀', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 10),
        Text(
          'Nạp 100% nhiên liệu trong 50 giây',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đúng = nạp thêm (streak càng dài càng nhanh). Sai = hao nhiên liệu!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text('Khởi động'),
        ),
      ],
    );
  }
}

class _RocketAsk extends StatelessWidget {
  const _RocketAsk({super.key, required this.question, required this.onPick});
  final GradeQuestion question;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Tính nhanh để nạp nhiên liệu',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4CC9F0),
              ),
        ),
        const SizedBox(height: 16),
        Text(
          question.prompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        if (question.storyHint != null) ...[
          const SizedBox(height: 8),
          Text(
            question.storyHint!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
        const Spacer(),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final c in question.choices)
              SizedBox(
                width: 148,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4CC9F0),
                    foregroundColor: const Color(0xFF0B132B),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () => onPick(c),
                  child: Text('$c'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RocketEnd extends StatelessWidget {
  const _RocketEnd({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.onAgain,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onAgain,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Phóng lại'),
        ),
      ],
    );
  }
}
