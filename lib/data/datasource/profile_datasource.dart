import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/data/models/user_profile.dart';

class ProfileDatasource {
  static Future<void> createProfile(UserProfile profile) async {
    await FirebaseFirestore.instance
        .collection('profiles')
        .doc(profile.uid)
        .set(profile.toMap());
  }

  static Future<bool> profileExists(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .get();
    return doc.exists;
  }

  static Future<UserProfile?> getProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  @Deprecated(
      'Use getProfilesPage for pagination — getAllProfiles will crash with thousands of docs.')
  static Future<List<UserProfile>> getAllProfiles() async {
    final snap =
        await FirebaseFirestore.instance.collection('profiles').get();
    return snap.docs
        .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Paginated read of the legacy `profiles/*` collection. Returns the next
  /// [limit] docs after [startAfter] (null for the first page).
  ///
  /// Caller is responsible for tracking cursors. When the returned list is
  /// shorter than [limit], the end of the collection has been reached.
  ///
  /// Ordered by document ID (the auth UID) so the cursor is stable across
  /// app restarts — content created mid-scroll still appears on the next
  /// fetch rather than shifting the visible list.
  static Future<({List<UserProfile> items, DocumentSnapshot? cursor})>
      getProfilesPage({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('profiles')
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.get();
    final items = snap.docs
        .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
        .toList();
    return (
      items: items,
      cursor: snap.docs.isEmpty ? null : snap.docs.last,
    );
  }

  static Future<String> uploadPhoto(String uid, XFile file, int index) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profiles/$uid/photo_$index.jpg');
    await ref.putFile(File(file.path));
    return ref.getDownloadURL();
  }
}
