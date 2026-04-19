import 'package:app/core/notifications/fcm_service.dart';
import 'package:app/data/datasource/couples_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/couple_status.dart';
import 'package:app/presentation/pages/couples/couples_screen.dart';
import 'package:app/presentation/pages/profile_setup/profile_setup_screen.dart';
import 'package:app/presentation/pages/settings/cancel_deletion_screen.dart';
import 'package:app/presentation/pages/verification/verification_pending_screen.dart';
import 'package:app/presentation/pages/verification/verification_rejected_screen.dart';
import 'package:app/presentation/widgets/recovery_attempts_dialog.dart';
import 'package:flutter/material.dart';

/// Routes the signed-in user to the right post-auth surface.
///
/// Decision tree (in order — first match wins):
///   1. couples/{uid}.status == pending_deletion → CancelDeletionScreen
///   2. couples/{uid}.status == pending_review   → VerificationPendingScreen
///   3. couples/{uid}.status == rejected         → VerificationRejectedScreen
///   4. couples/{uid}.status == suspended | under_review → VerificationPendingScreen
///      (with the soft-block banner — same UI, different copy via the Couple data)
///   5. profiles/{uid} exists                    → CouplesScreen (legacy/approved)
///   6. nothing                                  → ProfileSetupScreen
///
/// Side effect: surfaces any pending password-recovery attempts via a
/// one-time dialog after the destination screen mounts.
Future<void> navigateAfterSignIn(BuildContext context, String uid) async {
  final couple = await CouplesDatasource.getCouple(uid);

  if (couple != null) {
    Widget? next;
    switch (couple.status) {
      case CoupleStatus.pendingDeletion:
        next = CancelDeletionScreen(couple: couple);
      case CoupleStatus.pendingReview:
      case CoupleStatus.suspended:
      case CoupleStatus.underReview:
        next = const VerificationPendingScreen();
      case CoupleStatus.rejected:
        next = VerificationRejectedScreen(couple: couple);
      case CoupleStatus.approved:
        next = null; // fall through to legacy / feed
    }
    if (next != null) {
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => next!),
        (route) => false,
      );
      return;
    }
  }

  final hasProfile = await ProfileDatasource.profileExists(uid);
  if (!context.mounted) return;
  await Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) =>
          hasProfile ? const CouplesScreen() : ProfileSetupScreen(uid: uid),
    ),
    (route) => false,
  );

  if (!context.mounted) return;
  await RecoveryAttemptsDialog.maybeShow(context);

  // Fire-and-forget FCM registration. Safe to call for every destination
  // (pending_review, approved, etc.) — the Security Rules may reject the
  // token write for non-approved couples and FcmService silently swallows
  // that error, retrying on the next sign-in.
  // ignore: unawaited_futures
  FcmService.register();
}
