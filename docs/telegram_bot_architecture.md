# Affinity — Telegram Monetization Bot · Architecture

> **Status:** design draft (pre-client-approval of the bundle offer)
> **Author:** Gabriel · 2026-04-25
> **Purpose:** blueprint for the custom Telegram bot that monetizes the
> client's two existing Telegram groups. If the client accepts the
> bundle offer (Affinity subscriptions + Telegram bot = USD 2,800),
> this doc is the starting point for Entrega 1 of that work.
>
> Internal — not for the client.

---

## 1. What the client asked for (recap)

From the WhatsApp thread, distilled:

1. **Custom bot** (not InviteMember) — the client's own brand, no
   intermediary commission.
2. **Migrate current members to paid** — the bot DMs each existing
   member a personal checkout link; non-payers are auto-removed after
   a grace window.
3. **New members must pay to enter** (same flow as above, no
   migration step).
4. **Own admin panel** — the client sees subscribers, revenue, churn
   without depending on an external dashboard.
5. **Automatic renewals**, with retry-on-failure and automatic removal
   of users whose cards keep failing.

Scope explicitly left out:
- Chat moderation inside the groups (the group admins already do this).
- Content discovery / search inside Telegram.
- Any integration with Affinity data (the two systems share Stripe +
  the subscriber email list, nothing more).

---

## 2. High-level flow

```
Existing group members              New prospects
       │                                   │
       │ one-time migration DM             │ invite link from ad / mouth
       ▼                                   ▼
┌─────────────────────────────────────────────────┐
│ Telegram Bot (Node.js / Telegraf on Cloud Run)  │
│   commands:  /start, /pay, /status, /help       │
│   admin:     /broadcast, /stats                 │
└──────────┬──────────────────────────────────────┘
           │
           │ checkout link
           ▼
    ┌────────────────┐
    │ Stripe Checkout│    (same Stripe account as Affinity)
    └──────┬─────────┘
           │ webhook
           ▼
┌─────────────────────────────────────────────────┐
│ Cloud Function: telegramStripeWebhook           │
│   - mark subscriber paid                        │
│   - create single-use group invite via Bot API  │
│   - DM the invite link to the user              │
│   - log to Firestore telegram_subscribers/      │
└──────────┬──────────────────────────────────────┘
           │
           ▼
  Firestore: telegram_subscribers/{telegram_user_id}
     plan, status, period_end, group_ids, …

           │
           │ renewal / cancel / fail events
           ▼
┌─────────────────────────────────────────────────┐
│ Scheduled function: telegramGroupReconciliation │
│   - daily 06:00 UTC                             │
│   - for any subscriber past_due > 3 days →      │
│     Bot API banChatMember(group_id, user_id)    │
└─────────────────────────────────────────────────┘
```

Three cardinal rules:
1. **Stripe is source of truth** — exactly like Affinity
   subscriptions. The bot never mutates subscription state directly.
2. **Group membership is an effect of subscription state**, not the
   other way round. Cancel subscription → user is banned from groups
   on the next reconciliation pass (max 24 h lag).
3. **No in-app pricing logic on the bot side**. Checkout URLs are
   signed by the server and opened in a browser; the bot itself
   never knows the price.

---

## 3. Firestore schema

### `telegram_subscribers/{telegram_user_id}`

| Field                       | Type              | Notes                                                |
|-----------------------------|-------------------|------------------------------------------------------|
| `telegram_user_id`          | number            | Document ID; stored denormalised for convenience      |
| `username`                  | string?           | `@handle` if set, else null                          |
| `first_name` / `last_name`  | string?           | Cached at join                                       |
| `status`                    | enum              | `pending_payment` \| `active` \| `past_due` \| `canceled` \| `grandfathered` |
| `plan`                      | string            | `monthly` \| `annual` \| `vip_annual`                |
| `stripe_customer_id`        | string?           | null for grandfathered                                |
| `stripe_subscription_id`    | string?           | null for grandfathered                                |
| `current_period_end`        | timestamp?        | When access ends if they don't renew                 |
| `group_ids`                 | array<string>     | Telegram group IDs the user is a member of          |
| `joined_at`                 | timestamp         | When the row was created                             |
| `source`                    | enum              | `migration` \| `new_signup` \| `invited_by_admin`    |
| `removed_at`                | timestamp?        | Non-null once banned from groups                     |

