import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/enums/project_status.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  final Project? existingProject; // null = create mode, non-null = edit mode

  const ProjectFormScreen({super.key, this.existingProject});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _clientController;
  late final TextEditingController _descriptionController;

  ProjectStatus _status = ProjectStatus.active;
  Map<String, dynamic>? _selectedManager;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditMode => widget.existingProject != null;

  @override
  void initState() {
    super.initState();
    final project = widget.existingProject;
    _nameController = TextEditingController(text: project?.name ?? '');
    _clientController = TextEditingController(text: project?.client ?? '');
    _descriptionController = TextEditingController(
      text: project?.description ?? '',
    );
    _status = project?.status ?? ProjectStatus.active;
    // _selectedManager is set once activeManagersProvider resolves, matched by uid, below.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedManager == null) {
      setState(() => _errorMessage = 'Please select a manager.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final project = Project(
      id: widget.existingProject?.id ?? '',
      name: _nameController.text.trim(),
      client: _clientController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      managerUid: _selectedManager!['uid'] as String,
      managerName: _selectedManager!['name'] as String,
    );

    try {
      final service = ref.read(projectServiceProvider);
      if (_isEditMode) {
        await service.updateProject(widget.existingProject!.id, project);
      } else {
        await service.createProject(project);
      }
      if (mounted) context.go('/projects');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save project: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final managersAsync = ref.watch(activeManagersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditMode ? 'Edit Project' : 'New Project',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: 'Client',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectStatus>(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: _status,
                items: ProjectStatus.values
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 16),
              managersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Failed to load managers: $err'),
                data: (managers) {
                  // Match existing manager by uid, once data is available.
                  if (_isEditMode && _selectedManager == null) {
                    final match = managers.where(
                      (m) => m['uid'] == widget.existingProject!.managerUid,
                    );
                    if (match.isNotEmpty) _selectedManager = match.first;
                  }
                  return DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(
                      labelText: 'Assigned Manager',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedManager,
                    items: managers
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text('${m['name']} (${m['role']})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedManager = value),
                  );
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditMode ? 'Save Changes' : 'Create Project'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/projects'),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
