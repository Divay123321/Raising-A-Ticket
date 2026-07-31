import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ticket_providers.dart';
import 'ticket_form_screen.dart';

class TicketEditLoader extends ConsumerWidget {
  final String ticketId;
  const TicketEditLoader({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketByIdProvider(ticketId));

    return ticketAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Failed to load ticket: $err')),
      data: (ticket) {
        if (ticket == null) return const Center(child: Text('Ticket not found.'));
        return TicketFormScreen(existingTicket: ticket);
      },
    );
  }
}