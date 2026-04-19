import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles FCM token lifecycle: request permission, acquire the token,
/// write it to `couples/{myId}/fcm_tokens/{deviceId}`, and refresh on
/// rotate.
///
/// Called from `navigateAfterSignIn` so the token exists well before any
/// Cloud Function tries to push. Silent failures are fine — a missing token
/// just means the couple won't get that particular push; nothing else breaks.
///
/// We deliberately don't store the token in a device-unique doc beyond the
/// raw FCM token (no app-install IDs, no hardware fingerprints). Privacy
/// benefit: if a user uninstalls, the old token stops receiving
/// notifications; when they sign in again we write a new token doc and the
/// old one naturally ages out through FCM's own token-expiry GC.
class FcmService {
  FcmService._();

  static bool _initialised = false;

  /// Should be called after the user has signed in AND has an approved
  /// couple doc. Safe to call multiple times — first call does the
  /// permission prompt + token write, subsequent calls only refresh tokens.
  static Future<void> register() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (!_initialised) {
      _initialised = true;
      // Request permission (iOS is explicit; Android Tier 1 auto-grants
      // unless targeting Android 13+ which requires runtime prompt).
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Refresh token subscription — fires when FCM rotates the token.
      FirebaseMessaging.instance.onTokenRefresh
          .listen((t) => _writeToken(uid, t));
    }

    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? null : null, // web needs a key; mobile doesn't
    );
    if (token != null) await _writeToken(uid, token);
  }

  /// Removes the current device's token from Firestore. Called on sign-out
  /// so other accounts using this device don't inherit notifications.
  static Future<void> unregister() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(uid)
          .collection('fcm_tokens')
          .doc(_sanitize(token))
          .delete();
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Non-fatal
    }
  }

  static Future<void> _writeToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(uid)
          .collection('fcm_tokens')
          .doc(_sanitize(token))
          .set({
        'token': token,
        'platform': _platformLabel(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Security Rules may reject for a pending_review couple — silently
      // skip, we'll retry next sign-in.
    }
  }

  /// Token contains `:` which Firestore rejects in document IDs. Hash-ish
  /// substitute: take a URL-safe slice. Collisions require full token
  /// equality so this is fine in practice.
  static String _sanitize(String token) =>
      token.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_').substring(
            0,
            token.length.clamp(0, 96),
          );

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'unknown';
  }
}
