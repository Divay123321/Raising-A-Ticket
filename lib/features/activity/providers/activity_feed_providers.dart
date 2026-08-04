// lib/features/activity/providers/activity_feed_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/enums/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../../projects/providers/project_providers.dart';
import '../../tickets/providers/ticket_providers.dart';
import '../../tickets/models/activity_entry.dart';
import '../models/feed_entry.dart';

final activityFeedProvider = FutureProvider<List<FeedEntry>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return [];

  final db = ref.watch(firestoreProvider);
  final allProjects = await ref.watch(projectListProvider.future);
  final allTickets = await ref.watch(ticketListProvider.future);

  // Scope: Admin sees everything; PM sees only projects/tickets they manage.
  final visibleProjects = currentUser.role == UserRole.admin
      ? allProjects
      : allProjects.where((p) => p.managerUid == currentUser.uid).toList();
  final visibleProjectIds = visibleProjects.map((p) => p.id).toSet();

  final visibleTickets = currentUser.role == UserRole.admin
      ? allTickets
      : allTickets.where((t) => visibleProjectIds.contains(t.projectId)).toList();

  // Employees: derived team across all visible projects (Admin gets everyone active).
  final visibleEmployeeUids = <String>{};
  if (currentUser.role == UserRole.admin) {
    final allEmployeesSnapshot = await db.collection('users').get();
    visibleEmployeeUids.addAll(allEmployeesSnapshot.docs.map((d) => d.id));
  } else {
    for (final ticket in visibleTickets) {
      if (ticket.assignedEngineerUid != null) {
        visibleEmployeeUids.add(ticket.assignedEngineerUid!);
      }
    }
  }

  final feed = <FeedEntry>[];

  for (final project in visibleProjects) {
    final snapshot = await db.collection('projects').doc(project.id).collection('activity').get();
    for (final doc in snapshot.docs) {
      feed.add(FeedEntry(
        entry: ActivityEntry.fromMap(doc.id, doc.data()),
        source: ActivitySource.project,
        sourceId: project.id,
        sourceLabel: project.name,
      ));
    }
  }

  for (final ticket in visibleTickets) {
    final snapshot = await db.collection('tickets').doc(ticket.id).collection('activity').get();
    for (final doc in snapshot.docs) {
      feed.add(FeedEntry(
        entry: ActivityEntry.fromMap(doc.id, doc.data()),
        source: ActivitySource.ticket,
        sourceId: ticket.id,
        sourceLabel: ticket.title,
      ));
    }
  }

  for (final uid in visibleEmployeeUids) {
    final snapshot = await db.collection('users').doc(uid).collection('activity').get();
    for (final doc in snapshot.docs) {
      final entry = ActivityEntry.fromMap(doc.id, doc.data());
      feed.add(FeedEntry(
        entry: entry,
        source: ActivitySource.employee,
        sourceId: uid,
        sourceLabel: entry.actorUid == uid ? entry.actorName : uid,
      ));
    }
  }

  feed.sort((a, b) => (b.entry.timestamp ?? DateTime(0)).compareTo(a.entry.timestamp ?? DateTime(0)));
  return feed;
});