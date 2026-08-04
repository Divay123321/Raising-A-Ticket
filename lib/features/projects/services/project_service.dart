// lib/features/projects/services/project_service.dart — full file
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/firestore_retry.dart';
import '../../tickets/models/activity_entry.dart';
import '../models/project.dart';

class ProjectService {
  final FirebaseFirestore _firestore;
  ProjectService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('projects');

  Stream<List<Project>> watchProjects() => withRetry(
    () => _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Project.fromMap(doc.id, doc.data()))
              .toList(),
        ),
  );

  Stream<Project?> watchProjectById(String id) => withRetry(
    () => _collection
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Project.fromMap(doc.id, doc.data()!) : null),
  );

  Future<void> createProject(
    Project project, {
    required String actorUid,
    required String actorName,
  }) async {
    final data = project.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _collection.add(data);
    await _logActivity(
      projectId: docRef.id,
      type: ActivityType.created,
      actorUid: actorUid,
      actorName: actorName,
      detail: 'Project created',
    );
  }

 // ProjectService.updateProject — detect what changed before logging
Future<void> updateProject(
  String id,
  Project project, {
  required String actorUid,
  required String actorName,
}) async {
  final existingDoc = await _collection.doc(id).get();
  final existing = existingDoc.data();
  final managerChanged = existing != null && existing['managerUid'] != project.managerUid;

  await _collection.doc(id).update(project.toMap());

  await _logActivity(
    projectId: id,
    type: ActivityType.edited,
    actorUid: actorUid,
    actorName: actorName,
    detail: managerChanged
        ? 'Reassigned project manager to ${project.managerName}'
        : 'Project details edited',
  );
}

  Stream<List<ActivityEntry>> watchActivity(String projectId) => withRetry(
    () => _collection
        .doc(projectId)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityEntry.fromMap(doc.id, doc.data()))
              .toList(),
        ),
  );

  Future<void> _logActivity({
    required String projectId,
    required ActivityType type,
    required String actorUid,
    required String actorName,
    required String detail,
  }) async {
    final entry = ActivityEntry(
      id: '',
      type: type,
      actorUid: actorUid,
      actorName: actorName,
      detail: detail,
    );
    final data = entry.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();
    await _collection.doc(projectId).collection('activity').add(data);
  }
}
