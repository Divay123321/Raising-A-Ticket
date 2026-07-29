import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../widgets/app_shell.dart';
import 'package:flutter/material.dart';
import '../../features/projects/screens/project_list_screen.dart';
import '../../features/projects/screens/project_form_screen.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier();

  ref.listen(authStateProvider, (previous, next) {
    refreshNotifier.refresh();
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ProjectFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    const Placeholder(), // detail screen: Day 5
              ),
            ],
          ),
          GoRoute(
            path: '/employees',
            builder: (context, state) =>
                const Placeholder(), // real screen: Day 6
          ),
          GoRoute(
            path: '/tickets',
            builder: (context, state) =>
                const Placeholder(), // real screen: Day 7
          ),
        ],
      ),
    ],
  );
});
