import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/lists/search_field.dart';
import '../../../shared/widgets/lists/filter_dropdown.dart';
import '../../../shared/widgets/lists/error_state.dart';
import '../../../shared/widgets/lists/list_row_card.dart';
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
              const Text(
                'Projects',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isAdmin)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => context.go('/projects/new'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Project'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SearchField(
                  hint: 'Search by project name...',
                  onChanged: (value) =>
                      ref.read(projectSearchQueryProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilterDropdown<ProjectStatus?>(
                  value: ref.watch(projectStatusFilterProvider),
                  hint: 'All statuses',
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
              error: (err, stack) => ErrorState(
                message: 'Failed to load projects: $err',
                onRetry: () => ref.invalidate(projectListProvider),
              ),
              data: (projects) {
                if (projects.isEmpty) {
                  return const Center(
                    child: Text(
                      'No projects found.',
                      style: TextStyle(color: AppColors.slate),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return ListRowCard(
                      icon: Icons.folder_outlined,
                      title: project.name,
                      subtitle: '${project.client} · ${project.managerName}',
                      trailing: ProjectStatusChip(status: project.status),
                      onTap: () => context.go('/projects/${project.id}'),
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
