import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/enums/ticket_status.dart';
import '../../../shared/enums/ticket_priority.dart';
import '../../../shared/widgets/lists/search_field.dart';
import '../../../shared/widgets/lists/filter_dropdown.dart';
import '../../../shared/widgets/lists/error_state.dart';
import '../../../shared/widgets/lists/list_row_card.dart';
import '../../projects/providers/project_providers.dart';
import '../providers/ticket_providers.dart';
import '../widgets/ticket_priority_chip.dart';
import '../widgets/ticket_status_chip.dart';

class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(filteredTicketListProvider);
    final projectsAsync = ref.watch(projectListProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tickets',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => context.go('/tickets/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Ticket'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SearchField(
                  hint: 'Search by title...',
                  onChanged: (value) =>
                      ref.read(ticketSearchQueryProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilterDropdown<TicketStatus?>(
                  value: ref.watch(ticketStatusFilterProvider),
                  hint: 'All statuses',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...TicketStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: (value) =>
                      ref.read(ticketStatusFilterProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilterDropdown<TicketPriority?>(
                  value: ref.watch(ticketPriorityFilterProvider),
                  hint: 'All priorities',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All priorities'),
                    ),
                    ...TicketPriority.values.map(
                      (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                    ),
                  ],
                  onChanged: (value) =>
                      ref.read(ticketPriorityFilterProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: projectsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (projects) => FilterDropdown<String?>(
                    value: ref.watch(ticketProjectFilterProvider),
                    hint: 'All projects',
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All projects'),
                      ),
                      ...projects.map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      ),
                    ],
                    onChanged: (value) =>
                        ref.read(ticketProjectFilterProvider.notifier).state =
                            value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ErrorState(
                message: 'Failed to load tickets: $err',
                onRetry: () => ref.invalidate(ticketListProvider),
              ),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tickets found.',
                      style: TextStyle(color: AppColors.slate),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return ListRowCard(
                      icon: Icons.confirmation_number_outlined,
                      title: ticket.title,
                      subtitle:
                          '${ticket.projectName} · ${ticket.assignedEngineerName ?? "Unassigned"}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TicketPriorityChip(priority: ticket.priority),
                          const SizedBox(width: 6),
                          TicketStatusChip(status: ticket.status),
                        ],
                      ),
                      onTap: () => context.go('/tickets/${ticket.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
