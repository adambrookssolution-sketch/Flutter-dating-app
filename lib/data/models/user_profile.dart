import 'age_range.dart';
import 'couple.dart';
import 'couple_status.dart';
import 'partner.dart';

/// Legacy single-document profile model used by the original `profiles`
/// collection. New code MUST read/write [Couple] from the `couples`
/// collection instead.
///
/// Kept around because pre-migration screens (profile_setup, couples_option,
/// inbox, profile, request_match) still consume it. Removed in Phase 2 once
/// the migration script has run on production data and call sites are
/// updated to [Couple].
@Deprecated('Use Couple (couples collection) instead. Removed in Phase 2.')
class UserProfile {
  final String uid;
  final String herName;
  final String hisName;
  final String herBirth;
  final String hisBirth;
  final String city;
  final String herHeight;
  final String hisHeight;
  final String description;
  final String interests;
  final List<String> photos;

  const UserProfile({
    required this.uid,
    required this.herName,
    required this.hisName,
    required this.herBirth,
    required this.hisBirth,
    required this.city,
    required this.herHeight,
    required this.hisHeight,
    required this.description,
    required this.interests,
    this.photos = const [],
  });

  Map<String, dynamic> toMap() => {
        'her_name': herName,
        'his_name': hisName,
        'her_birth': herBirth,
        'his_birth': hisBirth,
        'city': city,
        'her_height': herHeight,
        'his_height': hisHeight,
        'description': description,
        'interests': interests,
        'photos': photos,
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) =>
      UserProfile(
        uid: uid,
        herName: m['her_name'] as String? ?? '',
        hisName: m['his_name'] as String? ?? '',
        herBirth: m['her_birth'] as String? ?? '',
        hisBirth: m['his_birth'] as String? ?? '',
        city: m['city'] as String? ?? '',
        herHeight: m['her_height'] as String? ?? '',
        hisHeight: m['his_height'] as String? ?? '',
        description: m['description'] as String? ?? '',
        interests: m['interests'] as String? ?? '',
        photos: List<String>.from(m['photos'] as List? ?? []),
      );

  /// Best-effort conversion to the new [Couple] schema. Used by the migration
  /// script (Week 1.2) and as a fallback when reading legacy docs during
  /// the transition window.
  ///
  /// Lossy by necessity:
  /// - [city] keeps the legacy string but lat/lng/geohash/country need to be
  ///   geocoded by the caller (we don't do network I/O in a model).
  /// - [interests] CSV is split into the `interests` array only — the
  ///   `dynamics` and `experience_preferences` arrays start empty because
  ///   the legacy data has no way to distinguish them. Users will fill them
  ///   on next profile edit.
  /// - [status] defaults to `approved` (existing users are grandfathered).
  Couple toCouple() => Couple(
        id: uid,
        partnerA: Partner(name: herName, birth: herBirth, height: herHeight),
        partnerB: Partner(name: hisName, birth: hisBirth, height: hisHeight),
        city: city,
        description: description,
        photos: photos,
        interests: _splitCsv(interests),
        status: CoupleStatus.approved,
        ageRange: AgeRange.fromBirths(herBirth, hisBirth),
      );

  static List<String> _splitCsv(String csv) => csv
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
