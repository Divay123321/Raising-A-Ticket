import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/enums/user_role.dart';
import '../../auth/models/app_user.dart';
import '../services/employee_service.dart';
import '../../tickets/models/activity_entry.dart';

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService(firestore: ref.watch(firestoreProvider));
});

final employeeListProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(employeeServiceProvider).watchEmployees();
});

final employeeByIdProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  return ref.watch(employeeServiceProvider).watchEmployeeById(uid);
});

final employeeSearchQueryProvider = StateProvider<String>((ref) => '');
final employeeRoleFilterProvider = StateProvider<UserRole?>((ref) => null);

final filteredEmployeeListProvider = Provider<AsyncValue<List<AppUser>>>((ref) {
  final employeesAsync = ref.watch(employeeListProvider);
  final query = ref.watch(employeeSearchQueryProvider).toLowerCase();
  final roleFilter = ref.watch(employeeRoleFilterProvider);

  return employeesAsync.whenData((employees) {
    return employees.where((e) {
      final matchesQuery = query.isEmpty || e.name.toLowerCase().contains(query);
      final matchesRole = roleFilter == null || e.role == roleFilter;
      return matchesQuery && matchesRole;
    }).toList();
  });
});


final employeeActivityProvider = StreamProvider.family<List<ActivityEntry>, String>((ref, uid) {
  return ref.watch(employeeServiceProvider).watchActivity(uid);
});