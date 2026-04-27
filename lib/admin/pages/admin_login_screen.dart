import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/admin/admin_app.dart';

/// Login screen for moderators — dark, modern dating-app aesthetic.
///
/// Email + password only; SSO is overkill for a handful of internal users.
/// After sign-in, [AdminApp] checks for the `moderator: true` claim before
/// routing to the queue. Without the claim, the queue screen renders a
/// no-access view and signs the user back out.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Correo no válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta de nuevo en unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return e.message ?? 'No se pudo iniciar sesión.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ambient burgundy → purple wash so the background isn't dead flat.
          const _AmbientBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BrandMark(),
                      const SizedBox(height: 28),
                      const Text(
                        'Affinity Moderation',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AdminApp.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Herramienta interna · acceso de moderador',
                        style: TextStyle(
                          color: AdminApp.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 36),
                      _LoginCard(
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        obscure: _obscure,
                        busy: _busy,
                        error: _error,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onSubmit: _signIn,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '🔒 Todas las acciones quedan registradas.',
                        style: TextStyle(
                          color: AdminApp.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AdminApp.burgundy, AdminApp.purple],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AdminApp.burgundy.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.shield_moon_rounded,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.busy,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool busy;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminApp.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminApp.line),
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AdminApp.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Icons.alternate_email_rounded,
                  color: AdminApp.textMuted, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passCtrl,
            obscureText: obscure,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => busy ? null : onSubmit(),
            style: const TextStyle(color: AdminApp.textPrimary),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  color: AdminApp.textMuted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AdminApp.textMuted,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AdminApp.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AdminApp.danger.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AdminApp.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: AdminApp.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: busy ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: busy
                        ? [
                            AdminApp.burgundy.withValues(alpha: 0.5),
                            AdminApp.purple.withValues(alpha: 0.5),
                          ]
                        : const [AdminApp.burgundy, AdminApp.purple],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft burgundy → purple radial wash bottom-right so the page reads as
/// a designed surface instead of a flat charcoal rectangle.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.7, 0.9),
              radius: 1.1,
              colors: [
                AdminApp.purple.withValues(alpha: 0.22),
                AdminApp.burgundy.withValues(alpha: 0.10),
                AdminApp.bgDeep.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
