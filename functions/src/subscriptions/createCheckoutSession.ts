/**
 * Create a Stripe Checkout session for the caller.
 *
 * Flow:
 *   1. Auth-required callable. Resolves the caller's couple document.
 *   2. Reuses (or lazily creates) a Stripe Customer tied to the couple.
 *   3. Creates a Checkout session with `metadata.couple_id` so the
 *      webhook can map the event back to our Firestore doc.
 *   4. Returns `{ url }` — the client opens it via `url_launcher`
 *      (external browser; Apple compliance requirement).
 *
 * Stability: the Stripe SDK is dynamically imported so the skeleton
 * compiles without the dependency. Entrega 1 adds `stripe` to
 * functions/package.json and removes the `// @ts-expect-error` shims.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";

import { db, COLLECTIONS } from "../common/firestore";
import {
  SUBSCRIPTIONS_COLLECTION,
  SubscriptionDoc,
  PRICE_LOOKUP_KEYS,
  PriceLookupKey,
} from "./types";

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");

interface CreateCheckoutPayload {
  lookupKey?: PriceLookupKey;
  /** Where Stripe should redirect after success/cancel. */
  successUrl?: string;
  cancelUrl?: string;
}

export const createCheckoutSession = onCall<CreateCheckoutPayload>(
  {
    region: "us-central1",
    maxInstances: 20,
    secrets: [STRIPE_SECRET_KEY],
  },
  async (req) => {
    if (!req.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required");
    }
    const coupleId = req.auth.uid;

    const lookupKey = req.data.lookupKey;
    if (!lookupKey || !Object.values(PRICE_LOOKUP_KEYS).includes(lookupKey)) {
      throw new HttpsError("invalid-argument", "Unknown plan");
    }
    const successUrl = req.data.successUrl;
    const cancelUrl = req.data.cancelUrl;
    if (!successUrl || !cancelUrl) {
      throw new HttpsError(
        "invalid-argument",
        "successUrl and cancelUrl are required",
      );
    }

    // ─── Verify the couple is eligible (must be approved) ──────────────
    const coupleSnap = await db()
      .collection(COLLECTIONS.couples)
      .doc(coupleId)
      .get();
    if (!coupleSnap.exists) {
      throw new HttpsError("failed-precondition", "Couple not found");
    }
    const status = coupleSnap.get("status");
    if (status !== "approved") {
      throw new HttpsError(
        "failed-precondition",
        "Couple must be approved before upgrading",
      );
    }
    const email = coupleSnap.get("contact_email") ?? req.auth.token.email ?? "";

    // ─── Resolve / create Stripe customer ──────────────────────────────
    const subRef = db().collection(SUBSCRIPTIONS_COLLECTION).doc(coupleId);
    const subSnap = await subRef.get();
    const existing = subSnap.exists ? (subSnap.data() as SubscriptionDoc) : null;
    let customerId = existing?.stripe_customer_id ?? null;

    // Dynamic import so the module compiles without `stripe` installed.
    // @ts-expect-error — stripe is a peer dep added in Entrega 1
    const { default: Stripe } = await import("stripe");
    const stripe = new Stripe(STRIPE_SECRET_KEY.value(), {
      apiVersion: "2024-06-20",
    });

    if (!customerId) {
      const customer = await stripe.customers.create({
        email,
        metadata: { couple_id: coupleId },
      });
      customerId = customer.id;
      await subRef.set(
        { stripe_customer_id: customerId },
        { merge: true },
      );
    }

    // ─── Resolve price id from lookup key ──────────────────────────────
    const prices = await stripe.prices.list({
      lookup_keys: [lookupKey],
      active: true,
      limit: 1,
    });
    const price = prices.data[0];
    if (!price) {
      logger.error(`createCheckoutSession: no active price for ${lookupKey}`);
      throw new HttpsError("not-found", "Plan price unavailable");
    }

    // ─── Create the session ────────────────────────────────────────────
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: customerId,
      line_items: [{ price: price.id, quantity: 1 }],
      subscription_data: {
        metadata: { couple_id: coupleId },
      },
      metadata: { couple_id: coupleId },
      success_url: successUrl,
      cancel_url: cancelUrl,
      allow_promotion_codes: true,
    });

    return { url: session.url };
  },
);
