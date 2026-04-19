import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/utils/navigate_after_sign_in.dart';
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
  } on Exception catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (e.toString().contains('cancelled')) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.errorGoogleSignIn)),
    );
  }
}
