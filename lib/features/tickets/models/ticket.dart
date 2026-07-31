import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/enums/ticket_status.dart';
import '../../../shared/enums/ticket_priority.dart';

class Ticket {
  final String id;
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final String projectId;
  final String projectName;
  final String? assignedEngineerUid;
  final String? assignedEngineerName;
  final String createdByUid;
  final String createdByName;
  final String? reportedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.projectId,
    required this.projectName,
    this.assignedEngineerUid,
    this.assignedEngineerName,
    required this.createdByUid,
    required this.createdByName,
    this.reportedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Ticket.fromMap(String id, Map<String, dynamic> map) {
    return Ticket(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: TicketPriorityX.fromValue(map['priority'] as String? ?? 'medium'),
      status: TicketStatusX.fromValue(map['status'] as String? ?? 'open'),
      projectId: map['projectId'] as String? ?? '',
      projectName: map['projectName'] as String? ?? '',
      assignedEngineerUid: map['assignedEngineerUid'] as String?,
      assignedEngineerName: map['assignedEngineerName'] as String?,
      createdByUid: map['createdByUid'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      reportedBy: map['reportedBy'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': status.value,
      'projectId': projectId,
      'projectName': projectName,
      'assignedEngineerUid': assignedEngineerUid,
      'assignedEngineerName': assignedEngineerName,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'reportedBy': reportedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}