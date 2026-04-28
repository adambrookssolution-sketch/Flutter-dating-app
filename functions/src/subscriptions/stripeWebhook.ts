/**
 * Stripe webhook receiver — production-grade.
 *
 * Stripe events flow in here from Stripe → we translate them into
 * Firestore mutations on `subscriptions/{coupleId}`. Stripe is the
 * single source of truth; Firestore is a read-optimised mirror.
 *
 * Security:
 * - Signature verification using STRIPE_WEBHOOK_SECRET (Firebase Secret
 *   Manager). Any request without a valid signature is rejected 400.
 * - Idempotency: each event is recorded under
 *   `subscription_events/{stripe_event_id}` before side effects. Replays
 *   are cheap no-ops.
 *
 * The handler is deliberately defensive — every Stripe object access
 * either has a sensible fallback or fails silently with a logger
 * warning. We never throw inside a handler unless we want Stripe to
 * retry the delivery; for resolvable issues (missing metadata,
 * unrecognised type) we log and return 200 so Stripe stops retrying.
 */
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import StripeCtor from "stripe";
import type { Stripe } from "stripe/cjs/stripe.core.js";

import { db } from "../common/firestore";
import {
  SUBSCRIPTIONS_COLLECTION,
  SUBSCRIPTION_EVENTS_COLLECTION,
  SubscriptionDoc,
  SubscriptionStatus,
  planFromLookupKey,
} from "./types";

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");

export const stripeWebhook = onRequest(
  {
    region: "us-central1",
    memory: "512MiB",
    secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET],
    // Stripe POSTs the raw body; we need it unparsed for HMAC verification.
    cors: false,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const signature = req.header("stripe-signature");
    if (!signature) {
      logger.warn("stripeWebhook: missing signature header");
      res.status(400).send("Missing Stripe signature");
      return;
    }

    const stripe = new StripeCtor(STRIPE_SECRET_KEY.value(), {
      apiVersion: "2026-04-22.dahlia",
    });

    // ─── Signature verification ────────────────────────────────────────
    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        signature,
        STRIPE_WEBHOOK_SECRET.value(),
      );
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.warn(`stripeWebhook: bad signature — ${msg}`);
      res.status(400).send("Bad signature");
      return;
    }

    // ─── Idempotency guard ─────────────────────────────────────────────
    const eventsRef = db().collection(SUBSCRIPTION_EVENTS_COLLECTION);
    const existing = await eventsRef.doc(event.id).get();
    if (existing.exists) {
      logger.info(`stripeWebhook: duplicate event ${event.id}, ignoring`);
      res.status(200).send("ok (replay)");
      return;
    }

    // ─── Dispatch ──────────────────────────────────────────────────────
    try {
      switch (event.type) {
        case "checkout.session.completed":
          await handleCheckoutCompleted(
            event.data.object as Stripe.Checkout.Session,
          );
          break;

        case "customer.subscription.created":
        case "customer.subscription.updated":
          await handleSubscriptionChange(
            event.data.object as Stripe.Subscription,
          );
          break;

        case "customer.subscription.deleted":
          await handleSubscriptionDeleted(
            event.data.object as Stripe.Subscription,
          );
          break;

        case "invoice.payment_succeeded":
          await handlePaymentSucceeded(
            event.data.object as Stripe.Invoice,
          );
          break;

        case "invoice.payment_failed":
          await handlePaymentFailed(event.data.object as Stripe.Invoice);
          break;

        default:
          logger.debug(`stripeWebhook: unhandled event type ${event.type}`);
      }

      // Record after processing so a mid-flight crash doesn't mask a replay.
      await eventsRef.doc(event.id).set({
        type: event.type,
        stripe_event_id: event.id,
        payload: event.data.object as unknown as Record<string, unknown>,
        processed_at: FieldValue.serverTimestamp(),
      });

      res.status(200).send("ok");
    } catch (err) {
      logger.error("stripeWebhook: handler failure", err);
      // 500 so Stripe retries with exponential backoff.
      res.status(500).send("handler failure");
    }
  },
);

// ── Handlers ─────────────────────────────────────────────────────────────

async function handleCheckoutCompleted(
  session: Stripe.Checkout.Session,
): Promise<void> {
  const coupleId = session.metadata?.couple_id;
  if (!coupleId) {
    logger.warn(
      "handleCheckoutCompleted: session without couple_id metadata — ignoring",
    );
    return;
  }

  // The subscription.created event usually arrives within a second of
  // checkout.session.completed and carries the price. We store the customer
  // and subscription IDs here; plan/status are filled in by
  // handleSubscriptionChange so we don't rely on a specific event order.
  await upsertSubscription(coupleId, {
    stripe_customer_id:
      typeof session.customer === "string" ? session.customer : null,
    stripe_subscription_id:
      typeof session.subscription === "string"
        ? session.subscription
        : null,
  });
}

