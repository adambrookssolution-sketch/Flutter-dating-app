import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/data/models/couple.dart';
import 'package:app/data/models/couple_status.dart';

/// Filter parameters for the discovery feed query. All fields are optional;
/// the datasource applies them progressively (cheap server-side filters
/// first, then in-memory refinements for things Firestore can't express
/// natively).
///
/// [openToUnicorn] / [openToBull] are tri-state: null = no filter, true =
/// require the same flag on the couple. False is intentionally not
/// supported.
class CoupleFilters {
  final double? centerLat;
  final double? centerLng;
  final double radiusKm;
  final List<String> interests; // matching: at least one common element
  final int? minAge;
  final int? maxAge;
  final bool? openToUnicorn;
  final bool? openToBull;

  /// ISO 3166-1 alpha-2 ("MX", "ES", "AR"). Null = any country.
  /// Client request 2026-04-30 (#4): pineapple filter sheet exposes this
  /// alongside the existing geo radius. Country is a discrete filter so
  /// it complements (not replaces) the radius.
  final String? countryCode;

  /// Client request 2026-04-30 (#5): explicit content is hidden by
  /// default; setting this to true returns posts with explicit=true
  /// and hides the rest, behaving like a separate feed.
  final bool showExplicit;

  /// Dynamics-split filter (client design 2026-05-12). These describe what
  /// THIS couple is looking for in the OTHER couple — matched against the
  /// candidate's SELF fields (partner.identity / partner.role /
  /// type_of_interaction / experience / dynamics_interests).
  /// Empty string / empty list means "no constraint on this field".
  /// Subset of [CoupleInteractionTypes] — multi-select since client
  /// feedback 2026-05-15 #6.
  final List<String> lookingForInteraction;
  final List<String> lookingForExperience;
  final List<String> lookingForInterests;
  final String lookingForHerIdentity;
  final String lookingForHimIdentity;
  final String lookingForHerRole;
  final String lookingForHimRole;
  final bool lookingForUnicorn;
  final bool lookingForBull;

  const CoupleFilters({
    this.centerLat,
    this.centerLng,
    this.radiusKm = 200,
    this.interests = const [],
    this.minAge,
    this.maxAge,
    this.openToUnicorn,
    this.openToBull,
    this.countryCode,
    this.showExplicit = false,
    this.lookingForInteraction = const [],
    this.lookingForExperience = const [],
    this.lookingForInterests = const [],
    this.lookingForHerIdentity = '',
    this.lookingForHimIdentity = '',
    this.lookingForHerRole = '',
    this.lookingForHimRole = '',
    this.lookingForUnicorn = false,
    this.lookingForBull = false,
  });

  bool get hasGeo => centerLat != null && centerLng != null;
}

