import 'package:flutter/material.dart';
import '../../../shared/enums/ticket_status.dart';

class TicketStatusChip extends StatelessWidget {
  final TicketStatus status;
  const TicketStatusChip({super.key, required this.status});

  Color _color() => switch (status) {
        TicketStatus.open => Colors.red,
        TicketStatus.inProgress => Colors.orange,
        TicketStatus.resolved => Colors.blue,
        TicketStatus.closed => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}