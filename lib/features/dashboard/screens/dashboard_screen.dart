import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/enums/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/stat_card.dart';
import '../widgets/ticket_status_chart.dart';
import '../../../core/theme/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Not signed in'));
        }
        if (!user.isActive) {
          return _PendingApprovalView(userName: user.name);
        }
        return const _DashboardContent();
      },
    );
  }
}

class _PendingApprovalView extends ConsumerWidget {
  final String userName;
  const _PendingApprovalView({required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top, size: 48),
            const SizedBox(height: 16),
            Text('Hi $userName, your account is awaiting Admin activation.'),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerStatefulWidget {
  const _DashboardContent();

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(dashboardStatsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentTicketsAsync = ref.watch(recentTicketsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),

          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Failed to load stats: $err'),
            data: (stats) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 240,
                  child: StatCard(
                    label: 'Projects',
                    value: stats.projectCount,
                    icon: Icons.folder_outlined,
                    accentColor: AppColors.teal,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: StatCard(
                    label: 'Employees',
                    value: stats.employeeCount,
                    icon: Icons.people_outline,
                    accentColor: AppColors.ink,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: StatCard(
                    label: 'Open Tickets',
                    value: stats.openTicketCount,
                    icon: Icons.error_outline,
                    accentColor: const Color(
                      0xFFEA580C,
                    ), // warm amber — "needs attention"
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: StatCard(
                    label: 'Closed Tickets',
                    value: stats.closedTicketCount,
                    icon: Icons.check_circle_outline,
                    accentColor: const Color(0xFF16A34A), // green — "resolved"
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final currentUser = ref.watch(currentUserProvider).value;
                    if (currentUser?.role != UserRole.engineer) {
                      return const SizedBox.shrink();
                    }

                    final myTicketsAsync = ref.watch(myTicketCountProvider);
                    return myTicketsAsync.when(
                      loading: () => const SizedBox(
                        width: 240,
                        child: Card(child: SizedBox(height: 76)),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (count) => SizedBox(
                        width: 240,
                        child: StatCard(
                          label: 'My Tickets',
                          value: count,
                          icon: Icons.assignment_ind_outlined,
                          accentColor: AppColors.teal,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'Ticket Status Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => TicketStatusChart(
              openCount: stats.openTicketCount,
              closedCount: stats.closedTicketCount,
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'Recent Tickets',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          recentTicketsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Failed to load tickets: $err'),
            data: (tickets) {
              if (tickets.isEmpty) {
                return const Text(
                  'No tickets yet.',
                  style: TextStyle(color: AppColors.slate),
                );
              }
              return Column(
                children: tickets.map((t) {
                  final status = t['status'] as String? ?? '';
                  final statusColor = switch (status) {
                    'open' => const Color(0xFFEA580C),
                    'in_progress' => AppColors.teal,
                    'resolved' => Colors.blue,
                    'closed' => const Color(0xFF16A34A),
                    _ => AppColors.slate,
                  };

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => context.go('/tickets/${t['id']}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t['title'] as String? ?? 'Untitled',
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
