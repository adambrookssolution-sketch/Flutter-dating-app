import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyData {
  final String id;
  final String uid;
  final String herName;
  final String hisName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;
  final String? replyToName;
  final String? replyToUid;

  const ReplyData({
    required this.id,
    required this.uid,
    required this.herName,
    required this.hisName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
    this.replyToName,
    this.replyToUid,
  });

  factory ReplyData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return ReplyData(
      id: doc.id,
      uid: m['uid'] as String? ?? '',
      herName: m['her_name'] as String? ?? '',
      hisName: m['his_name'] as String? ?? '',
      authorPhotoUrl: m['author_photo_url'] as String?,
      text: m['text'] as String? ?? '',
      createdAt: (m['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replyToName: m['reply_to_name'] as String?,
      replyToUid: m['reply_to_uid'] as String?,
    );
  }
}
