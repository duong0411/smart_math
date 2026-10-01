import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/features/math_games/presentation/widgets/game_result_logger.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Story adventure: move along a treasure map by answering grade-8 questions.
class TreasureTrailGamePage extends ConsumerStatefulWidget {
  const TreasureTrailGamePage({super.key});

  @override
  ConsumerState<TreasureTrailGamePage> createState() =>
      _TreasureTrailGamePageState();
}

class _TreasureTrailGamePageState extends ConsumerState<TreasureTrailGamePage>
    with SingleTickerProviderStateMixin {
  static const _stations = 8;

  var _step = 0;
  var _hearts = 3;
  var _stars = 0;
  var _playing = false;
  var _won = false;
  var _lost = false;
  GradeQuestion? _q;
  late final AnimationController _bounce;

  static const _story = [
    'Rời làng bắt đầu tìm kho báu…',
    'Qua cầu gỗ — tính đúng để qua sông!',
    'Gặp thương nhân bí ẩn…',
    'Leo đèo đá — cần sức mạnh Toán!',
    'Rừng sương mù hiện ra lối đi',
    'Hang động phát sáng kỳ lạ',
    'Người canh cổng thử thách cuối',
    'Rương kho báu ngay trước mắt!',
  ];

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _step = 0;
      _hearts = 3;
      _stars = 0;
      _playing = true;
      _won = false;
      _lost = false;
      _q = GradeQuestionBank.nextGrade8();
    });
    _bounce.forward(from: 0);
  }

  Future<void> _answer(int value) async {
    if (!_playing || _q == null) return;
    final ok = value == _q!.answer;
    if (ok) {
      HapticFeedback.lightImpact();
      setState(() {
        _stars += 1;
        _step += 1;
        if (_step >= _stations) {
          _playing = false;
          _won = true;
          _q = null;
        } else {
          _q = GradeQuestionBank.nextGrade8();
        }
      });
      _bounce.forward(from: 0);
      if (_won) {
        await logMathGameResult(
          ref,
          topic: 'Hành trình Kho báu',
          detail: 'Toán 8 · thắng · $_stars sao',
          success: true,
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hearts -= 1;
        if (_hearts <= 0) {
          _playing = false;
          _lost = true;
          _q = null;
        } else {
          _q = GradeQuestionBank.nextGrade8();
        }
      });
      if (_lost) {
        await logMathGameResult(
          ref,
          topic: 'Hành trình Kho báu',
          detail: 'Toán 8 · thua ở trạm $_step',
          success: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _step / _stations;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Hành trình Kho báu · Toán 8'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                _Hud(
                  hearts: _hearts,
                  stars: _stars,
                  step: _step,
                  total: _stations,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: const Color(0xFFD4A373),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: !_playing && !_won && !_lost
                          ? _IntroPanel(key: const ValueKey('i'), onStart: _start)
                          : _won
                              ? _EndPanel(
                                  key: const ValueKey('w'),
                                  title: 'Mở được rương kho báu!',
                                  subtitle: '$_stars ngôi sao · Toán 8',
                                  emoji: '🏆',
                                  onAgain: _start,
                                )
                              : _lost
                                  ? _EndPanel(
                                      key: const ValueKey('l'),
                                      title: 'Hành trình tạm dừng…',
                                      subtitle:
                                          'Hết trái tim ở trạm $_step/$_stations. Thử lại nhé!',
                                      emoji: '🗺️',
                                      onAgain: _start,
                                    )
                                  : _PlayPanel(
                                      key: ValueKey(_q?.prompt),
                                      story: _story[_step.clamp(0, _story.length - 1)],
                                      question: _q!,
                                      bounce: _bounce,
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

class _Hud extends StatelessWidget {
  const _Hud({
    required this.hearts,
    required this.stars,
    required this.step,
    required this.total,
  });

  final int hearts;
  final int stars;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          List.generate(3, (i) => i < hearts ? '❤️' : '🖤').join(),
          style: const TextStyle(fontSize: 18),
        ),
        const Spacer(),
        Text('⭐ $stars', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 12),
        Text(
          'Trạm $step/$total',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏝️', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          'Phiêu lưu 8 trạm đến kho báu',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Trả lời đúng để tiến lên. Sai mất 1 trái tim. Độ khó theo lớp của em.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.explore_rounded),
          label: const Text('Lên đường'),
        ),
      ],
    );
  }
}

class _PlayPanel extends StatelessWidget {
  const _PlayPanel({
    super.key,
    required this.story,
    required this.question,
    required this.bounce,
    required this.onPick,
  });

  final String story;
  final GradeQuestion question;
  final AnimationController bounce;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: bounce, curve: Curves.easeOutBack),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4A373).withValues(alpha: 0.35),
                  scheme.primaryContainer.withValues(alpha: 0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('🧭', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 6),
                Text(
                  story,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
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
                  color: scheme.onSurfaceVariant,
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
                    backgroundColor: const Color(0xFFD4A373),
                    foregroundColor: const Color(0xFF3D2B1F),
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

class _EndPanel extends StatelessWidget {
  const _EndPanel({
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
        Text(emoji, style: const TextStyle(fontSize: 56)),
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
          label: const Text('Chơi lại'),
        ),
      ],
    );
  }
}
