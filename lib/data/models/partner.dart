/// One half of a couple. Stored as a sub-object inside the `couples` document
/// (never as a separate Firestore document — couple-as-single-entity rule).
///
/// [identity] and [role] are part of the Dynamics-split rework
/// (client design 2026-05-12): on the profile they describe "what represents
/// this partner"; on the filter screen the same fields describe "what you're
/// looking for in the other couple". Both stored as opaque strings against
/// the closed lists in [PartnerIdentities] / [PartnerRoles].
class Partner {
  final String name;
  final String birth; // "DD/MM/YYYY" — kept as string to match legacy schema
  final String height; // "175 cm" or "5'7\""

  /// One of: '', 'Hetero', 'Bi-Curious', 'Bi'.
  final String identity;

  /// One of: '', 'Dom', 'Sub', 'Switch'.
  final String role;

  const Partner({
    required this.name,
    required this.birth,
    required this.height,
    this.identity = '',
    this.role = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'birth': birth,
        'height': height,
        if (identity.isNotEmpty) 'identity': identity,
        if (role.isNotEmpty) 'role': role,
      };

  factory Partner.fromMap(Map<String, dynamic>? m) => Partner(
        name: (m?['name'] as String?) ?? '',
        birth: (m?['birth'] as String?) ?? '',
        height: (m?['height'] as String?) ?? '',
        identity: (m?['identity'] as String?) ?? '',
        role: (m?['role'] as String?) ?? '',
      );

  Partner copyWith({
    String? name,
    String? birth,
    String? height,
    String? identity,
    String? role,
  }) =>
      Partner(
        name: name ?? this.name,
        birth: birth ?? this.birth,
        height: height ?? this.height,
        identity: identity ?? this.identity,
        role: role ?? this.role,
      );
}

/// Closed lists for the Dynamics blocks. Kept as constants so they're the
/// single source of truth for both the profile screen and the filter screen.
class PartnerIdentities {
  static const hetero = 'Hetero';
  static const biCurious = 'Bi-Curious';
  static const bi = 'Bi';
  static const all = <String>[hetero, biCurious, bi];
}

class PartnerRoles {
  static const dom = 'Dom';
  static const sub = 'Sub';
  static const switchRole = 'Switch';
  static const all = <String>[dom, sub, switchRole];
}

class CoupleInteractionTypes {
  static const parallelPlay = 'Parallel Play';
  static const softSwap = 'Soft Swap';
  static const fullSwap = 'Full Swap';
  static const all = <String>[parallelPlay, softSwap, fullSwap];
}

class CoupleExperiences {
  static const sameRoom = 'Same Room';
  static const separateRoom = 'Separate Room';
  static const voyeur = 'Voyeur';
  static const exhibition = 'Exhibition';
  static const all = <String>[sameRoom, separateRoom, voyeur, exhibition];
}

class CoupleDynamicInterests {
  static const mmf = 'MMF';
  static const ffm = 'FFM';
  static const groupPlay = 'Group Play';
  static const bdsm = 'BDSM';
  static const roleplay = 'Roleplay';
  static const all = <String>[mmf, ffm, groupPlay, bdsm, roleplay];

  /// Subset shown on the REGISTRATION / profile-edit screen. Client
  /// feedback 2026-05-25: "eliminar del registro la sección de
  /// intereses tipo MMF, MFM, etc — eso debe quedarse únicamente
  /// dentro de la piña/filtros." MMF and FFM stay available in the
  /// filter sheet (`all`) so couples can still search for them.
  static const forRegistration = <String>[groupPlay, bdsm, roleplay];
}
