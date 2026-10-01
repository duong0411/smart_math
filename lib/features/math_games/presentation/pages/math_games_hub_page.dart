import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MathGamesHubPage extends ConsumerStatefulWidget {
  const MathGamesHubPage({super.key});

  @override
  ConsumerState<MathGamesHubPage> createState() => _MathGamesHubPageState();
}

class _MathGamesHubPageState extends ConsumerState<MathGamesHubPage> {
  int _grade = 5;
  var _didInitGrade = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitGrade) return;
      final fromProfile =
          ref.read(mathProfileProvider).valueOrNull?.gradeLevel;
      setState(() {
        _grade = (fromProfile ?? 5).clamp(1, 12);
        _didInitGrade = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final band = GradeBandX.fromGrade(_grade);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Giải trí Toán học'),
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
                    'Chọn lớp · chọn nhiệm vụ',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Câu hỏi đổi theo lớp ${band.labelVi}: ${band.blurb}. Không cần API key.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Lớp đang chơi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var g = 1; g <= 12; g++)
                  ChoiceChip(
                    label: Text('L$g'),
                    selected: _grade == g,
                    onSelected: (_) => setState(() => _grade = g),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              band.labelVi,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nhiệm vụ hấp dẫn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '🏝️',
              title: 'Hành trình Kho báu',
              subtitle:
                  'Phiêu lưu 8 trạm · trái tim · ngôi sao — độ khó lớp $_grade',
              accent: const Color(0xFFD4A373),
              onTap: () => context.push('/games/treasure?grade=$_grade'),
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '⚔️',
              title: 'Đại chiến Boss Toán',
              subtitle:
                  'Đánh boss theo cấp lớp · combo sát thương · thanh máu',
              accent: const Color(0xFFE76F51),
              onTap: () => context.push('/games/boss?grade=$_grade'),
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '🚀',
              title: 'Phóng Tên Lửa',
              subtitle:
                  'Đua 50 giây nạp nhiên liệu · streak càng dài phóng càng nhanh',
              accent: const Color(0xFF4CC9F0),
              onTap: () => context.push('/games/rocket?grade=$_grade'),
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
