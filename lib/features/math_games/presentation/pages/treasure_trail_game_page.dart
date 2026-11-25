import 'dart:async';

import 'package:eduself_study_app/features/math_games/domain/game_play_mode.dart';
import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/features/math_games/presentation/widgets/game_result_logger.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Truy tìm kho báu: đơn (có đếm giờ) hoặc đấu vs Bạn (cùng máy).
class TreasureTrailGamePage extends ConsumerStatefulWidget {
  const TreasureTrailGamePage({
    super.key,
    this.gradeLevel = SupportedGrades.fallback,
    this.mode = GamePlayMode.solo,
  });

  final int gradeLevel;
  final GamePlayMode mode;

  @override
  ConsumerState<TreasureTrailGamePage> createState() =>
      _TreasureTrailGamePageState();
}

class _TreasureTrailGamePageState extends ConsumerState<TreasureTrailGamePage>
    with SingleTickerProviderStateMixin {
  static const _stations = 8;
  static const _soloSeconds = 180;

  late final int _grade;
  late final GamePlayMode _mode;
  var _stepA = 0;
  var _stepB = 0;
  var _turnIsA = true;
  var _hearts = 3;
  var _stars = 0;
  var _playing = false;
  var _won = false;
  var _lost = false;
  var _winnerLabel = '';
  var _secondsLeft = _soloSeconds;
  Timer? _timer;
  GradeQuestion? _q;
  final _mistakes = <String>[];
  late final AnimationController _bounce;
  late final List<String> _story;

  static List<String> _storyFor(int grade) {
    final g = SupportedGrades.normalize(grade);
    if (g <= 7) {
      return const [
        'Trạm 1 — Cổng Chính tả mở ra…',
        'Trạm 2 — Cầu Từ vựng & đồng nghĩa',
        'Trạm 3 — Rừng Biện pháp tu từ',
        'Trạm 4 — Hồ Kể chuyện',
        'Trạm 5 — Hang Miêu tả bí ẩn',
        'Trạm 6 — Đồi Thành ngữ tục ngữ',
        'Trạm 7 — Thung lũng Đọc hiểu',
        'Trạm 8 — Đỉnh kho báu Ngữ văn 6–7!',
      ];
    }
    return const [
      'Trạm 1 — Cổng Nghị luận mở ra…',
      'Trạm 2 — Phép tu từ canh cầu!',
      'Trạm 3 — Mê cung Phân tích văn bản',
      'Trạm 4 — Cảm nhận thơ & văn xuôi',
      'Trạm 5 — Thư viện Tác giả – tác phẩm',
      'Trạm 6 — Làm văn & bố cục',
      'Trạm 7 — Tiếng Việt nâng cao',
      'Trạm 8 — Đỉnh kho báu Ngữ văn 8–9!',
    ];
  }

  @override
  void initState() {
    super.initState();
    _grade = SupportedGrades.normalize(widget.gradeLevel);
    _mode = widget.mode;
    _story = _storyFor(_grade);
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounce.dispose();
    super.dispose();
  }

  GradeQuestion _nextQ() => GradeQuestionBank.next(_grade);

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _soloSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_playing) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        t.cancel();
        _timeUp();
      }
    });
  }

  Future<void> _timeUp() async {
    if (!_playing) return;
    setState(() {
      _playing = false;
      _lost = true;
      _q = null;
      _winnerLabel = _mode == GamePlayMode.versus
          ? 'Hết giờ — cả hai chưa tìm được kho báu'
          : 'Hết giờ — chưa tìm được kho báu';
    });
    await logMathGameResult(
      ref,
      topic: 'Truy tìm kho báu',
      detail: 'Ngữ văn $_grade · hết giờ · ${_mode.labelVi}',
      success: false,
    );
  }

  void _start() {
    setState(() {
      _stepA = 0;
      _stepB = 0;
      _turnIsA = true;
      _hearts = 3;
      _stars = 0;
      _playing = true;
      _won = false;
      _lost = false;
      _winnerLabel = '';
      _mistakes.clear();
      _q = _nextQ();
    });
    _bounce.forward(from: 0);
    _startTimer();
  }

  Future<void> _answer(int value) async {
    if (!_playing || _q == null) return;
    final ok = value == _q!.answer;
    if (!ok) {
      HapticFeedback.heavyImpact();
      _mistakes.add(
        '${_q!.prompt.split('\n').first} → đáp án đúng: ${_q!.answer}'
        '${_q!.storyHint == null ? '' : ' (${_q!.storyHint})'}',
      );
      if (_mode == GamePlayMode.versus) {
        setState(() {
          _turnIsA = !_turnIsA;
          _q = _nextQ();
        });
        return;
      }
      setState(() {
        _hearts -= 1;
        if (_hearts <= 0) {
          _playing = false;
          _lost = true;
          _q = null;
          _timer?.cancel();
        } else {
          _q = _nextQ();
        }
      });
      if (_lost) {
        await logMathGameResult(
          ref,
          topic: 'Truy tìm kho báu',
          detail: 'Ngữ văn $_grade · thua · ${_mode.labelVi}',
          success: false,
        );
      }
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _stars += 1;
      if (_mode == GamePlayMode.versus) {
        if (_turnIsA) {
          _stepA += 1;
        } else {
          _stepB += 1;
        }
        if (_stepA >= _stations || _stepB >= _stations) {
          _playing = false;
          _won = true;
          _q = null;
          _winnerLabel = _stepA >= _stations ? 'Người chơi A thắng!' : 'Bạn B thắng!';
          _timer?.cancel();
        } else {
          _turnIsA = !_turnIsA;
          _q = _nextQ();
        }
      } else {
        _stepA += 1;
        if (_stepA >= _stations) {
          _playing = false;
          _won = true;
          _q = null;
          _winnerLabel = 'Mở được rương kho báu!';
          _timer?.cancel();
        } else {
          _q = _nextQ();
        }
      }
    });
    _bounce.forward(from: 0);
    if (_won) {
      final playerWon =
          _mode != GamePlayMode.versus || _stepA >= _stations;
      await logMathGameResult(
        ref,
        topic: 'Truy tìm kho báu',
        detail:
            'Ngữ văn $_grade · ${_mode.labelVi} · $_winnerLabel · $_stars sao',
        success: playerWon,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (_mode == GamePlayMode.versus
            ? (_stepA > _stepB ? _stepA : _stepB)
            : _stepA) /
        _stations;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Truy tìm kho báu · ${_mode.labelVi}'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_mode == GamePlayMode.solo)
                      Text(
                        List.generate(3, (i) => i < _hearts ? '❤️' : '🖤')
                            .join(),
                        style: const TextStyle(fontSize: 18),
                      )
                    else
                      Text(
                        _turnIsA ? 'Lượt: Người A' : 'Lượt: Bạn B',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    const Spacer(),
                    Text(
                      '⏱️ $_secondsLeft s',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _secondsLeft <= 30 ? scheme.error : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _mode == GamePlayMode.versus
                          ? 'A $_stepA · B $_stepB /$_stations'
                          : 'Trạm $_stepA/$_stations',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
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
                          ? _Intro(
                              key: const ValueKey('i'),
                              mode: _mode,
                              onStart: _start,
                            )
                          : (_won || _lost)
                              ? _End(
                                  key: ValueKey(_won ? 'w' : 'l'),
                                  title: _won
                                      ? _winnerLabel
                                      : (_winnerLabel.isEmpty
                                          ? 'Hành trình tạm dừng…'
                                          : _winnerLabel),
                                  mistakes: _mistakes,
                                  onAgain: _start,
                                )
                              : _Play(
                                  key: ValueKey(_q?.prompt),
                                  story: _story[
                                      _stepA.clamp(0, _story.length - 1)],
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

class _Intro extends StatelessWidget {
  const _Intro({
    super.key,
    required this.mode,
    required this.onStart,
  });
  final GamePlayMode mode;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏝️', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          mode == GamePlayMode.versus
              ? 'Đấu truy tìm kho báu'
              : 'Phiêu lưu 8 trạm đến kho báu',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          mode == GamePlayMode.versus
              ? 'Người A và Bạn B lần lượt trả lời trên cùng máy. Ai đủ 8 trạm trước khi hết giờ thắng.'
              : 'Trả lời đúng để mở mảnh bản đồ trước khi hết 3 phút. Sai mất 1 trái tim.',
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

class _Play extends StatelessWidget {
  const _Play({
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
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

class _End extends StatelessWidget {
  const _End({
    super.key,
    required this.title,
    required this.mistakes,
    required this.onAgain,
  });

  final String title;
  final List<String> mistakes;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Nhật ký trận đấu',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        if (mistakes.isEmpty)
          const Text('Không có câu sai — tuyệt vời!')
        else
          ...mistakes.take(6).map(
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
          label: const Text('Chơi lại'),
        ),
      ],
    );
  }
}
