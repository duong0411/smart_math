import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/parents/presentation/pages/parents_hub_page.dart';
import 'package:eduself_study_app/features/student/presentation/providers/student_providers.dart';
import 'package:eduself_study_app/features/teachers/presentation/pages/teachers_hub_page.dart';
import 'package:eduself_study_app/shared/navigation/app_destinations.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/feature_tile.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Role-dispatch home: each role gets its own hub, no shared mega-grid.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).valueOrNull?.role;
    return switch (role) {
      UserRole.teacher => const TeachersHubPage(),
      UserRole.parent => const ParentsHubPage(),
      UserRole.student || null => const _StudentHomeHub(),
    };
  }
}

class _StudentHomeHub extends ConsumerWidget {
  const _StudentHomeHub();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final profileAsync = ref.watch(studentProfileProvider);
    final scheme = Theme.of(context).colorScheme;
    final user = session.valueOrNull;
    final destinations = AppDestinations.hubFor(UserRole.student);

    final profile = profileAsync.valueOrNull;
    final needsProfile = profile != null &&
        ((profile.displayName == null || profile.displayName!.trim().isEmpty) ||
            profile.gradeLevel == null);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(AppDestinations.homeTitleFor(UserRole.student)),
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [scheme.primary, scheme.secondary],
                            ),
                          ),
                          child: Icon(
                            Icons.waving_hand_rounded,
                            color: scheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profile?.displayName?.trim().isNotEmpty == true
                                    ? profile!.displayName!
                                    : (user?.email ?? 'Học sinh'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (profile?.gradeLevel != null)
                                Text(
                                  'Lớp ${profile!.gradeLevel}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (needsProfile)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Hoàn thiện hồ sơ để học tốt hơn',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Em cho thầy biết tên và lớp nhé.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context.push('/profile'),
                            child: const Text('Cập nhật hồ sơ'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    AppDestinations.sectionLabelFor(UserRole.student),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dest = destinations[index];
                      return FeatureTile(
                        icon: dest.icon,
                        label: dest.label,
                        subtitle: dest.subtitle,
                        enabled: !dest.comingSoon,
                        badge: dest.comingSoon ? 'Sắp có' : null,
                        onTap: () => context.push(dest.route),
                      );
                    },
                    childCount: destinations.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
