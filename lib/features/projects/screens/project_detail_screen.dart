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
    final canManage = userAsync.value?.role == UserRole.admin || userAsync.value?.role == UserRole.projectManager;
    final isAdmin = userAsync.value?.role == UserRole.admin;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load project: $err')),
        data: (project) {
          if (project == null) {
            return const Center(child: Text('Project not found.'));
          }
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
                      child: Text(project.name, style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    ProjectStatusChip(status: project.status),
                  ],
                ),
                const SizedBox(height: 24),
                _DetailRow(label: 'Client', value: project.client),
                _DetailRow(label: 'Manager', value: project.managerName),
                _DetailRow(
                  label: 'Description',
                  value: project.description.isEmpty ? '—' : project.description,
                ),
                const SizedBox(height: 32),
                if (canManage)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.go('/projects/${project.id}/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 12),
                      if (isAdmin)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _confirmDelete(context, ref, project.id, project.name),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, String projectId, String projectName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "$projectName"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(projectServiceProvider).deleteProject(projectId);
              if (context.mounted) context.go('/projects');
            },
            child: const Text('Delete'),
          ),
        ],
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
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}