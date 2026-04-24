/**
 * Subscription module — shared types.
 *
 * Kept separate from business logic so the Flutter side can mirror these
 * shapes 1:1 without digging through handlers.
 */

export type SubscriptionPlan = "free" | "gold" | "black";

export type SubscriptionStatus =
  | "active"
  | "past_due"
  | "canceled"
  | "trialing"
  | "incomplete";

export interface SubscriptionDoc {
  plan: SubscriptionPlan;
  status: SubscriptionStatus;
  stripe_customer_id?: string | null;
  stripe_subscription_id?: string | null;
  price_id?: string | null;
  current_period_start?: FirebaseFirestore.Timestamp | null;
  current_period_end?: FirebaseFirestore.Timestamp | null;
  cancel_at_period_end?: boolean;
  updated_at: FirebaseFirestore.Timestamp;
  created_at: FirebaseFirestore.Timestamp;
}

/**
 * Stripe `price.lookup_key` values. Using lookup_keys instead of raw
 * price IDs means we can rotate prices (e.g. regional pricing
 * experiments) without redeploying Cloud Functions — just change the
 * active price under the same lookup_key in the Stripe dashboard.
 */
export const PRICE_LOOKUP_KEYS = {
  gold_monthly: "gold_monthly",
  gold_annual: "gold_annual",
  black_monthly: "black_monthly",
  black_annual: "black_annual",
} as const;

export type PriceLookupKey =
  (typeof PRICE_LOOKUP_KEYS)[keyof typeof PRICE_LOOKUP_KEYS];

export function planFromLookupKey(key: string): SubscriptionPlan {
  if (key.startsWith("gold_")) return "gold";
  if (key.startsWith("black_")) return "black";
  return "free";
}

export const SUBSCRIPTIONS_COLLECTION = "subscriptions";
export const SUBSCRIPTION_EVENTS_COLLECTION = "subscription_events";
