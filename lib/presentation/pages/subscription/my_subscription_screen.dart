import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:app/core/subscription/subscription_plan.dart';
import 'package:app/data/datasource/subscription_datasource.dart';
import 'package:app/data/models/subscription.dart';
import 'package:app/presentation/pages/subscription/paywall_screen.dart';
import 'package:app/providers/subscription_provider.dart';

/// "Tu plan" — subscription management screen reached from Profile →
/// Account settings → Tu plan.
///
/// Store compliance: this screen never shows a raw price. It summarises
/// the current plan's benefits, the renewal date, and either an upgrade
/// path (to the external paywall) or a cancel action (callable → Stripe
/// handles billing, Firestore mirrors the state within seconds).
class MySubscriptionScreen extends ConsumerWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSub = ref.watch(currentSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu plan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFAF8F5),
      body: asyncSub.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFB01030)),
        ),
        error: (_, __) => const _ErrorState(),
        data: (sub) => _Body(sub: sub),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.sub});

  final SubscriptionState sub;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _PlanHeader(sub: sub),
        const SizedBox(height: 16),
        _StatusBanner(sub: sub),
        const SizedBox(height: 20),
        _BenefitsSection(plan: sub.plan),
        const SizedBox(height: 24),
        _ActionsBlock(sub: sub),
      ],
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.sub});

  final SubscriptionState sub;

  @override
  Widget build(BuildContext context) {
    final plan = sub.plan;
    final (label, gradient) = switch (plan) {
      SubscriptionPlan.free => (
          'Free',
          const LinearGradient(
            colors: [Color(0xFFB0B0B8), Color(0xFF8A8A93)],
          ),
        ),
      SubscriptionPlan.gold => (
          'Gold',
          const LinearGradient(
            colors: [Color(0xFFC9A24B), Color(0xFF8A6E20)],
          ),
        ),
      SubscriptionPlan.black => (
          'Black',
          const LinearGradient(
            colors: [Color(0xFF1B1B1F), Color(0xFF2A1B3A)],
          ),
        ),
    };

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu plan actual',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (sub.currentPeriodEnd != null && sub.plan != SubscriptionPlan.free)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                sub.cancelAtPeriodEnd
                    ? 'Termina el ${_fmt(sub.currentPeriodEnd!)}'
                    : 'Se renueva el ${_fmt(sub.currentPeriodEnd!)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat('d \'de\' MMMM y', 'es').format(d);
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.sub});

  final SubscriptionState sub;

  @override
  Widget build(BuildContext context) {
    if (sub.status == SubscriptionStatus.pastDue) {
      return _banner(
        color: const Color(0xFFFFF6ED),
        accent: const Color(0xFFC76A1A),
        icon: Icons.warning_amber_rounded,
        title: 'Tu método de pago necesita atención',
        body: 'Tus beneficios siguen activos unos días mientras reintentamos '
            'el cobro. Actualiza el método desde la página web para evitar '
            'pausa del servicio.',
      );
    }
    if (sub.cancelAtPeriodEnd && sub.currentPeriodEnd != null) {
      return _banner(
        color: const Color(0xFFFFF9EF),
        accent: const Color(0xFFC9A24B),
        icon: Icons.info_outline_rounded,
        title: 'Tu suscripción termina al cierre del periodo',
        body: 'Seguirás con los beneficios hasta el ${DateFormat('d MMM y', 'es').format(sub.currentPeriodEnd!)}. '
            'Si cambias de idea, puedes reactivar desde la web antes de esa fecha.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _banner({
    required Color color,
    required Color accent,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A4A52),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final items = switch (plan) {
      SubscriptionPlan.free => const [
          'Feed completo de parejas',
          'Filtros de distancia y edad',
          '3 solicitudes de mensaje por semana',
          'Bloqueo, reporte y soporte por correo',
        ],
      SubscriptionPlan.gold => const [
          'Solicitudes ilimitadas',
          'Filtros avanzados completos',
          'Travel Match sin límite de ventana temporal',
          'Prioridad visual en el feed',
          'Ver quién te marcó como favorita',
        ],
      SubscriptionPlan.black => const [
          'Todo lo de Gold',
          'Badge dorado en tu tarjeta',
          'Conexión directa con otros Black',
          'Invitaciones a eventos privados',
          'Acceso temprano a destinos nuevos',
          'Soporte prioritario directo',
        ],
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6EA)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incluido en tu plan',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB01030),
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((t) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFFB01030), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A4A52),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ActionsBlock extends StatelessWidget {
  const _ActionsBlock({required this.sub});

  final SubscriptionState sub;

  @override
  Widget build(BuildContext context) {
    if (sub.plan == SubscriptionPlan.free) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB01030),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Ver planes'),
            ),
          ),
        ],
      );
    }

    // Paid plans: cancel + compare plans (to upgrade Gold → Black).
    return Column(
      children: [
        if (sub.plan == SubscriptionPlan.gold)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFB01030), width: 1.5),
                foregroundColor: const Color(0xFFB01030),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Comparar con Black'),
            ),
          ),
        if (sub.plan == SubscriptionPlan.gold) const SizedBox(height: 10),
        if (!sub.cancelAtPeriodEnd)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => _confirmCancel(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8A8A93),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancelar al final del periodo'),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cancelar tu plan?'),
        content: const Text(
          'Mantienes todos los beneficios hasta el final del periodo '
          'pagado. Después de esa fecha tu cuenta vuelve a Free. '
          'Puedes reactivar cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar plan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await SubscriptionDatasource.cancel();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cancelación registrada. Tus beneficios siguen hasta el final del periodo.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos procesar la cancelación. Intenta más tarde o contáctanos.',
          ),
        ),
      );
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No pudimos cargar tu plan ahora mismo. Intenta de nuevo en un momento.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8A8A93)),
        ),
      ),
    );
  }
}
