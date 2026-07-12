import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:eduself_study_app/shared/navigation/app_destinations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  final _scrollController = ScrollController();
  final _itemKeys = <String, GlobalKey>{};
  String? _scrolledForLocation;

  GlobalKey _keyFor(String id) =>
      _itemKeys.putIfAbsent(id, GlobalKey.new);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    if (_scrolledForLocation == location) return;
    _scrolledForLocation = location;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelected(location);
    });
  }

  String _selectedItemId(String location, UserRole? role) {
    if (location == '/home') return 'home';
    if (location == '/settings') return 'settings';
    if (location == '/about') return 'about';

    for (final dest in AppDestinations.hubFor(role)) {
      if (location == dest.route || location.startsWith('${dest.route}/')) {
        return dest.id;
      }
    }
    return 'home';
  }

  bool _isSelected(String location, String route) {
    if (route == '/home') return location == '/home';
    return location == route || location.startsWith('$route/');
  }

  Future<void> _scrollToSelected(String location) async {
    final user = ref.read(authSessionProvider).valueOrNull;
    final id = _selectedItemId(location, user?.role);
    final key = _itemKeys[id];
    final itemContext = key?.currentContext;
    if (itemContext == null) return;

    await Scrollable.ensureVisible(
      itemContext,
      alignment: 0.3,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final container = ProviderScope.containerOf(context);
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    await container.read(logoutProvider)();
    container.read(authSessionProvider.notifier).clear();
    await container.read(apiAccessTokenProvider.notifier).clear();
    router.go('/login');
  }

  void _go(BuildContext context, String location) {
    Navigator.of(context).pop();
    final current = GoRouterState.of(context).matchedLocation;
    if (current == location) return;
    context.go(location);
  }

  String _roleLabel(UserRole? role) {
    return switch (role) {
      UserRole.teacher => 'Giáo viên',
      UserRole.parent => 'Phụ huynh',
      UserRole.student => 'Học sinh',
      null => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authSessionProvider).valueOrNull;
    final location = GoRouterState.of(context).matchedLocation;
    final destinations = AppDestinations.hubFor(user?.role)
        .where((d) => d.route != '/home')
        .toList(growable: false);
    final selectedId = _selectedItemId(location, user?.role);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary,
                    Color.lerp(scheme.primary, scheme.secondary, 0.45)!,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.onPrimary.withValues(alpha: 0.18),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Chưa đăng nhập',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimary.withValues(alpha: 0.85),
                        ),
                  ),
                  if (user?.role != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _roleLabel(user!.role),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onPrimary.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  const _DrawerSectionLabel('Trang chính'),
                  _DrawerTile(
                    key: _keyFor('home'),
                    icon: Icons.home_rounded,
                    label: AppDestinations.homeTitleFor(user?.role),
                    selected: selectedId == 'home',
                    onTap: () => _go(context, '/home'),
                  ),
                  if (destinations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DrawerSectionLabel(
                      AppDestinations.sectionLabelFor(user?.role),
                    ),
                    for (final dest in destinations)
                      _DrawerTile(
                        key: _keyFor(dest.id),
                        icon: dest.icon,
                        label: dest.label,
                        selected: selectedId == dest.id ||
                            _isSelected(location, dest.route),
                        onTap: () => _go(context, dest.route),
                      ),
                  ],
                  const SizedBox(height: 8),
                  const _DrawerSectionLabel('Hệ thống'),
                  _DrawerTile(
                    key: _keyFor('settings'),
                    icon: AppDestinations.settings.icon,
                    label: AppDestinations.settings.label,
                    selected: selectedId == 'settings',
                    onTap: () => _go(context, '/settings'),
                  ),
                  _DrawerTile(
                    key: _keyFor('about'),
                    icon: Icons.info_rounded,
                    label: 'Giới thiệu',
                    selected: selectedId == 'about',
                    onTap: () => _go(context, '/about'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: scheme.error),
                title: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Match FilledButton.tonal look: soft wash of primary on surface (pale mint),
    // not full primaryContainer which reads too strong in the drawer.
    final selectedBg = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.14),
      scheme.surface,
    );
    final selectedFg = scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon,
            color: selected ? selectedFg : null,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? selectedFg : null,
            ),
          ),
          selected: selected,
          selectedTileColor: selectedBg,
          selectedColor: selectedFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
