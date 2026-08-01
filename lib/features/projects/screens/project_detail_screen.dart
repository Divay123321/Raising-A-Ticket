import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/enums/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/project_providers.dart';
import '../widgets/project_status_chip.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));
    final userAsync = ref.watch(currentUserProvider);
    final currentUser = userAsync.value;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load project: $err'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(projectByIdProvider(projectId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (project) {
          if (project == null) {
            return const Center(child: Text('Project not found.'));
          }

          final canManage =
              currentUser?.role == UserRole.admin ||
              currentUser?.uid == project.managerUid;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/projects'),
                    ),
                    Expanded(
                      child: Text(
                        project.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    ProjectStatusChip(status: project.status),
                  ],
                ),
                const SizedBox(height: 24),
                _DetailRow(label: 'Client', value: project.client),
                _DetailRow(label: 'Manager', value: project.managerName),
                _DetailRow(
                  label: 'Description',
                  value: project.description.isEmpty
                      ? '—'
                      : project.description,
                ),
                const SizedBox(height: 32),
                if (canManage)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/projects/${project.id}/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
