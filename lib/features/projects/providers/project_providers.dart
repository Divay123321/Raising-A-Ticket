import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/enums/project_status.dart';
import '../models/project.dart';
import '../services/project_service.dart';

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(firestore: ref.watch(firestoreProvider));
});

final projectListProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectServiceProvider).watchProjects();
});

/// Users eligible to be assigned as a project manager: Admins or PMs.
final activeManagersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final db = ref.watch(firestoreProvider);
  final snapshot = await db
      .collection('users')
      .where('role', whereIn: ['admin', 'project_manager'])
      .where('isActive', isEqualTo: true)
      .get();
  return snapshot.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
});

final projectSearchQueryProvider = StateProvider<String>((ref) => '');
final projectStatusFilterProvider = StateProvider<ProjectStatus?>(
  (ref) => null,
);

/// Derived provider: takes the raw list + current search/filter state,
/// returns the filtered result. Recomputes automatically whenever any
/// of its three dependencies change.
final filteredProjectListProvider = Provider<AsyncValue<List<Project>>>((ref) {
  final projectsAsync = ref.watch(projectListProvider);
  final query = ref.watch(projectSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(projectStatusFilterProvider);

  return projectsAsync.whenData((projects) {
    return projects.where((p) {
      final matchesQuery =
          query.isEmpty || p.name.toLowerCase().contains(query);
      final matchesStatus = statusFilter == null || p.status == statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  });
});

final projectByIdProvider = StreamProvider.family<Project?, String>((
  ref,
  projectId,
) {
  return ref.watch(projectServiceProvider).watchProjectById(projectId);
});
