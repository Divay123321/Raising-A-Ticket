import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/firestore_retry.dart';
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

  Future<void> createProject(Project project) async {
    final data = project.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _collection.add(data);
  }

  Future<void> updateProject(String id, Project project) async {
    await _collection.doc(id).update(project.toMap());
  }
}
