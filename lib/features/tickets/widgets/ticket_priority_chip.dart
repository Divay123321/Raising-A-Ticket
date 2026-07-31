import 'package:flutter/material.dart';
import '../../../shared/enums/ticket_priority.dart';

class TicketPriorityChip extends StatelessWidget {
  final TicketPriority priority;
  const TicketPriorityChip({super.key, required this.priority});

  Color _color() => switch (priority) {
        TicketPriority.low => Colors.blueGrey,
        TicketPriority.medium => Colors.blue,
        TicketPriority.high => Colors.orange,
        TicketPriority.critical => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(priority.label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}