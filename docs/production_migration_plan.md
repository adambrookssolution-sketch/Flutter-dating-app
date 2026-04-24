# Production Migration — Pre-flight Plan

> Internal runbook. Walks everything that has to happen between "client
> hands over production Firebase" and "Affinity is live on production".
>
> Target production project: **affinity-dating-app-cf807** (per
> `.firebaserc`). The dev / test project we've been using is
> **affinity-test-f4c84** — it stays where it is.
>
> Author: Gabriel · 2026-04-25

---

## The migration in one picture

```
affinity-test-f4c84 (Spark)          affinity-dating-app-cf807 (Blaze)
├── subscriptions   (seed docs)      ──► not migrated — start fresh on prod
├── couples         (mirror of       ──► MIGRATED via migrate_profiles_to_couples.ts
│                    legacy)                └─ OR: rebuilt from agency phase 2 output
├── conversations   (test data)      ──► NOT migrated (test noise)
├── message_requests (test data)     ──► NOT migrated
├── reports         (test data)      ──► NOT migrated
├── blocks          (test data)      ──► NOT migrated
├── destinations    (seeded)         ──► RE-SEEDED on prod (new list from client)
└── tags            (seeded)         ──► RE-SEEDED on prod

Rules, indexes, functions           ──► DEPLOYED as-is to prod
```

The production data either comes from:
- **(A)** agency's phase 2 output (if they delivered the real user base), OR
- **(B)** our `migrate_profiles_to_couples.ts` if the agency delivered a
  legacy `profiles/*` collection we have to translate.

Both paths are covered below.

---

## Gate before touching production

None of the following may happen until ALL of the items below are
green:

- [ ] Client (Alejandra) has handed over owner-level access to the
      production Firebase project.
- [ ] Agency phase 2 is merged into our codebase and
      `flutter analyze` is clean.
