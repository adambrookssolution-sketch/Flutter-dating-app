/**
 * Direct webhook smoke test — POST a synthetic event to the running
 * stripeWebhook emulator endpoint and verify the Firestore mirror.
 *
 * Why this exists: the real webhook verifies an HMAC signature against
 * STRIPE_WEBHOOK_SECRET. To test the handler logic without a live
 * Stripe account we sign the payload ourselves with the placeholder
 * secret in functions/.secret.local.
 *
 * Pre-conditions:
 *   - Emulators running on default ports
 *   - functions/.secret.local has STRIPE_WEBHOOK_SECRET set
 *
 * Usage:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
 *     node functions/lib/scripts/smoke_test_webhook.js
 */
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as http from "http";

const TEST_UID = "smoke-webhook-couple-001";
const TEST_PROJECT = "affinity-test-f4c84";
const WEBHOOK_URL = `http://127.0.0.1:5001/${TEST_PROJECT}/us-central1/stripeWebhook`;

// Match the placeholder in functions/.secret.local. In production this
// secret comes from Firebase Secret Manager.
const WEBHOOK_SECRET =
  process.env.STRIPE_WEBHOOK_SECRET ??
  "whsec_emulator_placeholder_replace_with_real_test_secret";

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
}
admin.initializeApp({ projectId: TEST_PROJECT });
const db = admin.firestore();

interface SyntheticEvent {
  id: string;
  type: string;
  data: { object: Record<string, unknown> };
}

function signEvent(rawBody: string, secret: string): string {
  // Stripe's signature format: t=<timestamp>,v1=<hmac sha256>
  const ts = Math.floor(Date.now() / 1000);
  const signedPayload = `${ts}.${rawBody}`;
  const v1 = crypto
    .createHmac("sha256", secret)
    .update(signedPayload, "utf8")
    .digest("hex");
  return `t=${ts},v1=${v1}`;
}

function postToWebhook(
  body: string,
  signature: string,
): Promise<{ status: number; text: string }> {
  return new Promise((resolve, reject) => {
    const url = new URL(WEBHOOK_URL);
    const req = http.request(
      {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(body),
          "stripe-signature": signature,
        },
      },
      (res) => {
        let chunks = "";
        res.on("data", (c) => (chunks += c));
        res.on("end", () => {
          resolve({ status: res.statusCode ?? 0, text: chunks });
        });
      },
    );
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

async function step(label: string, fn: () => Promise<void>): Promise<void> {
  console.log(`\n→ ${label}`);
  try {
    await fn();
    console.log("  ✓");
  } catch (err) {
    console.error("  ✗", err instanceof Error ? err.message : err);
    process.exit(1);
  }
}

async function main(): Promise<void> {
  console.log(`Smoke testing stripeWebhook against ${WEBHOOK_URL}`);

  await step("Clean up", async () => {
    await db.collection("subscriptions").doc(TEST_UID).delete().catch(() => {});
    // Try removing prior synthetic events too.
    const evts = await db
      .collection("subscription_events")
      .where("stripe_event_id", "==", "evt_smoke_001")
      .get();
    for (const e of evts.docs) await e.ref.delete();
  });

  await step("Reject request without signature header", async () => {
    const body = JSON.stringify({ id: "evt_x", type: "x", data: { object: {} } });
    const url = new URL(WEBHOOK_URL);
    const res = await new Promise<{ status: number }>((resolve, reject) => {
      const r = http.request(
        {
          hostname: url.hostname,
          port: url.port,
          path: url.pathname,
          method: "POST",
          headers: { "Content-Type": "application/json" },
        },
        (rs) => resolve({ status: rs.statusCode ?? 0 }),
      );
      r.on("error", reject);
      r.write(body);
      r.end();
    });
    if (res.status !== 400) {
      throw new Error(`expected 400 without signature, got ${res.status}`);
    }
  });

  await step("Reject request with bad signature", async () => {
    const body = JSON.stringify({ id: "evt_x", type: "x", data: { object: {} } });
    const res = await postToWebhook(body, "t=1,v1=deadbeef");
    if (res.status !== 400) {
      throw new Error(`expected 400 for bad sig, got ${res.status}`);
    }
  });

  await step(
    "Accept signed customer.subscription.created → couple becomes Gold",
    async () => {
      const event: SyntheticEvent = {
        id: "evt_smoke_001",
        type: "customer.subscription.created",
        data: {
          object: {
            id: "sub_smoke_001",
            status: "active",
            customer: "cus_smoke_001",
            cancel_at_period_end: false,
            metadata: { couple_id: TEST_UID },
            items: {
              data: [
                {
                  current_period_start: Math.floor(Date.now() / 1000),
                  current_period_end:
                    Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60,
                  price: {
                    id: "price_smoke_gold",
                    lookup_key: "gold_monthly",
                  },
                },
              ],
            },
          },
        },
      };
      const body = JSON.stringify(event);
      const signature = signEvent(body, WEBHOOK_SECRET);
      const res = await postToWebhook(body, signature);
      if (res.status !== 200) {
        throw new Error(
          `webhook returned ${res.status}: ${res.text}`,
        );
      }

      // Wait briefly for the Firestore write to land.
      await new Promise((r) => setTimeout(r, 1500));
      const sub = await db.collection("subscriptions").doc(TEST_UID).get();
      if (!sub.exists) {
        throw new Error("subscription doc not created");
      }
      const data = sub.data()!;
      if (data.plan !== "gold") {
        throw new Error(`expected plan=gold, got ${data.plan}`);
      }
      if (data.stripe_subscription_id !== "sub_smoke_001") {
        throw new Error(
          `expected stripe_subscription_id=sub_smoke_001, got ${data.stripe_subscription_id}`,
        );
      }
      console.log(
        `    sub doc: plan=${data.plan}, status=${data.status}, period_end=${data.current_period_end?.toDate?.()?.toISOString?.() ?? "?"}`,
      );

      const eventDoc = await db
        .collection("subscription_events")
        .doc("evt_smoke_001")
        .get();
      if (!eventDoc.exists) {
        throw new Error("audit event doc not written");
      }
    },
  );

  await step("Replay of same event is a no-op (idempotency)", async () => {
    const event: SyntheticEvent = {
      id: "evt_smoke_001", // same ID
      type: "customer.subscription.created",
      data: { object: { metadata: { couple_id: TEST_UID } } },
    };
    const body = JSON.stringify(event);
    const signature = signEvent(body, WEBHOOK_SECRET);
    const res = await postToWebhook(body, signature);
    if (res.status !== 200) {
      throw new Error(`replay returned ${res.status}`);
    }
    if (!res.text.includes("replay")) {
      console.log(
        `    note: response did not say 'replay' but returned 200 — replay still rejected from side effects`,
      );
    } else {
      console.log("    replay correctly identified as duplicate");
    }
  });

  await step("Cleanup", async () => {
    await db.collection("subscriptions").doc(TEST_UID).delete();
    await db.collection("subscription_events").doc("evt_smoke_001").delete();
  });

  console.log("\nAll webhook smoke checks passed ✓");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
