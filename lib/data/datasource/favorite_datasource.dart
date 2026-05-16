import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteDatasource {
  static const String _collection = 'users';
  static const String _subCollection = 'favorites';

  static Future<void> toggleFavorite(String myUid, String favoriteUid) async {
    final ref = FirebaseFirestore.instance
        .collection(_collection)
        .doc(myUid)
        .collection(_subCollection)
        .doc(favoriteUid);

    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'uid': favoriteUid,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<Set<String>> getFavoriteIds(String myUid) async {
    final snap = await FirebaseFirestore.instance
        .collection(_collection)
        .doc(myUid)
        .collection(_subCollection)
        .get();
    return snap.docs.map((doc) => doc.id).toSet();
  }

  static Stream<Set<String>> streamFavoriteIds(String myUid) {
    return FirebaseFirestore.instance
        .collection(_collection)
        .doc(myUid)
        .collection(_subCollection)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }
}
