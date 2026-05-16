import 'package:app/data/models/chat_conversation.dart';
import 'package:app/data/models/firestore_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationDatasource {
  static String _docId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  // ── Conversations ──────────────────────────────────────────────────────────

  /// Returns the UIDs of every user that already has a conversation with [myUid].
  static Future<Set<String>> getConversationPartnerIds(String myUid) async {
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .get();

    final result = <String>{};
    for (final doc in snap.docs) {
      final participants =
          List<String>.from(doc.data()['participants'] as List? ?? []);
      for (final uid in participants) {
        if (uid != myUid) result.add(uid);
      }
    }
    return result;
  }

  /// Returns all conversations that include [myUid] as a participant (one-time).
  static Future<List<ChatConversation>> getConversations(String myUid) async {
    final snap = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .get();
    return snap.docs.map(ChatConversation.fromDoc).toList();
  }

  /// Real-time count of pending conversation requests for [myUid]:
  /// conversations initiated by someone else that [myUid] hasn't yet
  /// replied to. Drives the badge on the inbox tab.
  ///
  /// Sourced from the agency's ConversationDatasource during the
  /// 2026-05-16 merge — the inbox/request UI relies on this counter
  /// to surface unread request invitations.
  static Stream<int> pendingRequestsStream(String myUid) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .snapshots()
        .map((snap) => snap.docs.where((doc) {
              final data = doc.data();
              final initiatedBy = data['initiated_by'] as String? ?? '';
              final repliedBy =
                  List<String>.from(data['replied_by'] as List? ?? []);
              return initiatedBy != myUid && !repliedBy.contains(myUid);
            }).length);
  }

  /// Real-time stream of all conversations that include [myUid],
  /// ordered by most-recently-updated first.
  static Stream<List<ChatConversation>> conversationsStream(String myUid) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatConversation.fromDoc).toList());
  }

  /// Creates a conversation document. [myUid] is recorded as the initiator.
  /// Returns the conversation document ID.
  static Future<String> createConversation(
    String myUid,
    String otherUid,
  ) async {
    final docId = _docId(myUid, otherUid);
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(docId)
        .set({
      'participants': [myUid, otherUid],
      'initiated_by': myUid,
      'created_at': FieldValue.serverTimestamp(),
    });
    return docId;
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  /// Real-time stream of messages for [conversationId], ordered by time.
  static Stream<List<FirestoreMessage>> messagesStream(
    String conversationId,
  ) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('created_at')
        .snapshots()
        .map((snap) => snap.docs.map(FirestoreMessage.fromDoc).toList());
  }

  /// Marks a conversation as accepted by [myUid] without sending a message.
  /// Adds [myUid] to the `replied_by` array on the conversation document.
  static Future<void> acceptRequest(
    String conversationId,
    String myUid,
  ) async {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .update({
      'replied_by': FieldValue.arrayUnion([myUid]),
    });
  }

  /// Saves a message and updates the denormalized last_message on the
  /// conversation document in a single batch write.
  static Future<void> sendMessage(
    String conversationId,
    String senderUid,
    String text,
  ) async {
    final db = FirebaseFirestore.instance;
    final convRef = db.collection('conversations').doc(conversationId);
    final msgRef = convRef.collection('messages').doc();

    final batch = db.batch();
    batch.set(msgRef, {
      'text': text,
      'sender_uid': senderUid,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.update(convRef, {
      'last_message': text,
      'last_message_time': FieldValue.serverTimestamp(),
      'last_message_by': senderUid,
      'replied_by': FieldValue.arrayUnion([senderUid]),
    });
    await batch.commit();
  }
}
