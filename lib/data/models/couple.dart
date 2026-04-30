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
/// All matching tags live in a single flat `interests` array. The
/// three visual blocks come from [InterestGroups] at render time.
/// "Apertura de la pareja" is two independent booleans
/// ([openToUnicorn], [openToBull]) so they can be queried directly.
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

  final List<String> interests;

  /// Open to interacting with a single woman as a third party.
  final bool openToUnicorn;

  /// Open to interacting with a single man as a third party.
  final bool openToBull;

  /// Client request 2026-04-30 (#5): when true, the couple's content is
  /// classified explicit and only appears for users who opt into the
  /// explicit feed. Defaults to false.
  final bool explicit;

  /// Client request 2026-04-30 (#2): IETF language tag the couple speaks
  /// ("es", "en"). Used to bias the discovery feed so users browsing in
  /// English see English-speaking couples first. Empty string = unknown
  /// (legacy docs without the field) — those still appear, just not
  /// preferentially in either bucket.
  final String language;

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
    this.interests = const [],
    this.openToUnicorn = false,
    this.openToBull = false,
    this.explicit = false,
    this.language = '',
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
        'interests': interests,
        'open_to_unicorn': openToUnicorn,
        'open_to_bull': openToBull,
        'explicit': explicit,
        'language': language,
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

  /// Reads new and legacy shapes:
  ///   - `interests`: array, CSV string, or split `dynamics +
  ///     experience_preferences + interests` arrays
  ///   - `photos`: `photos` or `photos_urls`
  ///   - `verification`: map, or flat `verification_video_url` +
  ///     `verification_status`
  ///   - `open_to_unicorn` / `open_to_bull` default to false when absent
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
      interests: _readInterests(m),
      openToUnicorn: m['open_to_unicorn'] as bool? ?? false,
      openToBull: m['open_to_bull'] as bool? ?? false,
      explicit: m['explicit'] as bool? ?? false,
      language: (m['language'] as String?) ?? '',
      status: CoupleStatus.fromString(m['status'] as String?),
      verification: _readVerification(m),
      ageRange: AgeRange.fromMap(m['age_range'] as Map<String, dynamic>?),
      deletionRequestedAt:
          (m['deletion_requested_at'] as Timestamp?)?.toDate(),
      createdAt: (m['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (m['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  static List<String> _readPhotos(Map<String, dynamic> m) {
    final raw = (m['photos'] ?? m['photos_urls']) as List?;
    if (raw == null) return const [];
    return raw
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// Reads `interests` as array, CSV string, or — for pre-2026-04-29
  /// docs — concatenates the legacy `dynamics` and
  /// `experience_preferences` arrays.
  static List<String> _readInterests(Map<String, dynamic> m) {
    final v = m['interests'];
    if (v is List && v.isNotEmpty) {
      return v.whereType<String>().toList(growable: false);
    }
    if (v is String && v.trim().isNotEmpty) {
      return v
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }
    final dynamics = (m['dynamics'] as List?)?.whereType<String>() ?? const [];
    final experience =
        (m['experience_preferences'] as List?)?.whereType<String>() ??
            const [];
    if (dynamics.isNotEmpty || experience.isNotEmpty) {
      return [...dynamics, ...experience].toList(growable: false);
    }
    return const [];
  }

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
    List<String>? interests,
    bool? openToUnicorn,
    bool? openToBull,
    bool? explicit,
    String? language,
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
        interests: interests ?? this.interests,
        openToUnicorn: openToUnicorn ?? this.openToUnicorn,
        openToBull: openToBull ?? this.openToBull,
        explicit: explicit ?? this.explicit,
        language: language ?? this.language,
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
