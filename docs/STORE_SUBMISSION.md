# AFFINITY — Store Submission Checklist

> Hand-off document for Alejandra + Gabriel when the codebase reaches
> submission-ready state. Every item below is a **manual** step that
> cannot be automated — account sign-ups, credit-card entry, asset
> approval, store metadata editing.

---

## 🛂 Pre-submission hard gates

Confirm ALL of these before touching App Store Connect or Google Play Console:

- [ ] `flutter analyze` clean on a fresh clone
- [ ] `cd functions && npm run build` green
- [ ] `cd firestore-tests && npm test` → 25/25 passing
- [ ] `flutter test` → all passing (watermark + any added)
- [ ] Debug APK builds and installs on a physical Android device
- [ ] Debug IPA builds on a physical iOS device (TestFlight internal)
- [ ] [STORE_SUBMISSION.md](STORE_SUBMISSION.md) (this file) and [PROGRESS_LOG.md](PROGRESS_LOG.md) checked into repo
- [ ] Legal site (privacy/terms/moderation) deployed and reachable via HTTPS
- [ ] Moderation admin web app deployed and at least one moderator claim minted
- [ ] 10 Destinations documents seeded via the moderation panel (Week 3.3)
- [ ] Tags (Dynamics / Experience / Interests) seeded or confirmed using in-code defaults

---

## 🍎 Apple Developer Program

