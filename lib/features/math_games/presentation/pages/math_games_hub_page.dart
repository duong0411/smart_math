import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MathGamesHubPage extends StatelessWidget {
  const MathGamesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Khám phá Địa lí THCS'),
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
                    'Chương trình Địa lí THCS (Lớp 6–9)',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bộ câu hỏi phong phú bám sát chương trình GDPT 2018 (Lớp 6, 7, 8, 9): '
                    'Trái Đất, bản đồ, các châu lục trên thế giới, địa lí tự nhiên & '
                    'kinh tế - xã hội Việt Nam. Học vui, không cần API key.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chọn nhiệm vụ thám hiểm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '🧭',
              title: 'Hành trình Khám phá Địa Cầu',
              subtitle: '8 trạm thám hiểm các châu lục và non sông Việt Nam',
              accent: const Color(0xFFD4A373),
              onTap: () => context.push('/games/treasure'),
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '🌋',
              title: 'Chinh phục Đỉnh Địa lí',
              subtitle: 'Vượt thử thách Thần Núi Lửa bằng kiến thức Địa lí THCS',
              accent: const Color(0xFFE76F51),
              onTap: () => context.push('/games/boss'),
            ),
            const SizedBox(height: 10),
            _MissionTile(
              emoji: '🛰️',
              title: 'Vệ tinh Địa lý',
              subtitle: 'Nạp năng lượng bay qua các vùng miền và kinh tuyến',
              accent: const Color(0xFF4CC9F0),
              onTap: () => context.push('/games/rocket'),
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
