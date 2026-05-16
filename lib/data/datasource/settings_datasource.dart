import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsDatasource {
  static const _col = 'settings';

  static Future<String?> getLanguage(String uid) async {
    final doc = await FirebaseFirestore.instance.collection(_col).doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['language'] as String?;
  }

  static Future<void> setLanguage(String uid, String languageCode) async {
    await FirebaseFirestore.instance
        .collection(_col)
        .doc(uid)
        .set({'language': languageCode}, SetOptions(merge: true));
  }
}
