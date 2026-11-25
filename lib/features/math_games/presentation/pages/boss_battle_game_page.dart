import 'dart:async';
import 'dart:math';

import 'package:eduself_study_app/features/math_games/domain/game_play_mode.dart';
import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/features/math_games/presentation/widgets/game_result_logger.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Đại chiến Boss: đấu đơn hoặc Song hành (co-op) + tuyệt chiêu.
class BossBattleGamePage extends ConsumerStatefulWidget {
  const BossBattleGamePage({
    super.key,
    this.gradeLevel = SupportedGrades.fallback,
    this.mode = GamePlayMode.solo,
  });

  final int gradeLevel;
  final GamePlayMode mode;

  @override
  ConsumerState<BossBattleGamePage> createState() => _BossBattleGamePageState();
}

class _BossBattleGamePageState extends ConsumerState<BossBattleGamePage> {
  late final _Boss _boss;
  late final int _grade;
  late final GamePlayMode _mode;
  var _playerHp = 100;
  var _bossHp = 100;
  var _combo = 0;
  var _playing = false;
  var _won = false;
  var _lost = false;
  var _shake = 0.0;
  var _secondsLeft = 150;
  var _awaitingB = false;
  int? _pickA;
  var _doubleNext = false;
  var _skillReady = false;
  Timer? _timer;
  GradeQuestion? _q;
  final _log = <String>[];

