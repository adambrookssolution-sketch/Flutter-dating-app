import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app/data/models/trip.dart';

/// CRUD for the per-couple `trips` subcollection.
///
/// Match queries are intentionally NOT here — they require collectionGroup
/// reads + cross-couple privacy filtering and live in the `findMatches`
/// Cloud Function (Week 3). Clients call that callable instead of querying
/// directly so we don't have to expose collectionGroup reads in Security
/// Rules.
class TripsDatasource {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _coll(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('trips');

  static Future<String> addTrip(String coupleId, Trip trip) async {
    final ref = await _coll(coupleId).add(trip.toMap());
    return ref.id;
  }

  static Future<void> updateTrip(
    String coupleId,
    String tripId,
    Map<String, dynamic> updates,
  ) async {
    await _coll(coupleId).doc(tripId).update(updates);
  }

  static Future<void> deleteTrip(String coupleId, String tripId) async {
    await _coll(coupleId).doc(tripId).delete();
  }

  static Stream<List<Trip>> streamTrips(String coupleId) {
    return _coll(coupleId)
        .orderBy('start_date')
        .snapshots()
        .map((snap) => snap.docs.map(Trip.fromDoc).toList());
  }

  static Future<List<Trip>> getUpcomingTrips(String coupleId,
      {DateTime? from}) async {
    final cutoff = from ?? DateTime.now();
    final snap = await _coll(coupleId)
        .where('end_date', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('end_date')
        .get();
    return snap.docs.map(Trip.fromDoc).toList();
  }
}
