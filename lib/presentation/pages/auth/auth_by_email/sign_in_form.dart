import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/presentation/utils/google_sign_in_action.dart';
import 'package:app/presentation/utils/navigate_after_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/presentation/pages/auth/widgets/form_title.dart';
import 'package:app/presentation/pages/forgot_password/forgot_password_screen.dart';
import 'package:app/presentation/widgets/widgets.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class SignInForm extends StatefulWidget {
  final VoidCallback? onSignUpTap;

  const SignInForm({super.key, this.onSignUpTap});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? emailError;
    if (email.isEmpty) {
      emailError = l10n.errorEmailEmpty;
    } else if (!_emailRegex.hasMatch(email)) {
      emailError = l10n.errorEmailInvalid;
    }

    String? passwordError;
    if (password.isEmpty) {
      passwordError = l10n.errorPasswordEmpty;
    } else if (password.length < 8) {
      passwordError = l10n.errorPasswordTooShort;
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    if (emailError != null || passwordError != null) return;

    setState(() => _isLoading = true);
    try {
      final credential = await AuthDatasource.signInWithEmail(email, password);
      if (!mounted) return;
      await navigateAfterSignIn(context, credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlySignInError(l10n, e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorSignIn} (${e.toString()})')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlySignInError(AppLocalizations l10n, FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return l10n.errorUserNotFound;
      case 'wrong-password':
        return l10n.errorWrongPassword;
      case 'invalid-credential':
        return l10n.errorInvalidCredential;
      case 'invalid-email':
        return l10n.errorInvalidEmailFormat;
      case 'user-disabled':
        return l10n.errorUserDisabled;
      case 'too-many-requests':
        return l10n.errorTooManyAttempts;
      case 'network-request-failed':
        return l10n.errorNetworkRequest;
      default:
        return '${l10n.errorSignIn} (${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTitle(title: l10n.signIn),
        CustomInput(
          label: l10n.email,
          hintText: l10n.emailHint,
          controller: _emailController,
          errorText: _emailError,
        ),
        CustomInput(
          label: l10n.password,
          hintText: l10n.passwordHint,
          isObscure: true,
          marginBottom: 0,
          controller: _passwordController,
          errorText: _passwordError,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              );
            },
            child: Text(
              l10n.forgotPassword,
              style: TextStyle(color: Color(0xFF007AFF), fontSize: 14),
            ),
          ),
        ),
        SizedBox(height: 16),
        CustomButton(
          buttonText: _isLoading ? '...' : l10n.logIn,
          type: ButtonType.mainSystem,
          onTap: _isLoading ? null : () => _submit(l10n),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.haveNotAccount,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
              const SizedBox(width: 4),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: widget.onSignUpTap,
                child: Text(
                  l10n.signUp,
                  style: TextStyle(color: Color(0xFF007AFF), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        CustomButton(
          buttonText: l10n.signInWithGoogle,
          prefixIcon: SvgPicture.asset('assets/images/google.svg', height: 18),
          type: ButtonType.secondarySystem,
          onTap: () => googleSignInAction(context),
        ),
        const SizedBox(height: 13),
        CustomButton(
          buttonText: l10n.signInWithApple,
          prefixIcon: SvgPicture.asset('assets/images/apple.svg', height: 18),
          type: ButtonType.secondarySystem,
        ),
      ],
    );
  }
}
