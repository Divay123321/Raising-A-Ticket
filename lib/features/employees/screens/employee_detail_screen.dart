import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/enums/user_role.dart';
import '../providers/employee_providers.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final String uid;
  const EmployeeDetailScreen({super.key, required this.uid});

  @override
  ConsumerState<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  UserRole? _role;
  bool? _isActive;
  List<String> _skills = [];
  final _skillController = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(employeeServiceProvider)
          .updateEmployee(
            uid: widget.uid,
            role: _role!.value,
            isActive: _isActive!,
            skills: _skills,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeAsync = ref.watch(employeeByIdProvider(widget.uid));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load employee: $err'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(employeeByIdProvider(widget.uid)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (employee) {
          if (employee == null) {
            return const Center(child: Text('Employee not found.'));
          }

          // One-time initialization of local editable state from fetched data.
          if (!_initialized) {
            _role = employee.role;
            _isActive = employee.isActive;
            _skills = List.from(employee.skills);
            _initialized = true;
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/employees'),
                    ),
                    Expanded(
                      child: Text(
                        employee.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  employee.email,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<UserRole>(
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  value: _role,
                  items: UserRole.values
                      .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _role = value),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Account Active'),
                  subtitle: Text(
                    _isActive!
                        ? 'Can log in and use the app'
                        : 'Blocked from accessing the app',
                  ),
                  value: _isActive!,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 16),

                Text('Skills', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          onDeleted: () =>
                              setState(() => _skills.remove(skill)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillController,
                        decoration: const InputDecoration(
                          hintText: 'Add a skill...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addSkill,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
