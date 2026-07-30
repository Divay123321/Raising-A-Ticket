import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import 'project_form_screen.dart';

class ProjectEditLoader extends ConsumerWidget {
  final String projectId;
  const ProjectEditLoader({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));

    return projectAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Failed to load project: $err')),
      data: (project) {
        if (project == null) return const Center(child: Text('Project not found.'));
        return ProjectFormScreen(existingProject: project);
      },
    );
  }
}