class CouplesDatasource {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Single-couple read by document ID. Returns null when the doc doesn't
  /// exist (a fresh sign-in before profile setup, for example) OR when the
  /// caller lacks permission — treating the read as "no couple doc yet" lets
  /// sign-in fall through to the legacy profile path on environments where
  /// the `couples` collection rules haven't been deployed yet.
  static Future<Couple?> getCouple(String coupleId) async {
    try {
      final doc = await _db.collection('couples').doc(coupleId).get();
      if (!doc.exists) return null;
      return Couple.fromDoc(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  /// Real-time stream of a single couple — used by the verification gate to
  /// know the moment a moderator approves or rejects.
  static Stream<Couple?> watchCouple(String coupleId) {
    return _db.collection('couples').doc(coupleId).snapshots().map(
          (snap) => snap.exists ? Couple.fromDoc(snap) : null,
        );
  }

  /// Whether a couple document exists at all (used as the
  /// "needs profile setup?" check after sign-in).
  static Future<bool> coupleExists(String coupleId) async {
    final doc = await _db.collection('couples').doc(coupleId).get();
    return doc.exists;
  }

  /// Create the initial couple document at the end of profile setup. The
  /// caller is responsible for setting [Couple.status] = `pending_review`
  /// (new accounts) or `approved` (legacy migrated accounts).
  /// Creates a couple doc on initial registration. **Refuses to overwrite
  /// an existing doc** — this is the data-loss guard for the regression
  /// reported 2026-05-23: if the post-sign-in router accidentally lands
  /// an already-approved couple back on ProfileSetupScreen and the user
  /// hits Save, the previous behavior (`.set()`) would clobber their
  /// `status: approved` back to the default `pending_review`. We now
  /// silently skip the write when the doc already exists; the caller is
  /// expected to route the user back to the feed instead.
  ///
  /// Returns true if a new doc was actually created. Callers can branch
  /// on the return to decide where to route after.
  static Future<bool> createCouple(Couple couple) async {
    final ref = _db.collection('couples').doc(couple.id);
    final existing = await ref.get();
    if (existing.exists) {
      // Never overwrite — preserves status, moderation flags, photos
      // already uploaded, etc.
      return false;
    }
    await ref.set(couple.toMap());
    return true;
  }

  /// Partial update — only the keys present in [updates] are touched.
  /// Always re-stamps `updated_at` server-side.
  ///
  /// When the patch includes both `lat` and `lng` and they are non-zero,
  /// also synthesises the nested `geo` map (`{geohash, geopoint}`) that
  /// `geoflutterfire_plus` queries on. This means callers can pass the
  /// flat fields produced by [PlaceResult.toCoupleFields] without having
  /// to know about the geo map convention.
  static Future<void> updateCouple(
    String coupleId,
    Map<String, dynamic> updates,
  ) async {
    final patch = Map<String, dynamic>.from(updates)
      ..['updated_at'] = FieldValue.serverTimestamp();

    final lat = (patch['lat'] as num?)?.toDouble();
    final lng = (patch['lng'] as num?)?.toDouble();
    final geohash = patch['geohash'] as String?;
    if (lat != null && lng != null && (lat != 0 || lng != 0) && geohash != null) {
      patch['geo'] = {
        'geohash': geohash,
        'geopoint': GeoPoint(lat, lng),
      };
    }

    await _db.collection('couples').doc(coupleId).set(
      patch,
      SetOptions(merge: true),
    );
  }

  /// Mark for deletion — sets status + timestamp; the actual data purge is
  /// performed 30 days later by the `executeDeletion` Cloud Function.
  static Future<void> requestDeletion(String coupleId) async {
    await _db.collection('couples').doc(coupleId).update({
      'status': CoupleStatus.pendingDeletion.value,
      'deletion_requested_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel an in-grace-period deletion. Restores the couple to `approved`
  /// (assumes prior status was approved — this is true for the only
  /// transition we currently allow).
  static Future<void> cancelDeletion(String coupleId) async {
    await _db.collection('couples').doc(coupleId).update({
      'status': CoupleStatus.approved.value,
      'deletion_requested_at': null,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Paginated, filtered discovery feed.
  ///
  /// Strategy (DECISIONS_LOG Point 4 — Filter Logic Flow):
  /// 1. Server: WHERE status == approved, optional WHERE country / city.
  /// 2. Server: ORDER BY geohash, paginate with cursor.
  /// 3. Client (in-memory): apply dynamics + experience + interests filters,
  ///    age range, distance refinement, blocked-couple exclusion.
  ///
  /// We deliberately over-fetch by [overFetchMultiplier] to give in-memory
  /// filtering enough material before pagination cursor advances. Tune via
  /// telemetry once we have real users; 3x is a defensible starting default.
  ///
  /// [excludedIds] is a hot exclusion set: self UID + already-conversation
  /// partners + blocked couples. Caller fetches once per session and passes in.
  static Future<List<Couple>> getFilteredCouples({
    required CoupleFilters filters,
    required Set<String> excludedIds,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
    int overFetchMultiplier = 3,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('couples')
        .where('status', isEqualTo: CoupleStatus.approved.value);

    // Server-side narrowing for the boolean openness filters when set —
    // these are cheap composite-index queries with high selectivity.
    if (filters.openToUnicorn == true) {
      q = q.where('open_to_unicorn', isEqualTo: true);
    }
    if (filters.openToBull == true) {
      q = q.where('open_to_bull', isEqualTo: true);
    }
    // Country filter — indexed on country_code (ISO 3166-1 alpha-2).
    if (filters.countryCode != null && filters.countryCode!.isNotEmpty) {
      q = q.where('country_code', isEqualTo: filters.countryCode);
    }
    // Explicit-content gating — when off (default), exclude any couple
    // marked explicit; when on, return only the explicit ones (separate
    // feed per client spec).
    q = q.where('explicit', isEqualTo: filters.showExplicit);

    // Geohash ordering enables proximity-based pagination when geo is set.
    // Without geo we fall back to created_at ordering (stable, unique enough).
    if (filters.hasGeo) {
      q = q.orderBy('geohash');
    } else {
      q = q.orderBy('created_at', descending: true);
    }

    if (startAfter != null) q = q.startAfterDocument(startAfter);
    q = q.limit(limit * overFetchMultiplier);

    final snap = await q.get();
    final raw = snap.docs.map(Couple.fromDoc).toList();

    final filtered = raw.where((c) {
      if (excludedIds.contains(c.id)) return false;
      if (!_passesInterests(c, filters)) return false;
      if (!_passesAge(c, filters)) return false;
      if (!_passesDistance(c, filters)) return false;
      if (!_passesLookingFor(c, filters)) return false;
      return true;
    }).toList();

    // Sort by distance ascending when geo is enabled, otherwise keep the
    // server's created_at ordering.
    if (filters.hasGeo) {
      filtered.sort((a, b) {
        final da = _haversineKm(filters.centerLat!, filters.centerLng!,
            a.lat ?? 0, a.lng ?? 0);
        final db = _haversineKm(filters.centerLat!, filters.centerLng!,
            b.lat ?? 0, b.lng ?? 0);
        return da.compareTo(db);
      });
    }

    return filtered.take(limit).toList();
  }

  // ── Filter predicates (private) ─────────────────────────────────────────

  /// Set intersection — the candidate must share at least one interest.
  static bool _passesInterests(Couple c, CoupleFilters f) {
    if (f.interests.isEmpty) return true;
    return c.interests.any(f.interests.contains);
  }

  static bool _passesAge(Couple c, CoupleFilters f) {
    if (f.minAge == null && f.maxAge == null) return true;
    if (f.maxAge != null && c.ageRange.min > f.maxAge!) return false;
    if (f.minAge != null && c.ageRange.max < f.minAge!) return false;
    return true;
  }

  static bool _passesDistance(Couple c, CoupleFilters f) {
    if (!f.hasGeo) return true;
    if (c.lat == null || c.lng == null) return false;
    return _haversineKm(f.centerLat!, f.centerLng!, c.lat!, c.lng!) <=
        f.radiusKm;
  }

  /// Dynamics-split predicate (client design 2026-05-12). Each lookingFor*
  /// field that is non-empty must be satisfied by the candidate's SELF
  /// field. The match rules:
  ///   • Identity/Role (Her/Him)   — exact string equality on the partner
  ///   • Type of Interaction       — exact match on `type_of_interaction`
  ///   • Experience / Interests    — at least one common element (∩ ≥ 1)
  ///   • Looking-for Unicorn/Bull  — candidate must have the open_to_* flag
  ///
  /// Empty values are "no constraint" and pass automatically.
  static bool _passesLookingFor(Couple c, CoupleFilters f) {
    if (f.lookingForHerIdentity.isNotEmpty &&
        c.partnerA.identity != f.lookingForHerIdentity) {
      return false;
    }
    if (f.lookingForHimIdentity.isNotEmpty &&
        c.partnerB.identity != f.lookingForHimIdentity) {
      return false;
    }
    if (f.lookingForHerRole.isNotEmpty &&
        c.partnerA.role != f.lookingForHerRole) {
      return false;
    }
    if (f.lookingForHimRole.isNotEmpty &&
        c.partnerB.role != f.lookingForHimRole) {
      return false;
    }
    // Multi-select since client feedback 2026-05-15 #6 — match passes
    // when the candidate offers at least one of the requested types.
    if (f.lookingForInteraction.isNotEmpty &&
        !c.typeOfInteraction.any(f.lookingForInteraction.contains)) {
      return false;
    }
    if (f.lookingForExperience.isNotEmpty &&
        !c.experience.any(f.lookingForExperience.contains)) {
      return false;
    }
    if (f.lookingForInterests.isNotEmpty &&
        !c.dynamicsInterests.any(f.lookingForInterests.contains)) {
      return false;
    }
    if (f.lookingForUnicorn && !c.openToUnicorn) return false;
    if (f.lookingForBull && !c.openToBull) return false;
    return true;
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthKm * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  /// Geo-native filtered fetch using `geoflutterfire_plus`.
  ///
  /// Use this for the main discovery feed once `couples/*` has enough
  /// documents with non-null geohash. Returns couples within [radiusKm] of
  /// ([centerLat], [centerLng]), post-filtered in-memory by the same rules
  /// as [getFilteredCouples] (dynamics/experience strict, interests 50%,
  /// blocked-exclusion).
  ///
  /// Unlike [getFilteredCouples] this doesn't support cursor pagination —
  /// `geoflutterfire_plus` returns all hits in the radius in a single query.
  /// For large radii with many hits the caller should tighten the radius or
  /// fall back to [getFilteredCouples]. 200km is a reasonable default for
  /// LATAM lifestyle community density.
  static Future<List<Couple>> getNearbyCouples({
    required double centerLat,
    required double centerLng,
    required Set<String> excludedIds,
    required CoupleFilters filters,
    double radiusKm = 200,
  }) async {
    final center = GeoFirePoint(GeoPoint(centerLat, centerLng));
    // geoflutterfire_plus wraps a CollectionReference (not Query). The geo
    // expansion widens the hit set; we apply status + other filters in
    // memory after the geohash-based narrowing.
    final coll = FirebaseFirestore.instance.collection('couples');

    final snaps = await GeoCollectionReference(coll).fetchWithin(
      center: center,
      radiusInKm: radiusKm,
      field: 'geo', // couples docs will need a `geo: {geohash, geopoint}` map
      geopointFrom: (data) {
        final geo = data['geo'] as Map<String, dynamic>?;
        final gp = geo?['geopoint'] as GeoPoint?;
        return gp ?? const GeoPoint(0, 0);
      },
      strictMode: true,
    );

    final raw = snaps
        .whereType<DocumentSnapshot<Map<String, dynamic>>>()
        .map(Couple.fromDoc)
        .toList();

    return raw.where((c) {
      if (c.status != CoupleStatus.approved) return false;
      if (excludedIds.contains(c.id)) return false;
      if (!_passesInterests(c, filters)) return false;
      if (!_passesAge(c, filters)) return false;
      if (filters.openToUnicorn == true && !c.openToUnicorn) return false;
      if (filters.openToBull == true && !c.openToBull) return false;
      if (filters.countryCode != null &&
          filters.countryCode!.isNotEmpty &&
          c.countryCode.toUpperCase() != filters.countryCode!.toUpperCase()) {
        return false;
      }
      // In-memory explicit gating — Couple.explicit defaults to false on
      // legacy docs, matching the off-by-default behaviour.
      if (filters.showExplicit != c.explicit) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final da = _haversineKm(centerLat, centerLng,
            a.lat ?? 0, a.lng ?? 0);
        final db = _haversineKm(centerLat, centerLng,
            b.lat ?? 0, b.lng ?? 0);
        return da.compareTo(db);
      });
  }

  // ── Photo upload (parallel of legacy uploadPhoto, new path) ─────────────

  /// Uploads a photo to `couples/{coupleId}/photos/photo_{index}.jpg`.
  /// Returns the public download URL.
  static Future<String> uploadPhoto(
    String coupleId,
    XFile file,
    int index,
  ) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('couples/$coupleId/photos/photo_$index.jpg');
    await ref.putFile(File(file.path));
    return ref.getDownloadURL();
  }
}
