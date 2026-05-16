import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMessage {
  final String id;
  final String text;
  /// Image attachment URL (agency feature merged 2026-05-16). Null when
  /// the message is text-only, set when the sender attached a photo via
  /// the chat composer's image picker. Stored in Firestore at the
  /// `image_url` field for backwards-compatibility with the agency's
  /// existing chat documents.
  final String? imageUrl;
  final String senderUid;
  final DateTime createdAt;

  const FirestoreMessage({
    required this.id,
    required this.text,
    this.imageUrl,
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
      imageUrl: data['image_url'] as String?,
      senderUid: data['sender_uid'] as String? ?? '',
      // serverTimestamp() can be null briefly while pending — fallback to now
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
