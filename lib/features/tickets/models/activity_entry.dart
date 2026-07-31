import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { created, edited, statusChanged, assigned }

extension ActivityTypeX on ActivityType {
  String get value => switch (this) {
        ActivityType.created => 'created',
        ActivityType.edited => 'edited',
        ActivityType.statusChanged => 'status_change',
        ActivityType.assigned => 'assignment',
      };

  static ActivityType fromValue(String value) => switch (value) {
        'created' => ActivityType.created,
        'edited' => ActivityType.edited,
        'status_change' => ActivityType.statusChanged,
        'assignment' => ActivityType.assigned,
        _ => ActivityType.edited,
      };
}

class ActivityEntry {
  final String id;
  final ActivityType type;
  final String actorUid;
  final String actorName;
  final String detail;
  final DateTime? timestamp;

  const ActivityEntry({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorName,
    required this.detail,
    this.timestamp,
  });

  factory ActivityEntry.fromMap(String id, Map<String, dynamic> map) {
    return ActivityEntry(
      id: id,
      type: ActivityTypeX.fromValue(map['type'] as String? ?? 'edited'),
      actorUid: map['actorUid'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      detail: map['detail'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'actorUid': actorUid,
      'actorName': actorName,
      'detail': detail,
    };
  }
}