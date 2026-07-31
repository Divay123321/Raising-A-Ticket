import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/dashboard_stats.dart';

/// Runs a Firestore aggregate count query, returning 0 if the collection
/// doesn't exist yet or rules currently deny it (both expected pre-Day-4/7).
Future<int> _safeCount(FirebaseFirestore db, Query query) async {
  try {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  } catch (_) {
    return 0;
  }
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = ref.watch(firestoreProvider);

  final results = await Future.wait([
    _safeCount(db, db.collection('projects')),
    _safeCount(db, db.collection('users')),
    _safeCount(
      db,
      db
          .collection('tickets')
          .where('status', whereIn: ['open', 'in_progress']),
    ),
    _safeCount(
      db,
      db.collection('tickets').where('status', whereIn: ['resolved', 'closed']),
    ),
  ]);

  return DashboardStats(
    projectCount: results[0],
    employeeCount: results[1],
    openTicketCount: results[2],
    closedTicketCount: results[3],
  );
});

/// Raw recent tickets — kept as plain maps since the full Ticket model
final recentTicketsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final db = ref.watch(firestoreProvider);
  try {
    final snapshot = await db
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    return snapshot.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList(); // include the id now
  } catch (_) {
    return [];
  }
});
