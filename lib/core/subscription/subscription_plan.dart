/// Subscription plan + status enums.
///
/// Mirrors the shapes in `functions/src/subscriptions/types.ts` 1:1 so
/// Firestore docs can round-trip without a translation layer. Any change
/// here should land in both files in the same commit.
enum SubscriptionPlan {
  free,
  gold,
  black;

  static SubscriptionPlan fromFirestore(String? raw) {
    switch (raw) {
      case 'gold':
        return SubscriptionPlan.gold;
      case 'black':
        return SubscriptionPlan.black;
      default:
        return SubscriptionPlan.free;
    }
  }

  String get firestoreValue => name;

  /// True when the plan includes unlimited requests, advanced filters,
  /// and priority placement — i.e. the user is paying.
  bool get isPaid =>
      this == SubscriptionPlan.gold || this == SubscriptionPlan.black;
}

enum SubscriptionStatus {
  active,
  pastDue,
  canceled,
  trialing,
  incomplete;

  static SubscriptionStatus fromFirestore(String? raw) {
    switch (raw) {
      case 'active':
        return SubscriptionStatus.active;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'trialing':
        return SubscriptionStatus.trialing;
      case 'incomplete':
      default:
        return SubscriptionStatus.incomplete;
    }
  }

  /// Benefits are active for the user when status is active OR trialing.
  /// past_due keeps benefits during Stripe's retry window — see §7 of
  /// docs/subscription_architecture.md.
  bool get grantsBenefits =>
      this == SubscriptionStatus.active ||
      this == SubscriptionStatus.trialing ||
      this == SubscriptionStatus.pastDue;
}

/// Stripe lookup_keys. The values must match the Stripe dashboard exactly.
class PriceLookupKeys {
  PriceLookupKeys._();
  static const goldMonthly = 'gold_monthly';
  static const goldAnnual = 'gold_annual';
  static const blackMonthly = 'black_monthly';
  static const blackAnnual = 'black_annual';
}
