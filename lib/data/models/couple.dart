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

  // ───── Dynamics split (client design 2026-05-12) ─────
  // On the profile screen these answer "what represents this couple".
  // On the filter screen the parallel `lookingFor*` answer "what is this
  // couple searching for in others".

  /// One of [CoupleInteractionTypes].
  final String typeOfInteraction;

  /// Subset of [CoupleExperiences] (multi-select).
  final List<String> experience;

  /// Subset of [CoupleDynamicInterests] (multi-select). Kept separate from
  /// the legacy [interests] field so the closed-list dynamics block doesn't
  /// collide with any free-form tags that may still live in legacy docs.
  final List<String> dynamicsInterests;

  /// Filter-side: subset of [CoupleInteractionTypes].
  final List<String> lookingForInteraction;

  /// Filter-side: subset of [CoupleExperiences].
  final List<String> lookingForExperience;

  /// Filter-side: subset of [CoupleDynamicInterests].
  final List<String> lookingForInterests;

  /// Filter-side: one of [PartnerIdentities].
  final String lookingForHerIdentity;
  final String lookingForHimIdentity;

  /// Filter-side: one of [PartnerRoles].
  final String lookingForHerRole;
  final String lookingForHimRole;

  /// Open to interacting with a single woman as a third party.
  final bool openToUnicorn;

  /// Open to interacting with a single man as a third party.
  final bool openToBull;

  /// Filter-side: looking for a Unicorn third party.
  final bool lookingForUnicorn;

  /// Filter-side: looking for a Bull third party.
  final bool lookingForBull;

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
    this.typeOfInteraction = '',
    this.experience = const [],
    this.dynamicsInterests = const [],
    this.lookingForInteraction = const [],
    this.lookingForExperience = const [],
    this.lookingForInterests = const [],
    this.lookingForHerIdentity = '',
    this.lookingForHimIdentity = '',
    this.lookingForHerRole = '',
    this.lookingForHimRole = '',
    this.openToUnicorn = false,
    this.openToBull = false,
    this.lookingForUnicorn = false,
    this.lookingForBull = false,
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
        if (typeOfInteraction.isNotEmpty)
          'type_of_interaction': typeOfInteraction,
        if (experience.isNotEmpty) 'experience': experience,
        if (dynamicsInterests.isNotEmpty)
          'dynamics_interests': dynamicsInterests,
        if (lookingForInteraction.isNotEmpty)
          'looking_for_interaction': lookingForInteraction,
        if (lookingForExperience.isNotEmpty)
          'looking_for_experience': lookingForExperience,
        if (lookingForInterests.isNotEmpty)
          'looking_for_interests': lookingForInterests,
        if (lookingForHerIdentity.isNotEmpty)
          'looking_for_her_identity': lookingForHerIdentity,
        if (lookingForHimIdentity.isNotEmpty)
          'looking_for_him_identity': lookingForHimIdentity,
        if (lookingForHerRole.isNotEmpty)
          'looking_for_her_role': lookingForHerRole,
        if (lookingForHimRole.isNotEmpty)
          'looking_for_him_role': lookingForHimRole,
        'open_to_unicorn': openToUnicorn,
        'open_to_bull': openToBull,
        'looking_for_unicorn': lookingForUnicorn,
        'looking_for_bull': lookingForBull,
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
      typeOfInteraction: (m['type_of_interaction'] as String?) ?? '',
      experience: _readStringList(m, 'experience'),
      dynamicsInterests: _readStringList(m, 'dynamics_interests'),
      lookingForInteraction: _readStringList(m, 'looking_for_interaction'),
      lookingForExperience: _readStringList(m, 'looking_for_experience'),
      lookingForInterests: _readStringList(m, 'looking_for_interests'),
      lookingForHerIdentity: (m['looking_for_her_identity'] as String?) ?? '',
      lookingForHimIdentity: (m['looking_for_him_identity'] as String?) ?? '',
      lookingForHerRole: (m['looking_for_her_role'] as String?) ?? '',
      lookingForHimRole: (m['looking_for_him_role'] as String?) ?? '',
      openToUnicorn: m['open_to_unicorn'] as bool? ?? false,
      openToBull: m['open_to_bull'] as bool? ?? false,
      lookingForUnicorn: m['looking_for_unicorn'] as bool? ?? false,
      lookingForBull: m['looking_for_bull'] as bool? ?? false,
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

  static List<String> _readStringList(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is List) {
      return v
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const [];
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
    String? typeOfInteraction,
    List<String>? experience,
    List<String>? dynamicsInterests,
    List<String>? lookingForInteraction,
    List<String>? lookingForExperience,
    List<String>? lookingForInterests,
    String? lookingForHerIdentity,
    String? lookingForHimIdentity,
    String? lookingForHerRole,
    String? lookingForHimRole,
    bool? openToUnicorn,
    bool? openToBull,
    bool? lookingForUnicorn,
    bool? lookingForBull,
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
        typeOfInteraction: typeOfInteraction ?? this.typeOfInteraction,
        experience: experience ?? this.experience,
        dynamicsInterests: dynamicsInterests ?? this.dynamicsInterests,
        lookingForInteraction:
            lookingForInteraction ?? this.lookingForInteraction,
        lookingForExperience:
            lookingForExperience ?? this.lookingForExperience,
        lookingForInterests:
            lookingForInterests ?? this.lookingForInterests,
        lookingForHerIdentity:
            lookingForHerIdentity ?? this.lookingForHerIdentity,
        lookingForHimIdentity:
            lookingForHimIdentity ?? this.lookingForHimIdentity,
        lookingForHerRole: lookingForHerRole ?? this.lookingForHerRole,
        lookingForHimRole: lookingForHimRole ?? this.lookingForHimRole,
        openToUnicorn: openToUnicorn ?? this.openToUnicorn,
        openToBull: openToBull ?? this.openToBull,
        lookingForUnicorn: lookingForUnicorn ?? this.lookingForUnicorn,
        lookingForBull: lookingForBull ?? this.lookingForBull,
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
