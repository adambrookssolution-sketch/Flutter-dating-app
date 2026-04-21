import 'package:flutter/material.dart';

import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/data/models/couple.dart';
import 'package:app/presentation/pages/auth/auth_screen.dart';
import 'package:app/presentation/pages/verification/verification_intro_screen.dart';

/// Shown when the moderator rejected the verification video.
///
/// Client spec (2026-04-21): after the first rejection the couple gets two
/// more attempts. On the third rejection the account is permanently locked
/// — the Cloud Function flips status to `suspended` and sets
/// `verification.final_rejection = true`, and we render a dead-end screen
/// with no retry button.
///
/// Branches:
/// - attempts 1–2 AND not flagged final → "try again" CTA loops to
///   [VerificationIntroScreen].
/// - attempts >= 3 OR `final_rejection` flag true → permanent block;
///   only "Contact support" + sign-out are offered.
///
/// The reject reason from the moderation panel is displayed verbatim so the
/// user knows what went wrong (e.g. "El video es poco claro").
class VerificationRejectedScreen extends StatelessWidget {
  final Couple couple;

  const VerificationRejectedScreen({super.key, required this.couple});

  bool get _exhausted {
    final v = couple.verification;
    if (v == null) return false;
    if (v.finalRejection == true) return true;
    return v.attempts >= 3;
  }

  String get _displayReason {
    final r = couple.verification?.rejectReason;
    if (r == null || r.isEmpty) {
      return 'The moderator did not approve the video. Please record a new one '
          'following the on-screen instructions carefully.';
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final attemptsUsed = couple.verification?.attempts ?? 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _exhausted ? Icons.block : Icons.replay,
                size: 64,
                color: const Color(0xFFB31637),
              ),
              const SizedBox(height: 24),
              Text(
                _exhausted
                    ? 'Verification permanently blocked'
                    : 'Verification not approved',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _exhausted
                    ? 'You used all $attemptsUsed of 2 attempts.'
                    : 'Attempt $attemptsUsed of 2 used.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFA4A4AA),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6B800)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason from the moderator',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF6B5500),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _displayReason,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B5500),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!_exhausted) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB31637),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(250),
                      ),
                    ),
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VerificationIntroScreen(
                          attemptNumber: attemptsUsed + 1,
                        ),
                      ),
                      (r) => false,
                    ),
                    child: const Text(
                      'Try again',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(250),
                    ),
                  ),
                  onPressed: () async {
                    await AuthDatasource.signOut();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (r) => false,
                    );
                  },
                  child: Text(
                    _exhausted ? 'Sign out' : 'Sign out for now',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
