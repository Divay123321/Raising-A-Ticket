// lib/shared/widgets/navigation/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../enums/user_role.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.value?.role == UserRole.admin;
    final currentPath = GoRouterState.of(context).matchedLocation;

    final navItems = [
      _NavItem('/', 'Dashboard', Icons.dashboard_outlined),
      _NavItem('/projects', 'Projects', Icons.folder_outlined),
      if (isAdmin) _NavItem('/employees', 'Employees', Icons.people_outline),
      _NavItem('/tickets', 'Tickets', Icons.confirmation_number_outlined),
    ];

    final selectedIndex = navItems.indexWhere(
      (item) => item.path != '/' && currentPath.startsWith(item.path),
    );
    final effectiveIndex = selectedIndex == -1 ? 0 : selectedIndex;

    final sidebarContent = _SidebarContent(
      navItems: navItems,
      effectiveIndex: effectiveIndex,
      userAsync: userAsync,
      onNavigate: (path) => context.go(path),
      onSignOut: () => ref.read(authServiceProvider).signOut(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 240, child: sidebarContent),
                Expanded(child: child),
              ],
            ),
          );
        }

        // Narrow (mobile/tablet): sidebar becomes a slide-out Drawer,
        // opened via a hamburger icon in a top AppBar.
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.ink,
            foregroundColor: Colors.white,
            title: const Text('FILOI', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3, fontSize: 16)),
          ),
          drawer: Drawer(
            backgroundColor: AppColors.ink,
            child: sidebarContent,
          ),
          body: child,
        );
      },
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final List<_NavItem> navItems;
  final int effectiveIndex;
  final AsyncValue userAsync;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;

  const _SidebarContent({
    required this.navItems,
    required this.effectiveIndex,
    required this.userAsync,
    required this.onNavigate,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 4),
            child: Text(
              'FILOI',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 3),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              'OPS PORTAL',
              style: TextStyle(color: AppColors.teal, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2),
            ),
          ),
          userAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                user?.name ?? '',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 8),
          ...navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == effectiveIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: isSelected ? AppColors.teal.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    // Close the drawer first if we're in mobile mode (Navigator.pop
                    // is a no-op / harmless if there's no drawer open, e.g. wide layout).
                    if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
                    onNavigate(item.path);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 20, color: isSelected ? AppColors.teal : Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? AppColors.teal : Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onSignOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 12),
                      Text('Sign out', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  const _NavItem(this.path, this.label, this.icon);
}