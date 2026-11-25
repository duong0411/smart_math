import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/features/math_games/domain/game_play_mode.dart';
import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/widgets/grade_level_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MathGamesHubPage extends ConsumerStatefulWidget {
  const MathGamesHubPage({super.key});

  @override
  ConsumerState<MathGamesHubPage> createState() => _MathGamesHubPageState();
}

class _MathGamesHubPageState extends ConsumerState<MathGamesHubPage> {
  int _grade = SupportedGrades.fallback;
  var _synced = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted || _synced) return;
      final profile = ref.read(mathProfileProvider).valueOrNull;
      setState(() {
        _grade = SupportedGrades.normalize(profile?.gradeLevel);
        _synced = true;
      });
    });
  }

  Future<void> _openTreasure() async {
    final mode = await _pickMode(
      title: 'Truy tìm kho báu',
      modes: const [GamePlayMode.solo, GamePlayMode.versus],
      soloHint: 'Tự giải mã bản đồ trước khi hết giờ.',
      secondHint: 'Đấu với Bạn B trên cùng máy — ai tìm kho báu trước thắng.',
      secondIcon: Icons.sports_esports_rounded,
      secondLabel: 'Chơi đấu vs Bạn',
    );
    if (mode == null || !mounted) return;
    context.push('/games/treasure?grade=$_grade&mode=${mode.query}');
  }

  Future<void> _openBoss() async {
    final mode = await _pickMode(
      title: 'Đại chiến Boss',
      modes: const [GamePlayMode.solo, GamePlayMode.coop],
      soloHint: 'Tự đối đầu Boss ở mức máu tiêu chuẩn.',
      secondHint: 'Song hành: cả hai đúng mới combo mạnh · Boss máu cao hơn.',
      secondIcon: Icons.handshake_rounded,
      secondLabel: 'Song hành cùng bạn',
    );
    if (mode == null || !mounted) return;
    context.push('/games/boss?grade=$_grade&mode=${mode.query}');
  }

  Future<GamePlayMode?> _pickMode({
    required String title,
    required List<GamePlayMode> modes,
    required String soloHint,
    required String secondHint,
    required IconData secondIcon,
    required String secondLabel,
  }) {
    return showModalBottomSheet<GamePlayMode>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn chế độ chơi',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              _ModeTile(
                icon: Icons.person_rounded,
                title: 'Chơi 1 mình',
                subtitle: soloHint,
                onTap: () => Navigator.pop(ctx, GamePlayMode.solo),
              ),
              const SizedBox(height: 10),
              _ModeTile(
                icon: secondIcon,
                title: secondLabel,
                subtitle: secondHint,
                onTap: () => Navigator.pop(
                  ctx,
                  modes.contains(GamePlayMode.versus)
                      ? GamePlayMode.versus
                      : GamePlayMode.coop,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grade = _grade;
    final streak = ref.watch(studyStreakProvider).valueOrNull;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Giải trí Ngữ văn'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngữ văn THCS · lớp $grade',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${GradeQuestionBank.bandLabel(grade)} · '
                    '${GradeQuestionBank.curriculumHint(grade)} '
                    'Thắng game cộng Chuỗi học tập & Điểm Tinh Hoa.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  if (streak != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Chuỗi ${streak.currentStreak} ngày · ${streak.essencePoints} tinh hoa · '
                      '${streak.freezeCards} thẻ bảo vệ',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD97706),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: GradeLevelSelector(
                value: grade,
                onChanged: (g) => setState(() => _grade = g),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chọn nhiệm vụ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '🏝️',
              title: 'Truy tìm kho báu',
              subtitle: 'Đơn hoặc đấu vs Bạn · lớp $grade',
              accent: const Color(0xFFD4A373),
              onTap: _openTreasure,
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '⚔️',
              title: 'Đại chiến Boss Ngữ văn',
              subtitle: 'Đấu đơn hoặc Song hành (bắt tay) · lớp $grade',
              accent: const Color(0xFFE76F51),
              onTap: _openBoss,
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '🚀',
              title: 'Phóng Tên Lửa',
              subtitle: 'Nạp nhiên liệu bằng bài tập lớp $grade',
              accent: const Color(0xFF4CC9F0),
              onTap: () => context.push('/games/rocket?grade=$grade'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.35),
                      accent.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill_rounded, color: accent, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}
