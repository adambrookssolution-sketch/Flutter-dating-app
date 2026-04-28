# Subscriptions go-live — production deploy runbook

> One-shot runbook for the moment the client activates Blaze on the
> production Firebase project + creates her Stripe account. Everything
> below is mechanical: copy commands, paste, verify.
>
> Total wall-clock: ~30 minutes from Blaze flip to first live test
> charge sitting in Firestore.

---

## Pre-conditions

- Affinity production Firebase project (`affinity-dating-app-cf807`)
  is on the **Blaze** plan.
- The client has created a Stripe account (alejandra@... or the
  business one) and shared **owner-level access** with us (or, more
  cleanly, gave us admin-of-only-test-mode access — same flow either
  way).
- Local checkout of master with all our subscriptions code (this
  branch) is up to date.
- Stripe CLI installed locally:
  `https://stripe.com/docs/stripe-cli`

---

## Step 1 — Stripe configuration (one-time)

### 1a. Create the four products

In Stripe Dashboard → Products → "+ Add product":

| Product name      | Price        | Recurring | Lookup key       |
|-------------------|--------------|-----------|------------------|
| Affinity Gold     | USD 14.99    | Monthly   | `gold_monthly`   |
| Affinity Gold     | USD 119.99   | Yearly    | `gold_annual`    |
| Affinity Black    | USD 39.99    | Monthly   | `black_monthly`  |
| Affinity Black    | USD 349.99   | Yearly    | `black_annual`   |

The lookup keys MUST be exact — they're what
`createCheckoutSession` queries by.

### 1b. Grab the test-mode secret key

Dashboard → Developers → API keys → **Test mode toggle ON** →
"Secret key" → reveal → copy. Format: `sk_test_...`

### 1c. Create the webhook endpoint

Dashboard → Developers → Webhooks → "+ Add endpoint":

- URL: `https://us-central1-affinity-dating-app-cf807.cloudfunctions.net/stripeWebhook`
- Events to listen for:
  - `checkout.session.completed`
  - `customer.subscription.created`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
  - `invoice.payment_succeeded`
  - `invoice.payment_failed`

After saving, click into the endpoint → "Signing secret" →
"Click to reveal" → copy. Format: `whsec_...`

---

## Step 2 — Push the secrets to Firebase Secret Manager

```bash
cd d:/app

firebase functions:secrets:set STRIPE_SECRET_KEY \
  --project=affinity-dating-app-cf807
# When prompted, paste sk_test_...

firebase functions:secrets:set STRIPE_WEBHOOK_SECRET \
  --project=affinity-dating-app-cf807
# When prompted, paste whsec_...
```

Both secrets are now in Secret Manager and will be injected into the
function processes at runtime.

---

## Step 3 — Deploy

```bash
cd d:/app

# Rules first so writes are validated as functions arrive.
firebase deploy --only firestore:rules,storage:rules \
  --project=affinity-dating-app-cf807

# Indexes so collection-group queries don't error out.
firebase deploy --only firestore:indexes \
  --project=affinity-dating-app-cf807

# All 15 functions including the new subscription ones.
firebase deploy --only functions \
  --project=affinity-dating-app-cf807
```

The Cloud Build runs for ~5 minutes the first time (Docker image
warm-up). Subsequent deploys are 1–2 minutes.

---

## Step 4 — Verify the webhook is reachable

```bash
curl -sI \
  https://us-central1-affinity-dating-app-cf807.cloudfunctions.net/stripeWebhook
```

Expected: `405 Method Not Allowed` (the function rejects GET on
purpose). That's the green light — DNS resolves, the function
responds, just not to GET.

In Stripe Dashboard → Webhooks → click the endpoint → "Send test
webhook" → pick `customer.subscription.created` → "Send test
webhook". Stripe should report a 200 response within a second.

---

## Step 5 — End-to-end flow with the Stripe CLI

```bash
stripe login                          # one-time
stripe listen \
  --forward-to https://us-central1-affinity-dating-app-cf807.cloudfunctions.net/stripeWebhook
```

In another terminal:

```bash
stripe trigger checkout.session.completed
```

The CLI reports: `--> checkout.session.completed [evt_xxx]`. In the
Firebase console → Firestore → `subscription_events/{evt_xxx}` —
the doc should appear within 2 seconds with the event payload.

---

## Step 6 — Real card test (test mode)

In the live app pointing at production:

1. Sign in as a couple, status=approved.
2. Open Profile → Tu plan → Ver planes → tap Continuar en el
   navegador on the Gold card.
3. The Stripe Checkout page opens in the browser.
4. Use Stripe's test card: `4242 4242 4242 4242`, any future
   expiry, any CVC, any name.
5. Complete the checkout.
6. Within 5 seconds, Firebase console →
   `subscriptions/{couple_uid}` shows `plan: "gold"`, `status:
   "active"`, real `stripe_subscription_id`.
7. Re-open the app → Tu plan → header is now Gold.

That's the full live loop validated.

---

## Step 7 — Flip the feature flag on

Once steps 1–6 are green:

```dart
// lib/core/feature_flags.dart
static const bool subscriptionsEnabled = true;
static const bool subscriptionStatusVisible = true;
```

Re-build the APK (CI does it automatically on push), distribute,
verify.

---

## Rollback

If something breaks:

1. Flip `subscriptionsEnabled` back to `false`, push, redeploy.
   Subscriptions disappear from the UI; the rest of the app keeps
   working.
2. If the webhook itself misbehaves, in Firebase console → Functions →
   `stripeWebhook` → "Disable function". Stripe retries with
   exponential backoff for 3 days, so re-enabling it within that
   window catches up automatically.

---

## Cost expectations

- Functions invocations: < 100/day during MVP. Free tier covers
  several thousand/day.
- Firestore reads/writes: each Stripe event = 1 read + 2 writes
  (subscriptions doc + event audit). Free tier handles 50k/day.
- Stripe takes 2.9% + $0.30 per successful charge. No fixed monthly
  fee.

For the validation phase the entire infrastructure is essentially
free.

---

## What was tested locally before this runbook applies

The webhook handler logic, signature verification, idempotency, and
Firestore mirror writes were all live-tested against the Firebase
emulator — see `functions/src/scripts/smoke_test_webhook.ts` for the
script and the run output in the deploy commit message.

That means by the time we run the steps above against production,
the only new variables are the real Stripe account and the real
network round-trip. Both are observable from Stripe Dashboard +
Firebase logs.

---

**End of runbook.**
