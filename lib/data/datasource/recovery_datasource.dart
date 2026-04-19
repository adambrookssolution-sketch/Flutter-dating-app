import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Password recovery surface used by the Forgot Password flow.
///
/// Two paths:
/// 1. Stock Firebase reset (default email TTL of 1 hour) — works with no
///    backend, useful in dev when functions aren't deployed.
/// 2. Custom 15-minute reset via the `sendCustomReset` Cloud Function
///    (DECISIONS_LOG Point 2: 15 min link + neutral wording + custom domain).
///    Used in production.
///
/// The two methods are functionally equivalent from the user's perspective —
/// they receive an email with a reset link. The custom path adds:
/// - 15-minute expiry instead of 1 hour
/// - Neutral subject + body (no Affinity branding)
/// - An entry in `account_recovery_attempts/*` for the in-app audit dialog
class RecoveryDatasource {
  static FirebaseFunctions get _fn =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Calls the custom reset Cloud Function. Falls back to the stock Firebase
  /// reset if the function isn't deployed (dev convenience).
  ///
  /// Always succeeds from the caller's perspective regardless of whether
  /// the email exists — that is intentional, surfacing "user not found"
  /// would let an attacker enumerate accounts.
  static Future<void> sendResetEmail(String email) async {
    final normalised = email.trim().toLowerCase();
    if (normalised.isEmpty) return;

    try {
      final callable = _fn.httpsCallable('sendCustomReset');
      await callable.call<Map<String, dynamic>>({'email': normalised});
      return;
    } on FirebaseFunctionsException catch (e) {
      // `unavailable` (503) means the function isn't deployed yet — fall back.
      // `not-found` would mean we never deployed under that name.
      if (e.code != 'unavailable' && e.code != 'not-found') {
        // Other errors are still swallowed to preserve the no-enumeration
        // contract; logged so devs can spot real failures during testing.
        // ignore: avoid_print
        print('sendCustomReset failed (${e.code}): ${e.message}');
        return;
      }
    } catch (_) {
      // Same enumeration-protection rationale.
    }

    // Fallback path
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: normalised);
    } catch (_) {
      // swallowed (no enumeration)
    }
  }

  /// Stream of the current user's recent recovery attempts. Used by the
  /// post-login dialog ("Recovery attempted on [date] from [device]").
  /// Empty when the user is signed out.
  static Stream<List<RecoveryAttempt>> streamMyRecentAttempts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('account_recovery_attempts')
        .where('couple_id', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) => snap.docs.map(RecoveryAttempt.fromDoc).toList());
  }
}

class RecoveryAttempt {
  final String id;
  final String coupleId;
  final String? ip;
  final String? device;
  final DateTime? date;
  final bool completed;

  const RecoveryAttempt({
    required this.id,
    required this.coupleId,
    this.ip,
    this.device,
    this.date,
    this.completed = false,
  });

  factory RecoveryAttempt.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return RecoveryAttempt(
      id: doc.id,
      coupleId: (m['couple_id'] as String?) ?? '',
      ip: m['ip'] as String?,
      device: m['device'] as String?,
      date: (m['date'] as Timestamp?)?.toDate(),
      completed: (m['completed'] as bool?) ?? false,
    );
  }
}
