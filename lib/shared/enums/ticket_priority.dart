enum TicketPriority { low, medium, high, critical }

extension TicketPriorityX on TicketPriority {
  String get value => switch (this) {
        TicketPriority.low => 'low',
        TicketPriority.medium => 'medium',
        TicketPriority.high => 'high',
        TicketPriority.critical => 'critical',
      };

  String get label => switch (this) {
        TicketPriority.low => 'Low',
        TicketPriority.medium => 'Medium',
        TicketPriority.high => 'High',
        TicketPriority.critical => 'Critical',
      };

  static TicketPriority fromValue(String value) => switch (value) {
        'low' => TicketPriority.low,
        'medium' => TicketPriority.medium,
        'high' => TicketPriority.high,
        'critical' => TicketPriority.critical,
        _ => throw ArgumentError('Unknown priority: $value'),
      };
}