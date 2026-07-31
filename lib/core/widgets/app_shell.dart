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
    final isAdmin = userAsync.value?.role == UserRole.admin;
    final currentPath = GoRouterState.of(context).matchedLocation;

    final routes = ['/', '/projects', if (isAdmin) '/employees', '/tickets'];

    int selectedIndex = routes.indexWhere(
      (r) => r != '/' && currentPath.startsWith(r),
    );
    if (selectedIndex == -1) selectedIndex = 0;

    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => context.go(routes[index]),
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filoi Ops Portal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              userAsync.when(
                data: (user) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    user?.name ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Divider(),
              const NavigationDrawerDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: Text('Dashboard'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.folder_outlined),
                label: Text('Projects'),
              ),
              if (isAdmin)
                const NavigationDrawerDestination(
                  icon: Icon(Icons.people_outline),
                  label: Text('Employees'),
                ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                label: Text('Tickets'),
              ),
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
}
