import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/features/math_games/presentation/widgets/game_result_logger.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pirate Math Quest — vượt cửa ải, lấy chìa khóa, mở rương kho báu.
class TreasureTrailGamePage extends ConsumerStatefulWidget {
  const TreasureTrailGamePage({
    super.key,
    this.gradeLevel = SupportedGrades.fallback,
  });

  final int gradeLevel;

  @override
  ConsumerState<TreasureTrailGamePage> createState() =>
      _TreasureTrailGamePageState();
}

class _TreasureTrailGamePageState extends ConsumerState<TreasureTrailGamePage>
    with SingleTickerProviderStateMixin {
  static const _stations = 8;

  late final int _grade;
  var _step = 0;
  var _hearts = 3;
  var _keys = 0;
  var _coins = 0;
  var _chests = 0;
  var _streak = 0;
  var _playing = false;
  var _won = false;
  var _lost = false;
  String? _hint;
  GradeQuestion? _q;
  late final AnimationController _bounce;
  late final List<_Gate> _gates;

  static List<_Gate> _gatesFor(int grade) {
    final g = SupportedGrades.normalize(grade);
    if (g <= 7) {
      return const [
        _Gate('Cổng Số nguyên', 'Số học', '🔑'),
        _Gate('Cầu Phần trăm', 'Số học', '🗝️'),
        _Gate('Rừng Biểu thức', 'Đại số', '🔑'),
        _Gate('Hồ Phương trình', 'Phương trình', '🗝️'),
        _Gate('Hang Hình học', 'Hình học', '🔑'),
        _Gate('Đồi Lũy thừa', 'Lũy thừa', '🗝️'),
        _Gate('Thung lũng Tỉ lệ', 'Bài toán thực tế', '🔑'),
        _Gate('Đảo Kho báu', 'Tổng hợp', '💎'),
      ];
    }
    return const [
      _Gate('Cổng Đại số', 'Đại số', '🔑'),
      _Gate('Cầu Hằng đẳng thức', 'Đại số', '🗝️'),
      _Gate('Mê cung Hình học', 'Hình học', '🔑'),
      _Gate('Đường trung bình', 'Hình học', '🗝️'),
      _Gate('Hang Dữ liệu', 'Số học', '🔑'),
      _Gate('Vịnh Phân thức', 'Phương trình', '🗝️'),
      _Gate('Đảo Pythagore', 'Hình học', '🔑'),
      _Gate('Đỉnh Kho báu', 'Tổng hợp', '💎'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _grade = SupportedGrades.normalize(widget.gradeLevel);
    _gates = _gatesFor(_grade);
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

  GradeQuestion _nextQ() => GradeQuestionBank.next(_grade);

  void _start() {
    setState(() {
      _step = 0;
      _hearts = 3;
      _keys = 0;
      _coins = 0;
      _chests = 0;
      _streak = 0;
      _playing = true;
      _won = false;
      _lost = false;
      _hint = null;
      _q = _nextQ();
    });
    _bounce.forward(from: 0);
  }

  String _buildHint(GradeQuestion q) {
    final chapter = q.chapter ?? 'bài này';
    if (q.storyHint != null && q.storyHint!.trim().isNotEmpty) {
      return '💡 Gợi ý AI: ${q.storyHint}';
    }
    return '💡 Gợi ý AI: Xem lại chương «$chapter». Thử tính từng bước '
        'rồi đối chiếu với các đáp án.';
  }

  Future<void> _answer(int value) async {
    if (!_playing || _q == null) return;
    final ok = value == _q!.answer;
    if (ok) {
      HapticFeedback.lightImpact();
      final bonus = 10 + (_streak * 2).clamp(0, 20);
      setState(() {
        _streak += 1;
        _keys += 1;
        _coins += bonus;
        if (_keys >= 2) {
          _chests += 1;
          _keys -= 2;
          _coins += 25;
        }
        _step += 1;
        _hint = null;
        if (_step >= _stations) {
          _playing = false;
          _won = true;
          _coins += 100;
          _q = null;
        } else {
          _q = _nextQ();
        }
      });
      _bounce.forward(from: 0);
      if (_won) {
        await logMathGameResult(
          ref,
          topic: 'Truy tìm kho báu Toán học',
          detail: 'Toán $_grade · thắng · $_coins vàng · $_chests rương',
          success: true,
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _streak = 0;
        _hearts -= 1;
        _hint = _buildHint(_q!);
        if (_hearts <= 0) {
          _playing = false;
          _lost = true;
          _q = null;
        } else {
          // Adaptive: sau sai → câu mới cùng lớp (giữ nhịp luyện).
          _q = _nextQ();
        }
      });
      if (_lost) {
        await logMathGameResult(
          ref,
          topic: 'Truy tìm kho báu Toán học',
          detail: 'Toán $_grade · thua ở cửa ải $_step · $_coins vàng',
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
          title: Text('Pirate Math Quest · Lớp $_grade'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                _Hud(
                  hearts: _hearts,
                  keys: _keys,
                  coins: _coins,
                  chests: _chests,
                  step: _step,
                  total: _stations,
                ),
                const SizedBox(height: 10),
                _MapStrip(step: _step, total: _stations),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: const Color(0xFFE9A825),
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
                                  subtitle:
                                      '$_coins vàng · $_chests rương · Toán lớp $_grade',
                                  emoji: '🏴‍☠️',
                                  onAgain: _start,
                                )
                              : _lost
                                  ? _EndPanel(
                                      key: const ValueKey('l'),
                                      title: 'Hành trình tạm dừng…',
                                      subtitle:
                                          'Hết trái tim ở cửa ải $_step/$_stations. Thử lại nhé!',
                                      emoji: '🗺️',
                                      onAgain: _start,
                                    )
                                  : _PlayPanel(
                                      key: ValueKey(_q?.prompt),
                                      gate: _gates[_step.clamp(0, _gates.length - 1)],
                                      question: _q!,
                                      bounce: _bounce,
                                      hint: _hint,
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

class _Gate {
  const _Gate(this.name, this.topic, this.icon);
  final String name;
  final String topic;
  final String icon;
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.hearts,
    required this.keys,
    required this.coins,
    required this.chests,
    required this.step,
    required this.total,
  });

  final int hearts;
  final int keys;
  final int coins;
  final int chests;
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
        Text('🔑 $keys', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Text('📦 $chests', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Text('🪙 $coins', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Text(
          'Ải $step/$total',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _MapStrip extends StatelessWidget {
  const _MapStrip({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 3,
                  color: i <= step
                      ? const Color(0xFFE9A825)
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < step
                    ? const Color(0xFFE9A825)
                    : i == step
                        ? const Color(0xFF2A9D8F)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Text(
                i < step
                    ? '✓'
                    : i == total - 1
                        ? '💎'
                        : '${i + 1}',
                style: TextStyle(
                  fontSize: i == total - 1 && i >= step ? 12 : 11,
                  fontWeight: FontWeight.w800,
                  color: i <= step ? Colors.white : null,
                ),
              ),
            ),
          ],
        ],
      ),
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
        const Text('🏴‍☠️', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          'Truy tìm kho báu Toán học',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vượt 8 cửa ải · lấy chìa khóa · mở rương. '
          'Sai có gợi ý từng bước. Độ khó theo lớp của em.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE9A825),
            foregroundColor: const Color(0xFF3D2B1F),
          ),
          icon: const Icon(Icons.explore_rounded),
          label: const Text('Lên đường tìm kho báu'),
        ),
      ],
    );
  }
}

class _PlayPanel extends StatelessWidget {
  const _PlayPanel({
    super.key,
    required this.gate,
    required this.question,
    required this.bounce,
    required this.onPick,
    this.hint,
  });

  final _Gate gate;
  final GradeQuestion question;
  final AnimationController bounce;
  final ValueChanged<int> onPick;
  final String? hint;

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
                  const Color(0xFFE9A825).withValues(alpha: 0.35),
                  const Color(0xFF2A9D8F).withValues(alpha: 0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(gate.icon, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 6),
                Text(
                  gate.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Chủ đề: ${gate.topic}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
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
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
        if (hint != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hint!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                    backgroundColor: const Color(0xFFE9A825),
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
