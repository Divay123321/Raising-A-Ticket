import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../widgets/app_shell.dart';
import 'package:flutter/material.dart';
import '../../features/projects/screens/project_list_screen.dart';
import '../../features/projects/screens/project_form_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/projects/screens/project_edit_loader.dart';
import '../../features/employees/screens/employee_list_screen.dart';
import '../../features/employees/screens/employee_detail_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/tickets/screens/ticket_list_screen.dart';
import '../../features/tickets/screens/ticket_form_screen.dart';

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
      if (ref.read(authTransitionInProgressProvider)) {
        return null;
      } // mid-transition, don't redirect yet

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
                    ProjectDetailScreen(projectId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => ProjectEditLoader(
                      projectId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/employees',
            builder: (context, state) => const EmployeeListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    EmployeeDetailScreen(uid: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/tickets',
            builder: (context, state) => const TicketListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const TicketFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    const Placeholder(), // detail screen: Day 8
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
