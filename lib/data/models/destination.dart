import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of lifestyle destination — enables filtered Travel Match
/// (e.g. "show me cruise matches only").
enum DestinationKind {
  resort('resort'),
  cruise('cruise'),
  event('event');

  const DestinationKind(this.value);
  final String value;

  static DestinationKind fromString(String? raw) {
    for (final k in DestinationKind.values) {
      if (k.value == raw) return k;
    }
    return DestinationKind.resort;
  }
}

/// One of the ~10 predefined lifestyle Resorts/Cruises the client supplies
/// before Week 3. Stored in `destinations/{id}` and managed via the
/// moderation web panel — never user-editable.
class Destination {
  final String id;
  final String name;
  final DestinationKind kind;
  final String country;
  final String countryCode;
  final String? imageUrl;
  final int order;

  const Destination({
    required this.id,
    required this.name,
    this.kind = DestinationKind.resort,
    this.country = '',
    this.countryCode = '',
    this.imageUrl,
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'kind': kind.value,
        'country': country,
        'country_code': countryCode,
        'image_url': imageUrl,
        'order': order,
      };

  factory Destination.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return Destination(
      id: doc.id,
      name: (m['name'] as String?) ?? '',
      kind: DestinationKind.fromString(m['kind'] as String?),
      country: (m['country'] as String?) ?? '',
      countryCode: (m['country_code'] as String?) ?? '',
      imageUrl: m['image_url'] as String?,
      order: (m['order'] as num?)?.toInt() ?? 0,
    );
  }
}
