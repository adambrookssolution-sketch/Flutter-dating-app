import 'package:cloud_firestore/cloud_firestore.dart';

class CommentData {
  final String id;
  final String uid;
  final String herName;
  final String hisName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;
  final int repliesCount;

  const CommentData({
    required this.id,
    required this.uid,
    required this.herName,
    required this.hisName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
    this.repliesCount = 0,
  });

  factory CommentData.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data()!;
    return CommentData(
      id: doc.id,
      uid: m['uid'] as String? ?? '',
      herName: m['her_name'] as String? ?? '',
      hisName: m['his_name'] as String? ?? '',
      authorPhotoUrl: m['author_photo_url'] as String?,
      text: m['text'] as String? ?? '',
      createdAt: (m['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repliesCount: m['replies_count'] as int? ?? 0,
    );
  }
}
