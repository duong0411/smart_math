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
                    'Chơi mà học',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Các trò chơi Toán sinh động — luyện phản xạ, trí nhớ và tính nhanh. Không cần API key.',
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
              'Chọn trò chơi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _GameTile(
              emoji: '⚡',
              title: 'Tính siêu tốc',
              subtitle: 'Đua thời gian 45 giây — combo càng cao điểm càng lớn',
              accent: const Color(0xFFE85D04),
              onTap: () => context.push('/games/speed'),
            ),
            const SizedBox(height: 10),
            _GameTile(
              emoji: '🫧',
              title: 'Bong bóng số',
              subtitle: 'Chạm đúng đáp án trước khi bóng bay mất',
              accent: const Color(0xFF2A9D8F),
              onTap: () => context.push('/games/bubbles'),
            ),
            const SizedBox(height: 10),
            _GameTile(
              emoji: '🧩',
              title: 'Ghép đôi Toán',
              subtitle: 'Lật thẻ — khớp phép tính với kết quả',
              accent: const Color(0xFF577590),
              onTap: () => context.push('/games/match'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
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
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
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
              Icon(Icons.play_circle_fill_rounded, color: accent, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
