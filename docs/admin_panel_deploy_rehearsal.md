# Admin Moderation Panel — Deploy Rehearsal

> Internal runbook for Gabriel. Walks every step of deploying the
> Flutter Web moderation panel to Firebase Hosting on the test
> project. Running this end-to-end proves the path works, so when
> the client's production Firebase is handed over we can deploy in
> under 30 minutes.

---

## What this panel is

A separate Flutter Web app, NOT bundled with the mobile app. Entry
point: [lib/main_admin.dart](../lib/main_admin.dart). Screens live
under [lib/admin/](../lib/admin/).

Features (already coded):
- `AdminLoginScreen` — Firebase Auth login, rejects non-moderator users
- `ModerationQueueScreen` — live stream of `couples` with
  `status == "pending_review"`
- `ModerationReviewScreen` — video player + approve / reject actions
  with predefined rejection reasons

Backend hook: `moderateVerification` Cloud Function enforces
`token.claims.moderator == true` so compromised client code can't
approve anyone.

---

## One-time setup on the Firebase side

The `hosting.admin` target in `firebase.json` is already declared but
unmapped. You need to create a Firebase Hosting site and point the
target at it.

### 1. Create the Hosting site

**Via Firebase Console:**
1. Open https://console.firebase.google.com/project/affinity-test-f4c84/hosting/sites
2. Click "Add another site"
3. Site ID: `affinity-admin-test` (becomes `affinity-admin-test.web.app`)
4. Confirm.

**Or via CLI (requires `firebase login` first):**
```bash
cd d:/app
firebase hosting:sites:create affinity-admin-test --project affinity-test-f4c84
```

### 2. Map the `admin` target to the site

```bash
cd d:/app
firebase target:apply hosting admin affinity-admin-test --project affinity-test-f4c84
```

Verify by re-reading `.firebaserc` — the `targets.affinity-test-f4c84.hosting.admin`
key should now contain `["affinity-admin-test"]`.

### 3. Optional: do the same for `legal`

```bash
firebase hosting:sites:create affinity-legal-test --project affinity-test-f4c84
firebase target:apply hosting legal affinity-legal-test --project affinity-test-f4c84
```

---

## Build the web bundle

```bash
cd d:/app
/d/flutter/bin/flutter.bat build web -t lib/main_admin.dart --release
```

Outputs to `build/web/`. Verify:
```bash
ls build/web/index.html build/web/main.dart.js
```

### Known Windows issue — asset file lock

On Windows the VSCode Dart Analyzer keeps a read handle on
`assets/images/*.png`. When `flutter build web` tries to copy those
files into `build/web/assets/` Gradle's copy task fails with
`PathAccessException: file being used by another process`.

Three mitigations, in order of preference:

1. **Build on GitHub Actions instead** (Ubuntu runner — no lock).
   Extend `.github/workflows/build-apk.yml` with a parallel
   `build-admin-web` job that runs `flutter build web -t lib/main_admin.dart`
   and uploads the `build/web/` artifact. Deploy from there.

2. **Close VSCode, run the build, then reopen.** Works but disrupts
   flow. Useful for one-off local verification.

3. **Build in a fresh PowerShell session where VSCode never opened
   the project.** `cd d:/app; flutter build web -t lib/main_admin.dart`.

Don't try `flutter clean` + retry in a loop — the lock reappears as
soon as Dart Analyzer reindexes.

### Common failures beyond the Windows lock

- Missing Firebase JS config. Flutter Web auto-includes it when
  `lib/firebase_options.dart` is valid — we already have this.
- Wasm dry-run warnings about `flutter_secure_storage_web` using
  `dart:html`. These are warnings, not errors, and can be suppressed
  with `--no-wasm-dry-run`. Ignore for now.

---

## Deploy

```bash
cd d:/app
firebase deploy --only hosting:admin --project affinity-test-f4c84
```

Typical output:
```
✔  hosting[affinity-admin-test]: release complete
Hosting URL: https://affinity-admin-test.web.app
```

---

## Verify end-to-end

1. Open `https://affinity-admin-test.web.app` in a browser.
2. Login page should render with Affinity branding.
3. Try logging in with a non-moderator account → expect a rejection
   message.
4. Mint moderator claim on your own account (see next section) and
   log in again.
5. Queue screen should stream pending verifications (empty if no
   couples submitted video yet — that's fine).

---

## Grant the moderator claim

Without the `moderator: true` custom claim, users are rejected by the
admin app AND by the `moderateVerification` Cloud Function. Two
approaches:

### Option A — One-off via Node shell

```bash
cd d:/app/functions
GOOGLE_APPLICATION_CREDENTIALS=/d/app/sa-key.json node -e "
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'affinity-test-f4c84' });
admin.auth().getUserByEmail('<your-email>')
  .then(u => admin.auth().setCustomUserClaims(u.uid, { moderator: true }))
  .then(() => console.log('Moderator claim granted. Re-login required.'))
  .then(() => process.exit(0));
"
```

### Option B — Use the existing grant_moderator.ts script

Already compiled at `functions/lib/scripts/grant_moderator.js`:

```bash
cd d:/app/functions
GOOGLE_APPLICATION_CREDENTIALS=/d/app/sa-key.json \
  node lib/scripts/grant_moderator.js \
  --project=affinity-test-f4c84 \
  --email=<your-email>
```

After either, the user must **sign out and back in** to pick up the
new token.

---

## Rollback

```bash
firebase hosting:clone affinity-admin-test:live affinity-admin-test:live --project affinity-test-f4c84
# then pick an older release from the hosting releases list in the console.
```

Or redeploy the previous build:
```bash
# if build/web is stale, rebuild from the previous commit:
git stash
git checkout <earlier-commit>
/d/flutter/bin/flutter.bat build web -t lib/main_admin.dart --release
firebase deploy --only hosting:admin --project affinity-test-f4c84
git checkout master
git stash pop
```

---

## Production migration checklist (when the time comes)

When the client's production Firebase is handed over:

- [ ] `firebase hosting:sites:create affinity-admin` on the production project
- [ ] `firebase target:apply hosting admin affinity-admin --project <production-id>`
- [ ] Change `.firebaserc` default back to dev after the deploy
- [ ] Run `firebase deploy --only hosting:admin --project <production-id>`
- [ ] Grant moderator claims to Alejandra + designated reviewers
- [ ] Share `https://affinity-admin.web.app` with the client
- [ ] Record short Loom walkthrough so reviewers know the workflow

---

## Security considerations

1. **Admin app is public but useless without the claim.** Anyone can
   visit the URL; only users with `moderator: true` pass the login
   gate. The gate is enforced both on the UI (for UX) and on the
   Cloud Function call (real security).

2. **Don't expose `sa-key.json`.** The admin app uses the regular
   Firebase Web SDK + Auth. The service account key is never bundled.

3. **Claims propagate on re-login.** If a moderator quits, revoke
   the claim and they lose access within 1 hour (Firebase ID token
   TTL). For instant lockout use `revokeRefreshTokens(uid)`.

---

**End of deploy rehearsal.**
