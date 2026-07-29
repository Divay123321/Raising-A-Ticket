import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/enums/project_status.dart';

class Project {
  final String id;
  final String name;
  final String client;
  final String description;
  final ProjectStatus status;
  final String managerUid;
  final String managerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.name,
    required this.client,
    required this.description,
    required this.status,
    required this.managerUid,
    required this.managerName,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromMap(String id, Map<String, dynamic> map) {
    return Project(
      id: id,
      name: map['name'] as String? ?? '',
      client: map['client'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: ProjectStatusX.fromValue(map['status'] as String? ?? 'active'),
      managerUid: map['managerUid'] as String? ?? '',
      managerName: map['managerName'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'client': client,
      'description': description,
      'status': status.value,
      'managerUid': managerUid,
      'managerName': managerName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}