# Affinity Subscriptions — Technical Architecture

> **Status:** design draft (pre-client-approval)
> **Author:** Gabriel · 2026-04-25
> **Purpose:** blueprint for the Stripe-based subscription module so that
> when the client green-lights the proposal, Entrega 1 can ship within
> 24 hours. This document is internal — not for the client.

---

## 1. High-level flow

```
┌──────────────┐   1. Tap "Upgrade"   ┌─────────────────────────┐
│ Affinity app │ ────────────────────▶│ In-app "Tu plan" screen │
│   (Flutter)  │                      │  (no prices, no CTA      │
│              │◀───── 5. /me/sync ───│   copy that Apple flags) │
└──────┬───────┘                      └───────────┬─────────────┘
       │                                          │
       │ 2. "Open web checkout"                   │
       ▼                                          │
┌──────────────────────┐                          │
│ Landing (affinity.   │                          │
│ club/premium)        │                          │
│  — Stripe Checkout   │                          │
└──────┬───────────────┘                          │
       │                                          │
       │ 3. customer pays                         │
       ▼                                          │
┌──────────────────────┐                          │
│ Stripe servers       │                          │
│  — subscription.*    │                          │
│  — invoice.*         │                          │
└──────┬───────────────┘                          │
       │ 4. webhook (HMAC-signed)                 │
       ▼                                          │
┌──────────────────────┐                          │
│ Cloud Function       │                          │
│ stripeWebhook        │                          │
│  — verify signature  │                          │
│  — idempotency check │                          │
│  — write Firestore   │                          │
└──────┬───────────────┘                          │
       │                                          │
       ▼                                          │
┌──────────────────────────────────────────────┐  │
│ Firestore                                    │  │
│  subscriptions/{couple_id}                   │──┘  (app reads on next auth)
│    plan, status, period_end, etc.            │
│  subscription_events/{event_id}              │
│    raw Stripe payloads for audit             │
└──────────────────────────────────────────────┘
```

Three cardinal rules:

1. **Single source of truth is Stripe**, mirrored into Firestore.
   Firestore state is recomputed from Stripe events, never authored
   client-side.
2. **iOS app never shows a price.** Apple Guideline 3.1.3(b) compliance
   is enforced at the UI layer — the "Tu plan" screen is deliberately
   copy-thin.
3. **All permissions checked server-side first.** Security rules
   validate `subscriptions/{uid}.plan` on every privileged write
   (e.g. unlimited message requests). Clients can cache plan info
   for UX but cannot forge it.

---

## 2. Firestore schema

### `subscriptions/{coupleId}`

| Field                 | Type             | Notes                                                                   |
|-----------------------|------------------|-------------------------------------------------------------------------|
| `plan`                | string enum      | `free` \| `gold` \| `black`                                             |
| `status`              | string enum      | `active` \| `past_due` \| `canceled` \| `trialing` \| `incomplete`      |
| `stripe_customer_id`  | string?          | `cus_…`; null until first paid upgrade                                  |
| `stripe_subscription_id` | string?       | `sub_…`                                                                 |
| `current_period_start`| timestamp?       | Stripe's `current_period_start`                                          |
| `current_period_end`  | timestamp?       | Stripe's `current_period_end` — UI shows "Se renueva el {date}"          |
| `cancel_at_period_end`| bool             | true if user clicked "Cancel subscription" — benefits keep until period_end |
| `price_id`            | string?          | `price_…` so we can tell monthly/annual                                  |
| `updated_at`          | timestamp        | server timestamp, written by CF                                          |
| `created_at`          | timestamp        | server timestamp, written by CF                                          |

**Default document on couple creation:** `{plan: "free", status: "active"}`.
Created by a Cloud Function trigger on `couples` insert so the app can
read the doc without nullability handling.

### `subscription_events/{eventId}`

Audit-only, write-once, read by back-office:

| Field          | Type      | Notes                                                  |
|----------------|-----------|--------------------------------------------------------|
| `type`         | string    | Stripe event type, e.g. `customer.subscription.updated`|
| `couple_id`    | string?   | Resolved via customer metadata                          |
| `stripe_event_id` | string | Used for idempotency — CF aborts if already present    |
| `payload`      | map       | Full Stripe event object (for debugging)               |
| `processed_at` | timestamp | Server timestamp                                        |

### `subscriptions_history/{coupleId}/changes/{eventId}` (optional, later)

Per-couple rolling history of plan changes. Useful for analytics; not
required for MVP.

---

## 3. Cloud Functions

