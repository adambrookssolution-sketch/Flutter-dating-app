# Affinity — Integration Guide

> Internal reference for the day Gabriel's branch merges with the
> agency's phase 2 code. Goal: zero collisions, zero edits to the
> agency's existing files, zero broken flows.
>
> Read this first when starting the merge.

---

## The cardinal rule

**Never edit the agency's files.** Every feature we ship lives in its
own folder, exposes one entry point (a widget or a single function),
and is wired into the agency's app via a single import + a single
call site. If the agency rolls back, our code is dormant but
present — nothing breaks.

If the merge requires editing an agency file, the change is limited
to:
- **Add an import** (one line)
- **Insert a widget** (one line in a build method)
- **Insert a route** (one line in the routing table)

Never delete, never rename, never reshape an existing function in
their files.

---

## Module inventory — what we own

Each row is a self-contained module. Drop the folder in, add the
listed integration line, ship.

| Module | Owns | Integration point |
|---|---|---|
| `lib/admin/` + `lib/main_admin.dart` | Whole moderation web app | Separate Flutter Web entry, deployed to its own Hosting site |
| `lib/core/subscription/` | Plan / status enums + price keys | Imported by `lib/data/datasource/subscription_datasource.dart` and any UI that gates on plan |
| `lib/core/security/` | Watermark + secure view widget | `SecureView(child: ...)` wrapper widget |
| `lib/core/notifications/` | FCM service | One `FcmService.register()` call after sign-in |
| `lib/core/geo/` | GeoHash utility | Pure function, no side effects |
| `lib/data/models/couple.dart` | Couple model (new schema) | New shape, lives next to legacy `UserProfile` |
| `lib/data/models/subscription.dart` | Subscription state | Read by Riverpod provider |
| `lib/data/datasource/couples_datasource.dart` | New `couples/*` reads/writes | Adapter that also tolerates legacy `profiles/*` shape |
| `lib/data/datasource/subscription_datasource.dart` | Stripe-side reads + callable wrappers | Stateless utility |
| `lib/data/datasource/verification_datasource.dart` | Video upload + status updates | Self-contained |
| `lib/data/datasource/blocks_datasource.dart` | Block list + bidirectional silent block | Self-contained |
| `lib/data/datasource/reports_datasource.dart` | Report write + auto-block | Self-contained |
| `lib/data/datasource/message_requests_datasource.dart` | Request preflight + send + cooldown | Self-contained |
| `lib/data/datasource/trips_datasource.dart` | Trip CRUD + match query | Self-contained |
| `lib/data/datasource/recovery_datasource.dart` | Password reset attempt log | Self-contained |
| `lib/providers/filters_provider.dart` | Riverpod filter state (km radius, age, tags, travel) | Used only by Filters screen and feed |
| `lib/providers/subscription_provider.dart` | Live subscription stream | Used wherever a paid feature is gated |
| `lib/presentation/pages/filters/` | Filters bottom-sheet panel | Wired via `_openFiltersSheet()` in `couples_screen.dart` |
| `lib/presentation/pages/subscription/` | Paywall + "Tu plan" screens | Imported routes |
| `lib/presentation/pages/trips/` | Manage trips, add trip, travel match | Linked from Profile menu |
| `lib/presentation/pages/security/` | Block management screen | Linked from Profile menu |
| `lib/presentation/pages/settings/` | Account settings + delete + cancel | Linked from Profile menu |
| `lib/presentation/pages/report/` | Report flow | Linked from chat overflow + couple card overflow |
| `lib/presentation/pages/verification/` | Intro, record, pending, rejected screens | Linked from `navigateAfterSignIn` |
| `lib/presentation/widgets/secure_view.dart` | Screenshot protection wrapper | Wraps sensitive widgets |
| `lib/presentation/widgets/sticky_feed_actions.dart` | Bottom-pinned Start Conversation CTA | Drop into feed Column |
| `lib/presentation/widgets/pineapple_filter_button.dart` | Top-right filter trigger | Drop into AppBar actions |
| `lib/presentation/widgets/places_autocomplete_field.dart` | Google Places search field | Used in profile setup |
| `functions/src/` | All 11 Cloud Functions | Deployed via `firebase deploy --only functions` |
| `firestore.rules` | New security rules | Replaces agency's rules wholesale |
| `firestore.indexes.json` | Composite indexes | Merge with agency's index file |
| `storage.rules` | Storage rules | Replaces agency's |
| `assets/branding/` | Icon + splash placeholders | Replace with creative team's finals |

---

## Integration steps

### Step 1 — Pull agency main into a fresh branch

```bash
git checkout -b integration-agency-phase2
git fetch agency
git merge agency/main --allow-unrelated-histories --no-commit
```

Resolve conflicts only on these high-risk paths (everything else is
ours and additive):

- `pubspec.yaml` — keep the union of dependencies, never drop one of theirs
- `lib/main.dart` — add `ProviderScope` wrapper if missing, keep their routing
- `firestore.indexes.json` — concat both arrays
- `android/app/build.gradle.kts` — keep their applicationId if different from ours

