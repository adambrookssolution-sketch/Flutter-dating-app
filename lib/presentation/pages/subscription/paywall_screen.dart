import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app/core/subscription/subscription_plan.dart';
import 'package:app/data/datasource/subscription_datasource.dart';
import 'package:app/providers/subscription_provider.dart';

/// Paywall comparison screen — shown when a Free user hits a gated
/// feature or taps "Upgrade" from "Tu plan".
///
/// Apple / Google compliance (DECISIONS_LOG §8 + subscription_architecture §7):
///   - No raw prices inside the app binary.
///   - The CTA leads to an external browser via url_launcher (NOT done
///     in this skeleton — wired once Stripe is live).
///   - No "save X%" copy, no "cheaper online" hints, no in-app
///     purchase flow for non-IAP payments.
///
/// Visual direction:
///   - Burgundy → purple gradient masthead matching the rest of Affinity.
///   - Three stacked plan cards (Free, Gold, Black) — Black uses the
///     dark gradient from the HTML proposal so the visual hierarchy
///     lines up with what the client already approved.
///   - Each card shows 5–7 headline benefits. Full matrix lives in
///     docs/subscription_benefits_matrix.csv; the paywall is designed
///     to be scannable in 10 seconds, not exhaustive.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const Color _burgundy = Color(0xFFB01030);
  static const Color _purple = Color(0xFF5B1280);
  static const Color _gold = Color(0xFFC9A24B);
  static const Color _inkSoft = Color(0xFF4A4A52);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentSubscriptionProvider).valueOrNull;
    final currentPlan = current?.plan ?? SubscriptionPlan.free;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: _burgundy,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: const Text(
                'Elige tu experiencia',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_burgundy, _purple],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 36, 20, 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tres niveles. Una comunidad.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sigue en Affinity tal cual estás, o desbloquea más funciones cuando estés lista.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _PlanCard(
                    tier: SubscriptionPlan.free,
                    isCurrent: currentPlan == SubscriptionPlan.free,
                    title: 'Free',
                    tagline: 'Tu punto de entrada a la comunidad',
                    accent: _inkSoft,
                    benefits: const [
                      'Registro de pareja y verificación por video',
                      'Feed de parejas sin límite diario',
                      'Filtros básicos: distancia y edad',
                      '3 solicitudes de mensaje por semana',
                      'Travel Match: tus propios viajes',
                      'Bloqueo, reporte y soporte por correo',
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PlanCard(
                    tier: SubscriptionPlan.gold,
                    isCurrent: currentPlan == SubscriptionPlan.gold,
                    title: 'Gold',
                    tagline: 'El plan para quien está en serio',
                    accent: _gold,
                    highlight: true,
                    badgeText: 'Más elegido',
                    benefits: const [
                      'Todo lo de Free',
                      'Solicitudes de mensaje ilimitadas',
                      'Filtros avanzados: dinámicas, experiencia, intereses',
                      'Travel Match sin límite de ventana temporal',
                      'Prioridad visual en el feed',
                      'Ver quién te marcó como favorita',
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PlanCard(
                    tier: SubscriptionPlan.black,
                    isCurrent: currentPlan == SubscriptionPlan.black,
                    title: 'Black',
                    tagline: 'Experiencia exclusiva · círculo cerrado',
                    accent: _gold,
                    dark: true,
                    benefits: const [
                      'Todo lo de Gold',
                      'Badge dorado visible en tu tarjeta',
                      'Conexión directa con otros Black, sin solicitud',
                      'Acceso temprano a nuevos destinos y eventos',
                      'Invitaciones a eventos privados curados',
                      'Soporte prioritario directo',
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _ComplianceNote(),
                  const SizedBox(height: 12),
                  const _FooterNote(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-tier plan card. When `dark` is true the card renders the VIP
/// dark gradient used for Black in the client-approved HTML proposal.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tier,
    required this.isCurrent,
    required this.title,
    required this.tagline,
    required this.accent,
    required this.benefits,
    this.highlight = false,
    this.badgeText,
    this.dark = false,
  });

  final SubscriptionPlan tier;
  final bool isCurrent;
  final String title;
  final String tagline;
  final Color accent;
  final List<String> benefits;
  final bool highlight;
  final String? badgeText;
  final bool dark;

  static const Color _burgundy = Color(0xFFB01030);
  static const Color _gold = Color(0xFFC9A24B);

  @override
  Widget build(BuildContext context) {
    final bg = dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B1B1F), Color(0xFF2A1B3A)],
          )
        : null;
    final bodyColor = dark ? const Color(0xFFCFC6B8) : const Color(0xFF4A4A52);
    final titleColor = dark ? const Color(0xFFF5F0E5) : Colors.black;
    final tick = dark ? _gold : _burgundy;

    return Container(
      decoration: BoxDecoration(
        color: dark ? null : Colors.white,
        gradient: bg,
        borderRadius: BorderRadius.circular(18),
        border: highlight
            ? Border.all(color: accent, width: 2)
            : Border.all(color: const Color(0xFFE6E6EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tagline,
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (badgeText != null && !isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText!.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (dark ? _gold : _burgundy)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TU PLAN',
                    style: TextStyle(
                      color: dark ? _gold : _burgundy,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded, size: 18, color: tick),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          if (!isCurrent && tier != SubscriptionPlan.free)
            _CtaButton(
              dark: dark,
              onPressed: () => _openWebCheckout(context, tier),
            ),
        ],
      ),
    );
  }

  /// Maps a tier card to the monthly Stripe price lookup key. Annual
  /// pricing is intentionally not exposed from the paywall — a small
  /// "switch to annual" toggle lands in Entrega 3 once monthly conversion
  /// data exists.
  String? _lookupKeyForTier(SubscriptionPlan tier) {
    switch (tier) {
      case SubscriptionPlan.gold:
        return PriceLookupKeys.goldMonthly;
      case SubscriptionPlan.black:
        return PriceLookupKeys.blackMonthly;
      case SubscriptionPlan.free:
        return null;
    }
  }

  Future<void> _openWebCheckout(
    BuildContext context,
    SubscriptionPlan tier,
  ) async {
    final lookupKey = _lookupKeyForTier(tier);
    if (lookupKey == null) return;

    // Stripe redirects back to these URLs after the user finishes (or
    // bails out of) the hosted checkout. The deep links are configured
    // in [main.dart] / iOS associated-domains; if the deep link fails
    // we still land on a marketing page that explains "your plan is
    // active, open the app".
    const successUrl =
        'https://affinitysocialclub.com/subscribe/success?couple_id={CHECKOUT_SESSION_ID}';
    const cancelUrl = 'https://affinitysocialclub.com/subscribe/cancel';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrirá el checkout seguro en tu navegador.'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final url = await SubscriptionDatasource.createCheckoutUrl(
        lookupKey: lookupKey,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );
      final uri = Uri.tryParse(url);
      if (uri == null) throw const FormatException('Invalid checkout URL');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showCheckoutFailure(context);
      }
    } catch (_) {
      if (context.mounted) _showCheckoutFailure(context);
    }
  }

  void _showCheckoutFailure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No pudimos abrir el checkout en este momento. Inténtalo de nuevo en unos segundos.',
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.dark, required this.onPressed});

  final bool dark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        // Store-compliance copy: no price, no "save X%", no "cheaper",
        // just a neutral redirect hint. Apple's Guideline 3.1.3(b) OK.
        label: const Text('Continuar en el navegador'),
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? const Color(0xFFC9A24B) : const Color(0xFFB01030),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ComplianceNote extends StatelessWidget {
  const _ComplianceNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EF),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFFC9A24B), width: 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: const Text(
        'La gestión de suscripciones (alta, baja, facturación) se realiza '
        'desde nuestra página web segura. Dentro de la app verás siempre '
        'el estado de tu plan y podrás ver tus beneficios al instante.',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF4A4A52),
          height: 1.4,
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Puedes cambiar o cancelar tu plan en cualquier momento desde '
          'tu cuenta.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
