// lib/features/employees/services/employee_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/app_user.dart';

class EmployeeService {
  final FirebaseFirestore _firestore;
  EmployeeService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  Stream<List<AppUser>> watchEmployees() async* {
    int attempt = 0;
    while (true) {
      try {
        yield* _collection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.id, doc.data()))
              .toList(),
        );
        return; // stream ended normally (rare for .snapshots(), but handles it cleanly)
      } catch (e) {
        attempt++;
        if (attempt >= 3) {
          rethrow;
        } // genuine failure after 3 tries — let it surface as a real error
        await Future.delayed(
          Duration(milliseconds: 400 * attempt),
        ); // 400ms, then 800ms
      }
    }
  }

  Stream<AppUser?> watchEmployeeById(String uid) async* {
    int attempt = 0;
    while (true) {
      try {
        yield* _collection
            .doc(uid)
            .snapshots()
            .map(
              (doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null,
            );
        return;
      } catch (e) {
        attempt++;
        if (attempt >= 3) rethrow;
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

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
