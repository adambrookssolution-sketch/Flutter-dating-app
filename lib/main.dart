import 'package:app/presentation/pages/auth/auth_screen.dart';
import 'package:app/presentation/pages/pages.dart';
import 'package:app/presentation/router/app_routes.dart';
import 'package:app/presentation/utils/navigate_after_sign_in.dart';
import 'package:app/providers/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();

  // currentUser is synchronously available after initializeApp when the
  // session was persisted from a previous run.
  final uid = FirebaseAuth.instance.currentUser?.uid;

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MyApp(startUid: uid),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final String? startUid;

  const MyApp({super.key, this.startUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB01030)),
        scaffoldBackgroundColor: Colors.white,
      ),
      routes: AppRoutes.routes,
      home: startUid != null
          ? _ProfileGate(uid: startUid!)
          : const AuthScreen(),
    );
  }
}

/// Shown briefly on restart when the user is already logged in.
/// Checks whether a profile exists then routes to ProfileSetupScreen or
/// CouplesScreen — reusing the same helper used after every sign-in.
class _ProfileGate extends StatefulWidget {
  final String uid;

  const _ProfileGate({required this.uid});

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => navigateAfterSignIn(context, widget.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
