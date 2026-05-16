import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String uid;
  final String herName;
  final String hisName;
  final String text;
  final String? imageUrl;
  final String? authorPhotoUrl;
  final DateTime createdAt;
  final int likesCount;
  final List<String> likedBy;
  final int commentsCount;

  const CommunityPost({
    required this.id,
    required this.uid,
    required this.herName,
    required this.hisName,
    required this.text,
    this.imageUrl,
    this.authorPhotoUrl,
    required this.createdAt,
    required this.likesCount,
    required this.likedBy,
    required this.commentsCount,
  });

  CommunityPost copyWith({
    int? likesCount,
    List<String>? likedBy,
    int? commentsCount,
  }) =>
      CommunityPost(
        id: id,
        uid: uid,
        herName: herName,
        hisName: hisName,
        text: text,
        imageUrl: imageUrl,
        authorPhotoUrl: authorPhotoUrl,
        createdAt: createdAt,
        likesCount: likesCount ?? this.likesCount,
        likedBy: likedBy ?? this.likedBy,
        commentsCount: commentsCount ?? this.commentsCount,
      );

  factory CommunityPost.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data()!;
    return CommunityPost(
      id: doc.id,
      uid: m['uid'] as String? ?? '',
      herName: m['her_name'] as String? ?? '',
      hisName: m['his_name'] as String? ?? '',
      text: m['text'] as String? ?? '',
      imageUrl: m['image_url'] as String?,
      authorPhotoUrl: m['author_photo_url'] as String?,
      createdAt: (m['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: m['likes_count'] as int? ?? 0,
      likedBy: List<String>.from(m['liked_by'] as List? ?? []),
      commentsCount: m['comments_count'] as int? ?? 0,
    );
  }
}
