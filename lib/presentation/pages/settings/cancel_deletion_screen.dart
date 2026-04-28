import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/data/datasource/couples_datasource.dart';
import 'package:app/data/models/couple.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/auth/auth_screen.dart';
import 'package:app/presentation/pages/couples/couples_screen.dart';

/// Shown when a user signs in and their couple status is `pending_deletion`.
/// Two paths:
/// - Cancel deletion → status returns to `approved`, normal app access resumes.
/// - Sign out → keep deletion pending; the Cloud Function purges on day 30.
///
/// Wired by [navigateAfterSignIn] (Week 1.6 task d) — that helper checks
/// the couple status before routing to the feed.
class CancelDeletionScreen extends StatefulWidget {
  final Couple couple;

  const CancelDeletionScreen({super.key, required this.couple});

  @override
  State<CancelDeletionScreen> createState() => _CancelDeletionScreenState();
}

class _CancelDeletionScreenState extends State<CancelDeletionScreen> {
  bool _isCancelling = false;

  Future<void> _cancel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isCancelling = true);
    try {
      await CouplesDatasource.cancelDeletion(uid);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CouplesScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotCancelDeletion(e.toString()))),
      );
    }
  }

  Future<void> _keepDeleting() async {
    await AuthDatasource.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  String _daysLeftText() {
    final requested = widget.couple.deletionRequestedAt;
    if (requested == null) return 'within 30 days';
    final daysElapsed = DateTime.now().difference(requested).inDays;
    final remaining = (30 - daysElapsed).clamp(0, 30);
    return remaining == 1 ? '1 day left' : '$remaining days left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_bottom,
                  size: 64, color: Color(0xFFB31637)),
              const SizedBox(height: 24),
              const Text(
                'Your account is scheduled for deletion',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _daysLeftText(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFB31637),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cancel now to restore full access. If you do nothing, your '
                'data is permanently deleted on day 30.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 32),
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
                  onPressed: _isCancelling ? null : _cancel,
                  child: Text(
                    _isCancelling ? 'Working…' : 'Cancel deletion',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _keepDeleting,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(250),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.keepDeletionScheduled),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