- [ ] Production `google-services.json` + `GoogleService-Info.plist`
      are in place (we're running against the real Firebase config).
- [ ] Production project is on the **Blaze** plan (required for
      Cloud Functions + Storage).
- [ ] Production Firebase Auth sign-in methods enabled (Email/Password,
      Google, Apple as needed).
- [ ] SendGrid / Mailgun credentials for the custom recovery email
      transport are available.
- [ ] GCP Places API key restricted to production Android + iOS
      bundle IDs is available.

Anything missing → stop. Don't run a partial migration.

---

## Step 1 — Dry-run rehearsal on the test project

Rehearse the entire script against the test project with `--dry-run`
so the team sees every log line it would produce.

```bash
cd d:/app/functions
npm run build  # compile TypeScript

GOOGLE_APPLICATION_CREDENTIALS=d:/app/sa-key.json \
  node lib/scripts/migrate_profiles_to_couples.js \
  --dry-run \
  --project=affinity-test-f4c84
```

Expected output:
```
Target: affinity-test-f4c84 (dry-run)
  Scanning profiles/*…
    profiles/<uid> → couples/<uid>  (her_name=…, city=…)
    …
  Done. Would convert N profiles. 0 writes performed.
```

Failure modes to check:
- Any profile with missing `her_birth` or `his_birth` → logs a warning,
  skipped.
- Any profile whose `city` can't be geocoded → skipped with warning.
- Rate-limit from Google Geocoding → script pauses 100ms between calls
  already; if the batch is huge (>1000), do it in chunks.

Sample 5 random conversions; if they look right, proceed.

---

## Step 2 — Snapshot the production project before any write

### 2a. Firestore export

```bash
gcloud firestore export gs://affinity-dating-app-cf807-backups/pre-migration-$(date -u +%Y%m%dT%H%M%S) \
  --project=affinity-dating-app-cf807
```

Export completes in a few minutes for a small dataset. Keep the bucket
contents for 30 days minimum — this is our rollback pill.

### 2b. Storage snapshot

Storage isn't bulk-snapshottable from the CLI, so either:
- Use `gsutil -m cp -r gs://<source>/* gs://<backup>/…` (pay for
  egress, acceptable for a small app), OR
- Rely on the fact that we don't delete Storage objects during
  migration (we only write).

### 2c. Auth snapshot (most critical)

```bash
firebase auth:export d:/app/backups/production-auth-$(date -u +%Y%m%d).json \
  --project=affinity-dating-app-cf807 \
  --format=JSON
```

Keep this file out of the repo (it's in `.gitignore` via the `backups/`
rule we'll add).

---

## Step 3 — Deploy infrastructure BEFORE data

Order matters: rules first (so early writes are validated), indexes
second (so queries return immediately after migration), functions
third.

```bash
cd d:/app

# 3a. Security rules
firebase deploy --only firestore:rules,storage:rules \
  --project=affinity-dating-app-cf807

# 3b. Firestore composite indexes
firebase deploy --only firestore:indexes \
  --project=affinity-dating-app-cf807
# Wait for index builds in the console — larger ones take 5-10 min.

# 3c. Cloud Functions (all 11)
firebase deploy --only functions \
  --project=affinity-dating-app-cf807
```

Verify:
- Rules tab in the console shows the uploaded version
- All indexes show "Enabled"
- Functions list shows all 11 Cloud Functions deployed and healthy

---

## Step 4 — Run the actual migration (only if path B applies)

```bash
cd d:/app/functions
GOOGLE_APPLICATION_CREDENTIALS=d:/path/to/production-sa-key.json \
  node lib/scripts/migrate_profiles_to_couples.js \
  --write \
  --project=affinity-dating-app-cf807 \
  --geocode-key=$PROD_GCP_PLACES_KEY
```

**Don't pass `--delete-old` yet.** Legacy `profiles/*` documents stay
in place so the legacy code paths keep working during the handover
window. Delete them only after 1-2 weeks of observed stability.

Expected: one warning per partially-populated legacy profile (missing
birth dates, unusable city strings). Capture the log and send it to
the client as a handover artefact.

---

## Step 5 — Seed Destinations and Tags

The Travel Match destinations list and the three Tag categories
(Dynamics / Experience / Interests) are seeded on each environment
separately — they're not migrated.

```bash
cd d:/app/functions
GOOGLE_APPLICATION_CREDENTIALS=d:/path/to/production-sa-key.json \
  node lib/scripts/seed_test_data.js \
  --project=affinity-dating-app-cf807 \
  --destinations-only \
  --tags-only
```

Destination list comes from the client (we're waiting on the updated
one as of this doc date). Until that arrives, the existing seeds in
the script match the 10 resorts/cruises we proposed.

---

## Step 6 — Create the demo reviewer account

Required for Apple + Google review submissions.

```bash
cd d:/app/functions
GOOGLE_APPLICATION_CREDENTIALS=d:/path/to/production-sa-key.json \
  node lib/scripts/seed_demo_account.js \
  --project=affinity-dating-app-cf807 \
  --email=demo-reviewer@affinitysocialclub.com \
  --password=<rotate-quarterly>
```

The seed script writes:
- Auth user with email + password
- `couples/{uid}` with `status=approved` (bypasses video verification)
- Sample trip and a sample conversation so the reviewer sees real UI
  on first login

Document the rotated password in 1Password under "Affinity / demo
reviewer".

---

## Step 7 — Deploy the admin moderation panel

See [admin_panel_deploy_rehearsal.md](admin_panel_deploy_rehearsal.md)
for the full walkthrough. Short version:

```bash
# One-time site creation on production:
firebase hosting:sites:create affinity-admin \
  --project=affinity-dating-app-cf807
firebase target:apply hosting admin affinity-admin \
  --project=affinity-dating-app-cf807

# Build + deploy:
cd d:/app
/d/flutter/bin/flutter.bat build web -t lib/main_admin.dart --release
firebase deploy --only hosting:admin \
  --project=affinity-dating-app-cf807
```

Final URL: `https://affinity-admin.web.app`.

Mint moderator claims for Alejandra + any designated reviewers via
the `grant_moderator.js` script.

---

## Step 8 — Smoke tests on production

Run through [REGRESSION_CHECKLIST.md](REGRESSION_CHECKLIST.md) on
physical Android + iOS, this time pointing at production:

- [ ] New couple registration → video verification → admin approval
- [ ] Password recovery reaches inbox (not spam)
- [ ] Feed shows real couples, not test data
- [ ] Travel Match returns matches for seeded test trip
- [ ] Request → accept → chat
- [ ] Block + report both work
- [ ] Account deletion 30-day grace period starts

Any failure → freeze on production, hot-fix, redeploy the affected
function only (never redeploy everything on a single fix).

---

## Step 9 — Store submission (separate milestone)

Once smoke tests pass and the admin panel is live, we move to
[STORE_SUBMISSION.md](STORE_SUBMISSION.md) for the Apple + Google
submission process. Not part of this migration doc.

---

## Rollback plan

If step 4 goes wrong:

1. **Restore Firestore from the pre-migration export:**
   ```bash
   gcloud firestore import \
     gs://affinity-dating-app-cf807-backups/pre-migration-<ts> \
     --project=affinity-dating-app-cf807
   ```
   Import replaces the current Firestore contents — minutes for a
   small dataset, confirmable in the console.

2. **Re-deploy the older rules / functions:**
   ```bash
   git checkout <pre-migration-commit>
   firebase deploy --only firestore:rules,firestore:indexes,functions \
     --project=affinity-dating-app-cf807
   git checkout master
   ```

3. **Communicate with the client** — tell Alejandra what was rolled
   back and why within 1 hour. Silent rollbacks destroy trust faster
   than the bug did.

---

## Known integration collision points with the agency's phase 2

When the agency's phase 2 code lands in our repo, these are the
places to check for schema drift before running any migration:

| Area                 | Our shape                  | Likely agency drift         | Resolution |
|----------------------|----------------------------|-----------------------------|------------|
| Couple document      | `couples/{uid}` + split arrays | May still have CSV fields | Merge into both; legacy readers tolerate both shapes |
| Verification field   | `verification.*` map       | May have flat `verification_video_url` | Normalize in `couples_datasource.dart` on read |
| Message requests     | `message_requests/*` separate collection | May still nest in conversations | Keep both paths; our code writes to the new one |
| Trips                | `couples/{uid}/trips/*` subcol | May be top-level `trips/*` | Migrate trips into the subcollection as part of agency merge |
| Image URLs           | `photos: [string]` in couples | May be `photos_urls` | Rename-on-read, don't rewrite legacy docs |
| Tags                 | `tags/*` with category enum | May be free strings | Our seed script normalizes; agency data may need a one-off cleanup |

Zero of these prevent a working MVP — they just add a half day of
glue code. Budget that into the Entrega schedule.

---

**End of production migration plan.**
