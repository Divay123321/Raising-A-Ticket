import 'package:cloud_firestore/cloud_firestore.dart';

class TicketComment {
  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  const TicketComment({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  factory TicketComment.fromMap(String id, Map<String, dynamic> map) {
    return TicketComment(
      id: id,
      authorUid: map['authorUid'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'text': text,
    };
  }
}