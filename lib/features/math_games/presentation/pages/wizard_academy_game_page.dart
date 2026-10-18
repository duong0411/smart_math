import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/features/math_games/presentation/widgets/game_result_logger.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Học viện Pháp sư Toán học — mỗi chủ đề là một phép thuật cần mở khóa.
class WizardAcademyGamePage extends ConsumerStatefulWidget {
  const WizardAcademyGamePage({
    super.key,
    this.gradeLevel = SupportedGrades.fallback,
  });

  final int gradeLevel;

  @override
  ConsumerState<WizardAcademyGamePage> createState() =>
      _WizardAcademyGamePageState();
}

class _WizardAcademyGamePageState extends ConsumerState<WizardAcademyGamePage>
    with SingleTickerProviderStateMixin {
  static const _spellsNeeded = 4;
  static const _correctPerSpell = 3;

  late final int _grade;
  var _xp = 0;
  var _rank = 0;
  var _spellIndex = 0;
  var _spellProgress = 0;
  var _badges = 0;
  var _playing = false;
  var _won = false;
  var _lost = false;
  var _hearts = 3;
  String? _hint;
  GradeQuestion? _q;
  late final List<_Spell> _spells;
  late final AnimationController _glow;

  static const _ranks = [
    'Tập sự',
    'Pháp sư mới',
    'Pháp sư bạc',
    'Pháp sư vàng',
    'Đại pháp sư',
  ];

  static List<_Spell> _spellsFor(int grade) {
    final g = SupportedGrades.normalize(grade);
    if (g <= 6) {
      return const [
        _Spell('Phép Phân số', 'Phân số / tỉ lệ', '✨', Color(0xFF7C3AED)),
        _Spell('Phép Số học', 'Số nguyên & phần trăm', '🔢', Color(0xFF2563EB)),
        _Spell('Phép Đại số', 'Biểu thức & phương trình', '📐', Color(0xFF0D9488)),
        _Spell('Phép Hình học', 'Hình phẳng', '🔺', Color(0xFFEA580C)),
      ];
    }
    if (g == 7) {
      return const [
        _Spell('Phép Lũy thừa', 'Lũy thừa & căn', '⚡', Color(0xFF7C3AED)),
        _Spell('Phép Biểu thức', 'Đại số cơ bản', '📜', Color(0xFF2563EB)),
        _Spell('Phép Tam giác', 'Hình học', '🔺', Color(0xFF0D9488)),
        _Spell('Phép Tỉ lệ thức', 'Tỉ lệ & thực tế', '⚖️', Color(0xFFEA580C)),
      ];
    }
    if (g == 8) {
      return const [
        _Spell('Phép Đa thức', 'Đại số', '📜', Color(0xFF7C3AED)),
        _Spell('Phép Hằng đẳng thức', 'Đại số', '✨', Color(0xFF2563EB)),
        _Spell('Phép Phân thức', 'Phương trình', '➗', Color(0xFF0D9488)),
        _Spell('Phép Pythagore', 'Hình học', '📐', Color(0xFFEA580C)),
      ];
    }
    return const [
      _Spell('Phép Hệ PT', 'Đại số', '🔗', Color(0xFF7C3AED)),
      _Spell('Phép Căn thức', 'Lũy thừa / căn', '⚡', Color(0xFF2563EB)),
      _Spell('Phép Bậc hai', 'Phương trình', '📈', Color(0xFF0D9488)),
      _Spell('Phép Đường tròn', 'Hình học', '⭕', Color(0xFFEA580C)),
    ];
  }

  @override
  void initState() {
    super.initState();
    _grade = SupportedGrades.normalize(widget.gradeLevel);
    _spells = _spellsFor(_grade);
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  GradeQuestion _nextQ() => GradeQuestionBank.next(_grade);

  void _start() {
    setState(() {
      _xp = 0;
      _rank = 0;
      _spellIndex = 0;
      _spellProgress = 0;
      _badges = 0;
      _hearts = 3;
      _playing = true;
      _won = false;
      _lost = false;
      _hint = null;
      _q = _nextQ();
    });
    _glow.forward(from: 0);
  }

  String _buildHint(GradeQuestion q) {
    final spell = _spells[_spellIndex.clamp(0, _spells.length - 1)];
    if (q.storyHint != null && q.storyHint!.trim().isNotEmpty) {
      return '🪄 Gia sư AI: ${q.storyHint}';
    }
    return '🪄 Gia sư AI: Với phép «${spell.name}», hãy làm từng bước '
        'theo chương ${q.chapter ?? spell.topic} rồi chọn đáp án.';
  }

  Future<void> _answer(int value) async {
    if (!_playing || _q == null) return;
    final ok = value == _q!.answer;
    if (ok) {
      HapticFeedback.mediumImpact();
      setState(() {
        _xp += 15;
        _spellProgress += 1;
        _hint = null;
        _rank = (_xp ~/ 45).clamp(0, _ranks.length - 1);
        if (_spellProgress >= _correctPerSpell) {
          _badges += 1;
          _spellProgress = 0;
          _spellIndex += 1;
          if (_spellIndex >= _spellsNeeded) {
            _playing = false;
            _won = true;
            _rank = _ranks.length - 1;
            _q = null;
          } else {
            _q = _nextQ();
          }
        } else {
          _q = _nextQ();
        }
      });
      _glow.forward(from: 0);
      if (_won) {
        await logMathGameResult(
          ref,
          topic: 'Học viện Pháp sư Toán học',
          detail: 'Toán $_grade · ${_ranks[_rank]} · $_badges huy hiệu',
          success: true,
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hearts -= 1;
        _hint = _buildHint(_q!);
        if (_hearts <= 0) {
          _playing = false;
          _lost = true;
          _q = null;
        } else {
          _q = _nextQ();
        }
      });
      if (_lost) {
        await logMathGameResult(
          ref,
          topic: 'Học viện Pháp sư Toán học',
          detail:
              'Toán $_grade · dừng ở phép ${_spellIndex + 1}/$_spellsNeeded',
          success: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spell = _spells[_spellIndex.clamp(0, _spells.length - 1)];
    final progress = (_spellIndex + _spellProgress / _correctPerSpell) /
        _spellsNeeded;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Pháp sư Toán · Lớp $_grade'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                _WizardHud(
                  hearts: _hearts,
                  xp: _xp,
                  rank: _ranks[_rank],
                  badges: _badges,
                ),
                const SizedBox(height: 10),
                _SpellTrack(
                  spells: _spells,
                  unlocked: _spellIndex,
                  currentProgress: _spellProgress,
                  needed: _correctPerSpell,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: spell.color,
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
                                  title: 'Thăng cấp Đại pháp sư!',
                                  subtitle:
                                      '$_badges huy hiệu · ${_ranks[_rank]} · lớp $_grade',
                                  emoji: '🧙‍♂️',
                                  onAgain: _start,
                                )
                              : _lost
                                  ? _EndPanel(
                                      key: const ValueKey('l'),
                                      title: 'Phép thuật tạm dừng…',
                                      subtitle:
                                          'Hết năng lượng ở phép ${_spellIndex + 1}/$_spellsNeeded. Thử lại nhé!',
                                      emoji: '📖',
                                      onAgain: _start,
                                    )
                                  : _PlayPanel(
                                      key: ValueKey(_q?.prompt),
                                      spell: spell,
                                      progress: _spellProgress,
                                      needed: _correctPerSpell,
                                      question: _q!,
                                      glow: _glow,
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

class _Spell {
  const _Spell(this.name, this.topic, this.emoji, this.color);
  final String name;
  final String topic;
  final String emoji;
  final Color color;
}

class _WizardHud extends StatelessWidget {
  const _WizardHud({
    required this.hearts,
    required this.xp,
    required this.rank,
    required this.badges,
  });

  final int hearts;
  final int xp;
  final String rank;
  final int badges;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          List.generate(3, (i) => i < hearts ? '💙' : '🖤').join(),
          style: const TextStyle(fontSize: 18),
        ),
        const Spacer(),
        Text('⭐ $xp XP', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Text('🏅 $badges', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            rank,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5B8DEF),
                ),
          ),
        ),
      ],
    );
  }
}

