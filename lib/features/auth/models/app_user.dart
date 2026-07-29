import 'package:filoi/shared/enums/user_role.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final List<String> skills;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.skills = const [],
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRoleX.fromValue(map['role'] as String? ?? 'engineer'),
      isActive: map['isActive'] as bool? ?? false,
      skills: List<String>.from(map['skills'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.value,
      'isActive': isActive,
      'skills': skills,
    };
  }
}