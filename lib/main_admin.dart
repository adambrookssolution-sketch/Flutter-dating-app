import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:app/admin/admin_app.dart';
import 'package:app/firebase_options.dart';

/// Entry point for the moderator-facing web app.
///
/// Run locally: `flutter run -d chrome -t lib/main_admin.dart`
/// Build:       `flutter build web -t lib/main_admin.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}
