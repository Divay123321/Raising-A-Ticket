import 'package:flutter/material.dart';
import '../../../shared/enums/project_status.dart';

class ProjectStatusChip extends StatelessWidget {
  final ProjectStatus status;
  const ProjectStatusChip({super.key, required this.status});

  Color _color() => switch (status) {
        ProjectStatus.active => Colors.green,
        ProjectStatus.onHold => Colors.orange,
        ProjectStatus.completed => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}