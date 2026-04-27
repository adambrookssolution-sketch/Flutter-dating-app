import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/core/feature_flags.dart';
import 'package:app/core/notifications/fcm_service.dart';

/// Drop-in widget that wires up Gabriel's session-lifecycle hooks
/// without the agency dev having to touch their `main.dart`,
/// `auth_screen.dart`, or sign-out logic.
///
/// What it does:
///   1. Listens to `FirebaseAuth.authStateChanges`.
///   2. When a user signs in → registers FCM token (if enabled).
///   3. When a user signs out → unregisters FCM token + removes the
///      `fcm_tokens/{device}` doc so the previous user stops getting
///      this device's pushes.
///
/// Integration: wrap the `MaterialApp` (or `runApp`'s child) with this:
///
/// ```dart
/// runApp(
///   ProviderScope(
///     child: AffinitySessionListener(
///       child: MyApp(),
///     ),
///   ),
/// );
/// ```
///
/// That's all. No state to manage, no init/dispose to coordinate. If
/// FCM ever causes problems, set
/// [FeatureFlags.fcmEnabled] to `false` and the wrapper becomes a
/// no-op without changing wiring.
class AffinitySessionListener extends StatefulWidget {
  const AffinitySessionListener({super.key, required this.child});

  final Widget child;

  @override
  State<AffinitySessionListener> createState() =>
      _AffinitySessionListenerState();
}

class _AffinitySessionListenerState extends State<AffinitySessionListener> {
  late final Stream<User?> _authStream;
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    _authStream.listen(_handleAuthChange);
  }

  Future<void> _handleAuthChange(User? user) async {
    final uid = user?.uid;
    if (uid == _lastUid) return;
    _lastUid = uid;

    if (!FeatureFlags.fcmEnabled) return;

    try {
      if (uid == null) {
        await FcmService.unregister();
      } else {
        await FcmService.register();
      }
    } catch (_) {
      // FCM failures are non-fatal — a missing token just means this
      // device won't get pushes. The rest of the app keeps working.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
