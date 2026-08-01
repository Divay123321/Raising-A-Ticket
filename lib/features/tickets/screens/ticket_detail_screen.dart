import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/enums/ticket_status.dart';
import '../../../shared/enums/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/ticket_providers.dart';
import '../widgets/ticket_priority_chip.dart';
import '../widgets/ticket_status_chip.dart';
import '../widgets/comment_thread.dart';
import '../widgets/activity_timeline.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, String ticketId, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Ticket'),
        content: Text(
          'Are you sure you want to delete "$title"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(ticketServiceProvider).deleteTicket(ticketId);
              if (context.mounted) context.go('/tickets');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketByIdProvider(widget.ticketId));
    final userAsync = ref.watch(currentUserProvider);
    final currentUser = userAsync.value;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load ticket: $err'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(ticketByIdProvider(widget.ticketId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (ticket) {
          if (ticket == null) {
            return const Center(child: Text('Ticket not found.'));
          }
          if (currentUser == null) return const SizedBox.shrink();

          final canManage =
              currentUser.role == UserRole.admin ||
              currentUser.role == UserRole.projectManager;
          final canChangeStatus =
              canManage || currentUser.uid == ticket.assignedEngineerUid;
          final canDelete = currentUser.role == UserRole.admin;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/tickets'),
                      ),
                      Expanded(
                        child: Text(
                          ticket.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      TicketPriorityChip(priority: ticket.priority),
                      const SizedBox(width: 8),
                      TicketStatusChip(status: ticket.status),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(ticket.description),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      _InfoItem(label: 'Project', value: ticket.projectName),
                      _InfoItem(
                        label: 'Created By',
                        value: ticket.createdByName,
                      ),
                      if (ticket.reportedBy != null)
                        _InfoItem(
                          label: 'Reported By',
                          value: ticket.reportedBy!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  if (canManage || canChangeStatus)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (canManage)
                              Expanded(
                                child: _AssignEngineerSection(
                                  ticketId: ticket.id,
                                  currentAssigneeUid:
                                      ticket.assignedEngineerUid,
                                ),
                              ),
                            if (canManage && canChangeStatus)
                              const SizedBox(width: 16),
                            if (canChangeStatus)
                              Expanded(
                                child: _StatusChangeSection(
                                  ticketId: ticket.id,
                                  currentStatus: ticket.status,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (canManage || currentUser.uid == ticket.createdByUid)
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go('/tickets/${ticket.id}/edit'),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                      if (canDelete) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () =>
                              _confirmDelete(context, ticket.id, ticket.title),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),
                  TabBar(
                    tabAlignment: TabAlignment.start,
                    controller: _tabController,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Comments'),
                      Tab(text: 'Activity'),
                    ],
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 16),
                          child: CommentThread(ticketId: ticket.id),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 16),
                          child: ActivityTimeline(ticketId: ticket.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        Text(value),
      ],
    );
  }
}

class _AssignEngineerSection extends ConsumerWidget {
  final String ticketId;
  final String? currentAssigneeUid;
  const _AssignEngineerSection({
    required this.ticketId,
    required this.currentAssigneeUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engineersAsync = ref.watch(activeEngineersProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return engineersAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load engineers: $err'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(activeEngineersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (engineers) {
        final matches = engineers.where((e) => e['uid'] == currentAssigneeUid);
        final currentValue = matches.isNotEmpty ? matches.first : null;

        return DropdownButtonFormField<Map<String, dynamic>?>(
          decoration: const InputDecoration(
            labelText: 'Assigned Engineer',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          value: currentValue,
          hint: const Text('Unassigned'),
          items: engineers
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e['name'] as String),
                ),
              )
              .toList(),
          onChanged: (value) async {
            if (value == null || currentUser == null) return;
            try {
              await ref
                  .read(ticketServiceProvider)
                  .assignEngineer(
                    ticketId: ticketId,
                    engineerUid: value['uid'] as String,
                    engineerName: value['name'] as String,
                    actorUid: currentUser.uid,
                    actorName: currentUser.name,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assigned to ${value['name']}')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed to assign: $e')));
              }
            }
          },
        );
      },
    );
  }
}

class _StatusChangeSection extends ConsumerWidget {
  final String ticketId;
  final TicketStatus currentStatus;
  const _StatusChangeSection({
    required this.ticketId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    return DropdownButtonFormField<TicketStatus>(
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      value: currentStatus,
      items: TicketStatus.values
          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
          .toList(),
      onChanged: (value) async {
        if (value == null || currentUser == null) return;
        try {
          await ref
              .read(ticketServiceProvider)
              .changeStatus(
                ticketId: ticketId,
                newStatus: value.value,
                actorUid: currentUser.uid,
                actorName: currentUser.name,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Status changed to ${value.label}')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to change status: $e')),
            );
          }
        }
      },
    );
  }
}
