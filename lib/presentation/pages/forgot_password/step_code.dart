import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/auth/auth_by_email/auth_by_email_screen.dart';
import 'package:app/presentation/pages/forgot_password/widget/text_information.dart';
import 'package:app/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// "We've sent you a recovery email" interstitial.
///
/// The legacy implementation prompted for a 4-digit OTP, but Firebase Auth's
/// password reset flow is link-based — the user clicks the link in their
/// email, sets a new password in the system browser, and returns. There is
/// no in-app code to enter.
///
/// We keep the screen position + assets intact (creative team approved them)
/// and switch the body to instructions + a "back to sign-in" CTA.
class StepCode extends StatelessWidget {
  final VoidCallback? onNext;
  final String email;

  const StepCode({super.key, this.onNext, required this.email});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: 41),
        TextInformation(
          title: l10n.weHaveSentYouACode,
          description: l10n.theCodeWasSentTo(email),
        ),
        const SizedBox(height: 36),
        CustomButton(
          buttonText: l10n.goToLogin,
          type: ButtonType.mainSystem,
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AuthByEmailScreen(initialIsSignIn: true),
            ),
            (route) => false,
          ),
        ),
      ],
    );
  }
}
