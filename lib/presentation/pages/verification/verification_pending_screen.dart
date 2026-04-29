import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/data/datasource/couples_datasource.dart';
import 'package:app/data/models/couple.dart';
import 'package:app/data/models/couple_status.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/auth/auth_screen.dart';
import 'package:app/presentation/pages/couples/couples_screen.dart';
import 'package:app/presentation/pages/verification/verification_intro_screen.dart';
import 'package:app/presentation/pages/verification/verification_rejected_screen.dart';

/// Full-screen blocker shown while verification is pending review.
///
/// Listens to the user's couple doc in real time so the moment a moderator
/// approves or rejects, this screen routes appropriately:
///   - approved → CouplesScreen (main feed)
///   - rejected → VerificationRejectedScreen (handles retry vs permanent block)
///   - suspended/under_review → soft block with sign-out option
class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Defensive — should never happen because callers check sign-in first.
      return const AuthScreen();
    }

    return StreamBuilder<Couple?>(
      stream: CouplesDatasource.watchCouple(uid),
      builder: (context, snap) {
        final couple = snap.data;

        // Auto-route on status changes
        if (couple != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            switch (couple.status) {
              case CoupleStatus.approved:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CouplesScreen()),
                  (r) => false,
                );
                break;
              case CoupleStatus.rejected:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerificationRejectedScreen(couple: couple),
                  ),
                  (r) => false,
                );
                break;
              case CoupleStatus.pendingReview:
              case CoupleStatus.suspended:
              case CoupleStatus.underReview:
              case CoupleStatus.pendingDeletion:
                // No transition; remain on this screen (or rendered below).
                break;
            }
          });
        }

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top,
                      size: 64, color: Color(0xFFB01030)),
                  const SizedBox(height: 24),
                  const Text(
                    'Verification in review',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A moderator is reviewing your video. This usually takes '
                    'less than 24 hours. We will notify you the moment a '
                    'decision is made — feel free to close the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
                  ),
                  if (couple?.status == CoupleStatus.suspended ||
                      couple?.status == CoupleStatus.underReview) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE6B800)),
                      ),
                      child: const Text(
                        'Your account is temporarily under additional review. '
                        'Please contact support if this persists more than 48 '
                        'hours.',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF6B5500)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () async {
                      await AuthDatasource.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (r) => false,
                      );
                    },
                    child: const Text(
                      'Sign out',
                      style: TextStyle(color: Color(0xFFB01030)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Re-entry helper — used when a user lands here without an in-flight upload
/// (e.g. they uninstalled and reinstalled). Routes to the intro to start
/// recording again.
class StartVerificationButton extends StatelessWidget {
  final int attemptNumber;
  const StartVerificationButton({super.key, this.attemptNumber = 1});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB01030),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(250),
        ),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VerificationIntroScreen(attemptNumber: attemptNumber),
        ),
      ),
      child: Text(AppLocalizations.of(context)!.startVerification),
    );
  }
}
