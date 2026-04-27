import 'package:cloud_firestore/cloud_firestore.dart';

import 'age_range.dart';
import 'couple_status.dart';
import 'partner.dart';
import 'verification.dart';

/// Single Firestore document per couple — the entire app operates at couple
/// level (`partner_a` and `partner_b` are sub-objects, never separate docs).
///
/// Document ID == Firebase Auth UID (one Auth account per couple in MVP, by
/// client decision). Will eventually decouple from Auth UID in Phase 2 if
/// per-partner login is added.
///
/// Filter strategy:
/// - [dynamics] and [experiencePreferences] use STRICT match (set intersection >= 1)
/// - [interests] uses 50% threshold (configurable, see DECISIONS_LOG Point 4)
class Couple {
  final String id;
  final Partner partnerA;
  final Partner partnerB;

  // Location
  final String city;
  final String country;
  final String countryCode; // ISO 3166-1 alpha-2 ("MX", "ES", "AR")
  final double? lat;
  final double? lng;
  final String? geohash;

  // Profile content
  final String description;
  final List<String> photos;

  // Filter dimensions (three independent arrays)
  final List<String> dynamics;
  final List<String> experiencePreferences;
  final List<String> interests;

  // Lifecycle
  final CoupleStatus status;
  final Verification? verification;
  final AgeRange ageRange;
  final DateTime? deletionRequestedAt; // set when status == pendingDeletion

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Couple({
    required this.id,
    required this.partnerA,
    required this.partnerB,
    this.city = '',
    this.country = '',
    this.countryCode = '',
    this.lat,
    this.lng,
    this.geohash,
    this.description = '',
    this.photos = const [],
    this.dynamics = const [],
    this.experiencePreferences = const [],
    this.interests = const [],
    this.status = CoupleStatus.pendingReview,
    this.verification,
    this.ageRange = const AgeRange(min: 0, max: 0),
    this.deletionRequestedAt,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'partner_a': partnerA.toMap(),
        'partner_b': partnerB.toMap(),
        'city': city,
        'country': country,
        'country_code': countryCode,
        'lat': lat,
        'lng': lng,
        'geohash': geohash,
        'description': description,
        'photos': photos,
        'dynamics': dynamics,
        'experience_preferences': experiencePreferences,
        'interests': interests,
        'status': status.value,
        'verification': verification?.toMap(),
        'age_range': ageRange.toMap(),
        'deletion_requested_at': deletionRequestedAt == null
            ? null
            : Timestamp.fromDate(deletionRequestedAt!),
        'created_at': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'updated_at': FieldValue.serverTimestamp(),
      };

  /// Adapter that accepts BOTH the new schema and the legacy / agency
  /// shape so a single read path works regardless of which collection
  /// the document was written by:
  ///
  ///   • `interests`     — array (new) OR CSV string (legacy)
  ///   • `photos`        — array (new) OR `photos_urls` array (legacy)
  ///   • `verification`  — map (new) OR flat `verification_video_url`
  ///                       + `verification_status` (legacy)
  ///
  /// Unknown / missing fields fall back to safe defaults — never throws.
  /// This is the safety net described in INTEGRATION_GUIDE.md so that
  /// the merge with the agency's phase 2 doesn't blow up the read path.
  factory Couple.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return Couple(
      id: doc.id,
      partnerA: Partner.fromMap(m['partner_a'] as Map<String, dynamic>?),
      partnerB: Partner.fromMap(m['partner_b'] as Map<String, dynamic>?),
      city: (m['city'] as String?) ?? '',
      country: (m['country'] as String?) ?? '',
      countryCode: (m['country_code'] as String?) ?? '',
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      geohash: m['geohash'] as String?,
      description: (m['description'] as String?) ?? '',
      photos: _readPhotos(m),
      dynamics: List<String>.from(m['dynamics'] as List? ?? []),
      experiencePreferences:
          List<String>.from(m['experience_preferences'] as List? ?? []),
      interests: _readInterests(m),
      status: CoupleStatus.fromString(m['status'] as String?),
      verification: _readVerification(m),
      ageRange: AgeRange.fromMap(m['age_range'] as Map<String, dynamic>?),
      deletionRequestedAt:
          (m['deletion_requested_at'] as Timestamp?)?.toDate(),
      createdAt: (m['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (m['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Photos array — accepts new `photos` OR legacy `photos_urls`.
  /// Filters out null and empty strings defensively.
  static List<String> _readPhotos(Map<String, dynamic> m) {
    final raw = (m['photos'] ?? m['photos_urls']) as List?;
    if (raw == null) return const [];
    return raw
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// Interests array — accepts the new array OR a legacy CSV string.
  /// Splitting on comma matches what the migration script does so the
  /// in-memory read is consistent with the eventual migrated shape.
  static List<String> _readInterests(Map<String, dynamic> m) {
    final v = m['interests'];
    if (v is List) return List<String>.from(v);
    if (v is String) {
      return v
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  /// Verification — accepts a structured map OR the legacy flat fields.
  static Verification? _readVerification(Map<String, dynamic> m) {
    final structured = m['verification'];
    if (structured is Map<String, dynamic>) {
      return Verification.fromMap(structured);
    }
    // Legacy flat fields fallback.
    final flatUrl = m['verification_video_url'] as String?;
    final flatStatus = m['verification_status'] as String?;
    if (flatUrl == null && flatStatus == null) return null;
    return Verification.fromMap({
      'video_url': flatUrl,
      'status': flatStatus,
    });
  }

  Couple copyWith({
    Partner? partnerA,
    Partner? partnerB,
    String? city,
    String? country,
    String? countryCode,
    double? lat,
    double? lng,
    String? geohash,
    String? description,
    List<String>? photos,
    List<String>? dynamics,
    List<String>? experiencePreferences,
    List<String>? interests,
    CoupleStatus? status,
    Verification? verification,
    AgeRange? ageRange,
    DateTime? deletionRequestedAt,
    bool clearDeletionRequestedAt = false,
  }) =>
      Couple(
        id: id,
        partnerA: partnerA ?? this.partnerA,
        partnerB: partnerB ?? this.partnerB,
        city: city ?? this.city,
        country: country ?? this.country,
        countryCode: countryCode ?? this.countryCode,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        geohash: geohash ?? this.geohash,
        description: description ?? this.description,
        photos: photos ?? this.photos,
        dynamics: dynamics ?? this.dynamics,
        experiencePreferences:
            experiencePreferences ?? this.experiencePreferences,
        interests: interests ?? this.interests,
        status: status ?? this.status,
        verification: verification ?? this.verification,
        ageRange: ageRange ?? this.ageRange,
        deletionRequestedAt: clearDeletionRequestedAt
            ? null
            : (deletionRequestedAt ?? this.deletionRequestedAt),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
