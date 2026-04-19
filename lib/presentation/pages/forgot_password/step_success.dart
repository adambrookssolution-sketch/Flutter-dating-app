import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/auth/auth_by_email/auth_by_email_screen.dart';
import 'package:app/presentation/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class StepSuccess extends StatefulWidget {
  const StepSuccess({super.key});

  @override
  State<StepSuccess> createState() => _StepSuccessState();
}

class _StepSuccessState extends State<StepSuccess> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 55),
        Text(
          l10n.youAreIn,
          style: TextStyle(fontSize: 26),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.recoveryPasswordSuccess,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 55),
        CustomButton(
          buttonText: l10n.goToLogin,
          type: ButtonType.mainSystem,
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AuthByEmailScreen(initialIsSignIn: true),
            ),
            (route) => false,
          ),
        ),
      ],
    );
  }
}
