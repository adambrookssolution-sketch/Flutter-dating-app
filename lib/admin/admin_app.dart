import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/admin/pages/admin_login_screen.dart';
import 'package:app/admin/pages/blocks_queue_screen.dart';
import 'package:app/admin/pages/moderation_queue_screen.dart';
import 'package:app/admin/pages/reports_queue_screen.dart';

/// Separate Flutter application for moderators. Built with
/// `flutter build web -t lib/main_admin.dart` and deployed to Firebase
/// Hosting under a distinct site (e.g. `affinity-admin.web.app`).
///
/// Auth gate: requires a Firebase user with the custom claim
/// `moderator: true`. See README in `lib/admin/` for how to mint claims.
///
/// Visual direction (2026-04-28): dark, modern dating-app feel — deep
/// charcoal background with a burgundy → purple accent, premium typography
/// and density that signals "this is a real internal tool", not a demo.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  // Brand palette — kept as static consts so every screen renders the
  // same shade without anyone reading from Theme.of(context).extension.
  static const Color bgDeep = Color(0xFF0E0B14);
  static const Color bgRaised = Color(0xFF161320);
  static const Color bgCard = Color(0xFF1D1A28);
  static const Color line = Color(0xFF2A2638);
  static const Color textPrimary = Color(0xFFF6F3FA);
  static const Color textMuted = Color(0xFF9C95B0);
  static const Color burgundy = Color(0xFFB01030);
  static const Color burgundyLight = Color(0xFFE63757);
  static const Color purple = Color(0xFF5B1280);
  static const Color gold = Color(0xFFC9A24B);
  static const Color success = Color(0xFF3DD68C);
  static const Color danger = Color(0xFFFF5C7A);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: bgDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Affinity — Moderation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDeep,
        canvasColor: bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: burgundy,
          secondary: purple,
          surface: bgCard,
          onSurface: textPrimary,
          error: danger,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
          headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textPrimary),
          bodySmall: TextStyle(color: textMuted),
          labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          labelMedium: TextStyle(color: textMuted, fontWeight: FontWeight.w600, letterSpacing: 1),
          labelSmall: TextStyle(color: textMuted, letterSpacing: 1.2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDeep,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: line),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: line,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgRaised,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: textMuted),
          floatingLabelStyle: const TextStyle(color: burgundyLight),
          hintStyle: const TextStyle(color: textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: burgundyLight, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: burgundy,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: line),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: bgCard,
          contentTextStyle: const TextStyle(color: textPrimary),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: bgCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: burgundyLight,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: textMuted,
          textColor: textPrimary,
        ),
        splashColor: burgundy.withValues(alpha: 0.08),
        highlightColor: burgundy.withValues(alpha: 0.04),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _BootScreen();
          }
          final user = snap.data;
          if (user == null) return const AdminLoginScreen();
          return const _AdminHome();
        },
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AdminApp.burgundy, AdminApp.purple],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.shield_moon_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin shell hosting the three moderation queues as tabs.
/// Client request 2026-04-30 (#6): give moderators visibility over
/// reports and blocks, not just the verification queue.
class _AdminHome extends StatelessWidget {
  const _AdminHome();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AdminApp.bgDeep,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                color: AdminApp.bgDeep,
                child: const TabBar(
                  isScrollable: false,
                  indicatorColor: AdminApp.burgundyLight,
                  indicatorWeight: 3,
                  labelColor: AdminApp.textPrimary,
                  unselectedLabelColor: AdminApp.textMuted,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                  tabs: [
                    Tab(text: 'VERIFICACIONES'),
                    Tab(text: 'REPORTES'),
                    Tab(text: 'BLOQUEOS'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    ModerationQueueScreen(),
                    ReportsQueueScreen(),
                    BlocksQueueScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
