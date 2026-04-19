import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app/data/models/tag.dart';

/// Reads tags grouped by [TagCategory] for the three-section filter UI.
///
/// Schema (current — extended in Week 1.3):
///   tags/{id}: { name: string, category: "dynamics"|"experience"|"interests", order: number }
///
/// Falls back to [_kLifestyleDefaults] when the collection is empty (initial
/// dev setup) so the UI is never broken by missing seed data. Production
/// must seed the collection — the moderation panel does this on first boot.
class TagsDatasource {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Lifestyle-specific defaults sourced from the design mockup
  /// (DECISIONS_LOG Point 4). Final wording + Spanish localisation will be
  /// confirmed by the client before Week 3 — these are placeholders that
  /// produce a usable UI in dev.
  static const Map<TagCategory, List<String>> _kLifestyleDefaults = {
    TagCategory.dynamics: [
      'Parallel Play',
      'Soft Swap',
      'Full Swap',
    ],
    TagCategory.experience: [
      'Same Room',
      'Separate Rooms',
      'Voyeur Couple',
      'Exhibition Couple',
    ],
    TagCategory.interests: [
      'Voyeur',
      'Exhibitionist',
      'Kinky',
      'Hot Wife',
      'Curious',
      'Vanilla',
      'Travel',
      'Foodies',
      'Adventure',
      'Night Life',
    ],
  };

  /// Fetches every tag in the requested [category], ordered.
  /// Returns the in-code defaults when the collection has no docs for the
  /// requested category yet.
  static Future<List<Tag>> getByCategory(TagCategory category) async {
    try {
      final snap = await _db
          .collection('tags')
          .where('category', isEqualTo: category.value)
          .orderBy('order')
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map(Tag.fromDoc).toList();
      }
    } catch (_) {
      // Falls through to defaults — never block the UI on a tags read failure.
    }
    return _defaultsFor(category);
  }

  /// All tags across all categories, for the legacy profile_setup screen
  /// which currently uses one flat chip list. Keeps backward compat until
  /// Week 3 splits the UI into three groups.
  static Future<List<String>> getAllNamesFlat() async {
    try {
      final snap = await _db.collection('tags').orderBy('order').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((d) => (d.data()['name'] as String?) ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Falls through to defaults.
    }
    return [
      ..._kLifestyleDefaults[TagCategory.dynamics]!,
      ..._kLifestyleDefaults[TagCategory.experience]!,
      ..._kLifestyleDefaults[TagCategory.interests]!,
    ];
  }

  /// Backward-compatibility alias for the legacy call site
  /// (profile_setup_screen). New code should call [getByCategory] instead.
  @Deprecated('Use getByCategory(TagCategory.interests) or getAllNamesFlat()')
  static Future<List<String>> getTags() => getAllNamesFlat();

  static List<Tag> _defaultsFor(TagCategory cat) {
    final names = _kLifestyleDefaults[cat] ?? const <String>[];
    return [
      for (var i = 0; i < names.length; i++)
        Tag(id: '${cat.value}_$i', name: names[i], category: cat, order: i),
    ];
  }
}