class _SpellTrack extends StatelessWidget {
  const _SpellTrack({
    required this.spells,
    required this.unlocked,
    required this.currentProgress,
    required this.needed,
  });

  final List<_Spell> spells;
  final int unlocked;
  final int currentProgress;
  final int needed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < spells.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                color: i <= unlocked
                    ? spells[i].color
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          Tooltip(
            message: spells[i].name,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < unlocked
                    ? spells[i].color
                    : i == unlocked
                        ? spells[i].color.withValues(alpha: 0.85)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: i == unlocked
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Text(
                i < unlocked
                    ? '✓'
                    : i == unlocked
                        ? '$currentProgress/$needed'
                        : spells[i].emoji,
                style: TextStyle(
                  fontSize: i == unlocked ? 10 : 14,
                  fontWeight: FontWeight.w800,
                  color: i <= unlocked ? Colors.white : null,
                ),
              ),
            ),
          ),
        ],
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
        const Text('🧙‍♂️', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          'Học viện Pháp sư Toán học',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mỗi chủ đề Toán là một phép thuật. '
          'Hoàn thành nhiệm vụ để mở khóa kỹ năng, nhận huy hiệu và thăng cấp pháp sư.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5B8DEF),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Vào học viện'),
        ),
      ],
    );
  }
}

class _PlayPanel extends StatelessWidget {
  const _PlayPanel({
    super.key,
    required this.spell,
    required this.progress,
    required this.needed,
    required this.question,
    required this.glow,
    required this.onPick,
    this.hint,
  });

  final _Spell spell;
  final int progress;
  final int needed;
  final GradeQuestion question;
  final AnimationController glow;
  final ValueChanged<int> onPick;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: glow, curve: Curves.easeOutBack),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  spell.color.withValues(alpha: 0.35),
                  scheme.primaryContainer.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(spell.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 6),
                Text(
                  spell.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Thử thách $progress/$needed · ${spell.topic}',
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
        if (hint != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: spell.color.withValues(alpha: 0.15),
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
                    backgroundColor: spell.color,
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
          label: const Text('Luyện lại'),
        ),
      ],
    );
  }
}