### `telegram_groups/{group_id}`

Static config, manually seeded:

| Field        | Type    | Notes                                                |
|--------------|---------|------------------------------------------------------|
| `name`       | string  | Display name                                         |
| `description`| string  | Shown in the paywall message                         |
| `plan_ids`   | array<string> | Which subscription plans grant access              |
| `active`     | bool    | Toggle to pause a group (e.g. seasonal)             |

### `telegram_events/{event_id}`

Audit trail (bot commands, admin actions, reconciliation decisions).
Same shape as `subscription_events` in the Affinity module — keep it
consistent.

---

## 4. Components

### 4.1 The bot (Node.js)

- **Framework:** Telegraf (stable, typed, actively maintained).
- **Host:** Cloud Run (Blaze plan). Not a Cloud Function — the bot
  needs a persistent HTTP server to receive Telegram webhooks with
  long-polling fallback.
- **Secrets:** `TELEGRAM_BOT_TOKEN`, `STRIPE_SECRET_KEY`,
  `ADMIN_TELEGRAM_USER_IDS` (comma-separated).

Commands:

| Command     | Who can use   | Behaviour                                              |
|-------------|---------------|--------------------------------------------------------|
| `/start`    | anyone        | Welcome + offer. If already active, shows status.     |
| `/pay`      | anyone        | Creates a Stripe Checkout link, DMs it                |
| `/status`   | authenticated | Plan, renewal date, group access list                  |
| `/help`     | anyone        | FAQ in Spanish                                         |
| `/broadcast <msg>` | admins | DM every active subscriber (careful)                   |
| `/stats`    | admins        | MRR, active count, churn last 30 days                  |

### 4.2 Cloud Functions

Co-located with the existing `functions/` codebase so deployments
are a single `firebase deploy`:

- `telegramStripeWebhook` — HTTP trigger, signed by Stripe, same
  idempotency pattern as the Affinity module.
- `onTelegramSubscriberCreated` — Firestore trigger, fires when a new
  row appears in `telegram_subscribers`, DMs the user.
- `telegramGroupReconciliation` — scheduled daily 06:00 UTC. Removes
  `past_due > 3d` and `canceled > 0d` users from their groups via
  `banChatMember`.

### 4.3 Admin panel

Reuse the existing admin web app shell (`lib/main_admin.dart`). Add a
tab "Telegram" that shows:
- Table of active subscribers (sortable by join date / revenue).
- MRR chart (last 90 days).
- Manual "remove from group" button (for moderation, not billing).
- Manual "grandfather this user" button (for edge cases like a friend
  of the client who shouldn't pay).

---

## 5. Migration of current members

The delicate part. The client said both groups already have users.
We DO NOT want to kick out everyone on day zero. Two-phase plan:

### Phase A — Scrape, announce, wait

1. **Scrape current members.** Telethon / MTProto script run once
   with the client's admin account (they provide their API
   credentials). Produces `telegram_subscribers_initial.csv`.
2. **Seed `telegram_subscribers` with `status: grandfathered`** for
   everyone. They stay in the groups, no billing attached yet.
3. **Broadcast the announcement.** Bot DMs each user:

   > "Hola, gracias por ser parte de {group}. A partir del {fecha}
   > necesitamos una suscripción mensual de {precio} para seguir
   > accediendo. Paga aquí → {checkout_url}. Si no puedes pagar, no
   > hay problema — no vamos a quitarte del grupo hasta {fecha + 14d}
   > y siempre puedes volver."

4. **Wait the grace window** (client decides, default 14 days).

