import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/enums/user_role.dart';
import '../../../shared/widgets/lists/error_state.dart';
import '../../../shared/widgets/detail/back_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../../tickets/models/activity_entry.dart';
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
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(employeeServiceProvider)
          .updateEmployee(
            uid: widget.uid,
            role: _role!.value,
            isActive: _isActive!,
            skills: _skills,
            actorUid: currentUser.uid,
            actorName: currentUser.name,
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
        error: (err, stack) => ErrorState(
          message: 'Failed to load employee: $err',
          onRetry: () => ref.invalidate(employeeByIdProvider(widget.uid)),
        ),
        data: (employee) {
          if (employee == null) {
            return const Center(
              child: Text(
                'Employee not found.',
                style: TextStyle(color: AppColors.slate),
              ),
            );
          }

          if (!_initialized) {
            _role = employee.role;
            _isActive = employee.isActive;
            _skills = List.from(employee.skills);
            _initialized = true;
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBackButton(onTap: () => context.go('/employees')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        employee.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    employee.email,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Editable fields card
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
                      DropdownButtonFormField<UserRole>(
                        decoration: InputDecoration(
                          labelText: 'Role',
                          filled: true,
                          fillColor: AppColors.parchment,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        value: _role,
                        items: UserRole.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _role = value),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.teal,
                        title: const Text(
                          'Account Active',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _isActive!
                              ? 'Can log in and use the app'
                              : 'Blocked from accessing the app',
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 13,
                          ),
                        ),
                        value: _isActive!,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SKILLS',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills
                            .map(
                              (skill) => Chip(
                                label: Text(skill),
                                backgroundColor: AppColors.teal.withValues(
                                  alpha: 0.1,
                                ),
                                labelStyle: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13,
                                ),
                                side: BorderSide.none,
                                onDeleted: () =>
                                    setState(() => _skills.remove(skill)),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _skillController,
                              decoration: InputDecoration(
                                hintText: 'Add a skill...',
                                filled: true,
                                fillColor: AppColors.parchment,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _addSkill(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: AppColors.teal,
                            ),
                            onPressed: _addSkill,
                          ),
                        ],
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
                            employeeActivityProvider(widget.uid),
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
                                    employeeActivityProvider(widget.uid),
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
                              return _EmployeeActivityList(entries: entries);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmployeeActivityList extends StatelessWidget {
  final List<ActivityEntry> entries;
  const _EmployeeActivityList({required this.entries});

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
                      color: AppColors.teal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.teal,
                    ),
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
