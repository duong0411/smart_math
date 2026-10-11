import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/widgets/grade_level_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MathHomePage extends ConsumerWidget {
  const MathHomePage({super.key});

  Future<void> _showGradePicker(BuildContext context, WidgetRef ref, int currentGrade) async {
    final grade = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
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
                'Chọn khối lớp học Toán',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nội dung câu hỏi và bài luyện tập sẽ tự động điều chỉnh theo chương trình của lớp được chọn.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 18),
              GradeLevelSelector(
                value: currentGrade,
                onChanged: (g) => Navigator.of(ctx).pop(g),
              ),
            ],
          ),
        ),
      ),
    );

    if (grade != null && grade != currentGrade) {
      final profile = ref.read(mathProfileProvider).valueOrNull;
      if (profile != null) {
        await ref.read(mathProfileProvider.notifier).save(
              profile.copyWith(gradeLevel: grade),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasKey =
        (ref.read(geminiApiKeyProvider).valueOrNull ?? '').trim().isNotEmpty;
    final profile = ref.watch(mathProfileProvider).valueOrNull;
    final currentGrade = SupportedGrades.normalize(profile?.gradeLevel);

    final events = ref.watch(mathEventsProvider).valueOrNull ?? [];
    final weekAgo = DateTime.now().toUtc().subtract(const Duration(days: 7));
    final weekEvents = events.where((e) => e.at.isAfter(weekAgo)).length;
    final practice = events.where((e) => e.type.name == 'practice').toList();
    final correct = practice.where((e) => e.correct == true).length;
    final accuracy = practice.isEmpty
        ? null
        : ((correct / practice.length) * 100).round();

    final studentName = profile?.displayName.trim().isNotEmpty == true
        ? profile!.displayName.trim()
        : 'em';

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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'EduSelf Toán AI',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Cài đặt',
              onPressed: () => context.push('/settings'),
              icon: Badge(
                isLabelVisible: !hasKey,
                smallSize: 9,
                backgroundColor: const Color(0xFFEF4444),
                child: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // Hero Banner - Tailored specifically for Math students
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: isDark ? 0.25 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => _showGradePicker(context, ref, currentGrade),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF2563EB).withValues(alpha: 0.30),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.school_rounded, size: 14, color: Color(0xFF2563EB)),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Lớp $currentGrade',
                                            style: const TextStyle(
                                              color: Color(0xFF2563EB),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF2563EB)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Toán THCS',
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Chào $studentName! 👋',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hôm nay em muốn chinh phục bài toán nào?',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.calculate_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),

                    // Key alert banner or Quick Prompts
                    if (!hasKey) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => context.push('/settings'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.key_rounded, color: Color(0xFFD97706), size: 18),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Dán Gemini API key để kích hoạt hỏi đáp AI',
                                  style: TextStyle(
                                    color: Color(0xFF92400E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFD97706)),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickPromptChip(
                            label: '📐 Giải phương trình',
                            onTap: () => context.push('/tutor'),
                          ),
                          _QuickPromptChip(
                            label: '📏 Hình học',
                            onTap: () => context.push('/tutor'),
                          ),
                          _QuickPromptChip(
                            label: '⚡ Phân tích đa thức',
                            onTap: () => context.push('/tutor'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title Section: Học tập & Luyện tập
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chức năng học tập',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                  ),
                  Text(
                    'Chương trình lớp $currentGrade',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4 Core Feature Cards - Beautifully separated, high-contrast, zero overlap
              GridView.extent(
                maxCrossAxisExtent: 360,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.25,
                children: [
                  _FeatureGridItem(
                    icon: Icons.psychology_rounded,
                    title: 'Gia sư Toán AI',
                    subtitle: 'Hỏi đáp & giải từng bước',
                    tag: 'AI 24/7',
                    iconColor: const Color(0xFF2563EB),
                    imagePath: 'assets/images/icon_tutor_1791473992645.png',
                    onTap: () => context.push('/tutor'),
                  ),
                  _FeatureGridItem(
                    icon: Icons.edit_note_rounded,
                    title: 'Luyện tập Toán',
                    subtitle: 'Sinh đề & chấm tự động',
                    tag: 'Luyện đề',
                    iconColor: const Color(0xFF0D9488),
                    imagePath: 'assets/images/icon_practice_1791474080286.png',
                    onTap: () => context.push('/practice'),
                  ),
                  _FeatureGridItem(
                    icon: Icons.sports_esports_rounded,
                    title: 'Giải trí Toán',
                    subtitle: 'Đấu boss & game toán',
                    tag: 'Game vui',
                    iconColor: const Color(0xFFEA580C),
                    imagePath: 'assets/images/icon_games_1791474095200.png',
                    onTap: () => context.push('/games'),
                  ),
                  _FeatureGridItem(
                    icon: Icons.insights_rounded,
                    title: 'Giám sát học',
                    subtitle: 'Tiến độ & báo cáo chi tiết',
                    tag: 'Thống kê',
                    iconColor: const Color(0xFF7C3AED),
                    imagePath: 'assets/images/icon_monitor_1791474108487.png',
                    onTap: () => context.push('/monitor'),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Quick Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Hoạt động tuần',
                      value: '$weekEvents lượt',
                      icon: Icons.auto_graph_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Độ chính xác',
                      value: accuracy == null ? 'Chưa có' : '$accuracy%',
                      icon: Icons.verified_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Khối lớp',
                      value: 'Lớp $currentGrade',
                      icon: Icons.school_rounded,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => _showGradePicker(context, ref, currentGrade),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Activities Section
              Text(
                'Hoạt động gần đây',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              _RecentActivityTile(
                icon: Icons.timeline_rounded,
                title: 'Tương tác học Toán 7 ngày qua',
                subtitle: '$weekEvents lượt câu hỏi & bài luyện tập',
                iconColor: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 8),
              _RecentActivityTile(
                icon: Icons.analytics_outlined,
                title: 'Tỷ lệ trả lời chính xác',
                subtitle: accuracy == null
                    ? 'Chưa có dữ liệu bài làm'
                    : '$accuracy% câu trả lời đúng',
                iconColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 8),
              _RecentActivityTile(
                icon: Icons.manage_accounts_outlined,
                title: 'Hồ sơ & Tuỳ chọn học tập',
                subtitle: 'Lớp $currentGrade • Thiết lập API key & giao diện',
                iconColor: const Color(0xFF7C3AED),
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  const _QuickPromptChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

/// Redesigned feature card: Clean solid surface, separated thumbnail badge on top right,
/// pristine legible text on the bottom. ZERO text overlapping on top of illustrations!
class _FeatureGridItem extends StatelessWidget {
  const _FeatureGridItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.iconColor,
    required this.onTap,
    this.imagePath,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final Color iconColor;
  final VoidCallback onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: iconColor.withValues(alpha: isDark ? 0.35 : 0.20),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: isDark ? 0.20 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Dedicated icon on left, thumbnail artwork on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  if (imagePath != null)
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset(
                          imagePath!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              // Bottom block: Title & Subtitle completely isolated and readable
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: scheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.3,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: iconColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: scheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 18, color: scheme.outline),
        onTap: onTap,
      ),
    );
  }
}