### Step 1 — Enroll
- Cost: **USD 99 / year**
- URL: https://developer.apple.com/programs/enroll/
- Entity: enroll under the Affinity company name. Alejandra to supply:
  - Legal entity name
  - D-U-N-S number (free at https://developer.apple.com/support/D-U-N-S/)
  - Country / region
- Verification calls from Apple can take 2–7 business days — **start here first**.

### Step 2 — App Store Connect setup
1. Log in at https://appstoreconnect.apple.com
2. **My Apps → + → New App**
   - Platform: iOS
   - Name: **Affinity**
   - Primary language: Spanish (Mexico) — with English (U.S.) as secondary
   - Bundle ID: `com.affinitysocialclub.app` (must already be registered in Certs/IDs)
   - SKU: `affinity-mvp` (internal identifier, never shown to users)
3. Create signing certificates + provisioning profiles via Xcode automatic signing (recommended).

### Step 3 — App Information
- **Category:** Social Networking (primary), Lifestyle (secondary)
- **Age rating:** 17+
  - "Infrequent/Mild Sexual Content and Nudity" ✓
  - "Infrequent/Mild Suggestive Themes" ✓
  - Everything else: None
- **Pricing:** Free
- **Available territories:** Limit to LATAM + US + Spain on first submission (smaller
  review set; expand later). Exclude regions where the content is
  explicitly illegal.
- **Rating reason notes:** include the moderation-policy URL so reviewers
  understand the safeguards in place.

### Step 4 — App Privacy ("nutrition labels")
Per Data Type, tick the data we collect + purpose. Declare honestly — a
mismatch with actual behaviour is auto-rejection.

| Data type                                  | Collected? | Linked to you? | Purpose               |
| ------------------------------------------ | ---------- | -------------- | --------------------- |
| Contact Info → Email                       | YES        | YES            | App functionality      |
| User Content → Photos, Videos              | YES        | YES            | App functionality      |
| User Content → Messages                    | YES        | YES            | App functionality     |
| User Content → Other (verification video)  | YES        | YES            | App functionality      |
| Identifiers → User ID                      | YES        | YES            | App functionality     |
| Location → Coarse location                 | YES        | YES            | App functionality      |
| Diagnostics → Crash data                   | YES        | NO             | Analytics              |
| Diagnostics → Performance data             | YES        | NO             | Analytics              |
| Everything else                            | NO         | —              | —                      |

### Step 5 — Store listing
- **Promotional text (170 chars):** "Social network for adventurous couples.
  Verified profiles, real conversations, travel matching."
- **Description:**
  - Open with the lifestyle-neutral pitch (social / community / travel).
  - Emphasise verification + manual moderation + privacy controls.
  - **Never use the words**: swinger, lifestyle (in the Apple sense),
    swap, hot wife, soft swap, full swap, parallel play. App Store
    guidelines treat these as adult triggers.
- **Keywords (100 chars):** `couples,social,community,dating,travel,lifestyle,connect`
- **Support URL:** https://<your-legal-domain>/
- **Marketing URL:** same or homepage
- **Privacy policy URL:** https://<your-legal-domain>/privacy
- **License agreement URL:** https://<your-legal-domain>/terms
- **Moderation policy URL (goes in reviewer notes, not store metadata):**
  https://<your-legal-domain>/moderation

### Step 6 — App Review Information (shown only to Apple reviewers)
- **Sign-in required:** YES
- **Demo account:** see Week 5.7 in PROGRESS_LOG — create a pre-verified
  couple account and paste the credentials in this field.
- **Notes:** use the following template:

  > Affinity is a community app for couples 21+. Every couple must pass a
  > human-reviewed video verification before accessing the main feed.
  > The included demo account bypasses that step so you can test the
  > full experience.
  >
  > Key screens to review:
  > 1. Couples discovery feed (filters button top-right)
  > 2. Chat with demo partner
  > 3. Report flow (⋮ in chat header)
  > 4. Block management (Profile → Security)
  > 5. Account deletion (Profile → Account settings → Delete account)
  >
  > Screenshot protection on sensitive screens is intentional and
  > complies with our Privacy Policy ({URL}).
  >
  > Moderation policy: {URL}/moderation
  > Privacy: {URL}/privacy
  > Terms: {URL}/terms

### Step 7 — Build + submit
1. Xcode → Product → Archive (Release config, com.affinitysocialclub.app).
2. Distribute → TestFlight & App Store.
3. Wait for processing (5–30 min).
4. App Store Connect → App version → Select the build.
5. Submit for Review.

### Step 8 — Review responses
Expect 2–5 days per review cycle. Honest approval probability estimate:
**75–85%** on first or second attempt (see DECISIONS_LOG Point 8). If
rejected:
1. Read the rejection letter word-for-word.
2. Respond in the Resolution Center within 24 hours with a technical
   clarification referencing specific guidelines.
3. Do NOT start a new submission without addressing the cited issues —
   it resets the review queue position.

---

## 🤖 Google Play Console

### Step 1 — Enroll
- Cost: **USD 25 one-time**
- URL: https://play.google.com/console/signup
- Entity: personal first, transfer to organisation later.

### Step 2 — Create app
- **App name:** Affinity
- **Default language:** Spanish (es-MX)
- **App or game:** App
- **Free or paid:** Free
- **Declarations:** accept dating-app policy + content policy

### Step 3 — Dashboard checklist
Google Play shows a checklist automatically. Fill each row:
- [ ] App access (provide demo account — same as Apple's)
- [ ] Ads: No
- [ ] Content rating (fill questionnaire; expect PEGI 16 / Everyone 18+)
- [ ] Target audience (18+)
- [ ] News app: No
- [ ] COVID-19 contact tracing: No
- [ ] Data safety: repeat the Apple privacy-labels table, mapped to Google's
      slightly different taxonomy
- [ ] Government app: No
- [ ] Financial features: No
- [ ] Health: No
- [ ] Main store listing (screenshots, icon, descriptions)
- [ ] Dating declaration form — YES, fill completely

### Step 4 — Build + upload
1. `flutter build appbundle --release` — produces `build/app/outputs/bundle/release/app-release.aab`
2. Release → Production → Create new release → Upload AAB
3. Release notes: localised EN + ES ("First release of Affinity.")
4. Send to review. Typical approval: 1–3 days.

---

## 📦 Store assets (shared between Apple + Google)

Drop finals into [`assets/branding/`](../assets/branding/) and into a private
`store-assets/` folder for distribution (do not commit the full marketing
set). Sizes:

- Icon: 1024×1024 (no alpha for iOS)
- Feature graphic (Google only): 1024×500
- Phone screenshots:
  - Apple 6.7": 1290×2796 — at least 3, recommend 5 per language
  - Apple 6.5" + 5.5": optional but recommended
  - Android phone: 1080×1920 minimum
  - Android 7" tablet: 1200×1920
  - Android 10" tablet: 1800×2560
- TV / Watch: N/A for Affinity

Per language: English (US) + Spanish (Mexico). Spanish is primary for the
target market. Never include the banned words in any screenshot caption.

---

## 🔐 Secrets handed off to the store runtime

| Secret                    | Where it lives                     | Rotation owner       |
| ------------------------- | ---------------------------------- | -------------------- |
| GCP Places API key (iOS)  | `lib/core/config/api_keys.dart`    | Gabriel              |
| GCP Places API key (And)  | `lib/core/config/api_keys.dart`    | Gabriel              |
| Firebase service account  | Managed by Firebase                | Alejandra (admin)     |
| Apple signing cert        | Apple Developer account keychain   | Alejandra            |
| Google upload key         | `android/upload-keystore.jks` (NOT committed) | Alejandra  |

Generate the upload keystore with:
```sh
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Store the password in 1Password / Bitwarden. Paste the SHA-1 fingerprint
into the Firebase Android app registration so Google Sign-In keeps working
on production builds.

---

## 🎭 Demo account for reviewers

Generated via [scripts/seed_demo_account.ts](../functions/src/scripts/seed_demo_account.ts) (Week 5.7).
Credentials to paste into App Store Connect / Google Play Console:

- Email: `demo-reviewer@affinitysocialclub.com` (create real Gmail alias)
- Password: rotate quarterly; store in 1Password

This account is pre-verified (status=approved) so reviewers bypass the
video-verification gate. Keep a second demo account with
`status=pending_review` in case a reviewer wants to test the full onboarding.

---

## 📋 7-Flow regression test (run on both platforms before every submission)

Follow [docs/REGRESSION_CHECKLIST.md](REGRESSION_CHECKLIST.md).

---

## 📝 Open items for Alejandra

- [ ] Final company name for Apple Developer enrollment
- [ ] D-U-N-S number (request at link above)
- [ ] Tax + banking info for both stores
- [ ] Final pineapple-motif icon + splash art
- [ ] 10 Travel Match destinations list (client to confirm from
      [seed list](../lib/data/datasource/destinations_datasource.dart))
- [ ] Legal review of Privacy Policy + Terms by licensed attorney
- [ ] Production Firebase project selection (reuse
      `affinity-dating-app-cf807` or create fresh?)
- [ ] Custom email domain for password-reset (no-reply@...)
- [ ] Signing certificates: who owns the iOS Distribution cert?

---

**End of STORE_SUBMISSION.md**
