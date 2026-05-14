import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/presentation/pages/auth/widgets/form_title.dart';
import 'package:app/presentation/pages/profile_setup/profile_setup_screen.dart';
import 'package:app/presentation/utils/google_sign_in_action.dart';
import 'package:app/presentation/widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class SignUpForm extends StatefulWidget {
  final VoidCallback? onSignInTap;

  const SignUpForm({super.key, this.onSignInTap});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isLoading = false;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

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

    String? confirmPasswordError;
    if (confirmPassword != password) {
      confirmPasswordError = l10n.errorConfirmPassword;
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    if (emailError != null || passwordError != null || confirmPasswordError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await AuthDatasource.signUpWithEmail(email, password);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(uid: credential.user!.uid),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlySignUpError(l10n, e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorSignUp} (${e.toString()})')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlySignUpError(AppLocalizations l10n, FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return l10n.errorEmailAlreadyInUse;
      case 'weak-password':
        return l10n.errorWeakPassword;
      case 'invalid-email':
        return l10n.errorInvalidEmailFormat;
      case 'too-many-requests':
        return l10n.errorTooManyAttempts;
      case 'network-request-failed':
        return l10n.errorNetworkRequest;
      case 'operation-not-allowed':
        return l10n.errorSignUp;
      default:
        return '${l10n.errorSignUp} (${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTitle(title: l10n.signUp),
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
          controller: _passwordController,
          errorText: _passwordError,
        ),
        CustomInput(
          label: l10n.confirmPassword,
          hintText: l10n.confirmPasswordHint,
          isObscure: true,
          controller: _confirmPasswordController,
          errorText: _confirmPasswordError,
        ),
        CustomButton(
          buttonText: _isLoading ? '...' : l10n.signUp,
          type: ButtonType.mainSystem,
          onTap: _isLoading ? null : () => _submit(l10n),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.alreadyAMember,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
              const SizedBox(width: 4),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: widget.onSignInTap,
                child: Text(
                  l10n.signIn,
                  style: const TextStyle(color: Color(0xFF007AFF), fontSize: 14),
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
