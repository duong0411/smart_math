import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MathHomePage extends ConsumerWidget {
  const MathHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(mathProfileProvider).valueOrNull;
    final hasKey =
        (ref.watch(geminiApiKeyProvider).valueOrNull ?? '').trim().isNotEmpty;
    final events = ref.watch(mathEventsProvider).valueOrNull ?? [];
    final weekAgo = DateTime.now().toUtc().subtract(const Duration(days: 7));
    final weekEvents = events.where((e) => e.at.isAfter(weekAgo)).length;
    final practice = events.where((e) => e.type.name == 'practice').toList();
    final correct = practice.where((e) => e.correct == true).length;
    final accuracy = practice.isEmpty
        ? null
        : ((correct / practice.length) * 100).round();

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(AppConfig.appName),
          actions: [
            IconButton(
              tooltip: 'Cài đặt',
              onPressed: () => context.push('/settings'),
              icon: Badge(
                isLabelVisible: !hasKey,
                smallSize: 8,
                child: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppConfig.appTagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile?.displayName.trim().isNotEmpty == true
                          ? 'Xin chào, ${profile!.displayName}'
                              '${profile.gradeLevel != null ? ' · Lớp ${profile.gradeLevel}' : ''}'
                          : 'Chưa có hồ sơ — vào Cài đặt để điền tên & lớp',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (!hasKey) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.key_rounded),
                        label: const Text('Dán Gemini API key để bắt đầu'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Hoạt động 7 ngày',
                      value: '$weekEvents',
                      icon: Icons.timeline_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      label: 'Độ chính xác',
                      value: accuracy == null ? '—' : '$accuracy%',
                      icon: Icons.analytics_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Chức năng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              _FeatureTile(
                icon: Icons.smart_toy_rounded,
                title: 'Gia sư Toán AI',
                subtitle: 'Hỏi đáp từng bước, không làm hộ bài',
                onTap: () => context.push('/tutor'),
              ),
              const SizedBox(height: 10),
              _FeatureTile(
                icon: Icons.fitness_center_rounded,
                title: 'Luyện tập Toán',
                subtitle: 'AI tạo bài · chấm · giải thích lỗi',
                onTap: () => context.push('/practice'),
              ),
              const SizedBox(height: 10),
              _FeatureTile(
                icon: Icons.sports_esports_rounded,
                title: 'Giải trí Toán 8',
                subtitle: 'Kho báu · boss · tên lửa · kiến thức lớp 8',
                onTap: () => context.push('/games'),
              ),
              const SizedBox(height: 10),
              _FeatureTile(
                icon: Icons.monitor_heart_outlined,
                title: 'Giám sát học tập',
                subtitle: 'Tiến độ, điểm yếu, kế hoạch ôn AI',
                onTap: () => context.push('/monitor'),
              ),
              const SizedBox(height: 10),
              _FeatureTile(
                icon: Icons.person_outline_rounded,
                title: 'Hồ sơ & API key',
                subtitle: 'Tên, lớp, Gemini API key',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
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
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
