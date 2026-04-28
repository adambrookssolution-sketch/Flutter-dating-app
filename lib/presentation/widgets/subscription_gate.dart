import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/feature_flags.dart';
import 'package:app/core/subscription/subscription_plan.dart';
import 'package:app/presentation/pages/subscription/paywall_screen.dart';
import 'package:app/providers/subscription_provider.dart';

/// Wraps a privileged feature so only callers with the required
/// subscription plan can use it. Anyone below the requirement sees a
/// blurred placeholder with an "Upgrade" CTA that opens the paywall.
///
/// Designed as a single drop-in: the agency's existing screens just wrap
/// the relevant Widget in a `SubscriptionGate(...)` and the gate handles
/// the rest. No state hookup, no provider plumbing on the call site.
///
/// When [FeatureFlags.subscriptionsEnabled] is `false` the gate is a
/// pass-through — the wrapped child renders normally. This is the
/// emergency-rollback escape hatch described in the integration guide.
///
/// Usage:
///
/// ```dart
/// SubscriptionGate(
///   requires: SubscriptionPlan.gold,
///   child: AdvancedFiltersPanel(),
/// )
/// ```
///
/// For non-visual gates (e.g. "is the user allowed to send another
/// request this week?") prefer reading [hasPaidBenefitsProvider] directly
/// from the call site rather than wrapping a widget.
class SubscriptionGate extends ConsumerWidget {
  const SubscriptionGate({
    super.key,
    required this.child,
    this.requires = SubscriptionPlan.gold,
    this.lockedPlaceholder,
  });

  final Widget child;

  /// Minimum tier needed to see [child]. Defaults to Gold; pass
  /// [SubscriptionPlan.black] for VIP-only widgets.
  final SubscriptionPlan requires;

  /// Optional override for the locked-state UI. By default the gate
  /// renders [_DefaultLockedView] which blurs nothing (children may
  /// be heavy) but shows a clear lock icon + Upgrade CTA. If the
  /// caller wants a custom blurred preview of the actual feature,
  /// pass the rendered preview here.
  final Widget? lockedPlaceholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!FeatureFlags.subscriptionsEnabled) {
      return child;
    }

    final asyncSub = ref.watch(currentSubscriptionProvider);
    return asyncSub.when(
      loading: () => const _LoadingShell(),
      error: (_, __) => child, // fail-open: don't block on infra hiccups
      data: (state) {
        final hasAccess = _meetsRequirement(state.plan, requires) &&
            state.status.grantsBenefits;
        if (hasAccess) return child;
        return lockedPlaceholder ?? _DefaultLockedView(required: requires);
      },
    );
  }

  /// Plan ordering: free < gold < black. Returns true when [actual] is
  /// at or above [needed]. Keeps tier comparison in one place so
  /// future tiers (e.g. an Elite above Black) only require updating
  /// this one switch.
  static bool _meetsRequirement(
    SubscriptionPlan actual,
    SubscriptionPlan needed,
  ) {
    int rank(SubscriptionPlan p) {
      switch (p) {
        case SubscriptionPlan.free:
          return 0;
        case SubscriptionPlan.gold:
          return 1;
        case SubscriptionPlan.black:
          return 2;
      }
    }

    return rank(actual) >= rank(needed);
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DefaultLockedView extends StatelessWidget {
  const _DefaultLockedView({required this.required});

  final SubscriptionPlan required;

  static const Color _burgundy = Color(0xFFB31637);
  static const Color _gold = Color(0xFFC9A24B);

  @override
  Widget build(BuildContext context) {
    final isBlack = required == SubscriptionPlan.black;
    final tierLabel = isBlack ? 'Black' : 'Gold';
    final tierColor = isBlack ? _gold : _burgundy;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6EA)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.lock_outline_rounded,
                color: tierColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            'Disponible con $tierLabel',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Conoce los planes y desbloquea esta función.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8A8A93),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: tierColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: const Text('Ver planes'),
          ),
        ],
      ),
    );
  }
}
