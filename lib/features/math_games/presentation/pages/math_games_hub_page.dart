import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/widgets/grade_level_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hub trò chơi Toán THCS — thay module trắc nghiệm ôn tập.
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grade = _grade;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Trò chơi Toán học'),
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
                    'Chơi mà học · lớp $grade',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${GradeQuestionBank.bandLabel(grade)} · '
                    '${GradeQuestionBank.curriculumHint(grade)} '
                    'Vượt ải, mở kỹ năng — không cần API key.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
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
              emoji: '🏴‍☠️',
              title: 'Truy tìm kho báu Toán học',
              subtitle:
                  'Pirate Math Quest · cửa ải, chìa khóa & rương báu · lớp $grade',
              accent: const Color(0xFFE9A825),
              badge: 'Nổi bật',
              onTap: () => context.push('/games/treasure?grade=$grade'),
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '🧙‍♂️',
              title: 'Học viện Pháp sư Toán học',
              subtitle:
                  'Mỗi chủ đề là một phép thuật · cấp bậc & huy hiệu · lớp $grade',
              accent: const Color(0xFF5B8DEF),
              badge: 'Mới',
              onTap: () => context.push('/games/wizard?grade=$grade'),
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '⚔️',
              title: 'Đại chiến Boss Toán',
              subtitle: 'Hạ boss bằng kiến thức lớp $grade',
              accent: const Color(0xFFE76F51),
              onTap: () => context.push('/games/boss?grade=$grade'),
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

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ],
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
