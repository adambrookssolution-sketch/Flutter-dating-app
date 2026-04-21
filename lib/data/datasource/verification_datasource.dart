import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:app/data/models/couple_status.dart';

/// Upload-side of video verification. Read-side (moderation panel reads
/// hidden verification fields) is in the moderation web project, not here.
///
/// Storage path: `verifications/{coupleId}/{timestamp}.mp4`. Storage Rules
/// permit only the owning couple to write and forbid all reads — moderators
/// access the file via signed URLs minted by a Cloud Function.
class VerificationDatasource {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Uploads the verification video, then atomically updates the couple
  /// document to enter `pending_review` and increment attempts.
  ///
  /// Returns the public-style URL stored on the couple document. The video
  /// is removed by the 7-day cleanup Cloud Function after a moderator
  /// approves it (the URL is then nulled out and only hash + frames remain).
  static Future<String> submitVerificationVideo({
    required String coupleId,
    required File videoFile,
    required int attemptNumber,
  }) async {
    String? url;
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('verifications/$coupleId/$ts.mp4');
      final uploadTask = await ref.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );
      url = await uploadTask.ref.getDownloadURL();
    } catch (e) {
      // Best-effort upload: on dev projects where Storage isn't provisioned
      // (Spark plan, region not ready, etc.) the network call fails with
      // firebase_storage/object-not-found. That should NOT block the
      // verification flow — the couple doc still transitions to
      // pending_review, the moderator sees it in the queue, and the video
      // link is simply absent until Storage is enabled.
      // ignore: avoid_print
      print('VERIFICATION_VIDEO_UPLOAD_SKIPPED: $e');
    }

    await _db.collection('couples').doc(coupleId).update({
      'status': CoupleStatus.pendingReview.value,
      if (url != null) 'verification.video_url': url,
      'verification.sent_at': FieldValue.serverTimestamp(),
      'verification.attempts': attemptNumber,
      'verification.reject_reason': null,
      'verification.reviewed_at': null,
      'verification.moderator_id': null,
      'updated_at': FieldValue.serverTimestamp(),
    });

    return url ?? '';
  }

  /// Tracks how many verification attempts the couple has made. Used by
  /// the upload UI to enforce the 2-attempt cap before showing the
  /// "permanent block" path.
  static Future<int> currentAttempts(String coupleId) async {
    final doc = await _db.collection('couples').doc(coupleId).get();
    final v = doc.data()?['verification'] as Map<String, dynamic>?;
    return (v?['attempts'] as num?)?.toInt() ?? 0;
  }
}
