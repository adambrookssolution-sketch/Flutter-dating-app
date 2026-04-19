import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMessage {
  final String id;
  final String text;
  final String senderUid;
  final DateTime createdAt;

  const FirestoreMessage({
    required this.id,
    required this.text,
    required this.senderUid,
    required this.createdAt,
  });

  factory FirestoreMessage.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return FirestoreMessage(
      id: doc.id,
      text: data['text'] as String? ?? '',
      senderUid: data['sender_uid'] as String? ?? '',
      // serverTimestamp() can be null briefly while pending — fallback to now
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
