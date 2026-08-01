import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/enums/ticket_status.dart';
import '../../../shared/enums/ticket_priority.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';
import '../models/ticket_comment.dart';
import '../models/activity_entry.dart';
import '../../../shared/enums/user_role.dart';
import '../../../features/auth/providers/auth_providers.dart';
import 'package:filoi/features/projects/providers/project_providers.dart';

final ticketServiceProvider = Provider<TicketService>((ref) {
  return TicketService(firestore: ref.watch(firestoreProvider));
});

final ticketListProvider = StreamProvider<List<Ticket>>((ref) {
  return ref.watch(ticketServiceProvider).watchTickets();
});

final ticketByIdProvider = StreamProvider.family<Ticket?, String>((
  ref,
  ticketId,
) {
  return ref.watch(ticketServiceProvider).watchTicketById(ticketId);
});

final ticketSearchQueryProvider = StateProvider<String>((ref) => '');
final ticketStatusFilterProvider = StateProvider<TicketStatus?>((ref) => null);
final ticketPriorityFilterProvider = StateProvider<TicketPriority?>(
  (ref) => null,
);
final ticketProjectFilterProvider = StateProvider<String?>((ref) => null);
// filters by projectId
final filteredTicketListProvider = Provider<AsyncValue<List<Ticket>>>((ref) {
  final ticketsAsync = ref.watch(ticketListProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  final managedProjectIdsAsync = ref.watch(myManagedProjectIdsProvider);
  final query = ref.watch(ticketSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(ticketStatusFilterProvider);
  final priorityFilter = ref.watch(ticketPriorityFilterProvider);
  final projectFilter = ref.watch(ticketProjectFilterProvider);

  // Need both tickets AND managed-project-ids resolved before filtering.
  if (ticketsAsync is AsyncLoading || managedProjectIdsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  if (ticketsAsync.hasError) {
    return AsyncValue.error(ticketsAsync.error!, ticketsAsync.stackTrace!);
  }

  final tickets = ticketsAsync.value ?? [];
  final managedProjectIds = managedProjectIdsAsync.value ?? {};

  final filtered = tickets.where((t) {
    final matchesQuery = query.isEmpty || t.title.toLowerCase().contains(query);
    final matchesStatus = statusFilter == null || t.status == statusFilter;
    final matchesPriority =
        priorityFilter == null || t.priority == priorityFilter;
    final matchesProject =
        projectFilter == null || t.projectId == projectFilter;

    final matchesRoleScope = switch (currentUser?.role) {
      UserRole.admin => true,
      UserRole.projectManager => managedProjectIds.contains(t.projectId),
      UserRole.engineer => t.assignedEngineerUid == currentUser?.uid,
      null => false,
    };

    return matchesQuery &&
        matchesStatus &&
        matchesPriority &&
        matchesProject &&
        matchesRoleScope;
  }).toList();

  return AsyncValue.data(filtered);
});
final ticketCommentsProvider =
    StreamProvider.family<List<TicketComment>, String>((ref, ticketId) {
      return ref.watch(ticketServiceProvider).watchComments(ticketId);
    });

final ticketActivityProvider =
    StreamProvider.family<List<ActivityEntry>, String>((ref, ticketId) {
      return ref.watch(ticketServiceProvider).watchActivity(ticketId);
    });

/// Users eligible for ticket assignment: active Engineers.
final activeEngineersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final db = ref.watch(firestoreProvider);
  final snapshot = await db
      .collection('users')
      .where('role', isEqualTo: 'engineer')
      .where('isActive', isEqualTo: true)
      .get();
  return snapshot.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
});

// ticket_providers.dart — new provider
final myManagedProjectIdsProvider = Provider<AsyncValue<Set<String>>>((ref) {
  final projectsAsync = ref.watch(projectListProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  return projectsAsync.whenData((projects) {
    if (currentUser == null) return <String>{};
    return projects
        .where((p) => p.managerUid == currentUser.uid)
        .map((p) => p.id)
        .toSet();
  });
});
