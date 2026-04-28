/// Visual grouping for the unified `interests` field.
///
/// Per the 2026-04-29 client spec, registration / profile / filter all
/// read and write a single flat `interests: [string]` array in Firestore.
/// The UI splits the chips into three labelled blocks for readability;
/// this file is the source of truth for which chip belongs where.
///
/// Casing matters — these strings are persisted as-is. Renaming any
/// without a data migration will orphan existing profiles.
class InterestGroups {
  InterestGroups._();

  static const List<String> tipoDeInteraccion = [
    'Parallel Play',
    'Soft Swap',
    'Full Swap',
  ];

  static const List<String> formaDeExperiencia = [
    'Same Room',
    'Separate Rooms',
    'Voyeur Couple',
    'Exhibition Couple',
  ];

  static const List<String> intereses = [
    'Voyeur',
    'Exhibitionist',
    'Girl Play',
    'BDSM',
    'Bi-curious',
    'Role Play',
    'Dominant',
    'Submissive',
    'Soft Dom',
    'Curious',
  ];

  static List<String> get all => [
        ...tipoDeInteraccion,
        ...formaDeExperiencia,
        ...intereses,
      ];

  /// Returns the group title for [chip], or null if it's a legacy
  /// custom value that doesn't belong to any of the three blocks.
  static String? groupOf(String chip) {
    if (tipoDeInteraccion.contains(chip)) return 'Tipo de interacción';
    if (formaDeExperiencia.contains(chip)) return 'Forma de experiencia';
    if (intereses.contains(chip)) return 'Intereses';
    return null;
  }
}
