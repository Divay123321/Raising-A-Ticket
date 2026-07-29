enum TicketStatus { open, inProgress, resolved, closed }

extension TicketStatusX on TicketStatus {
  String get value => switch (this) {
        TicketStatus.open => 'open',
        TicketStatus.inProgress => 'in_progress',
        TicketStatus.resolved => 'resolved',
        TicketStatus.closed => 'closed',
      };

  String get label => switch (this) {
        TicketStatus.open => 'Open',
        TicketStatus.inProgress => 'In Progress',
        TicketStatus.resolved => 'Resolved',
        TicketStatus.closed => 'Closed',
      };

  static TicketStatus fromValue(String value) => switch (value) {
        'open' => TicketStatus.open,
        'in_progress' => TicketStatus.inProgress,
        'resolved' => TicketStatus.resolved,
        'closed' => TicketStatus.closed,
        _ => throw ArgumentError('Unknown status: $value'),
      };
}