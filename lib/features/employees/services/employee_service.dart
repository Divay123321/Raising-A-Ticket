import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/firestore_retry.dart';
import '../../auth/models/app_user.dart';

class EmployeeService {
  final FirebaseFirestore _firestore;
  EmployeeService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  Stream<List<AppUser>> watchEmployees() => withRetry(
    () => _collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList(),
    ),
  );

  Stream<AppUser?> watchEmployeeById(String uid) => withRetry(
    () => _collection
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null),
  );

  Future<void> updateEmployee({
    required String uid,
    required String role,
    required bool isActive,
    required List<String> skills,
  }) async {
    await _collection.doc(uid).update({
      'role': role,
      'isActive': isActive,
      'skills': skills,
    });
  }
}
