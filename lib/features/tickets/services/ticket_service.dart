import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/firestore_retry.dart';
import '../models/ticket.dart';
import '../models/ticket_comment.dart';
import '../models/activity_entry.dart';

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
    final docRef = await _collection.add(data);
    await _logActivity(
      ticketId: docRef.id,
      type: ActivityType.created,
      actorUid: ticket.createdByUid,
      actorName: ticket.createdByName,
      detail: 'Ticket created',
    );
  }

  Future<void> updateTicket(String id, Ticket ticket, {required String actorUid, required String actorName}) async {
    await _collection.doc(id).update(ticket.toMap());
    await _logActivity(
      ticketId: id,
      type: ActivityType.edited,
      actorUid: actorUid,
      actorName: actorName,
      detail: 'Ticket details edited',
    );
  }

  Future<void> assignEngineer({
    required String ticketId,
    required String engineerUid,
    required String engineerName,
    required String actorUid,
    required String actorName,
  }) async {
    await _collection.doc(ticketId).update({
      'assignedEngineerUid': engineerUid,
      'assignedEngineerName': engineerName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logActivity(
      ticketId: ticketId,
      type: ActivityType.assigned,
      actorUid: actorUid,
      actorName: actorName,
      detail: 'Assigned to $engineerName',
    );
  }

  Future<void> changeStatus({
    required String ticketId,
    required String newStatus,
    required String actorUid,
    required String actorName,
  }) async {
    await _collection.doc(ticketId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logActivity(
      ticketId: ticketId,
      type: ActivityType.statusChanged,
      actorUid: actorUid,
      actorName: actorName,
      detail: 'Status changed to $newStatus',
    );
  }

  Future<void> deleteTicket(String id) async {
    await _collection.doc(id).delete();
  }

  // --- Comments subcollection ---

  Stream<List<TicketComment>> watchComments(String ticketId) => withRetry(
        () => _collection
            .doc(ticketId)
            .collection('comments')
            .orderBy('createdAt', descending: false)
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) => TicketComment.fromMap(doc.id, doc.data())).toList()),
      );

  Future<void> addComment(String ticketId, TicketComment comment) async {
    final data = comment.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _collection.doc(ticketId).collection('comments').add(data);
  }

  // --- Activity subcollection ---

  Stream<List<ActivityEntry>> watchActivity(String ticketId) => withRetry(
        () => _collection
            .doc(ticketId)
            .collection('activity')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) => ActivityEntry.fromMap(doc.id, doc.data())).toList()),
      );

  Future<void> _logActivity({
    required String ticketId,
    required ActivityType type,
    required String actorUid,
    required String actorName,
    required String detail,
  }) async {
    final entry = ActivityEntry(id: '', type: type, actorUid: actorUid, actorName: actorName, detail: detail);
    final data = entry.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();
    await _collection.doc(ticketId).collection('activity').add(data);
  }
}