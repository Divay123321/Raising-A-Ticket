import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/enums/project_status.dart';
import '../../../shared/enums/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/project_providers.dart';
import '../widgets/project_status_chip.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(filteredProjectListProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.value?.role == UserRole.admin;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Projects',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () => context.go('/projects/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New Project'),
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
                    hintText: 'Search by project name...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      ref.read(projectSearchQueryProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<ProjectStatus?>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: ref.watch(projectStatusFilterProvider),
                  hint: const Text('All statuses'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...ProjectStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: (value) =>
                      ref.read(projectStatusFilterProvider.notifier).state =
                          value,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load projects: $err'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(projectListProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (projects) {
                if (projects.isEmpty) {
                  return const Center(
                    child: Text(
                      'No projects found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Client')),
                      DataColumn(label: Text('Manager')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: projects.map((project) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(project.name),
                            onTap: () => context.go('/projects/${project.id}'),
                          ),
                          DataCell(Text(project.client)),
                          DataCell(Text(project.managerName)),
                          DataCell(ProjectStatusChip(status: project.status)),
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
