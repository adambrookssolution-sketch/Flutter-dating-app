import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/data/datasource/couples_datasource.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/auth/auth_screen.dart';

/// Mandatory Apple-policy screen: explains what deletion means, requires
/// the user to acknowledge permanence with a checkbox, and only then enables
/// the red confirmation button.
///
/// Behaviour (DECISIONS_LOG Point 3):
/// - Account immediately invisible to other users (status=pending_deletion).
/// - 30-day grace: user can sign back in and cancel via [CancelDeletionScreen].
/// - On day 30 a Cloud Function performs the atomic purge.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _acknowledged = false;
  bool _isSubmitting = false;

  Future<void> _confirm() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isSubmitting = true);
    try {
      await CouplesDatasource.requestDeletion(uid);
      // Sign out so other devices stop seeing the account immediately.
      await AuthDatasource.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const _DeletionPendingNoticeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotRequestDeletion(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deleteAccountTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are about to delete your couple account.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._consequences.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(c, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
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
              child: const Text(
                'You have 30 days to change your mind. Sign back in any time '
                'before then to cancel deletion. After 30 days, all data is '
                'erased permanently and cannot be recovered.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _acknowledged,
              onChanged: _isSubmitting
                  ? null
                  : (v) => setState(() => _acknowledged = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I understand this is permanent after 30 days.',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD0D0D0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(250),
                  ),
                ),
                onPressed:
                    (!_acknowledged || _isSubmitting) ? null : _confirm,
                child: Text(
                  _isSubmitting ? 'Working…' : 'Delete account',
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
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(250),
                  ),
                ),
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _consequences = [
    'Hide your couple profile from everyone immediately',
    'Stop incoming Requests and Travel Match alerts',
    'Delete your photos, verification video, and all profile data after 30 days',
    'Erase your conversations from your inbox (other couples see "deleted user")',
    'Cancel any pending Trips and Requests',
  ];
}

/// Final notice shown after the user requests deletion. Sends them back to
/// the Auth screen — if they sign in within 30 days they'll see the
/// CancelDeletionScreen instead of the normal feed.
class _DeletionPendingNoticeScreen extends StatelessWidget {
  const _DeletionPendingNoticeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, size: 64, color: Color(0xFFB31637)),
              const SizedBox(height: 24),
              const Text(
                'Deletion requested',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your account is now hidden. Sign in any time within the next '
                '30 days to cancel and restore it. After that, your data is '
                'permanently erased.',
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
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
