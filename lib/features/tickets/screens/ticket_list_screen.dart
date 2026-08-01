import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/enums/ticket_status.dart';
import '../../../shared/enums/ticket_priority.dart';
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
              Text('Tickets', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go('/tickets/new'),
                icon: const Icon(Icons.add),
                label: const Text('New Ticket'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by title...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      ref.read(ticketSearchQueryProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<TicketStatus?>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: ref.watch(ticketStatusFilterProvider),
                  hint: const Text('All statuses'),
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
                child: DropdownButtonFormField<TicketPriority?>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: ref.watch(ticketPriorityFilterProvider),
                  hint: const Text('All priorities'),
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
                  data: (projects) => DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: ref.watch(ticketProjectFilterProvider),
                    hint: const Text('All projects'),
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
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load tickets: $err'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(ticketListProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tickets found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Project')),
                      DataColumn(label: Text('Engineer')),
                      DataColumn(label: Text('Priority')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: tickets.map((ticket) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(ticket.title),
                            onTap: () => context.go('/tickets/${ticket.id}'),
                          ),
                          DataCell(Text(ticket.projectName)),
                          DataCell(
                            Text(ticket.assignedEngineerName ?? 'Unassigned'),
                          ),
                          DataCell(
                            TicketPriorityChip(priority: ticket.priority),
                          ),
                          DataCell(TicketStatusChip(status: ticket.status)),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