### Phase B — Enforce

1. **Reconciliation pass.** Anyone still `grandfathered` at the
   deadline is demoted to `pending_payment` with a final reminder DM.
2. **Seven days after that**, anyone still `pending_payment` is
   banned from the group via `banChatMember`. Their
   `telegram_subscribers` row stays (row for analytics + re-subscribe).

This two-phase approach keeps the client from losing goodwill while
still enforcing the new revenue model. The whole mechanism is driven
by the `telegramGroupReconciliation` scheduled function so the
client doesn't have to do anything manually.

---

## 6. Stripe configuration

Same Stripe account as Affinity (client wanted unified billing). New
products:

- **Telegram Group Access** — product
  - Price: Monthly, USD 9.99, lookup_key `telegram_monthly`
  - Price: Annual, USD 99.99, lookup_key `telegram_annual`
- **Telegram VIP Tier** (optional, phase 2) — product
  - Price: Annual, USD 299.99, lookup_key `telegram_vip_annual`

(Price points are placeholders — the client will set them; the
architecture is plan-agnostic.)

Webhook endpoint: `https://us-central1-{project}.cloudfunctions.net/telegramStripeWebhook`.

Metadata convention: every Checkout session carries
`metadata.telegram_user_id = {id}` so the webhook can resolve the
subscriber in Firestore.

---

## 7. Bundling with Affinity

Since both systems share the Stripe account, we can do exciting things
later (not MVP):

- An Affinity Black subscriber gets free Telegram group access.
- A Telegram subscriber gets 50% off Affinity Gold.
- Unified "my subscriptions" screen showing both across platforms.

These are natural extensions. The base architecture already supports
them through the shared Stripe `customer` object — if we set
`metadata.couple_id` AND `metadata.telegram_user_id` on the same
Customer, cross-linking is automatic.

MVP scope: keep them independent, ship value first, cross-link later.

---

## 8. Entregas (if the client accepts the bundle)

### Entrega 1 — Bot + Stripe plumbing (40%)
- Telegraf bot on Cloud Run, responding to `/start`, `/pay`, `/status`.
- Stripe products + webhook → Firestore sync working end-to-end.
- One live test transaction with a real card.

### Entrega 2 — Migration + enforcement (30%)
- Member scrape script.
- Broadcast function.
- Reconciliation function (removes non-payers).
- Grace-window logic tuned to the client's chosen deadline.

### Entrega 3 — Admin panel + handoff (30%)
- "Telegram" tab in admin web app.
- MRR chart + subscriber list.
- Manual actions (grandfather / remove).
- 5 min operator video walkthrough.

The Entrega boundaries match the Affinity subscription module so the
client sees a consistent delivery cadence across both tracks.

---

## 9. Risks

| Risk                                            | Mitigation                                                     |
|-------------------------------------------------|----------------------------------------------------------------|
| Telegram bans the bot for mass-DMing migrators | Rate-limit to 30 DMs/minute. Stagger the broadcast over hours. |
| Member scrapes their way back after ban         | `banChatMember` is permanent by default. Re-subscribe lifts it. |
| Stripe account gets flagged for adult content   | Use a separate "products" category on Stripe; provide the moderation policy URL. |
| Client's admin account loses access to MTProto API | Document the scrape step so any admin account can re-run it. |
| Group owner rotates — bot loses admin rights    | Health check on boot: bot verifies it's still admin in every group, alerts the owner. |
| Chargebacks                                      | Stripe dispute flow; subscriber auto-demoted to past_due until resolved. |

---

## 10. Open questions for the client

1. Monthly only for MVP, or bake in annual from day 1?
2. Grandfather window — 7 / 14 / 30 days?
3. Prices (per group and per plan)?
4. Both groups one combined subscription, or per-group pricing?
5. What do we do for users who were members, lapsed, then return?

Roll these into the subscription-proposal follow-up so the client
feels consulted rather than pitched.

---

**End of Telegram bot architecture draft.**
