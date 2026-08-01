import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/enums/user_role.dart';
import '../../../shared/widgets/lists/search_field.dart';
import '../../../shared/widgets/lists/filter_dropdown.dart';
import '../../../shared/widgets/lists/error_state.dart';
import '../../../shared/widgets/lists/list_row_card.dart';
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
          const Text(
            'Employees',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SearchField(
                  hint: 'Search by name...',
                  onChanged: (value) =>
                      ref.read(employeeSearchQueryProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilterDropdown<UserRole?>(
                  value: ref.watch(employeeRoleFilterProvider),
                  hint: 'All roles',
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
              error: (err, stack) => ErrorState(
                message: 'Failed to load employees: $err',
                onRetry: () => ref.invalidate(employeeListProvider),
              ),
              data: (employees) {
                if (employees.isEmpty) {
                  return const Center(
                    child: Text(
                      'No employees found.',
                      style: TextStyle(color: AppColors.slate),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return ListRowCard(
                      icon: Icons.person_outline,
                      title: employee.name,
                      subtitle: '${employee.email} · ${employee.role.label}',
                      trailing: _StatusBadge(isActive: employee.isActive),
                      onTap: () => context.go('/employees/${employee.uid}'),
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

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Pending',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
