enum ProjectStatus { active, onHold, completed }

extension ProjectStatusX on ProjectStatus {
  String get value => switch (this) {
        ProjectStatus.active => 'active',
        ProjectStatus.onHold => 'on_hold',
        ProjectStatus.completed => 'completed',
      };

  String get label => switch (this) {
        ProjectStatus.active => 'Active',
        ProjectStatus.onHold => 'On Hold',
        ProjectStatus.completed => 'Completed',
      };

  static ProjectStatus fromValue(String value) => switch (value) {
        'active' => ProjectStatus.active,
        'on_hold' => ProjectStatus.onHold,
        'completed' => ProjectStatus.completed,
        _ => throw ArgumentError('Unknown status: $value'),
      };
}