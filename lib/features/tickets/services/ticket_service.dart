import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/firestore_retry.dart';
import '../models/ticket.dart';

class TicketService {
  final FirebaseFirestore _firestore;
  TicketService({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('tickets');

  Stream<List<Ticket>> watchTickets() => withRetry(
        () => _collection.orderBy('createdAt', descending: true).snapshots().map(
              (snapshot) => snapshot.docs.map((doc) => Ticket.fromMap(doc.id, doc.data())).toList(),
            ),
      );

  Stream<Ticket?> watchTicketById(String id) => withRetry(
        () => _collection.doc(id).snapshots().map(
              (doc) => doc.exists ? Ticket.fromMap(doc.id, doc.data()!) : null,
            ),
      );

  Future<void> createTicket(Ticket ticket) async {
    final data = ticket.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _collection.add(data);
  }

  Future<void> updateTicket(String id, Ticket ticket) async {
    await _collection.doc(id).update(ticket.toMap());
  }

  Future<void> assignEngineer(String ticketId, String engineerUid, String engineerName) async {
    await _collection.doc(ticketId).update({
      'assignedEngineerUid': engineerUid,
      'assignedEngineerName': engineerName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> changeStatus(String ticketId, String newStatus) async {
    await _collection.doc(ticketId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTicket(String id) async {
    await _collection.doc(id).delete();
  }
}