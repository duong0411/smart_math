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
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('EduSelf Toán AI'),
            ],
          ),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              // Top Greeting Section
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Central abstract glowing orb/graphic
                    Image.asset(
                      'assets/images/central_logo_glow_1791473954847.png',
                      width: 140,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      profile?.displayName.trim().isNotEmpty == true
                          ? 'Hi, ${profile!.displayName}'
                          : 'Hi, I\'m here to help',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hôm nay bạn muốn học gì?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (!hasKey)
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.key_rounded),
                        label: const Text('Dán Gemini API key để bắt đầu'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2x2 Grid Features
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: [
                  _FeatureGridItem(
                    icon: Icons.hub_outlined,
                    title: 'Gia sư Toán AI',
                    subtitle: 'Hỏi đáp từng bước',
                    iconColor: scheme.primary,
                    onTap: () => context.push('/tutor'),
                  ),
                  _FeatureGridItem(
                    icon: Icons.memory_outlined,
                    title: 'Luyện tập Toán',
                    subtitle: 'Sinh bài & chấm điểm',
                    iconColor: scheme.secondary,
                    onTap: () => context.push('/practice'),
                  ),
                  _FeatureGridItem(
                    icon: Icons.blur_on_rounded,
                    title: 'Giải trí Toán 8',
                    subtitle: 'Học qua trò chơi',
                    iconColor: scheme.primary,
                    onTap: () => context.push('/games'),
                  ),
                  _FeatureGridItem(
                    icon: Icons.account_tree_rounded,
                    title: 'Giám sát học',
                    subtitle: 'Tiến độ & báo cáo',
                    iconColor: scheme.secondary,
                    onTap: () => context.push('/monitor'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Recent Activities / Stats
              Text(
                'Recent Activities',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 12),
              _RecentActivityTile(
                icon: Icons.timeline_rounded,
                title: 'Hoạt động 7 ngày qua',
                subtitle: '$weekEvents lượt tương tác',
              ),
              const SizedBox(height: 8),
              _RecentActivityTile(
                icon: Icons.analytics_outlined,
                title: 'Độ chính xác luyện tập',
                subtitle: accuracy == null ? 'Chưa có dữ liệu' : '$accuracy% chính xác',
              ),
              const SizedBox(height: 8),
              _RecentActivityTile(
                icon: Icons.person_outline_rounded,
                title: 'Hồ sơ học tập',
                subtitle: profile?.gradeLevel != null
                    ? 'Lớp ${profile!.gradeLevel}'
                    : 'Cập nhật tên & lớp',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGridItem extends StatelessWidget {
  const _FeatureGridItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white.withValues(alpha: 0.5)),
      onTap: onTap,
    );
  }
}
