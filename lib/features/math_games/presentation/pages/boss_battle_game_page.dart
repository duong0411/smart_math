import 'dart:math';

import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/features/math_games/presentation/widgets/game_result_logger.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RPG-style boss fight: correct answers deal damage, wrong answers hurt the player.
class BossBattleGamePage extends ConsumerStatefulWidget {
  const BossBattleGamePage({super.key});

  @override
  ConsumerState<BossBattleGamePage> createState() => _BossBattleGamePageState();
}

class _BossBattleGamePageState extends ConsumerState<BossBattleGamePage> {
  late final _Boss _boss;
  var _playerHp = 100;
  var _bossHp = 100;
  var _combo = 0;
  var _playing = false;
  var _won = false;
  var _lost = false;
  var _shake = 0.0;
  GradeQuestion? _q;

  @override
  void initState() {
    super.initState();
    _boss = _Boss.grade8;
    _bossHp = _boss.maxHp;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _start() {
    setState(() {
      _playerHp = 100;
      _bossHp = _boss.maxHp;
      _combo = 0;
      _playing = true;
      _won = false;
      _lost = false;
      _shake = 0;
      _q = GradeQuestionBank.nextGrade8();
    });
  }

  Future<void> _answer(int value) async {
    if (!_playing || _q == null) return;
    final ok = value == _q!.answer;
    if (ok) {
      HapticFeedback.mediumImpact();
      _combo += 1;
      final dmg = (14 + _combo * 3 + Random().nextInt(6)).clamp(10, 40);
      setState(() {
        _bossHp = (_bossHp - dmg).clamp(0, _boss.maxHp);
        _shake = 8;
        if (_bossHp <= 0) {
          _playing = false;
          _won = true;
          _q = null;
        } else {
          _q = GradeQuestionBank.nextGrade8();
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) setState(() => _shake = 0);
      if (_won) {
        await logMathGameResult(
          ref,
          topic: 'Đại chiến Boss Toán',
          detail: 'Toán 8 · hạ ${_boss.name}',
          success: true,
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      final dmg = 16 + Random().nextInt(10);
      setState(() {
        _combo = 0;
        _playerHp = (_playerHp - dmg).clamp(0, 100);
        _shake = -8;
        if (_playerHp <= 0) {
          _playing = false;
          _lost = true;
          _q = null;
        } else {
          _q = GradeQuestionBank.nextGrade8();
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) setState(() => _shake = 0);
      if (_lost) {
        await logMathGameResult(
          ref,
          topic: 'Đại chiến Boss Toán',
          detail: 'Toán 8 · thua ${_boss.name}',
          success: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Đại chiến Boss · Toán 8'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  transform: Matrix4.translationValues(_shake, 0, 0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(_boss.emoji, style: const TextStyle(fontSize: 48)),
                        Text(
                          _boss.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          _boss.taunt,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        _HpBar(
                          label: 'Boss',
                          value: _bossHp / _boss.maxHp,
                          color: const Color(0xFFE76F51),
                          hp: _bossHp,
                        ),
                        const SizedBox(height: 8),
                        _HpBar(
                          label: 'Bạn',
                          value: _playerHp / 100,
                          color: const Color(0xFF2A9D8F),
                          hp: _playerHp,
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Combo x$_combo',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE9C46A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: !_playing && !_won && !_lost
                          ? _BattleIntro(
                              key: const ValueKey('bi'),
                              boss: _boss,
                              onStart: _start,
                            )
                          : _won
                              ? _BattleEnd(
                                  key: const ValueKey('bw'),
                                  title: 'Chiến thắng!',
                                  subtitle: 'Em đã hạ ${_boss.name} bằng trí tuệ Toán!',
                                  emoji: '⚔️',
                                  onAgain: _start,
                                )
                              : _lost
                                  ? _BattleEnd(
                                      key: const ValueKey('bl'),
                                      title: 'Hồi máu rồi thử lại!',
                                      subtitle: '${_boss.name} còn mạnh — combo để đánh nhanh hơn.',
                                      emoji: '🛡️',
                                      onAgain: _start,
                                    )
                                  : _BattleAsk(
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

class _Boss {
  const _Boss({
    required this.name,
    required this.emoji,
    required this.taunt,
    required this.maxHp,
  });

  final String name;
  final String emoji;
  final String taunt;
  final int maxHp;

  static const grade8 = _Boss(
    name: 'Phù Thủy Phương Trình',
    emoji: '🧙',
    taunt: 'Căn · đa thức · PT bậc nhất — giải sai là bị lời nguyền!',
    maxHp: 120,
  );
}

class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.label,
    required this.value,
    required this.color,
    required this.hp,
  });

  final String label;
  final double value;
  final Color color;
  final int hp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 12,
              color: color,
              backgroundColor: color.withValues(alpha: 0.18),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$hp', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BattleIntro extends StatelessWidget {
  const _BattleIntro({super.key, required this.boss, required this.onStart});
  final _Boss boss;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(boss.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text(
          'Đối đầu ${boss.name}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Trả lời đúng để tấn công. Sai bị phản đòn. Combo càng cao sát thương càng lớn!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.sports_kabaddi_rounded),
          label: const Text('Khiêu chiến'),
        ),
      ],
    );
  }
}

class _BattleAsk extends StatelessWidget {
  const _BattleAsk({super.key, required this.question, required this.onPick});
  final GradeQuestion question;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Đòn tấn Toán!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFE76F51),
              ),
        ),
        const SizedBox(height: 14),
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
                    backgroundColor: const Color(0xFFE76F51),
                    foregroundColor: Colors.white,
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

class _BattleEnd extends StatelessWidget {
  const _BattleEnd({
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
          label: const Text('Đấu lại'),
        ),
      ],
    );
  }
}
