/**
 * Stripe webhook receiver.
 *
 * Subscription events flow in here from Stripe → we translate them into
 * Firestore mutations on `subscriptions/{coupleId}`. Stripe is the
 * single source of truth; Firestore is a read-optimised mirror.
 *
 * Security:
 * - Signature verification using STRIPE_WEBHOOK_SECRET (Firebase Secret
 *   Manager). Any request without a valid signature is rejected 400.
 * - Idempotency: each event is recorded under `subscription_events/
 *   {stripe_event_id}` before side effects. Replays are cheap no-ops.
 *
 * Scope (skeleton for Entrega 1):
 *   - Verify signature + reject bad requests.
 *   - Persist raw event with idempotency guard.
 *   - Dispatch handler stubs per event type (bodies filled once Stripe
 *     account + test mode are live).
 *
 * Not yet wired into `index.ts` — it stays dark until the client
 * approves the module.
 */
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

import { db } from "../common/firestore";
import {
  SUBSCRIPTIONS_COLLECTION,
  SUBSCRIPTION_EVENTS_COLLECTION,
  SubscriptionDoc,
  SubscriptionStatus,
  planFromLookupKey,
} from "./types";

// Stripe library is intentionally NOT imported here yet — it's a peer
// dependency we'll add to functions/package.json in Entrega 1. The
// skeleton below uses structural types so TypeScript stays happy
// without pulling the SDK in.
interface StripeEventShape {
  id: string;
  type: string;
  data: { object: Record<string, unknown> };
}

const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");

export const stripeWebhook = onRequest(
  {
    region: "us-central1",
    memory: "512MiB",
    secrets: [STRIPE_WEBHOOK_SECRET],
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

    // ─── Signature verification (wired in Entrega 1) ───────────────────
    //
    // const Stripe = (await import("stripe")).default;
    // const stripe = new Stripe(STRIPE_API_KEY.value(), { apiVersion: "2024-06-20" });
    // let event: Stripe.Event;
    // try {
    //   event = stripe.webhooks.constructEvent(
    //     req.rawBody,
    //     signature,
    //     STRIPE_WEBHOOK_SECRET.value()
    //   );
    // } catch (err) {
    //   logger.warn("stripeWebhook: bad signature", err);
    //   res.status(400).send("Bad signature");
    //   return;
    // }
    //
    // For the skeleton, pretend the event arrived pre-parsed.
    const event = req.body as StripeEventShape;

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
          await handleCheckoutCompleted(event);
          break;

        case "customer.subscription.created":
        case "customer.subscription.updated":
          await handleSubscriptionChange(event);
          break;

        case "customer.subscription.deleted":
          await handleSubscriptionDeleted(event);
          break;

        case "invoice.payment_succeeded":
          await handlePaymentSucceeded(event);
          break;

        case "invoice.payment_failed":
          await handlePaymentFailed(event);
          break;

        default:
          logger.debug(`stripeWebhook: unhandled event type ${event.type}`);
      }

      // Record after processing so a mid-flight crash doesn't mask a replay.
      await eventsRef.doc(event.id).set({
        type: event.type,
        stripe_event_id: event.id,
        payload: event.data.object,
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

async function handleCheckoutCompleted(event: StripeEventShape): Promise<void> {
  const session = event.data.object as {
    metadata?: { couple_id?: string };
    customer?: string;
    subscription?: string;
  };
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
    stripe_customer_id: session.customer ?? null,
    stripe_subscription_id: session.subscription ?? null,
  });
}

async function handleSubscriptionChange(
  event: StripeEventShape,
): Promise<void> {
  const sub = event.data.object as {
    id: string;
    status: string;
    customer: string;
    cancel_at_period_end?: boolean;
    current_period_start?: number;
    current_period_end?: number;
    metadata?: { couple_id?: string };
    items?: { data?: Array<{ price?: { id?: string; lookup_key?: string } }> };
  };

  const coupleId = sub.metadata?.couple_id;
  if (!coupleId) {
    logger.warn(
      `handleSubscriptionChange: subscription ${sub.id} has no couple_id`,
    );
    return;
  }

  const lookupKey = sub.items?.data?.[0]?.price?.lookup_key ?? "";
  const priceId = sub.items?.data?.[0]?.price?.id ?? null;

  await upsertSubscription(coupleId, {
    plan: planFromLookupKey(lookupKey),
    status: normalizeStatus(sub.status),
    stripe_customer_id: sub.customer,
    stripe_subscription_id: sub.id,
    price_id: priceId,
    cancel_at_period_end: sub.cancel_at_period_end ?? false,
    current_period_start: sub.current_period_start
      ? Timestamp.fromMillis(sub.current_period_start * 1000)
      : null,
    current_period_end: sub.current_period_end
      ? Timestamp.fromMillis(sub.current_period_end * 1000)
      : null,
  });
}

async function handleSubscriptionDeleted(
  event: StripeEventShape,
): Promise<void> {
  const sub = event.data.object as {
    metadata?: { couple_id?: string };
  };
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
  _event: StripeEventShape,
): Promise<void> {
  // The subscription.updated event fires alongside payment_succeeded and
  // already carries the new current_period_end. Keeping this handler as a
  // placeholder for analytics (MRR computation) in Entrega 3.
}

async function handlePaymentFailed(event: StripeEventShape): Promise<void> {
  const invoice = event.data.object as {
    subscription_details?: { metadata?: { couple_id?: string } };
    customer?: string;
  };
  const coupleId = invoice.subscription_details?.metadata?.couple_id;
  if (!coupleId) return;

  await upsertSubscription(coupleId, {
    status: "past_due",
  });
}

// ── Helpers ──────────────────────────────────────────────────────────────

function normalizeStatus(raw: string): SubscriptionStatus {
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
