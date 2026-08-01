import 'package:filoi/shared/widgets/detail/back_button.dart';
import 'package:filoi/shared/widgets/detail/detail_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/enums/user_role.dart';
import '../../../shared/widgets/lists/error_state.dart';
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
        error: (err, stack) => ErrorState(
          message: 'Failed to load project: $err',
          onRetry: () => ref.invalidate(projectByIdProvider(projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const Center(
              child: Text(
                'Project not found.',
                style: TextStyle(color: AppColors.slate),
              ),
            );
          }

          final canManage =
              currentUser?.role == UserRole.admin ||
              currentUser?.uid == project.managerUid;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBackButton(onTap: () => context.go('/projects')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ProjectStatusChip(status: project.status),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DetailField(
                              label: 'Client',
                              value: project.client,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: DetailField(
                              label: 'Manager',
                              value: project.managerName,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DetailField(
                        label: 'Description',
                        value: project.description.isEmpty
                            ? '—'
                            : project.description,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (canManage)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => context.go('/projects/${project.id}/edit'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
