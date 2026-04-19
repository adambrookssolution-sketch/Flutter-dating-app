import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks a couple's manual video verification lifecycle.
///
/// Retention rule: [videoUrl] is non-null only for the first 7 days after
/// [reviewedAt]; a scheduled Cloud Function then deletes the video file and
/// nulls this field, while [videoHash] and [videoFrames] are kept forever as
/// the auditable permanent record.
///
/// [attempts] caps at 2 — a third rejection means permanent block (Point 1
/// final decision in DECISIONS_LOG).
class Verification {
  final String? videoUrl;
  final DateTime? sentAt;
  final DateTime? reviewedAt;
  final String? moderatorId;
  final String? rejectReason;
  final int attempts;
  final String? videoHash;
  final List<String> videoFrames;

  const Verification({
    this.videoUrl,
    this.sentAt,
    this.reviewedAt,
    this.moderatorId,
    this.rejectReason,
    this.attempts = 0,
    this.videoHash,
    this.videoFrames = const [],
  });

  Map<String, dynamic> toMap() => {
        'video_url': videoUrl,
        'sent_at': sentAt == null ? null : Timestamp.fromDate(sentAt!),
        'reviewed_at':
            reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
        'moderator_id': moderatorId,
        'reject_reason': rejectReason,
        'attempts': attempts,
        'video_hash': videoHash,
        'video_frames': videoFrames,
      };

  factory Verification.fromMap(Map<String, dynamic>? m) => Verification(
        videoUrl: m?['video_url'] as String?,
        sentAt: (m?['sent_at'] as Timestamp?)?.toDate(),
        reviewedAt: (m?['reviewed_at'] as Timestamp?)?.toDate(),
        moderatorId: m?['moderator_id'] as String?,
        rejectReason: m?['reject_reason'] as String?,
        attempts: (m?['attempts'] as num?)?.toInt() ?? 0,
        videoHash: m?['video_hash'] as String?,
        videoFrames: List<String>.from(m?['video_frames'] as List? ?? []),
      );

  Verification copyWith({
    String? videoUrl,
    bool clearVideoUrl = false,
    DateTime? sentAt,
    DateTime? reviewedAt,
    String? moderatorId,
    String? rejectReason,
    int? attempts,
    String? videoHash,
    List<String>? videoFrames,
  }) =>
      Verification(
        videoUrl: clearVideoUrl ? null : (videoUrl ?? this.videoUrl),
        sentAt: sentAt ?? this.sentAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        moderatorId: moderatorId ?? this.moderatorId,
        rejectReason: rejectReason ?? this.rejectReason,
        attempts: attempts ?? this.attempts,
        videoHash: videoHash ?? this.videoHash,
        videoFrames: videoFrames ?? this.videoFrames,
      );
}
