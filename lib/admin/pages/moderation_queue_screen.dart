import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/admin/pages/moderation_review_screen.dart';
import 'package:app/data/models/couple.dart';
import 'package:app/data/models/couple_status.dart';

/// Queue view — couples waiting for verification review, oldest first.
///
/// Queries: `couples where status == pending_review order by verification.sent_at`.
/// The required composite index is already declared in `firestore.indexes.json`.
class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen> {
  bool? _isModerator;

  @override
  void initState() {
    super.initState();
    _checkClaim();
  }

  Future<void> _checkClaim() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isModerator = false);
      return;
    }
    // Force refresh so a newly-minted claim shows up without re-login.
    final token = await user.getIdTokenResult(true);
    if (!mounted) return;
    setState(() => _isModerator = token.claims?['moderator'] == true);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isModerator == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isModerator == false) {
      return _NoAccessView(onSignOut: _signOut);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('couples')
            .where('status', isEqualTo: CoupleStatus.pendingReview.value)
            .orderBy('verification.sent_at')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text('Query failed: ${snap.error}'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final couples = snap.data!.docs.map(Couple.fromDoc).toList();
          if (couples.isEmpty) {
            return const Center(
              child: Text(
                'Queue empty — nothing to review right now.',
                style: TextStyle(color: Color(0xFFA4A4AA)),
              ),
            );
          }
          return ListView.separated(
            itemCount: couples.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = couples[i];
              return ListTile(
                title: Text(
                  '${c.partnerA.name} & ${c.partnerB.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${c.city}${c.country.isNotEmpty ? ", ${c.country}" : ""}'
                  ' • Attempt ${c.verification?.attempts ?? 1}'
                  ' • Submitted ${_relative(c.verification?.sentAt)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModerationReviewScreen(couple: c),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _relative(DateTime? d) {
    if (d == null) return 'just now';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 48) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _NoAccessView extends StatelessWidget {
  final Future<void> Function() onSignOut;
  const _NoAccessView({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 64, color: Color(0xFFB31637)),
            const SizedBox(height: 16),
            const Text(
              'This account has no moderator access.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onSignOut, child: const Text('Sign out')),
          ],
        ),
      ),
    );
  }
}