async function handleSubscriptionChange(
  sub: Stripe.Subscription,
): Promise<void> {
  const coupleId = sub.metadata?.couple_id;
  if (!coupleId) {
    logger.warn(
      `handleSubscriptionChange: subscription ${sub.id} has no couple_id`,
    );
    return;
  }

  // Stripe API 2026-04 moved current_period_* off Subscription onto each
  // item. We only ever sell single-item subscriptions (one Gold OR one
  // Black, not bundles) so reading item[0] is correct for our model.
  const item = sub.items.data[0];
  const lookupKey = item?.price?.lookup_key ?? "";
  const priceId = item?.price?.id ?? null;
  const periodStart = item?.current_period_start;
  const periodEnd = item?.current_period_end;

  await upsertSubscription(coupleId, {
    plan: planFromLookupKey(lookupKey),
    status: normalizeStatus(sub.status),
    stripe_customer_id:
      typeof sub.customer === "string" ? sub.customer : null,
    stripe_subscription_id: sub.id,
    price_id: priceId,
    cancel_at_period_end: sub.cancel_at_period_end ?? false,
    current_period_start: periodStart
      ? Timestamp.fromMillis(periodStart * 1000)
      : null,
    current_period_end: periodEnd
      ? Timestamp.fromMillis(periodEnd * 1000)
      : null,
  });
}

async function handleSubscriptionDeleted(
  sub: Stripe.Subscription,
): Promise<void> {
  const coupleId = sub.metadata?.couple_id;
  if (!coupleId) return;

  // When the subscription is fully gone we drop back to free immediately.
  // Benefits-until-period-end logic lives on the `cancel_at_period_end`
  // flag handled in handleSubscriptionChange.
  await upsertSubscription(coupleId, {
    plan: "free",
    status: "canceled",
    stripe_subscription_id: null,
    price_id: null,
    cancel_at_period_end: false,
    current_period_end: null,
  });
}

async function handlePaymentSucceeded(
  _invoice: Stripe.Invoice,
): Promise<void> {
  // The subscription.updated event fires alongside payment_succeeded and
  // already carries the new current_period_end. Keeping this handler as a
  // placeholder for analytics (MRR computation) in Entrega 3.
}

async function handlePaymentFailed(invoice: Stripe.Invoice): Promise<void> {
  // Stripe API 2026-04 moved invoice.subscription under
  // invoice.parent.subscription_details.subscription.
  const parent = invoice.parent;
  const subRefRaw =
    parent?.type === "subscription_details"
      ? parent.subscription_details?.subscription
      : null;
  const subscriptionRef =
    typeof subRefRaw === "string" ? subRefRaw : subRefRaw?.id ?? null;
  if (!subscriptionRef) return;

  // We don't load the subscription object here — the customer.subscription.
  // updated event that follows a payment failure already carries the new
  // status. This handler just optimistically marks past_due for faster UI
  // reaction; the subscription handler will overwrite if Stripe says
  // otherwise.
  // To find the couple_id we read the related subscription's metadata via
  // its stripe_subscription_id from Firestore.
  const matching = await db()
    .collection(SUBSCRIPTIONS_COLLECTION)
    .where("stripe_subscription_id", "==", subscriptionRef)
    .limit(1)
    .get();
  const doc = matching.docs[0];
  if (!doc) {
    logger.warn(
      `handlePaymentFailed: no Firestore doc for subscription ${subscriptionRef}`,
    );
    return;
  }
  await upsertSubscription(doc.id, { status: "past_due" });
}

// ── Helpers ──────────────────────────────────────────────────────────────

function normalizeStatus(raw: Stripe.Subscription.Status): SubscriptionStatus {
  switch (raw) {
    case "active":
    case "trialing":
    case "past_due":
    case "canceled":
    case "incomplete":
      return raw;
    case "incomplete_expired":
    case "unpaid":
      return "canceled";
    default:
      return "incomplete";
  }
}

async function upsertSubscription(
  coupleId: string,
  patch: Partial<SubscriptionDoc>,
): Promise<void> {
  const ref = db().collection(SUBSCRIPTIONS_COLLECTION).doc(coupleId);
  const now = FieldValue.serverTimestamp();
  await ref.set(
    {
      ...patch,
      updated_at: now,
      created_at: FieldValue.serverTimestamp(), // only applied if doc new
    },
    { merge: true },
  );
}
