import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app/core/subscription/subscription_plan.dart';

/// Mirror of the Firestore `subscriptions/{coupleId}` document.
///
/// Read-only from the client — writes flow in from the Stripe webhook
/// Cloud Function. Any client-side mutation attempt is rejected by the
/// security rules.
class SubscriptionState {
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? priceId;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  const SubscriptionState({
    this.plan = SubscriptionPlan.free,
    this.status = SubscriptionStatus.active,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.priceId,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
  });

  /// Default Free state — used before any Firestore doc exists and as a
  /// safe fallback on read errors. Never blocks a user's access on
  /// transient infrastructure failures.
  factory SubscriptionState.free() => const SubscriptionState();

  factory SubscriptionState.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return SubscriptionState(
      plan: SubscriptionPlan.fromFirestore(data['plan'] as String?),
      status: SubscriptionStatus.fromFirestore(data['status'] as String?),
      stripeCustomerId: data['stripe_customer_id'] as String?,
      stripeSubscriptionId: data['stripe_subscription_id'] as String?,
      priceId: data['price_id'] as String?,
      currentPeriodStart:
          (data['current_period_start'] as Timestamp?)?.toDate(),
      currentPeriodEnd: (data['current_period_end'] as Timestamp?)?.toDate(),
      cancelAtPeriodEnd: data['cancel_at_period_end'] as bool? ?? false,
    );
  }

  /// True when the subscription grants access to paid-tier features
  /// right now. Handles the "canceled but not yet lapsed" window.
  bool get hasActiveBenefits =>
      plan.isPaid && status.grantsBenefits;
}
