import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/utils/navigate_after_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> googleSignInAction(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final credential = await AuthDatasource.signInWithGoogle();
    if (!context.mounted) return;
    await navigateAfterSignIn(context, credential.user!.uid);
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_friendlyGoogleError(l10n, e))),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    final msg = e.toString();
    if (msg.contains('cancelled') || msg.contains('canceled')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGoogleSignInCancelled)),
      );
      return;
    }
    // DEVELOPER_ERROR (10) on Android = SHA-1 fingerprint not registered in
    // Firebase Console for this APK build. This is the single most common
    // cause of "Google sign-in failed" on a freshly-built debug APK that
    // works in CI but fails on the client's device.
    if (msg.contains('DEVELOPER_ERROR') ||
        msg.contains('ApiException: 10') ||
        msg.contains('com.google.android.gms.common.api.ApiException: 10')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGoogleSignInConfig)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.errorGoogleSignIn} ($msg)')),
    );
  }
}

String _friendlyGoogleError(AppLocalizations l10n, FirebaseAuthException e) {
  switch (e.code) {
    case 'account-exists-with-different-credential':
      return l10n.errorEmailAlreadyInUse;
    case 'invalid-credential':
      return l10n.errorInvalidCredential;
    case 'user-disabled':
      return l10n.errorUserDisabled;
    case 'network-request-failed':
      return l10n.errorNetworkRequest;
    case 'too-many-requests':
      return l10n.errorTooManyAttempts;
    default:
      return '${l10n.errorGoogleSignIn} (${e.code})';
  }
}