  @override
  void initState() {
    super.initState();
    _grade = SupportedGrades.normalize(widget.gradeLevel);
    _mode = widget.mode;
    _boss = _Boss.forGrade(_grade, coop: _mode == GamePlayMode.coop);
    _bossHp = _boss.maxHp;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  GradeQuestion _nextQ() => GradeQuestionBank.next(_grade);

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _mode == GamePlayMode.coop ? 180 : 150;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_playing) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        t.cancel();
        _fail('Hết giờ — chưa hạ gục Boss');
      }
    });
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
      _awaitingB = false;
      _pickA = null;
      _doubleNext = false;
      _skillReady = false;
      _log.clear();
      _q = _nextQ();
    });
    _startTimer();
  }

  Future<void> _fail(String reason) async {
    if (!_playing && !_lost) return;
    setState(() {
      _playing = false;
      _lost = true;
      _q = null;
    });
    _timer?.cancel();
    await logMathGameResult(
      ref,
      topic: 'Đại chiến Boss Ngữ văn',
      detail: 'Ngữ văn $_grade · ${_mode.labelVi} · $reason',
      success: false,
    );
  }

  Future<void> _win() async {
    setState(() {
      _playing = false;
      _won = true;
      _q = null;
    });
    _timer?.cancel();
    await logMathGameResult(
      ref,
      topic: 'Đại chiến Boss Ngữ văn',
      detail: 'Ngữ văn $_grade · ${_mode.labelVi} · hạ ${_boss.name}',
      success: true,
    );
  }

  Future<void> _answer(int value) async {
    if (!_playing || _q == null) return;

    if (_mode == GamePlayMode.coop) {
      if (!_awaitingB) {
        setState(() {
          _pickA = value;
          _awaitingB = true;
        });
        return;
      }
      final aOk = _pickA == _q!.answer;
      final bOk = value == _q!.answer;
      setState(() {
        _awaitingB = false;
        _pickA = null;
      });
      await _resolveCoop(aOk: aOk, bOk: bOk);
      return;
    }

    await _resolveSolo(value == _q!.answer);
  }

  Future<void> _resolveSolo(bool ok) async {
    if (ok) {
      HapticFeedback.mediumImpact();
      _combo += 1;
      if (_combo >= 3) _skillReady = true;
      var dmg = (14 + _combo * 3 + Random().nextInt(6)).clamp(10, 40);
      if (_doubleNext) {
        dmg *= 2;
        _doubleNext = false;
        _log.add('Kiếm Tu từ: sát thương x2!');
      }
      setState(() {
        _bossHp = (_bossHp - dmg).clamp(0, _boss.maxHp);
        _shake = 8;
        if (_bossHp <= 0) {
          // win handled below
        } else {
          _q = _nextQ();
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _shake = 0);
      if (_bossHp <= 0) {
        await _win();
      }
    } else {
      HapticFeedback.heavyImpact();
      _log.add(
        'Sai: ${_q!.prompt.split('\n').first} → đúng ${_q!.answer}'
        '${_q!.storyHint == null ? '' : ' · ${_q!.storyHint}'}',
      );
      final dmg = 16 + Random().nextInt(10);
      setState(() {
        _combo = 0;
        _skillReady = false;
        _playerHp = (_playerHp - dmg).clamp(0, 100);
        _shake = -8;
        if (_playerHp <= 0) {
          _q = null;
        } else {
          _q = _nextQ();
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _shake = 0);
      if (_playerHp <= 0) {
        await _fail('Thua ${_boss.name}');
      }
    }
  }

  Future<void> _resolveCoop({required bool aOk, required bool bOk}) async {
    if (aOk && bOk) {
      HapticFeedback.heavyImpact();
      _combo += 1;
      if (_combo >= 3) _skillReady = true;
      var dmg = (22 + _combo * 4 + Random().nextInt(8)).clamp(18, 55);
      if (_doubleNext) {
        dmg *= 2;
        _doubleNext = false;
      }
      _log.add('Hợp lực! Cả hai đúng — trừ $dmg HP Boss');
      setState(() {
        _bossHp = (_bossHp - dmg).clamp(0, _boss.maxHp);
        _shake = 10;
        if (_bossHp > 0) _q = _nextQ();
      });
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) setState(() => _shake = 0);
      if (_bossHp <= 0) await _win();
    } else if (aOk || bOk) {
      HapticFeedback.selectionClick();
      final dmg = 6 + Random().nextInt(5);
      _log.add('Chỉ 1 người đúng — sát thương nhỏ ($dmg)');
      setState(() {
        _combo = 0;
        _bossHp = (_bossHp - dmg).clamp(0, _boss.maxHp);
        _q = _nextQ();
      });
      if (_bossHp <= 0) await _win();
    } else {
      HapticFeedback.heavyImpact();
      _log.add(
        'Cả hai sai: ${_q!.prompt.split('\n').first} → đúng ${_q!.answer}',
      );
      final dmg = 14 + Random().nextInt(8);
      setState(() {
        _combo = 0;
        _skillReady = false;
        _playerHp = (_playerHp - dmg).clamp(0, 100);
        if (_playerHp > 0) _q = _nextQ();
      });
      if (_playerHp <= 0) await _fail('Thua ${_boss.name}');
    }
  }

  void _useSkill(String skill) {
    if (!_skillReady || !_playing) return;
    setState(() {
      _skillReady = false;
      _combo = 0;
      switch (skill) {
        case 'shield':
          _secondsLeft += 15;
          _log.add('Lá chắn Ngữ pháp: +15 giây');
        case 'sword':
          _doubleNext = true;
          _log.add('Kiếm Tu từ: câu sau sát thương x2');
        case 'hint':
          if (_q != null) {
            final wrong = _q!.choices.where((c) => c != _q!.answer).toList()
              ..shuffle();
            final keep = {_q!.answer, if (wrong.isNotEmpty) wrong.first};
            _q = GradeQuestion(
              prompt: _q!.prompt,
              answer: _q!.answer,
              choices: keep.toList()..sort(),
              storyHint: 'Gợi ý AI: đã loại 2 đáp án nhiễu',
              chapter: _q!.chapter,
            );
            _log.add('Gợi ý AI: loại 2 đáp án nhiễu');
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Boss · ${_mode.labelVi}'),
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
                        Text(_boss.emoji, style: const TextStyle(fontSize: 44)),
                        Text(
                          _boss.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(_boss.taunt,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        _HpBar(
                          label: 'Boss',
                          value: _bossHp / _boss.maxHp,
                          color: const Color(0xFFE76F51),
                          hp: _bossHp,
                        ),
                        const SizedBox(height: 6),
                        _HpBar(
                          label: _mode == GamePlayMode.coop ? 'Đội' : 'Bạn',
                          value: _playerHp / 100,
                          color: const Color(0xFF2A9D8F),
                          hp: _playerHp,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Combo x$_combo',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE9C46A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '⏱️ $_secondsLeft s',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (_skillReady) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              ActionChip(
                                label: const Text('Lá chắn +15s'),
                                onPressed: () => _useSkill('shield'),
                              ),
                              ActionChip(
                                label: const Text('Kiếm x2'),
                                onPressed: () => _useSkill('sword'),
                              ),
                              ActionChip(
                                label: const Text('Gợi ý AI'),
                                onPressed: () => _useSkill('hint'),
                              ),
                            ],
                          ),
                        ],
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
                          ? _Intro(
                              key: const ValueKey('bi'),
                              boss: _boss,
                              mode: _mode,
                              onStart: _start,
                            )
                          : (_won || _lost)
                              ? _End(
                                  key: ValueKey(_won ? 'bw' : 'bl'),
                                  won: _won,
                                  bossName: _boss.name,
                                  log: _log,
                                  onAgain: _start,
                                )
                              : _Ask(
                                  key: ValueKey(
                                    '${_q?.prompt}-$_awaitingB-$_pickA',
                                  ),
                                  question: _q!,
                                  mode: _mode,
                                  awaitingB: _awaitingB,
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

  static _Boss forGrade(int grade, {required bool coop}) {
    final g = SupportedGrades.normalize(grade);
    if (coop) {
      return _Boss(
        name: g <= 7 ? 'Siêu Boss Thần Sách' : 'Siêu Boss Kẻ Đánh Cắp Ngôn Từ',
        emoji: '🐉',
        taunt: 'Song hành: cả hai đúng mới tung hợp lực!',
        maxHp: g <= 7 ? 180 : 200,
      );
    }
    if (g <= 7) {
      return const _Boss(
        name: 'Yêu Quái Lỗi Diễn Đạt',
        emoji: '🧚',
        taunt: 'Từ ngữ · tu từ · kể chuyện — trả lời sai là biến mất!',
        maxHp: 110,
      );
    }
    return const _Boss(
      name: 'Pháp Sư Nghị Luận',
      emoji: '🧙',
      taunt: 'Đọc hiểu · làm văn THCS — sai ý là bị lời nguyền!',
      maxHp: 120,
    );
  }
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

class _Intro extends StatelessWidget {
  const _Intro({
    super.key,
    required this.boss,
    required this.mode,
    required this.onStart,
  });
  final _Boss boss;
  final GamePlayMode mode;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(boss.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text(
          mode == GamePlayMode.coop
              ? 'Song hành vs ${boss.name}'
              : 'Đối đầu ${boss.name}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          mode == GamePlayMode.coop
              ? 'Người A chọn trước, Bạn B chọn sau trên cùng máy. Cả hai đúng = hợp lực. Combo 3 mở tuyệt chiêu.'
              : 'Trả lời đúng để tấn công. Combo 3 mở tuyệt chiêu (lá chắn / kiếm / gợi ý AI).',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onStart,
          icon: Icon(
            mode == GamePlayMode.coop
                ? Icons.handshake_rounded
                : Icons.sports_kabaddi_rounded,
          ),
          label: Text(mode == GamePlayMode.coop ? 'Bắt tay khai chiến' : 'Khiêu chiến'),
        ),
      ],
    );
  }
}

class _Ask extends StatelessWidget {
  const _Ask({
    super.key,
    required this.question,
    required this.mode,
    required this.awaitingB,
    required this.onPick,
  });
  final GradeQuestion question;
  final GamePlayMode mode;
  final bool awaitingB;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          mode == GamePlayMode.coop
              ? (awaitingB ? 'Bạn B chọn đáp án' : 'Người A chọn đáp án')
              : 'Đòn đánh Ngữ văn!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFE76F51),
              ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              question.prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
        if (question.storyHint != null)
          Text(
            question.storyHint!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        const SizedBox(height: 10),
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

class _End extends StatelessWidget {
  const _End({
    super.key,
    required this.won,
    required this.bossName,
    required this.log,
    required this.onAgain,
  });

  final bool won;
  final String bossName;
  final List<String> log;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          won ? 'Chiến thắng!' : 'Hồi máu rồi thử lại!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          won
              ? 'Đội đã hạ $bossName bằng trí tuệ Ngữ văn!'
              : '$bossName còn mạnh — dùng combo & tuyệt chiêu.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Nhật ký trận đấu',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        if (log.isEmpty)
          const Text('Không có ghi chú lỗi.')
        else
          ...log.reversed.take(8).map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $m',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAgain,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Đấu lại'),
        ),
      ],
    );
  }
}
