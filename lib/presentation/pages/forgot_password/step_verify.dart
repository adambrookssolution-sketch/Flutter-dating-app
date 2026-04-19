import 'package:app/data/datasource/recovery_datasource.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/forgot_password/widget/text_information.dart';
import 'package:app/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';

class StepVerify extends StatefulWidget {
  final void Function(String)? onNext;

  const StepVerify({super.key, this.onNext});

  @override
  State<StepVerify> createState() => _StepVerifyState();
}

class _StepVerifyState extends State<StepVerify> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _isSending = false;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validates input then triggers the recovery email. We deliberately call
  /// onNext UNCONDITIONALLY after a successful send (and even after server
  /// errors) so the receiver UX matches the "we don't disclose whether the
  /// account exists" rule from DECISIONS_LOG Point 2.
  Future<void> _validate(AppLocalizations l10n) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = l10n.errorEmailEmpty);
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = l10n.errorEmailInvalid);
      return;
    }
    setState(() {
      _emailError = null;
      _isSending = true;
    });

    await RecoveryDatasource.sendResetEmail(email);

    if (!mounted) return;
    setState(() => _isSending = false);
    widget.onNext?.call(email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: 41),
        TextInformation(
          title: l10n.welcomeBack,
          description: l10n.welcomeBackDescription,
        ),
        const SizedBox(height: 48),
        CustomInput(
          label: l10n.email,
          hintText: l10n.emailHint,
          controller: _emailController,
          errorText: _emailError,
        ),
        const SizedBox(height: 36),
        CustomButton(
          buttonText: _isSending ? '...' : l10n.verify,
          type: ButtonType.mainSystem,
          onTap: _isSending ? null : () => _validate(l10n),
        ),
        const SizedBox(height: 12),
        CustomButton(
          buttonText: l10n.cancel,
          type: ButtonType.secondarySystem,
          onTap: _isSending ? null : () => Navigator.pop(context),
        ),
      ],
    );
  }
}
