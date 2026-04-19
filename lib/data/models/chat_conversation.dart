import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final List<String> participants;
  final String initiatedBy;
  final String lastMessage;
  final String lastMessageBy;
  final List<String> repliedBy;
  final DateTime? lastMessageTime;
  final DateTime? createdAt;

  const ChatConversation({
    required this.id,
    required this.participants,
    required this.initiatedBy,
    this.lastMessage = '',
    this.lastMessageBy = '',
    this.repliedBy = const [],
    this.lastMessageTime,
    this.createdAt,
  });

  factory ChatConversation.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ChatConversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      initiatedBy: data['initiated_by'] as String? ?? '',
      lastMessage: data['last_message'] as String? ?? '',
      lastMessageBy: data['last_message_by'] as String? ?? '',
      repliedBy: List<String>.from(data['replied_by'] as List? ?? []),
      lastMessageTime: (data['last_message_time'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
