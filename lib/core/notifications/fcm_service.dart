import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  /// Global ScaffoldMessenger handle so the foreground-message listener
  /// can show a SnackBar without needing a BuildContext. Wired to the
  /// MaterialApp's `scaffoldMessengerKey` in `main.dart`.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Global Navigator handle — used by the foreground SnackBar action
  /// to push the relevant screen when the user taps "Ver" on an
  /// incoming push (e.g. tap a message-push to land in Inbox). Wired
  /// to MaterialApp.navigatorKey in main.dart.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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

      // Foreground listener — FCM only auto-displays a system banner
      // when the app is in the background. When a push lands while
      // the user is actively using the app, the OS hands the payload
      // to `onMessage` and we have to surface it ourselves. We just
      // log it for now; the in-app inbox badge already reflects new
      // messages/requests via the Firestore stream so the user has
      // a real-time signal without an extra banner. Adding a proper
      // in-app banner is a flutter_local_notifications follow-up.
      FirebaseMessaging.onMessage.listen((msg) {
        // ignore: avoid_print
        print('FCM foreground: ${msg.notification?.title ?? "(no title)"}'
            ' / ${msg.notification?.body ?? "(no body)"}');
        // Surface the push as a SnackBar so the user notices new
        // messages / requests / favourites without leaving the app.
        // FCM auto-displays a banner only when the app is in the
        // background; in the foreground we have to do it ourselves.
        final body = msg.notification?.body?.trim();
        final title = msg.notification?.title?.trim();
        if ((body == null || body.isEmpty) &&
            (title == null || title.isEmpty)) return;
        final messenger = messengerKey.currentState;
        if (messenger == null) return;
        // Tap target — message pushes land the user in Inbox, favourite
        // and report-decision land on Profile (closest signal-bearing
        // screen for each). The Cloud Functions stamp `data.kind` so
        // we can dispatch without parsing the body.
        final kind = (msg.data['kind'] as String?) ?? '';
        SnackBarAction? action;
        if (kind == 'message' || kind == 'favorite' ||
            kind == 'report_decision') {
          action = SnackBarAction(
            label: 'Ver',
            textColor: const Color(0xFFFFB3C0),
            onPressed: () => _openOnTap(kind),
          );
        }
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1A0A0E),
              duration: const Duration(seconds: 4),
              action: action,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  if (body != null && body.isNotEmpty)
                    Text(
                      body,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          );
      });
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

  /// Dispatches the SnackBar "Ver" tap to the right screen for each
  /// push kind. We route through the Couples shell so the bottom
  /// nav stays visible — the user lands inside the app's normal
  /// navigation rather than on an orphan stack push.
  static void _openOnTap(String kind) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    switch (kind) {
      case 'message':
        nav.pushNamedAndRemoveUntil('/inbox', (_) => false);
      case 'favorite':
      case 'report_decision':
        nav.pushNamedAndRemoveUntil('/profile', (_) => false);
    }
  }

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
