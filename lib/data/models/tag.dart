import 'package:cloud_firestore/cloud_firestore.dart';

/// Three independent tag categories drive the three filter groups defined in
/// the design mockup (DECISIONS_LOG Point 4):
/// - dynamics    → strict match (Parallel Play, Soft Swap, Full Swap)
/// - experience  → strict match (Same Room, Separate Rooms, Voyeur, Exhibition)
/// - interests   → 50% threshold match (free-form lifestyle tags)
enum TagCategory {
  dynamics('dynamics'),
  experience('experience'),
  interests('interests');

  const TagCategory(this.value);
  final String value;

  static TagCategory fromString(String? raw) {
    for (final c in TagCategory.values) {
      if (c.value == raw) return c;
    }
    return TagCategory.interests;
  }
}

/// Reference data for filter chips. Stored in `tags/{id}` and managed via
/// moderation panel; clients read-only.
class Tag {
  final String id;
  final String name;
  final TagCategory category;
  final int order;

  const Tag({
    required this.id,
    required this.name,
    this.category = TagCategory.interests,
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category.value,
        'order': order,
      };

  factory Tag.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return Tag(
      id: doc.id,
      name: (m['name'] as String?) ?? '',
      category: TagCategory.fromString(m['category'] as String?),
      order: (m['order'] as num?)?.toInt() ?? 0,
    );
  }
}
