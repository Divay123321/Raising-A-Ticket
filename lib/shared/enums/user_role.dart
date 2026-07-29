enum UserRole { admin, projectManager, engineer }

extension UserRoleX on UserRole {
  String get value => switch (this) {
        UserRole.admin => 'admin',
        UserRole.projectManager => 'project_manager',
        UserRole.engineer => 'engineer',
      };

  String get label => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.projectManager => 'Project Manager',
        UserRole.engineer => 'Engineer',
      };

  static UserRole fromValue(String value) => switch (value) {
        'admin' => UserRole.admin,
        'project_manager' => UserRole.projectManager,
        'engineer' => UserRole.engineer,
        _ => throw ArgumentError('Unknown role: $value'),
      };
}