### 3.1 `stripeWebhook` — HTTP endpoint

Location: `functions/src/subscriptions/stripeWebhook.ts`

Responsibilities:
1. Verify Stripe signature (raw request body + `STRIPE_WEBHOOK_SECRET`).
2. Parse event. Dispatch by type:
   - `checkout.session.completed`  → first subscription confirmation
   - `customer.subscription.created|updated|deleted` → sync plan/status
   - `invoice.payment_succeeded|failed` → update period_end, flag `past_due`
3. Resolve `couple_id` from `event.data.object.metadata.couple_id`
   (set at Checkout creation time, see §4).
4. Idempotency: check `subscription_events/{stripe_event_id}` exists;
   if so, return 200 without re-processing.
5. Write to `subscriptions/{couple_id}` (merge) + append to
   `subscription_events/{stripe_event_id}`.

Runtime: gen2, nodejs22, 512 MB, region `us-central1`.
Secret: `STRIPE_WEBHOOK_SECRET` via Firebase Secret Manager.

### 3.2 `createCheckoutSession` — callable

Location: `functions/src/subscriptions/createCheckoutSession.ts`

Called by the app (or by the web landing) when a user clicks "Upgrade".

Input:
```ts
{ priceId: string, returnUrl: string }
```

Steps:
1. Auth required (`context.auth.uid` present).
2. Load `couples/{uid}` — confirm approved status (can't buy before verification).
3. Reuse or create `stripe_customer_id`:
   - First purchase: `stripe.customers.create({ email, metadata: { couple_id: uid } })`, persist.
   - Subsequent: fetch from Firestore.
4. `stripe.checkout.sessions.create({…, metadata: { couple_id: uid }})`.
5. Return `{ url }` — client opens it via `url_launcher`.

### 3.3 `cancelSubscription` — callable

Simple wrapper that sets `cancel_at_period_end = true` on Stripe. Keeps
UX inside the app (no need to bounce to Stripe's portal).

### 3.4 `onCoupleCreated` — Firestore trigger (patch existing)

Extend the existing couple creation hook to seed
`subscriptions/{coupleId}` with the default Free plan.

### 3.5 `retryPastDue` — scheduled (optional for MVP)

Every 12 hours: scan `subscriptions` where `status = past_due` for >3 days,
downgrade to `free` and emit an in-app notification. Stripe already
retries 4 times in 14 days by default, so this is just the final cleanup.

---

## 4. Stripe configuration (to be created at project bootstrap)

### Products
- **Affinity Gold** — product
  - Price: Gold Monthly, USD 14.99, recurring monthly, lookup_key `gold_monthly`
  - Price: Gold Annual, USD 119.99, recurring yearly, lookup_key `gold_annual`
- **Affinity Black** — product
  - Price: Black Monthly, USD 39.99, recurring monthly, lookup_key `black_monthly`
  - Price: Black Annual, USD 349.99, recurring yearly, lookup_key `black_annual`

### Webhook endpoint
- URL: `https://us-central1-{project}.cloudfunctions.net/stripeWebhook`
- Events: subscribe to `checkout.session.completed`,
  `customer.subscription.*`, `invoice.payment_succeeded`,
  `invoice.payment_failed`.

### Metadata convention
Every Checkout session and Customer carries `metadata.couple_id = {firebase uid}`.
This is the bridge between Stripe's world and ours.

---

## 5. Flutter client layer

### 5.1 `lib/core/subscription/subscription_plan.dart`
Immutable enum + price-id-to-plan mapping.

### 5.2 `lib/data/datasource/subscription_datasource.dart`
- `Stream<SubscriptionState> watch(coupleId)` — live subscription doc.
- `Future<String> createCheckoutUrl(priceId)` — calls the CF, returns URL.
- `Future<void> cancelSubscription()` — calls the CF.

### 5.3 `lib/presentation/pages/subscription/`
- `paywall_screen.dart` — tiered comparison UI. Shown on "Upgrade" tap.
- `my_subscription_screen.dart` — "Tu plan" in Perfil. Shows status,
  renewal date, cancel button.

### 5.4 Permission gate widget
`SubscriptionGate(child: Widget, requires: SubscriptionPlan)` — wraps
any feature. On Free it renders a blurred placeholder with "Unlock with
Gold" CTA (that routes to Paywall). Gate logic also lives server-side
via security rules for sensitive writes.

### 5.5 Compliance copy rules
Paywall screen shows **features** but never raw prices. The
"Suscríbete" CTA sends the user to the web landing; prices live only
there. On iOS the CTA text is deliberately vague — e.g. "Ver planes en
la web" — to avoid any implication of in-app purchase flow.

---

## 6. Feature permission matrix (mapped to code changes)

| Feature                              | Free limit          | Gold    | Black   | Enforcement location                                     |
|--------------------------------------|---------------------|---------|---------|----------------------------------------------------------|
| Message requests per week            | 3                   | ∞       | ∞       | CF `canSend` preflight + security rule read              |
| Advanced filters (interests, tags)   | disabled            | enabled | enabled | Riverpod gate in FiltersScreen + ignore on apply         |
| Travel Match window                  | next 30 days only   | unlimited| unlimited| In-memory filter in CouplesOption                       |
| Feed visual priority                 | standard            | boosted | boosted | `couples_datasource.getNearbyCouples` sort weight        |
| Black badge on card                  | —                   | —       | shown   | `couple_card.dart` reads subscription plan               |
| Direct-to-Black (skip request step)  | —                   | —       | yes     | `SendRequestDialog` branches                             |
| See who favorited you                | —                   | yes     | yes     | Security rule + new `favorites` collection              |
| Support channel                      | email               | email   | whatsapp| Content flag in "Account settings" screen               |

Everything above is a simple bool/int derived from `subscriptions.plan`
— no plan-specific code paths deeper than a single check.

---

## 7. Compliance checklist (reused before every store submit)

- [ ] No price tag appears anywhere inside the iOS app binary.
- [ ] No "save X%" / "cheaper online" copy inside the iOS app.
- [ ] "Upgrade" button opens an external browser via `url_launcher`.
- [ ] Web landing is mobile-responsive and works on iOS Safari.
- [ ] Subscription status in "Tu plan" screen reflects Stripe state within 10 s of a webhook event (test with Stripe CLI).
- [ ] Canceled subscriptions keep benefits until `current_period_end` (no immediate downgrade).
- [ ] `past_due` state shows a non-alarming in-app banner ("Tu método de pago necesita atención") linking to the web portal.

---

## 8. Entrega roadmap (mapped to proposal §5)

### Entrega 1 — Backend foundation (40% / USD 800)
- Stripe account bootstrap, products created, webhook endpoint active.
- `subscriptions/{coupleId}` schema live, Firestore rules updated.
- `stripeWebhook` Cloud Function deployed, validated with Stripe CLI.
- `onCoupleCreated` extension seeding Free plan.
- Demo video: running `stripe trigger checkout.session.completed` and
  watching Firestore mutate in real time.

### Entrega 2 — Permission gates + paywall UI (30% / USD 600)
- Flutter `SubscriptionGate` widget + plan enum.
- Paywall screen, "Tu plan" screen.
- Feature permission matrix wired into all 8 places in §6.
- APK delivered for client hands-on testing.

### Entrega 3 — Production rollout + compliance (30% / USD 600)
- Web landing page (`affinity.club/premium`) with Stripe Checkout.
- Panel admin integration: active subscriber count, MRR.
- Apple compliance pass + submission.
- 3–5 min operator video walkthrough.

---

## 9. Risks and mitigations

| Risk                                            | Mitigation                                                                     |
|-------------------------------------------------|--------------------------------------------------------------------------------|
| Apple rejects for "purchase directing"          | Compliance checklist §7 run before every submit. External browser only.        |
| Stripe webhook missed during outage             | Idempotent replay via `subscription_events`. Stripe dashboard replay tool.     |
| User churns then re-subscribes                  | Stripe creates new subscription; `onSubscriptionCreated` handles as fresh start.|
| Refunds / chargebacks                           | Handle in `invoice.payment_refunded`; downgrade plan immediately.              |
| Country blocked (Stripe regional availability)  | Fallback messaging in paywall: "No disponible en tu región; contáctanos".      |
| Tax / VAT compliance                            | Stripe Tax enabled at account creation — handled outside code.                 |

---

## 10. Open questions (for the client response round)

1. Annual plans from launch or monthly-only for MVP? (affects paywall copy).
2. Trial period — 7 days free Gold? Skip entirely?
3. Re-subscription after lapse: keep past filter/favorites state or wipe?
4. Black "direct-to-Black" privilege — mutual or one-way? (does a Black's
   message land in another Black's chat directly, or only if both opted in?)
5. Grandfathering current (pre-launch) users — first 30 days free Gold?

Bring these five into the proposal follow-up so the client feels
**consulted**, not sold to.

---

**End of architecture draft.**
