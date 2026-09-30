import 'dart:async';
import 'dart:math';

import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/features/math_games/domain/math_game_engine.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BubblePopGamePage extends ConsumerStatefulWidget {
  const BubblePopGamePage({super.key});

  @override
  ConsumerState<BubblePopGamePage> createState() => _BubblePopGamePageState();
}

class _BubblePopGamePageState extends ConsumerState<BubblePopGamePage>
    with TickerProviderStateMixin {
  final _rng = Random();
  late MathGameDifficulty _difficulty;
  MathQuestion? _question;
  var _score = 0;
  var _lives = 3;
  var _round = 0;
  var _playing = false;
  var _finished = false;
  final List<_Bubble> _bubbles = [];
  Timer? _ticker;
  Size _arena = Size.zero;

  static const _palette = [
    Color(0xFF2A9D8F),
    Color(0xFFE9C46A),
    Color(0xFFF4A261),
    Color(0xFFE76F51),
    Color(0xFF264653),
  ];

  @override
  void initState() {
    super.initState();
    _difficulty = MathGameDifficulty.medium;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final grade = ref.read(mathProfileProvider).valueOrNull?.gradeLevel;
      setState(() {
        _difficulty = MathGameEngine.difficultyForGrade(grade);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    setState(() {
      _score = 0;
      _lives = 3;
      _round = 0;
      _playing = true;
      _finished = false;
      _bubbles.clear();
    });
    _spawnRound();
    _ticker = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!mounted || !_playing) return;
      _tick();
    });
  }

  void _spawnRound() {
    if (_arena == Size.zero) return;
    final q = MathGameEngine.nextQuestion(_difficulty);
    final bubbles = <_Bubble>[];
    final choices = List<int>.from(q.choices)..shuffle(_rng);
    for (var i = 0; i < choices.length; i++) {
      final value = choices[i];
      bubbles.add(
        _Bubble(
          value: value,
          isCorrect: value == q.answer,
          x: 24 + _rng.nextDouble() * (_arena.width - 88),
          y: _arena.height + _rng.nextDouble() * 80 + i * 30,
          radius: 34 + _rng.nextDouble() * 10,
          speed: 1.4 + _rng.nextDouble() * 1.6 + (_round * 0.08),
          drift: (_rng.nextDouble() - 0.5) * 0.8,
          color: _palette[i % _palette.length],
        ),
      );
    }
    setState(() {
      _question = q;
      _bubbles
        ..clear()
        ..addAll(bubbles);
      _round += 1;
    });
  }

  void _tick() {
    if (_arena == Size.zero) return;
    var escapedCorrect = false;
    for (final b in _bubbles) {
      if (b.popped) continue;
      b.y -= b.speed;
      b.x += b.drift;
      if (b.x < 8) {
        b.x = 8;
        b.drift = b.drift.abs();
      } else if (b.x > _arena.width - b.radius * 2) {
        b.x = _arena.width - b.radius * 2;
        b.drift = -b.drift.abs();
      }
      if (b.y + b.radius * 2 < 0) {
        b.popped = true;
        if (b.isCorrect) escapedCorrect = true;
      }
    }
    final alive = _bubbles.where((b) => !b.popped).toList();
    if (escapedCorrect) {
      _missLife();
      return;
    }
    if (alive.isEmpty && _playing) {
      // All wrong bubbles gone but somehow no correct — spawn next.
      _spawnRound();
      return;
    }
    setState(() {});
  }

  void _missLife() {
    HapticFeedback.heavyImpact();
    setState(() {
      _lives -= 1;
      if (_lives <= 0) {
        _playing = false;
        _finished = true;
        _ticker?.cancel();
      } else {
        _spawnRound();
      }
    });
    if (_finished) _logResult();
  }

  void _tapBubble(_Bubble b) {
    if (!_playing || b.popped) return;
    if (b.isCorrect) {
      HapticFeedback.lightImpact();
      setState(() {
        b.popped = true;
        _score += 15 + _round;
      });
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted && _playing) _spawnRound();
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        b.popped = true;
        _lives -= 1;
        if (_lives <= 0) {
          _playing = false;
          _finished = true;
          _ticker?.cancel();
        }
      });
      if (_finished) _logResult();
    }
  }

  Future<void> _logResult() async {
    await ref.read(mathLocalStoreProvider).addEvent(
          MathStudyEvent(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: MathStudyEventType.game,
            topic: 'Bong bóng số',
            detail: 'Điểm $_score · vòng $_round',
            correct: _score > 0,
            at: DateTime.now().toUtc(),
          ),
        );
    ref.invalidate(mathEventsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Bong bóng số'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Điểm $_score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      List.filled(_lives.clamp(0, 3), '❤️').join(),
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (_lives <= 0)
                      Text(
                        ' Hết mạng',
                        style: TextStyle(color: scheme.error),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final d in MathGameDifficulty.values)
                        ChoiceChip(
                          label: Text(switch (d) {
                            MathGameDifficulty.easy => 'Dễ',
                            MathGameDifficulty.medium => 'Vừa',
                            MathGameDifficulty.hard => 'Khó',
                          }),
                          selected: _difficulty == d,
                          onSelected: _playing
                              ? null
                              : (_) => setState(() => _difficulty = d),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_question != null && _playing)
                  Text(
                    _question!.prompt,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _arena = Size(constraints.maxWidth, constraints.maxHeight);
                        if (!_playing && !_finished) {
                          return _CenterPanel(
                            title: 'Chạm bóng có đáp án đúng',
                            subtitle:
                                'Bóng bay lên dần — để trôi mất đáp án đúng sẽ mất 1 mạng.',
                            actionLabel: 'Thổi bóng!',
                            onAction: _start,
                          );
                        }
                        if (_finished) {
                          return _CenterPanel(
                            title: 'Kết thúc · $_score điểm',
                            subtitle: 'Em đã qua $_round vòng. Chơi lại nhé!',
                            actionLabel: 'Chơi lại',
                            onAction: _start,
                          );
                        }
                        return Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            for (final b in _bubbles.where((e) => !e.popped))
                              Positioned(
                                left: b.x,
                                top: b.y,
                                child: GestureDetector(
                                  onTap: () => _tapBubble(b),
                                  child: _BubbleWidget(bubble: b),
                                ),
                              ),
                          ],
                        );
                      },
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

class _Bubble {
  _Bubble({
    required this.value,
    required this.isCorrect,
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.color,
  });

  final int value;
  final bool isCorrect;
  double x;
  double y;
  final double radius;
  final double speed;
  double drift;
  final Color color;
  bool popped = false;
}

class _BubbleWidget extends StatelessWidget {
  const _BubbleWidget({required this.bubble});
  final _Bubble bubble;

  @override
  Widget build(BuildContext context) {
    final size = bubble.radius * 2;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.85),
            bubble.color.withValues(alpha: 0.95),
          ],
          center: const Alignment(-0.3, -0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: bubble.color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '${bubble.value}',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: bubble.radius * 0.7,
          color: Colors.white,
          shadows: const [
            Shadow(blurRadius: 4, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _CenterPanel extends StatelessWidget {
  const _CenterPanel({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🫧', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
