import 'package:filoi/shared/widgets/detail/back_button.dart';
import 'package:filoi/shared/widgets/detail/detail_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/enums/user_role.dart';
import '../../../shared/widgets/lists/error_state.dart';
import '../../auth/providers/auth_providers.dart';
import '../../tickets/models/activity_entry.dart';
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

                // Info card
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

                const SizedBox(height: 16),

                // Team card — derived from ticket assignments, no stored field
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
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TEAM',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final teamAsync = ref.watch(
                            projectTeamProvider(project.id),
                          );
                          return teamAsync.when(
                            loading: () => const LinearProgressIndicator(
                              color: AppColors.teal,
                            ),
                            error: (_, __) => Row(
                              children: [
                                const Text(
                                  'Failed to load team.',
                                  style: TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => ref.invalidate(
                                    projectTeamProvider(project.id),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            data: (team) {
                              if (team.isEmpty) {
                                return const Text(
                                  'No engineers currently assigned to tickets on this project.',
                                  style: TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 13,
                                  ),
                                );
                              }
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: team.map((member) {
                                  return Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor: AppColors.teal
                                          .withValues(alpha: 0.2),
                                      child: Text(
                                        member['name']!.isNotEmpty
                                            ? member['name']![0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.teal,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    label: Text(member['name']!),
                                    backgroundColor: AppColors.parchment,
                                    side: BorderSide.none,
                                  );
                                }).toList(),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Activity card
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
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVITY',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final activityAsync = ref.watch(
                            projectActivityProvider(project.id),
                          );
                          return activityAsync.when(
                            loading: () => const LinearProgressIndicator(
                              color: AppColors.teal,
                            ),
                            error: (_, __) => Row(
                              children: [
                                const Text(
                                  'Failed to load activity.',
                                  style: TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => ref.invalidate(
                                    projectActivityProvider(project.id),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            data: (entries) {
                              if (entries.isEmpty) {
                                return const Text(
                                  'No activity yet.',
                                  style: TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 13,
                                  ),
                                );
                              }
                              return _ProjectActivityList(entries: entries);
                            },
                          );
                        },
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

class _ProjectActivityList extends StatelessWidget {
  final List<ActivityEntry> entries;
  const _ProjectActivityList({required this.entries});

  IconData _iconFor(ActivityType type) => switch (type) {
    ActivityType.created => Icons.add_circle_outline,
    ActivityType.edited => Icons.edit_outlined,
    ActivityType.statusChanged => Icons.sync_alt,
    ActivityType.assigned => Icons.person_add_alt_outlined,
  };

  Color _colorFor(ActivityType type) => switch (type) {
    ActivityType.created => Colors.green,
    ActivityType.edited => Colors.blueGrey,
    ActivityType.statusChanged => Colors.orange,
    ActivityType.assigned => Colors.blue,
  };

  String _relativeTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.asMap().entries.map((indexed) {
        final index = indexed.key;
        final e = indexed.value;
        final isLast = index == entries.length - 1;
        final color = _colorFor(e.type);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconFor(e.type), size: 14, color: color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: Colors.grey.shade300),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: e.actorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            TextSpan(
                              text: ' ${e.detail}',
                              style: const TextStyle(color: AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _relativeTime(e.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
