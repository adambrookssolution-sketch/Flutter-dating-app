import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/data/models/comment_data.dart';
import 'package:app/data/models/community_post.dart';
import 'package:app/data/models/reply_data.dart';

class CommunityDatasource {
  static const _col = 'community_posts';

  // ── Create ────────────────────────────────────────────────────────────────

  /// Creates a community post. At least one of [text] or [image] must be
  /// provided. If [image] is given it is uploaded to Firebase Storage first.
  static Future<void> createPost({
    required String uid,
    required String herName,
    required String hisName,
    String? authorPhotoUrl,
    String? text,
    XFile? image,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    log('CommunityDatasource.createPost '
        'uid=$uid '
        'auth.uid=${currentUser?.uid} '
        'isAnonymous=${currentUser?.isAnonymous} '
        'emailVerified=${currentUser?.emailVerified}');
    try {
      String? imageUrl;
      if (image != null) {
        log('Uploading image…');
        final ref = FirebaseStorage.instance.ref().child(
          'community_posts/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(File(image.path));
        imageUrl = await ref.getDownloadURL();
        log('Image uploaded: $imageUrl');
      }

      await FirebaseFirestore.instance.collection(_col).add({
        'uid': uid,
        'her_name': herName,
        'his_name': hisName,
        'author_photo_url': authorPhotoUrl,
        'text': text ?? '',
        'image_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'likes_count': 0,
        'liked_by': <String>[],
      });
      log('Post created successfully');
    } catch (e, st) {
      log('createPost FAILED: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Fetch (newest → oldest) ───────────────────────────────────────────────

  static Future<List<CommunityPost>> fetchPosts() async {
    final snap = await FirebaseFirestore.instance
        .collection(_col)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map(CommunityPost.fromDoc).toList();
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  static Future<void> addComment({
    required String postId,
    required String uid,
    required String herName,
    required String hisName,
    String? authorPhotoUrl,
    required String text,
  }) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    final commentRef =
        db.collection(_col).doc(postId).collection('comments').doc();

    batch.set(commentRef, {
      'uid': uid,
      'her_name': herName,
      'his_name': hisName,
      'author_photo_url': authorPhotoUrl,
      'text': text,
      // Client-side timestamp to avoid null ordering issues in the stream.
      'created_at': Timestamp.fromDate(DateTime.now()),
    });

    batch.update(db.collection(_col).doc(postId), {
      'comments_count': FieldValue.increment(1),
    });

    await batch.commit();
  }

  static Stream<List<CommentData>> streamComments(String postId) {
    return FirebaseFirestore.instance
        .collection(_col)
        .doc(postId)
        .collection('comments')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(CommentData.fromDoc).toList());
  }

  static Future<void> deleteComment(
    String postId,
    String commentId,
  ) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.delete(
      db.collection(_col).doc(postId).collection('comments').doc(commentId),
    );
    batch.update(db.collection(_col).doc(postId), {
      'comments_count': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  // ── Replies ───────────────────────────────────────────────────────────────

  static Future<void> addReply({
    required String postId,
    required String commentId,
    required String uid,
    required String herName,
    required String hisName,
    String? authorPhotoUrl,
    required String text,
    String? replyToName,
    String? replyToUid,
  }) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    final replyRef = db
        .collection(_col)
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc();

    batch.set(replyRef, {
      'uid': uid,
      'her_name': herName,
      'his_name': hisName,
      'author_photo_url': authorPhotoUrl,
      'text': text,
      'created_at': Timestamp.fromDate(DateTime.now()),
      if (replyToName != null) 'reply_to_name': replyToName,
      if (replyToUid != null) 'reply_to_uid': replyToUid,
    });

    batch.update(
      db.collection(_col).doc(postId).collection('comments').doc(commentId),
      {'replies_count': FieldValue.increment(1)},
    );

    await batch.commit();
  }

  static Stream<List<ReplyData>> streamReplies(
      String postId, String commentId) {
    return FirebaseFirestore.instance
        .collection(_col)
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ReplyData.fromDoc).toList());
  }

  static Future<void> deleteReply(
    String postId,
    String commentId,
    String replyId,
  ) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.delete(
      db
          .collection(_col)
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId),
    );
    batch.update(
      db.collection(_col).doc(postId).collection('comments').doc(commentId),
      {'replies_count': FieldValue.increment(-1)},
    );
    await batch.commit();
  }

  // ── Like / Unlike ─────────────────────────────────────────────────────────

  static Future<void> toggleLike(String postId, String uid) async {
    final ref =
        FirebaseFirestore.instance.collection(_col).doc(postId);
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final likedBy =
          List<String>.from(data['liked_by'] as List? ?? []);
      final int count = data['likes_count'] as int? ?? 0;
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
        txn.update(ref, {
          'liked_by': likedBy,
          'likes_count': count > 0 ? count - 1 : 0,
        });
      } else {
        likedBy.add(uid);
        txn.update(ref, {
          'liked_by': likedBy,
          'likes_count': count + 1,
        });
      }
    });
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  static Future<void> deletePost(String postId, String? imageUrl) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {}
    }
    await FirebaseFirestore.instance.collection(_col).doc(postId).delete();
  }
}
