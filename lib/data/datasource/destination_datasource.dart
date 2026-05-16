import 'package:cloud_firestore/cloud_firestore.dart';

class DestinationDatasource {
  static const _col = 'destinations';

  // Fallback list used when the Firestore collection is empty or unavailable.
  static const List<String> _fallback = [
    'Desire Riviera Maya',
    'Desire Pearl',
    'Desire Cruise',
    'Temptation Cancun',
    'Bliss Cruise',
    'Hedonism II',
    'Secrets Hideaway Resort & Spa',
    'Caliente FL',
    "Cap d'Agde Francia",
    'Venus Start Resort España',
    'Spice LS Resort España',
  ];

  /// Fetches destination names from Firestore, ordered by the `order` field.
  /// Falls back to the hardcoded list if the collection is empty or unavailable.
  static Future<List<String>> fetchDestinations() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_col)
          .orderBy('order')
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((d) => d.data()['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return _fallback;
  }
}
