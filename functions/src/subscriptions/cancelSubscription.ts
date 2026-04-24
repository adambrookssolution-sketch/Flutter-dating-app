/**
 * Cancel the caller's subscription at the end of the current period.
 *
 * UX rule: we never yank benefits mid-period. The user keeps Gold/Black
 * until `current_period_end`, then drops to Free. This matches the copy
 * shown on the "Tu plan" screen.
 *
 * We also do NOT delete the Stripe customer or subscription record —
 * Stripe marks it as `cancel_at_period_end = true` and fires a
 * `subscription.updated` event which our webhook syncs to Firestore.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

import { db } from "../common/firestore";
import { SUBSCRIPTIONS_COLLECTION, SubscriptionDoc } from "./types";

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");

export const cancelSubscription = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (req) => {
    if (!req.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required");
    }
    const coupleId = req.auth.uid;

    const subRef = db().collection(SUBSCRIPTIONS_COLLECTION).doc(coupleId);
    const snap = await subRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "No subscription to cancel");
    }
    const sub = snap.data() as SubscriptionDoc;
    if (!sub.stripe_subscription_id) {
      throw new HttpsError(
        "failed-precondition",
        "This couple is on the Free plan",
      );
    }

    // @ts-expect-error — stripe is a peer dep added in Entrega 1
    const { default: Stripe } = await import("stripe");
    const stripe = new Stripe(STRIPE_SECRET_KEY.value(), {
      apiVersion: "2024-06-20",
    });

    await stripe.subscriptions.update(sub.stripe_subscription_id, {
      cancel_at_period_end: true,
    });

    // The Stripe webhook will mirror the state back into Firestore. We
    // optimistically mark it here so the UI reflects the cancellation
    // intent without waiting a round-trip.
    await subRef.set({ cancel_at_period_end: true }, { merge: true });

    return { ok: true };
  },
);
