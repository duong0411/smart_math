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
              const Text('EduSelf Địa lí AI'),
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
                    // Large glowing abstract logo instead of small image
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [scheme.secondary, scheme.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.all_inclusive_rounded,
                        size: 90,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      profile?.displayName.trim().isNotEmpty == true
                          ? 'Hi, ${profile!.displayName}'
                          : 'Hi, I\'m here to help',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
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

              // Responsive Grid Features
              GridView.extent(
                maxCrossAxisExtent: 320,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _FeatureGridItem(
                    icon: Icons.hub_outlined,
                    title: 'Gia sư Địa lí AI',
                    subtitle: 'Hỏi đáp từng bước',
                    iconColor: scheme.primary,
                    gradientColors: [scheme.primary.withValues(alpha: 0.8), scheme.primary.withValues(alpha: 0.2)],
                    imagePath: 'assets/images/icon_tutor_1791473992645.png',
                    onTap: () => context.push('/tutor'),
                  ),
                  _FeatureGridItem(
                    icon: Icons.memory_outlined,
                    title: 'Luyện tập Địa lí',
                    subtitle: 'Sinh bài & chấm điểm',
                    iconColor: scheme.secondary,
                    gradientColors: [scheme.secondary.withValues(alpha: 0.7), scheme.secondary.withValues(alpha: 0.1)],
                    imagePath: 'assets/images/icon_practice_1791474080286.png',
                    onTap: () => context.push('/practice'),
                  ),
                  _FeatureGridItem(
                    icon: Icons.public_rounded,
                    title: 'Khám phá Địa lí',
                    subtitle: 'Trò chơi Địa lí THCS',
                    iconColor: const Color(0xFFF59E0B),
                    gradientColors: [const Color(0xFFF59E0B).withValues(alpha: 0.7), const Color(0xFFF59E0B).withValues(alpha: 0.1)],
                    imagePath: 'assets/images/icon_games_1791474095200.png',
                    onTap: () => context.push('/games'),
                  ),
                  _FeatureGridItem(
                    icon: Icons.account_tree_rounded,
                    title: 'Giám sát học',
                    subtitle: 'Tiến độ & báo cáo',
                    iconColor: const Color(0xFF10B981),
                    gradientColors: [const Color(0xFF10B981).withValues(alpha: 0.7), const Color(0xFF10B981).withValues(alpha: 0.1)],
                    imagePath: 'assets/images/icon_monitor_1791474108487.png',
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
                      color: scheme.onSurface,
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
    required this.gradientColors,
    required this.onTap,
    this.imagePath,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withValues(alpha: 0.2),
                gradientColors[1].withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Image illustration if provided, blended smoothly
              if (imagePath != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  top: 0,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.3, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: Opacity(
                      opacity: 0.6,
                      child: Image.asset(
                        imagePath!,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              // Huge watermark icon illustration as fallback or addition
              if (imagePath == null)
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    icon,
                    size: 110,
                    color: iconColor.withValues(alpha: 0.15),
                  ),
                ),
              // Foreground content
              Padding(
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
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
        child: Icon(icon, color: scheme.onSurfaceVariant, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
      onTap: onTap,
    );
  }
}
