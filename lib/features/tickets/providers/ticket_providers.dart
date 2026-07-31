import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/enums/ticket_status.dart';
import '../../../shared/enums/ticket_priority.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';
import '../models/ticket_comment.dart';
import '../models/activity_entry.dart';

final ticketServiceProvider = Provider<TicketService>((ref) {
  return TicketService(firestore: ref.watch(firestoreProvider));
});

final ticketListProvider = StreamProvider<List<Ticket>>((ref) {
  return ref.watch(ticketServiceProvider).watchTickets();
});

final ticketByIdProvider = StreamProvider.family<Ticket?, String>((ref, ticketId) {
  return ref.watch(ticketServiceProvider).watchTicketById(ticketId);
});

final ticketSearchQueryProvider = StateProvider<String>((ref) => '');
final ticketStatusFilterProvider = StateProvider<TicketStatus?>((ref) => null);
final ticketPriorityFilterProvider = StateProvider<TicketPriority?>((ref) => null);
final ticketProjectFilterProvider = StateProvider<String?>((ref) => null); // filters by projectId

final filteredTicketListProvider = Provider<AsyncValue<List<Ticket>>>((ref) {
  final ticketsAsync = ref.watch(ticketListProvider);
  final query = ref.watch(ticketSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(ticketStatusFilterProvider);
  final priorityFilter = ref.watch(ticketPriorityFilterProvider);
  final projectFilter = ref.watch(ticketProjectFilterProvider);

  return ticketsAsync.whenData((tickets) {
    return tickets.where((t) {
      final matchesQuery = query.isEmpty || t.title.toLowerCase().contains(query);
      final matchesStatus = statusFilter == null || t.status == statusFilter;
      final matchesPriority = priorityFilter == null || t.priority == priorityFilter;
      final matchesProject = projectFilter == null || t.projectId == projectFilter;
      return matchesQuery && matchesStatus && matchesPriority && matchesProject;
    }).toList();
  });
});
final ticketCommentsProvider = StreamProvider.family<List<TicketComment>, String>((ref, ticketId) {
  return ref.watch(ticketServiceProvider).watchComments(ticketId);
});

final ticketActivityProvider = StreamProvider.family<List<ActivityEntry>, String>((ref, ticketId) {
  return ref.watch(ticketServiceProvider).watchActivity(ticketId);
});

/// Users eligible for ticket assignment: active Engineers.
final activeEngineersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(firestoreProvider);
  final snapshot = await db
      .collection('users')
      .where('role', isEqualTo: 'engineer')
      .where('isActive', isEqualTo: true)
      .get();
  return snapshot.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
});