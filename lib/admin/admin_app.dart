import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/admin/pages/admin_login_screen.dart';
import 'package:app/admin/pages/moderation_queue_screen.dart';

/// Separate Flutter application for moderators. Built with
/// `flutter build web -t lib/main_admin.dart` and deployed to Firebase
/// Hosting under a distinct site (e.g. `affinity-admin.web.app`).
///
/// Auth gate: requires a Firebase user with the custom claim
/// `moderator: true`. See README in `lib/admin/` for how to mint claims.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Affinity — Moderation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB31637)),
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snap.data;
          if (user == null) return const AdminLoginScreen();
          return const ModerationQueueScreen();
        },
      ),
    );
  }
}
