// lib/features/employees/services/employee_service.dart — full file
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/firestore_retry.dart';
import '../../auth/models/app_user.dart';
import '../../tickets/models/activity_entry.dart';

class EmployeeService {
  final FirebaseFirestore _firestore;
  EmployeeService({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('users');

  Stream<List<AppUser>> watchEmployees() => withRetry(
        () => _collection.snapshots().map(
              (snapshot) => snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList(),
            ),
      );

  Stream<AppUser?> watchEmployeeById(String uid) => withRetry(
        () => _collection.doc(uid).snapshots().map(
              (doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null,
            ),
      );

  Future<void> updateEmployee({
    required String uid,
    required String role,
    required bool isActive,
    required List<String> skills,
    required String actorUid,
    required String actorName,
  }) async {
    final existingDoc = await _collection.doc(uid).get();
    final existing = existingDoc.data();

    final messages = <String>[];
    if (existing != null) {
      if (existing['role'] != role) {
        messages.add('changed role to $role');
      }
      if (existing['isActive'] != isActive) {
        messages.add(isActive ? 'activated the account' : 'deactivated the account');
      }
      final existingSkills = List<String>.from(existing['skills'] as List? ?? []);
      if (existingSkills.length != skills.length || !existingSkills.toSet().containsAll(skills)) {
        messages.add('updated skills');
      }
    }

    await _collection.doc(uid).update({
      'role': role,
      'isActive': isActive,
      'skills': skills,
    });

    if (messages.isNotEmpty) {
      await _logActivity(
        uid: uid,
        actorUid: actorUid,
        actorName: actorName,
        detail: messages.join(', '),
      );
    }
  }

  Stream<List<ActivityEntry>> watchActivity(String uid) => withRetry(
        () => _collection
            .doc(uid)
            .collection('activity')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) => ActivityEntry.fromMap(doc.id, doc.data())).toList()),
      );

  Future<void> _logActivity({
    required String uid,
    required String actorUid,
    required String actorName,
    required String detail,
  }) async {
    final entry = ActivityEntry(id: '', type: ActivityType.edited, actorUid: actorUid, actorName: actorName, detail: detail);
    final data = entry.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();
    await _collection.doc(uid).collection('activity').add(data);
  }
}