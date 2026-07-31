import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/enums/ticket_priority.dart';
import '../../auth/providers/auth_providers.dart';
import '../../projects/providers/project_providers.dart';
import '../models/ticket.dart';
import '../providers/ticket_providers.dart';
import '../../../shared/enums/ticket_status.dart';

class TicketFormScreen extends ConsumerStatefulWidget {
  final Ticket? existingTicket;
  const TicketFormScreen({super.key, this.existingTicket});

  @override
  ConsumerState<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends ConsumerState<TicketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reportedByController = TextEditingController();
  bool get _isEditMode => widget.existingTicket != null;

  TicketPriority _priority = TicketPriority.medium;
  String? _selectedProjectId;
  String? _selectedProjectName;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reportedByController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final ticket = widget.existingTicket;
    _titleController.text = ticket?.title ?? '';
    _descriptionController.text = ticket?.description ?? '';
    _reportedByController.text = ticket?.reportedBy ?? '';
    _priority = ticket?.priority ?? TicketPriority.medium;
    _selectedProjectId = ticket?.projectId;
    _selectedProjectName = ticket?.projectName;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      setState(() => _errorMessage = 'Please select a project.');
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(ticketServiceProvider);
      if (_isEditMode) {
        final updated = Ticket(
          id: widget.existingTicket!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          status: widget
              .existingTicket!
              .status, // status unchanged here — handled separately
          projectId: _selectedProjectId!,
          projectName: _selectedProjectName!,
          assignedEngineerUid: widget.existingTicket!.assignedEngineerUid,
          assignedEngineerName: widget.existingTicket!.assignedEngineerName,
          createdByUid: widget.existingTicket!.createdByUid,
          createdByName: widget.existingTicket!.createdByName,
          reportedBy: _reportedByController.text.trim().isEmpty
              ? null
              : _reportedByController.text.trim(),
        );
        await service.updateTicket(
          widget.existingTicket!.id,
          updated,
          actorUid: currentUser.uid,
          actorName: currentUser.name,
        );
      } else {
        final ticket = Ticket(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          status: TicketStatus.open,
          projectId: _selectedProjectId!,
          projectName: _selectedProjectName!,
          createdByUid: currentUser.uid,
          createdByName: currentUser.name,
          reportedBy: _reportedByController.text.trim().isEmpty
              ? null
              : _reportedByController.text.trim(),
        );
        await service.createTicket(ticket);
      }
      if (mounted) context.go('/tickets');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save ticket: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);

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
                _isEditMode ? 'Edit Ticket' : 'New Ticket',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
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
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              projectsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Failed to load projects: $err'),
                data: (projects) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedProjectId,
                  items: projects
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (value) {
                    final project = projects.firstWhere((p) => p.id == value);
                    setState(() {
                      _selectedProjectId = project.id;
                      _selectedProjectName = project.name;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TicketPriority>(
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                value: _priority,
                items: TicketPriority.values
                    .map(
                      (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reportedByController,
                decoration: const InputDecoration(
                  labelText: 'Reported By (optional)',
                  hintText: 'Client contact name, if applicable',
                  border: OutlineInputBorder(),
                ),
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
                        : Text(_isEditMode ? 'Save Changes' : 'Create Ticket'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/tickets'),
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
