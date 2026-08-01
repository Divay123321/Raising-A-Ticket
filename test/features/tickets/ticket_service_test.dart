import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:filoi/features/tickets/services/ticket_service.dart';
import 'package:filoi/features/tickets/models/ticket.dart';
import 'package:filoi/shared/enums/ticket_priority.dart';
import 'package:filoi/shared/enums/ticket_status.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TicketService ticketService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    ticketService = TicketService(firestore: fakeFirestore);
  });

  test('createTicket writes a ticket document with correct fields', () async {
    final ticket = Ticket(
      id: '',
      title: 'Login page broken',
      description: 'Users cannot sign in',
      priority: TicketPriority.high,
      status: TicketStatus.open,
      projectId: 'project123',
      projectName: 'Acme Rollout',
      createdByUid: 'user123',
      createdByName: 'Divay',
    );

    await ticketService.createTicket(ticket);

    final snapshot = await fakeFirestore.collection('tickets').get();
    expect(snapshot.docs.length, 1);
    expect(snapshot.docs.first.data()['title'], 'Login page broken');
  });

  test('createTicket also logs a "created" activity entry', () async {
    final ticket = Ticket(
      id: '',
      title: 'Test ticket',
      description: 'Test',
      priority: TicketPriority.low,
      status: TicketStatus.open,
      projectId: 'project123',
      projectName: 'Acme Rollout',
      createdByUid: 'user123',
      createdByName: 'Divay',
    );

    await ticketService.createTicket(ticket);

    final ticketDoc =
        (await fakeFirestore.collection('tickets').get()).docs.first;
    final activitySnapshot = await fakeFirestore
        .collection('tickets')
        .doc(ticketDoc.id)
        .collection('activity')
        .get();

    expect(activitySnapshot.docs.length, 1);
    expect(activitySnapshot.docs.first.data()['type'], 'created');
  });
  test(
    'changeStatus updates the ticket status and logs a status_change activity',
    () async {
      // First, create a ticket to change the status of.
      final ticket = Ticket(
        id: '',
        title: 'Ticket to update',
        description: 'Test',
        priority: TicketPriority.medium,
        status: TicketStatus.open,
        projectId: 'project123',
        projectName: 'Acme Rollout',
        createdByUid: 'user123',
        createdByName: 'Divay',
      );
      await ticketService.createTicket(ticket);

      final ticketDoc =
          (await fakeFirestore.collection('tickets').get()).docs.first;

      // Now change its status.
      await ticketService.changeStatus(
        ticketId: ticketDoc.id,
        newStatus: 'in_progress',
        actorUid: 'admin456',
        actorName: 'Admin User',
      );

      final updatedDoc = await fakeFirestore
          .collection('tickets')
          .doc(ticketDoc.id)
          .get();
      expect(updatedDoc.data()!['status'], 'in_progress');

      final activitySnapshot = await fakeFirestore
          .collection('tickets')
          .doc(ticketDoc.id)
          .collection('activity')
          .get();

      // Should now have 2 entries: one from creation, one from the status change.
      expect(activitySnapshot.docs.length, 2);
      final statusChangeEntry = activitySnapshot.docs.firstWhere(
        (d) => d.data()['type'] == 'status_change',
      );
      expect(statusChangeEntry.data()['actorName'], 'Admin User');
    },
  );
}
