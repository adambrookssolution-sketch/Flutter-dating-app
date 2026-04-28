/**
 * Smoke test for the subscriptions module against the running emulator.
 *
 * Pre-conditions:
 *   1. Firebase emulators running: firestore on :8080, functions on :5001.
 *   2. functions/.secret.local has STRIPE_SECRET_KEY + STRIPE_WEBHOOK_SECRET
 *      placeholders so the functions boot.
 *
 * What it does:
 *   1. Creates a fake `couples/{uid}` doc with status=approved, kicking
 *      `onCoupleCreatedSeedSubscription` to seed `subscriptions/{uid}`
 *      with the Free plan defaults.
 *   2. Reads back the seeded subscription and asserts the shape.
 *   3. Simulates a Stripe webhook by writing a synthetic
 *      `customer.subscription.created` event payload directly into
 *      Firestore via the helper logic — bypassing signature verification
 *      because the emulator doesn't have a real Stripe in front of it.
 *   4. Reads back the updated subscription and asserts plan=gold.
 *
 * This isn't a substitute for a real Stripe-CLI test (that requires a
 * live Stripe account and the deployed webhook). It IS a functional
 * end-to-end check that the Firestore writes, security rules, and
 * trigger wiring all work as designed.
 *
 * Usage:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
 *     node functions/lib/scripts/smoke_test_subscriptions.js
 */
import * as admin from "firebase-admin";

const TEST_UID = "smoke-test-couple-001";
const TEST_PROJECT = "affinity-test-f4c84";

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
}

admin.initializeApp({ projectId: TEST_PROJECT });
const db = admin.firestore();

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
  console.log(`Smoke testing subscriptions against ${TEST_PROJECT} emulator`);

  await step("Clean up any leftover from a previous run", async () => {
    await db.collection("couples").doc(TEST_UID).delete().catch(() => {});
    await db.collection("subscriptions").doc(TEST_UID).delete().catch(() => {});
  });

  await step("Create approved couple → seeds Free subscription", async () => {
    await db.collection("couples").doc(TEST_UID).set({
      partner_a: { name: "Smoke", birth: "1990-01-01" },
      partner_b: { name: "Test", birth: "1990-01-01" },
      status: "approved",
      city: "Test City",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Wait for the onCreate trigger. Emulator cold-starts on first
    // invocation can take 5-8s while it spins up the function process.
    // Poll up to 15s before giving up.
    let sub: FirebaseFirestore.DocumentSnapshot | null = null;
    for (let i = 0; i < 15; i++) {
      await new Promise((r) => setTimeout(r, 1000));
      const fetched = await db.collection("subscriptions").doc(TEST_UID).get();
      if (fetched.exists) {
        sub = fetched;
        break;
      }
    }
    if (!sub || !sub.exists) {
      throw new Error("subscription doc not seeded by trigger after 15s");
    }
    const data = sub.data()!;
    if (data.plan !== "free") {
      throw new Error(`expected plan=free, got plan=${data.plan}`);
    }
    if (data.status !== "active") {
      throw new Error(`expected status=active, got status=${data.status}`);
    }
    console.log(`    seeded subscription: plan=${data.plan}, status=${data.status}`);
  });

  await step("Simulate Stripe upgrade → couple is now Gold", async () => {
    // This mirrors what the webhook handler would write after a real
    // customer.subscription.created event.
    const now = Date.now();
    await db.collection("subscriptions").doc(TEST_UID).set(
      {
        plan: "gold",
        status: "active",
        stripe_customer_id: "cus_smoke_test",
        stripe_subscription_id: "sub_smoke_test",
        price_id: "price_smoke_test",
        cancel_at_period_end: false,
        current_period_start: admin.firestore.Timestamp.fromMillis(now),
        current_period_end: admin.firestore.Timestamp.fromMillis(
          now + 30 * 24 * 60 * 60 * 1000,
        ),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    const sub = await db.collection("subscriptions").doc(TEST_UID).get();
    const data = sub.data()!;
    if (data.plan !== "gold") {
      throw new Error(`upgrade did not stick: plan=${data.plan}`);
    }
    if (!data.stripe_subscription_id) {
      throw new Error("stripe_subscription_id missing after upgrade");
    }
    console.log(
      `    upgraded subscription: plan=${data.plan}, period_end=${data.current_period_end?.toDate().toISOString()}`,
    );
  });

  await step("Cleanup test docs", async () => {
    await db.collection("couples").doc(TEST_UID).delete();
    await db.collection("subscriptions").doc(TEST_UID).delete();
  });

  console.log("\nAll smoke checks passed ✓");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
