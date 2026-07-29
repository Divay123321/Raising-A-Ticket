// lib/core/widgets/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../shared/enums/user_role.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: _indexForPath(currentPath),
            onDestinationSelected: (index) => _navigateToIndex(context, index, userAsync.value?.role),
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Filoi Ops Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              userAsync.when(
                data: (user) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(user?.name ?? '', style: const TextStyle(color: Colors.grey)),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Divider(),
              const NavigationDrawerDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Dashboard')),
              const NavigationDrawerDestination(icon: Icon(Icons.folder_outlined), label: Text('Projects')),
              if (userAsync.value?.role == UserRole.admin)
                const NavigationDrawerDestination(icon: Icon(Icons.people_outline), label: Text('Employees')),
              const NavigationDrawerDestination(icon: Icon(Icons.confirmation_number_outlined), label: Text('Tickets')),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _indexForPath(String path) {
    if (path.startsWith('/projects')) return 1;
    if (path.startsWith('/employees')) return 2;
    if (path.startsWith('/tickets')) return 3;
    return 0;
  }

  void _navigateToIndex(BuildContext context, int index, UserRole? role) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/projects'); break;
      case 2:
        if (role == UserRole.admin) context.go('/employees');
        break;
      case 3: context.go('/tickets'); break;
    }
  }
}