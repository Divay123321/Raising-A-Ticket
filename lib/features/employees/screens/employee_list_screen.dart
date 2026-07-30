import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/enums/user_role.dart';
import '../providers/employee_providers.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(filteredEmployeeListProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Employees', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      ref.read(employeeSearchQueryProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<UserRole?>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: ref.watch(employeeRoleFilterProvider),
                  hint: const Text('All roles'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All roles'),
                    ),
                    ...UserRole.values.map(
                      (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                    ),
                  ],
                  onChanged: (value) =>
                      ref.read(employeeRoleFilterProvider.notifier).state =
                          value,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: employeesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Failed to load employees: $err')),
              data: (employees) {
                if (employees.isEmpty) {
                  return const Center(
                    child: Text(
                      'No employees found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: employees.map((employee) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(employee.name),
                            onTap: () =>
                                context.go('/employees/${employee.uid}'),
                          ),
                          DataCell(Text(employee.email)),
                          DataCell(Text(employee.role.label)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (employee.isActive
                                            ? Colors.green
                                            : Colors.orange)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                employee.isActive ? 'Active' : 'Pending',
                                style: TextStyle(
                                  color: employee.isActive
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
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