### Step 2 — Verify our datasources still compile against their model

The agency may use a different couple shape (CSV `interests`, flat
`verification_video_url`, etc.). Our `couples_datasource.dart`
already tolerates both shapes via `Couple.fromDoc()` adapter logic.
Run:

```bash
flutter analyze
```

Expected: zero errors. If anything fails, the fix lives in the
adapter, not in the datasource consumers.

### Step 3 — Wire the integration points

Per the inventory table above. Each is a one-liner, in this order:

1. **Filters panel** — already wired in `couples_screen.dart` via
   `_openFiltersSheet()`. Verify the pineapple button is in
   `appBarActions`.
2. **Sticky Start Conversation** — already wired in `couples_option.dart`.
3. **Profile menu items** — Manage Trips, Security, Account
   Settings, Report. Each is a `ListTile` with `onTap: Navigator.push`.
4. **Verification routing** — `navigateAfterSignIn` reads couple
   status and routes to the right verification screen.
5. **FCM registration** — call `FcmService.register()` in
   `navigateAfterSignIn` and `FcmService.unregister()` in sign-out.
6. **Subscription gate** — wrap any paid feature with
   `Consumer(builder: (_, ref, __) { final hasPaid = ref.watch(hasPaidBenefitsProvider); ... })`.

### Step 4 — Cloud Functions

Functions are deployed independently and don't conflict with the
agency's app code. Deploy them last so the app is ready to consume:

```bash
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only storage:rules
firebase deploy --only functions
```

### Step 5 — Migration (one-time, after step 4)

```bash
node functions/lib/scripts/migrate_profiles_to_couples.js \
  --write \
  --project=affinity-dating-app-cf807
```

Run dry-run first:

```bash
node functions/lib/scripts/migrate_profiles_to_couples.js \
  --dry-run \
  --project=affinity-dating-app-cf807
```

---

## Feature-flag rollout

Every new feature is gated behind a flag in
`lib/core/feature_flags.dart`. Default values:

```dart
class FeatureFlags {
  static const bool subscriptionsEnabled = false;  // until Stripe live
  static const bool travelMatchEnabled = true;
  static const bool advancedFiltersEnabled = true;
  static const bool screenshotProtectionEnabled = true;
  static const bool fcmEnabled = true;
}
```

If a feature breaks in production, set its flag to `false` in a
single line, redeploy, and the rest of the app keeps running.

---

## Adapter layer — the safety net

The `Couple.fromDoc()` factory in `lib/data/models/couple.dart`
accepts both shapes:

| Field | New shape | Legacy / agency shape |
|---|---|---|
| Interests | `dynamics: []`, `experience_preferences: []`, `interests: []` | `interests: "csv,string"` |
| Verification | `verification: { video_url, … }` map | flat `verification_video_url` |
| Trips | `couples/{id}/trips/*` subcollection | top-level `trips/*` |
| Photos | `photos: [string]` array | `photos_urls: [string]` array |

If the adapter encounters an unknown field, it falls back to the
default value — never throws. Production logs every unknown field
once per session for observability.

---

## What NOT to do during merge

- ❌ Edit the agency's `auth_screen.dart`, `sign_in_form.dart`,
  or `sign_up_form.dart`. They work; we extend the post-sign-in
  flow via `navigateAfterSignIn`.
- ❌ Edit the agency's chat screen rendering. We hook in via the
  overflow menu only.
- ❌ Replace the agency's `pubspec.yaml`. Always merge, never
  overwrite.
- ❌ Delete legacy `profiles/*` documents in production until the
  migration has run AND been validated AND a 7-day window has
  passed with no consumer complaints.
- ❌ Rename any agency file or class. If a name collides, we
  prefix ours (e.g. `CouplesDatasource` is ours, not `ProfileDatasource`).

---

## Rollback plan

Every step is reversible. The order of operations to roll back:

1. `firebase hosting:rollback admin --project=...` — admin panel back to prior version
2. `firebase functions:rollback ... --project=...` — Cloud Functions
3. Re-deploy prior `firestore.rules`
4. If migration was run: restore Firestore from the pre-migration
   export (see `production_migration_plan.md` step 2)

We never delete data destructively. Worst case is a 5-minute restore.

---

## Pre-merge checklist for the agency dev

If the agency dev is going to do the merge themselves, they need:

- [ ] Read this file end-to-end
- [ ] Read `production_migration_plan.md`
- [ ] Read `subscription_architecture.md` if subscriptions are in scope
- [ ] Have access to the test Firebase project for verification
- [ ] Run `flutter analyze` after each conflict resolution
- [ ] Run `cd functions && npm run build` after touching anything in `functions/`
- [ ] Run `cd firestore-tests && npm test` after touching `firestore.rules`

If any of those steps fails, stop and ask. Don't push.

---

**End of integration guide.**
