import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app/data/models/destination.dart';

/// Read-only client access to the curated destinations list.
/// Writes happen via the moderation web panel.
///
/// Falls back to [_kSeedDestinations] when the `destinations/*` collection
/// is empty so dev/test always have something to pick. Production seeds
/// the collection from the moderation panel before launch — these defaults
/// match the famous 10 lifestyle resorts/cruises commonly cited in the
/// community and serve as placeholders the client will refine before Week 3
/// ends (PROGRESS_LOG references "client to provide final list").
class DestinationsDatasource {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const List<Destination> _kSeedDestinations = [
    Destination(
      id: 'hedonism_ii',
      name: 'Hedonism II',
      kind: DestinationKind.resort,
      country: 'Jamaica',
      countryCode: 'JM',
      order: 0,
    ),
    Destination(
      id: 'desire_riviera_maya',
      name: 'Desire Riviera Maya',
      kind: DestinationKind.resort,
      country: 'Mexico',
      countryCode: 'MX',
      order: 1,
    ),
    Destination(
      id: 'desire_pearl',
      name: 'Desire Pearl',
      kind: DestinationKind.resort,
      country: 'Mexico',
      countryCode: 'MX',
      order: 2,
    ),
    Destination(
      id: 'temptation_cancun',
      name: 'Temptation Cancun',
      kind: DestinationKind.resort,
      country: 'Mexico',
      countryCode: 'MX',
      order: 3,
    ),
    Destination(
      id: 'cap_dagde',
      name: "Cap d'Agde Naturist Village",
      kind: DestinationKind.resort,
      country: 'France',
      countryCode: 'FR',
      order: 4,
    ),
    Destination(
      id: 'bliss_cruise',
      name: 'Bliss Cruise',
      kind: DestinationKind.cruise,
      country: 'International',
      countryCode: '',
      order: 5,
    ),
    Destination(
      id: 'original_sin_cruise',
      name: 'Original Sin Cruise',
      kind: DestinationKind.cruise,
      country: 'International',
      countryCode: '',
      order: 6,
    ),
    Destination(
      id: 'naughty_in_nawlins',
      name: 'Naughty in N\'Awlins',
      kind: DestinationKind.event,
      country: 'United States',
      countryCode: 'US',
      order: 7,
    ),
    Destination(
      id: 'sdc_takeover',
      name: 'SDC Takeover',
      kind: DestinationKind.event,
      country: 'International',
      countryCode: '',
      order: 8,
    ),
    Destination(
      id: 'lifestyles_convention',
      name: 'Lifestyles Convention',
      kind: DestinationKind.event,
      country: 'United States',
      countryCode: 'US',
      order: 9,
    ),
  ];

  static Future<List<Destination>> getAll() async {
    try {
      final snap =
          await _db.collection('destinations').orderBy('order').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map(Destination.fromDoc).toList();
      }
    } catch (_) {
      // Falls through to seed list — never block UI on a destinations read fail.
    }
    return _kSeedDestinations;
  }

  static Stream<List<Destination>> stream() {
    return _db
        .collection('destinations')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? _kSeedDestinations
            : snap.docs.map(Destination.fromDoc).toList());
  }

  static Future<Destination?> getById(String id) async {
    try {
      final doc = await _db.collection('destinations').doc(id).get();
      if (doc.exists) return Destination.fromDoc(doc);
    } catch (_) {}
    for (final d in _kSeedDestinations) {
      if (d.id == id) return d;
    }
    return null;
  }
}
