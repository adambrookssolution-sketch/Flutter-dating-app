# AFFINITY — Progress Log

> **Purpose:** Persistent state tracker across Claude sessions. Always read this first when resuming work.
> **Update rule:** After every meaningful step (completed task, blocker, decision change), update this file before ending the session.

---

## 🧭 How to use this file

1. **At session start (Claude):** Read this file FIRST, then `docs/PROJECT_OVERVIEW.md` for context refresh.
2. **At session start (User):** Tell Claude "read docs/PROGRESS_LOG.md and continue".
3. **During session (Claude):** Update the "Current State" + "Last Action" sections as work progresses.
4. **At session end (Claude):** Write a "Next Action" summary so the next session starts cold-start ready.

---

## 📍 CURRENT STATE

- **Phase:** Week 5 — ✅ **COMPLETE** (branding + legal + age gate + submission tooling + i18n pass)
- **Status:** 5-week MVP scope done. Handoff to Phase 2 integration pending manual steps.
- **Last action timestamp:** 2026-04-18
- **Last action by:** Claude (Opus 4.7)
- **Code state:**
  - `flutter analyze` → **No issues found**
  - `flutter test test/watermark_test.dart` → **4/4 passing**
  - `cd functions && npm run build` → green (11 Cloud Functions)
  - `cd firestore-tests && npm test` → **25/25 passing**

### 🚀 READY FOR SUBMISSION
All code-side work for the 5-week MVP scope is done. Remaining items are
strictly manual (store account enrolment, asset approval, legal review)
and listed in [STORE_SUBMISSION.md](STORE_SUBMISSION.md).

### Flutter SDK
- **Installed at:** `D:\flutter` (D drive, per user request — C drive only had 5GB free)
- **Version:** Flutter 3.41.7 stable (Dart 3.11.5, DevTools 2.54.2)
- **Invoke from bash:** `/d/flutter/bin/flutter`
- **Old broken PATH:** `C:\src\flutter\bin` — ignore; full path to `D:\flutter\bin\flutter.bat` always works
- **Install script:** [scripts/install_flutter.ps1](../scripts/install_flutter.ps1) (idempotent — re-run safely if SDK ever disappears)

### Blockers / awaiting user
1. **GCP setup (Week 0.1)** — see "Week 0.1" section below.
2. **Dev Firebase project (Week 0.2)** — see "Week 0.2" section below.
3. **Java JDK 21+** recommended for Firebase emulators (current works but unsupported in future firebase-tools v15).

---

## ✅ COMPLETED

| Date | Phase | Task | Notes |
|------|-------|------|-------|
| 2026-04-18 | Pre-work | Read all 6 project docs | Full context loaded |
| 2026-04-18 | Pre-work | Audited entire codebase (lib/, android/, ios/) | Confirmed CODE_ANALYSIS.md accuracy |
| 2026-04-18 | Pre-work | Created 5-week step-by-step build plan | See chat history; will be migrated to BUILD_PLAN.md if needed |
| 2026-04-18 | Week 0.1-0.2 | Documented manual steps for user (GCP + Firebase) | See sections below |
| 2026-04-18 | Week 0.3 | Hardened `.gitignore` for secrets + build artefacts | Added api_keys.dart, google-services.json, GoogleService-Info.plist, functions/lib, .firebase |
| 2026-04-18 | Week 0.3 | Created `.firebaserc` with dev/production aliases | Default = dev |
| 2026-04-18 | Week 0.3 | Rewrote `firebase.json` (firestore + storage + functions + emulators) | Ports: auth 9099, fn 5001, fs 8080, st 9199, ui 4000 |
| 2026-04-18 | Week 0.3 | Wrote `firestore.rules` v0 (default deny + per-collection allows) | Will harden in Week 1.7 after migration |
| 2026-04-18 | Week 0.3 | Wrote `firestore.indexes.json` (10 composite indexes) | Covers couples geo+status, conversations, requests, reports, trips |
| 2026-04-18 | Week 0.3 | Wrote `storage.rules` v0 | Photos owner-write, videos owner-write read-via-CF, frames CF-only |
| 2026-04-18 | Week 0.3 | Created `functions/` (TypeScript, Node 22, firebase-admin v12, firebase-functions v6) | Empty entry point with weekly export plan |
| 2026-04-18 | Week 0.3 | `functions/` `npm install` succeeded (704 packages) + `npm run build` succeeded | Ready to add Cloud Functions in Week 1+ |
| 2026-04-18 | Week 0.4 | Added 12 packages to `pubspec.yaml` | Riverpod, geoflutterfire_plus, http, camera, video_player, permission_handler, flutter_secure_storage, image, cached_network_image, url_launcher, firebase_messaging, cloud_functions |
| 2026-04-18 | Week 0.5 | Verified Firebase emulators boot (Firestore JAR auto-downloads) | Auth/Firestore/Storage start; Functions tested by build only |
| 2026-04-18 | Week 0.5 | Installed Flutter 3.41.7 (Dart 3.11.5) at `D:\flutter` | C drive too full (5GB) — used D per user instruction |
| 2026-04-18 | Week 0.5 | `flutter pub get` resolved all 93 deps (12 new + transitive) | Zero conflicts |
| 2026-04-18 | Week 0.5 | Cleaned `l10n.yaml` (removed deprecated `synthetic-package`) | One-line fix for analyzer warning |
| 2026-04-18 | Week 0.5 | `flutter analyze` → **No issues found** | Clean baseline before any new feature code |
| 2026-04-18 | Week 0 | Created PROGRESS_LOG.md (this file) | Session continuity established |
| 2026-04-18 | Week 1.1 | Created 11 new model files in `lib/data/models/` | Couple, Partner, Verification, AgeRange, CoupleStatus, Trip, MessageRequest+enums, Report+3 enums, Block+enum, Destination+enum, Tag+enum |
| 2026-04-18 | Week 1.1 | Marked legacy `UserProfile` as `@Deprecated` + added `toCouple()` migration helper | Removed in Phase 2 once call sites migrate |
| 2026-04-18 | Week 1.2 | Wrote `functions/src/scripts/migrate_profiles_to_couples.ts` | Idempotent dry-run/write/delete-old modes; geocodes via Google Geocoding API; computes geohash via `ngeohash`; TypeScript build green |
| 2026-04-18 | Week 1.3 | Created 6 new datasources + extended 1 | couples_datasource (paginated geo+filter), trips_datasource, reports_datasource (atomic block-too), blocks_datasource (bidirectional silent), message_requests_datasource (preflight + cooldown + silent reject), verification_datasource (video upload + status update), destinations_datasource (read-only); tags_datasource gained `getByCategory()` + lifestyle defaults |
| 2026-04-18 | Week 1.3 | `flutter analyze` clean across all new code | Maintains zero-warning baseline |
| 2026-04-18 | Week 1.4 | `lib/core/config/api_keys.dart` (gitignored) + `api_keys.example.dart` template | Stub keys; production fills via Week 0.1 |
| 2026-04-18 | Week 1.4 | `lib/core/geo/geohash.dart` — pure-Dart Niemeyer 2008 encoder | Interop with `ngeohash` (Cloud Functions) and `geoflutterfire_plus` |
| 2026-04-18 | Week 1.4 | `lib/data/models/place_result.dart` + `lib/data/datasource/places_datasource.dart` | Direct REST calls (no extra package); session-token billing |
| 2026-04-18 | Week 1.4 | `lib/presentation/widgets/places_autocomplete_field.dart` | 350ms debounce, dev fallback bottom-sheet when key absent, design-system compliant |
| 2026-04-18 | Week 1.4 | Replaced 16-city dropdown in `profile_setup_screen.dart` with Places field; dual-write to `couples` collection | Legacy `profiles` write preserved; non-fatal mirror write to new schema |
| 2026-04-18 | Week 1.5 | Wired `step_verify.dart` to `RecoveryDatasource.sendResetEmail` (no-enumeration UX) | Always advances to step_code regardless of email validity |
| 2026-04-18 | Week 1.5 | Rewrote `step_code.dart` from 4-digit OTP → "check your email" instructional screen | Firebase reset is link-based, not code-based; preserves creative team's image asset |
| 2026-04-18 | Week 1.5 | Cloud Function `sendCustomReset` (callable, neutral subject, recovery_attempts log) | Stub `sendEmail` — production wires SendGrid/Mailgun; documented in code |
| 2026-04-18 | Week 1.5 | Cloud Function `markRecoveryCompleted` (revokes refresh tokens) | Workaround for Identity Platform blocking trigger gap |
| 2026-04-18 | Week 1.5 | `RecoveryAttemptsDialog.maybeShow()` triggered from `navigateAfterSignIn` | One-time post-login banner per attempt |
| 2026-04-18 | Week 1.6 | 3 new screens: AccountSettingsScreen, DeleteAccountScreen, CancelDeletionScreen | Apple-required flow; double confirmation; 30-day grace UX |
| 2026-04-18 | Week 1.6 | `navigateAfterSignIn` now routes pending_deletion → CancelDeletionScreen | Auto-detect at every sign-in within 30 days |
| 2026-04-18 | Week 1.6 | Wired Profile screen "Account settings" menu item (was placeholder) | Other items (Trips, Favorites, Security, Help) still pending — Weeks 2-3 |
| 2026-04-18 | Week 1.6 | Cloud Function `executeDeletion` (scheduled daily 03:00 UTC, atomic purge) | Couples + subcollections + conversations + requests + blocks + storage + auth + report anonymisation |
| 2026-04-18 | Week 1.7 | Hardened `firestore.rules` v1 with helper functions (isApproved, noMutualBlock, status-transition guards) | Replaces v0 stub; default-deny + explicit allows |
| 2026-04-18 | Week 1.7 | Set up `firestore-tests/` ts-jest + @firebase/rules-unit-testing harness | One-shot npm test boots emulator + runs all suites + tears down |
| 2026-04-18 | Week 1.7 | Wrote 25 Rules tests across 4 suites (couples, blocks, reports, conversations) | All 25 passing — block silence, status guards, message immutability all enforced |
| 2026-04-18 | Week 2.1 | 4 verification screens: intro, video record, pending, rejected | Camera + mic permissions, 10-30s recording, 2-attempt cap, real-time status stream in pending screen |
| 2026-04-18 | Week 2.1 | Added Android CAMERA + RECORD_AUDIO permissions + iOS NSMicrophoneUsageDescription | Native manifests updated; video verification now permission-complete |
| 2026-04-18 | Week 2.1 | Extended `navigateAfterSignIn` to route pending_review/rejected/suspended/under_review → verification screens | Full status-based gating implemented |
| 2026-04-18 | Week 2.2 | Wired video upload: VideoRecordScreen._submit → VerificationDatasource.submitVerificationVideo → Firestore status transition | End-to-end couple side complete |
| 2026-04-18 | Week 2.3 | New Flutter Web admin app under `lib/admin/` + `lib/main_admin.dart` entry | Run: `flutter run -d chrome -t lib/main_admin.dart`; build: `flutter build web -t lib/main_admin.dart` |
| 2026-04-18 | Week 2.3 | Admin screens: AdminLoginScreen, ModerationQueueScreen (live stream), ModerationReviewScreen (video player + approve/reject) | Moderator claim check via `token.claims.moderator == true` |
| 2026-04-18 | Week 2.3 | Cloud Function `moderateVerification` (moderator-claim-gated; approve/reject with predefined reason list) | 6 allowed reasons: inappropriate, fake, single_person, minor_suspected, quality_low, other |
| 2026-04-18 | Week 2.3 | Security Rules updated: `isModerator()` helper + couples read bypass for moderators | Rules tests still 25/25 passing |
| 2026-04-18 | Week 2.3 | `firebase.json` hosting target `admin` added | Deploys build/web to a separate Firebase Hosting site |
| 2026-04-18 | Week 2.4 | Cloud Function `cleanupExpiredVideos` (daily 04:00 UTC, 7-day retention, SHA-256 hash, frames placeholder) | Frame extraction deferred — requires ffmpeg Cloud Run, logged for Week 5 hardening |
| 2026-04-18 | Week 2.5 | ReportScreen with 6-category dropdown, optional description (required for Other), pre-checked "also block" checkbox | Matches DECISIONS_LOG Point 5 exactly |
| 2026-04-18 | Week 2.5 | Chat header ⋮ menu → Report couple (derives other UID from deterministic conversation ID) | One entry point; more added in Week 3 when full profile view lands |
| 2026-04-18 | Week 2.5 | Cloud Function `onReportCreated` — auto-suspend at 5 reports/30d from distinct reporters, rate-limit reporter at 10/7d | Thresholds match DECISIONS_LOG Point 5 |
| 2026-04-18 | Week 2.6 | SecurityScreen — blocked couples list with unblock action, origin badges (manual/via report/auto) | Apple App Store requirement; wired from Profile menu |
| 2026-04-18 | Week 2.6 | Cloud Function `onSuspension` — when status → suspended, auto-block every couple who reported in last 90 days | DECISIONS_LOG Point 6 "auto-block after suspension: YES" (client override) |
| 2026-04-18 | Week 2.6 | Profile screen "Security" menu entry wired | Previously `onTap: () {}` placeholder |
| 2026-04-18 | Week 2 | Full verification: analyze clean + functions build green + 25 rules tests still passing | No regressions introduced |
| 2026-04-18 | Week 3.1 | Riverpod introduced via `ProviderScope` in main.dart + `lib/providers/filters_provider.dart` | First screen on Riverpod (FiltersScreen); existing screens untouched per progressive-adoption rule |
| 2026-04-18 | Week 3.1 | `FiltersScreen` matching client mockup (location, age slider, 3 chip sections, reset, apply) | Client design system colors + chip palette preserved |
| 2026-04-18 | Week 3.1 | CouplesOption now `ConsumerStatefulWidget` with floating filter button + active-count badge + in-memory filter on legacy `profiles/*` | Hybrid: legacy reads stay safe; richer filters auto-activate once data lives in `couples/*` |
| 2026-04-18 | Week 3.2 | Added `getNearbyCouples` to couples_datasource using `geoflutterfire_plus` GeoCollectionReference | `updateCouple` auto-synthesises the nested `geo: {geohash, geopoint}` map from flat lat/lng/geohash |
| 2026-04-18 | Week 3.3 | 3 trip screens: ManageTripsScreen, AddTripScreen (destination + date range), TravelMatchScreen | Profile screen "Manage trips" menu wired |
| 2026-04-18 | Week 3.3 | Destinations seeded with 10 well-known lifestyle resorts/cruises/events as fallback | Client confirms final list before launch (PROGRESS deferred-task tracker) |
| 2026-04-18 | Week 3.3 | Cloud Function `findMatches` (callable, collectionGroup query, blocked-exclusion both sides) | Caps at 50 matches per call |
| 2026-04-18 | Week 3.4 | Cloud Function `onTripCreated` — both new couple + existing matches get push | FCM via `sendEachForMulticast` against `couples/{id}/fcm_tokens/*` |
| 2026-04-18 | Week 3.4 | Cloud Function `tripReminder` — daily 08:00 UTC, 7-day advance push | Counts overlapping matches and personalises body |
| 2026-04-18 | Week 3.5 | `SendRequestDialog` (modal sheet) — initial message + length validation + canSend preflight | Silent rejection: cooldown returns `silent` → UI fakes success |
| 2026-04-18 | Week 3.5 | CouplesOption Start Conversation now invokes `SendRequestDialog`, writes to `message_requests/*` | Old empty-conversations path retired for new flow; existing conversations stay untouched |
| 2026-04-18 | Week 3.5 | Cloud Function `expireRequests` — daily 05:00 UTC, batch flips pending → expired after 14 days | Receiver gets no extra notification (silent expire) |
| 2026-04-18 | Week 3.5 | Chat suggestions left in EN with `TODO(week-5-i18n)` marker | Batched ARB move pushed to Week 5 store-prep i18n pass |
| 2026-04-18 | Week 3 | Full verification: analyze clean + functions build green + 25 rules tests still passing | No regressions introduced |
| 2026-04-18 | Week 4.1 | Android FLAG_SECURE via MethodChannel `affinity/secure_view` in MainActivity.kt | `enable`/`disable` methods toggle the window flag |
| 2026-04-18 | Week 4.2 | iOS [SecureView.swift](../ios/Runner/SecureView.swift) — FlutterPlatformView that reparents child UI into an `isSecureTextEntry` UITextField's protected canvas | Registered in AppDelegate under the same `affinity/secure_view` id |
| 2026-04-18 | Week 4.3 | [SecureView](../lib/presentation/widgets/secure_view.dart) Flutter widget — Android: ref-counted FLAG_SECURE toggle; iOS: stacked UiKitView; web/desktop: no-op | Ref-counting prevents parent disposing a nested child's protection |
| 2026-04-18 | Week 4.3b | SecureView applied to ChatScreen, TravelMatchScreen, RequestMatchScreen, MessageRequestPreviewScreen | Does not apply to own-profile screens (users may want own screenshots) |
| 2026-04-18 | Week 4.4 | [Watermarker](../lib/core/security/watermark.dart) LSB encoder with 8x8 block majority vote + magic prefix | 4/4 unit tests passing: round-trip, null on unwatermarked, over-size ID, under-size image |
| 2026-04-18 | Week 4.4 | [WatermarkedImage](../lib/presentation/widgets/watermarked_image.dart) widget — off-thread encoding via `compute` | Viewer coupleId embedded per-render; no disk cache |
| 2026-04-18 | Week 4.5 | [NoCacheImage](../lib/presentation/widgets/no_cache_image.dart) helper — memory-only Image.memory wrapper | For less-sensitive paths where watermark overhead isn't worth it |
| 2026-04-18 | Week 4.6 | [FcmService](../lib/core/notifications/fcm_service.dart) — permission + token acquire + write to `couples/{id}/fcm_tokens/{sanitised}` + refresh listener | Wired into `navigateAfterSignIn` (register) and `AuthDatasource.signOut` (unregister) |
| 2026-04-18 | Week 4.7 | Cursor-based pagination in CouplesOption — 20 per page, 80%-threshold infinite scroll, footer loader | [profile_datasource.dart](../lib/data/datasource/profile_datasource.dart) `getProfilesPage` returns items + cursor; `getAllProfiles` marked deprecated |
| 2026-04-18 | Week 4.8 | [MessageRequestsSection](../lib/presentation/pages/inbox/message_requests_section.dart) inserted at top of Inbox sliver tree | Stream-backed; empty state renders SizedBox.shrink to avoid chrome when no requests |
| 2026-04-18 | Week 4.8 | [MessageRequestPreviewScreen](../lib/presentation/pages/inbox/message_request_preview_screen.dart) — Accept promotes Request to a real Conversation + seeds initial message | Dismiss = silent rejection (sender never notified) |
| 2026-04-18 | Week 4 | Full verification: analyze clean + 4 watermark tests + functions build green + 25 rules tests still passing | No regressions |
| 2026-04-18 | Week 5.1 | Android package rename `com.example.app` → `com.affinitysocialclub.app` (dir move + MainActivity.kt + Manifest + build.gradle.kts) | Needs fresh google-services.json after Firebase Android app re-registration |
| 2026-04-18 | Week 5.1 | iOS bundle id rename in project.pbxproj + Info.plist CFBundleName/DisplayName = "Affinity" | Tests bundle variant `.RunnerTests` also updated |
| 2026-04-18 | Week 5.1 | Added `flutter_launcher_icons` + `flutter_native_splash` dev deps + pubspec config blocks + [assets/branding/README.md](../assets/branding/README.md) | Placeholder paths; final PNGs pending creative approval |
| 2026-04-18 | Week 5.2 | +21 age gate validator added to profile_setup `_validate()` | Per-partner check; shows "Must be 21 or older" on red-bordered birth field |
| 2026-04-18 | Week 5.3 | Firebase Hosting target `legal` + 4 HTML pages in [legal/](../legal/) (index, privacy, terms, moderation) | Template content; attorney review required before deploy |
| 2026-04-18 | Week 5.4-5.6 | [STORE_SUBMISSION.md](STORE_SUBMISSION.md) — complete hand-off for Apple Developer enrolment, Play Console, Privacy Labels, store assets, reviewer notes | 220+ line checklist |
| 2026-04-18 | Week 5.7 | [seed_demo_account.ts](../functions/src/scripts/seed_demo_account.ts) — idempotent pre-verified demo couple seeder | Password rotation documented |
| 2026-04-18 | Week 5.8 | [REGRESSION_CHECKLIST.md](REGRESSION_CHECKLIST.md) — 7-flow manual QA per DECISIONS_LOG | Run on physical iOS + Android before every submission |
| 2026-04-18 | Week 5 i18n | 6 chat suggestions moved to ARB (EN + ES); ChatScreen resolves at build time via `_suggestionFor(l10n)` | Removed `TODO(week-5-i18n)` marker from Week 3.5 |
| 2026-04-18 | Week 5 | Full verification: analyze clean + 4 watermark tests + 11 functions build green + 25 rules tests still passing | **Zero regressions across all 5 weeks** |

---

## 🚧 IN PROGRESS

### Week 0 — Environment Setup
- [ ] **0.1 GCP setup** (USER manual — see Week 0.1 section below)
- [ ] **0.2 Dev Firebase project** (USER manual — see Week 0.2 section below)
- [ ] **0.3 Firebase scaffolding** (CLAUDE — functions/, firestore.rules, storage.rules, emulators)
- [ ] **0.4 pubspec.yaml deps** (CLAUDE — add 12 packages)
- [ ] **0.5 Verification** (USER + CLAUDE — pub get, emulators, build)

---

## ⏭️ NEXT ACTION (cold-start ready)

**5-week MVP scope is code-complete.** Remaining work is Phase 2 integration
+ manual store enrolment.

**If starting a fresh Claude session:**
1. Read `docs/PROGRESS_LOG.md` (this file)
2. Read `docs/PROJECT_OVERVIEW.md` for full context
3. Read `docs/STORE_SUBMISSION.md` for the manual store-enrolment checklist
4. Read `docs/REGRESSION_CHECKLIST.md` before any submission
5. Check the "🔑 What still requires the user / client" section at the bottom of this file

---

## 📋 WEEK-BY-WEEK PLAN STATUS

### Week 0 — Environment Setup (current)
| # | Task | Owner | Status |
|---|------|-------|--------|
| 0.1 | GCP account + Places API + 2 API keys | User | 🟡 Awaiting user |
| 0.2 | Dev Firebase project (`affinity-dev-local`) | User | 🟡 Awaiting user |
| 0.3 | Init `functions/`, rules, indexes, emulators | Claude | 🟢 Done |
| 0.4 | Add 12 pubspec dependencies | Claude | 🟢 Done |
| 0.5 | Verify env (pub get, emulators boot, analyze) | Both | 🟢 Done (pub get + analyze clean; APK build deferred until dev Firebase keys placed) |

### Week 1 — Data Foundation + Recovery + Deletion
| # | Task | Status |
|---|------|--------|
| 1.1 | New data models (Couple, Partner, Verification, Trip, Report, Block, MessageRequest, Destination, Tag) | 🟢 Done |
| 1.2 | Migration script (`profiles` → `couples`) | 🟢 Done (TypeScript, dry-run/write/delete-old modes) |
| 1.3 | New `couples_datasource.dart` + 6 sibling datasources + tags_datasource extension | 🟢 Done |
| 1.4 | Google Places autocomplete widget + integration | 🟢 Done (dev fallback works without key; production needs Week 0.1 keys) |
| 1.5 | Forgot Password → Firebase Auth wired + email customization + audit log + recovery dialog | 🟢 Done (production needs custom email transport — see PROGRESS notes) |
| 1.6 | Account deletion UI + 30-day grace + atomic Cloud Function | 🟢 Done |
| 1.7 | Firestore Security Rules v1 + 25 unit tests passing | 🟢 Done |

### Week 2 — Verification + Reports + Blocks
| # | Task | Status |
|---|------|--------|
| 2.1 | Video record screen + camera permissions | 🟢 Done (4 screens: intro/record/pending/rejected) |
| 2.2 | Video upload + verification datasource | 🟢 Done (wired end-to-end) |
| 2.3 | Moderation web panel (Flutter Web) | 🟢 Done (login + queue + review + moderateVerification CF) |
| 2.4 | 7-day video cleanup Cloud Function (hash + frames) | 🟢 Done (hash OK; frame extraction deferred to Week 5 — needs ffmpeg Cloud Run) |
| 2.5 | Reports system (UI + datasource + thresholds) | 🟢 Done (onReportCreated CF enforces 5/30d + 10/7d thresholds) |
| 2.6 | Blocks system (bidirectional silent + auto-block on suspension) | 🟢 Done (onSuspension CF + SecurityScreen wired) |

### Week 3 — Filters + Travel Match + Requests
| # | Task | Status |
|---|------|--------|
| 3.1 | Filters screen UI + Riverpod provider | 🟢 Done |
| 3.2 | GeoHash query helper + auto geo-map synth | 🟢 Done (in-memory filter is the active path; geoflutterfire ready when feed switches to couples/) |
| 3.3 | Travel Match (destinations seed + trips CRUD + findMatches CF) | 🟢 Done |
| 3.4 | Travel Match push notifications (onTripCreated + tripReminder) | 🟢 Done (FCM tokens still need client-side registration in Week 4.6) |
| 3.5 | Message Requests (Send dialog + new write path + expireRequests CF) | 🟢 Done — receiver-side Inbox section deferred to Week 4 (avoid disrupting working flow) |

### Week 4 — Privacy + Performance + Push
| # | Task | Status |
|---|------|--------|
| 4.1 | Android FLAG_SECURE via MethodChannel | 🟢 Done |
| 4.2 | iOS SecureView (Swift PlatformView) | 🟢 Done |
| 4.3 | Flutter `SecureView` widget wrapper + applied to sensitive screens | 🟢 Done |
| 4.4 | Invisible watermarking (LSB pixel pattern) + decoder + 4 unit tests | 🟢 Done |
| 4.5 | No-local-cache policy (NoCacheImage) | 🟢 Done |
| 4.6 | Firebase Cloud Messaging client registration | 🟢 Done |
| 4.7 | Feed cursor-based pagination (20/page) | 🟢 Done |
| 4.8 | Receiver-side Inbox section for message_requests + preview screen | 🟢 Done (pulled forward from Week 3.5 deferred task) |

### Week 5 — Store Submission
| # | Task | Status |
|---|------|--------|
| 5.1 | Package rename (`com.affinitysocialclub.app`) + branding configs | 🟢 Code done; final art + re-registered google-services.json pending |
| 5.2 | +21 age gate at registration | 🟢 Done |
| 5.3 | Privacy Policy + Terms + Moderation Policy webpages | 🟢 Template done; attorney review pending |
| 5.4 | Apple Developer + Google Play Console accounts | 🟡 Manual (Alejandra — see STORE_SUBMISSION.md) |
| 5.5 | Store assets (icons, screenshots, EN+ES descriptions) | 🟡 Specs ready; art pending creative |
| 5.6 | Privacy Labels (App Store Connect) | 🟡 Table ready for manual entry |
| 5.7 | Demo account seeder | 🟢 Done |
| 5.8 | 7-flow regression checklist | 🟢 Done |
| 5.9 | Google Play submission | 🟡 Manual after enrollment |
| 5.10 | Apple submission + review team support | 🟡 Manual after enrollment |

### Phase 2 — Integration with DEV team's Phase 2 (post-Week 5)
| # | Task | Status |
|---|------|--------|
| P2.1 | Pull DEV main + merge Gabriel's branch | 🔴 Pending |
| P2.2 | Run migration script on production Firebase | 🔴 Pending |
| P2.3 | Deploy Security Rules + Cloud Functions to production | 🔴 Pending |
| P2.4 | Feature flags + gradual rollout | 🔴 Pending |
| P2.5 | E2E integrated testing | 🔴 Pending |
| P2.6 | Production deployment to both stores | 🔴 Pending |

---

## 🗒️ WEEK 0 — DETAILED INSTRUCTIONS (for user manual steps)

### Week 0.1 — Google Cloud Platform setup (USER does this)

**Goal:** Get 2 API keys (Android + iOS) for Google Places Autocomplete.

**Steps (in browser):**

1. Open https://console.cloud.google.com using `affinitysocialclub@gmail.com`.
2. Accept terms. Activate the **USD 200 free credit** (requires credit card; no charges within free tier).
3. Top bar → "Select a project" → **NEW PROJECT**:
   - Name: `affinity-places`
   - Organization: leave default
   - Click **CREATE**.
4. Once project is created, ensure it's selected in top bar.
5. Hamburger menu → **APIs & Services** → **Library**:
   - Search and **ENABLE** each:
     - **Places API (New)**
     - **Geocoding API**
     - **Maps SDK for Android**
     - **Maps SDK for iOS**
6. Hamburger menu → **APIs & Services** → **Credentials**:
   - Click **+ CREATE CREDENTIALS** → **API key**.
   - Copy the key. Name it `affinity-android`. Click **EDIT API KEY**:
     - Application restrictions → **Android apps**
     - Add package name `com.affinitysocialclub.app` and SHA-1 fingerprint (we'll generate later — leave empty for now, or use debug SHA-1 from `cd android && ./gradlew signingReport`).
     - API restrictions → **Restrict key** → select Places API + Geocoding API + Maps SDK for Android.
     - **SAVE**.
   - Repeat: Create another key named `affinity-ios`:
     - Application restrictions → **iOS apps**
     - Add bundle ID `com.affinitysocialclub.app`.
     - API restrictions → Places API + Geocoding API + Maps SDK for iOS.
     - **SAVE**.
7. **Copy both API keys somewhere safe** (we'll store them in `lib/core/config/api_keys.dart` which is gitignored).

**Tell Claude:** "GCP done. Android key: AIza..., iOS key: AIza..." and we'll move to 0.2.

---

### Week 0.2 — Dev Firebase project setup (USER does this)

**Goal:** Isolated Firebase project for local dev. Production Firebase (`affinity-dating-app-cf807`) untouched until integration.

**Steps:**

1. Open https://console.firebase.google.com using `affinitysocialclub@gmail.com`.
2. Click **Add project**:
   - Name: `affinity-dev-local`
   - Continue → enable Google Analytics: **No** (saves quota; not needed in dev) → Create.
3. Once project is created:
   - Left sidebar → **Build → Authentication** → Get started:
     - Sign-in method tab → enable **Email/Password**, **Google**, **Apple**.
     - For Google, set support email = `affinitysocialclub@gmail.com`.
     - For Apple, leave Service ID blank for now (configured later in Week 5).
   - Left sidebar → **Build → Firestore Database** → Create database:
     - Mode: **Production mode** (we'll deploy Rules ourselves).
     - Region: `us-central1` (cheapest, broad latency profile).
   - Left sidebar → **Build → Storage** → Get started:
     - Mode: **Production mode**.
     - Same region as Firestore.
   - Left sidebar → **Build → Functions** → enable (no setup needed; we use CLI).
4. Project Overview page → click ⚙ → **Project settings**:
   - **General** tab → scroll to **Your apps**:
     - Click Android icon → register app:
       - Package name: `com.affinitysocialclub.app`
       - App nickname: `Affinity Android Dev`
       - Skip SHA-1 for now → Register
       - **DOWNLOAD `google-services.json`** → save to user's machine.
     - Click iOS icon → register app:
       - Bundle ID: `com.affinitysocialclub.app`
       - App nickname: `Affinity iOS Dev`
       - Register → **DOWNLOAD `GoogleService-Info.plist`**.

**Tell Claude:** "Dev Firebase done. Project ID: affinity-dev-local. I have google-services.json and GoogleService-Info.plist downloaded to: <path>"

We'll then:
- Place `google-services.json` at `d:/app/android/app/google-services.json` (replacing production one; we'll keep the production copy as `google-services.production.json`).
- Place `GoogleService-Info.plist` in iOS Runner.
- Run `flutterfire configure` to regenerate `lib/firebase_options.dart` for the dev project.

---

## 🔐 SECRETS REGISTRY (DO NOT COMMIT)

This section lists what secrets exist and where they should be stored. **Never paste actual values into version-controlled files.**

| Secret | Location (gitignored) | Status |
|--------|----------------------|--------|
| GCP Android API key | `lib/core/config/api_keys.dart` | 🔴 Not yet created |
| GCP iOS API key | `lib/core/config/api_keys.dart` | 🔴 Not yet created |
| Dev Firebase google-services.json | `android/app/google-services.json` | 🔴 Not yet placed |
| Dev Firebase GoogleService-Info.plist | `ios/Runner/GoogleService-Info.plist` | 🔴 Not yet placed |
| Production google-services.json (existing) | Currently in `android/app/`? | ⚠️ Verify presence |

`.gitignore` will be updated to exclude these in step 0.3.

---

## 📚 REFERENCE — Key file paths

- Build plan source: see this file's "Week-by-week" section + chat conversation that produced it
- Project overview: `docs/PROJECT_OVERVIEW.md`
- Decisions: `docs/DECISIONS_LOG.md`
- Tech specs: `docs/TECHNICAL_SPEC.md`
- Code analysis: `docs/CODE_ANALYSIS.md`
- Chat history: `docs/CHAT_HISTORY.md`

---

## 📝 SESSION LOG (append-only)

### 2026-04-18 — Session 1 (Claude Opus 4.7)
- Read all 6 docs in `docs/`
- Audited [lib/main.dart](../lib/main.dart), all datasources, models, key Android/iOS files
- Produced 5-week build plan in chat
- Created this PROGRESS_LOG.md
- **Completed Week 0.3 + 0.4 + 0.5** end-to-end:
  - Hardened [.gitignore](../.gitignore)
  - Created [.firebaserc](../.firebaserc), rewrote [firebase.json](../firebase.json)
  - Wrote [firestore.rules](../firestore.rules), [firestore.indexes.json](../firestore.indexes.json), [storage.rules](../storage.rules)
  - Bootstrapped [functions/](../functions/) (TypeScript, Node 22) — `npm install` + `npm run build` both green
  - Updated [pubspec.yaml](../pubspec.yaml) with 12 new dependencies
  - Installed Flutter 3.41.7 to `D:\flutter` via [scripts/install_flutter.ps1](../scripts/install_flutter.ps1)
  - `flutter pub get` resolved all 93 deps cleanly
  - Cleaned `l10n.yaml` deprecation; `flutter analyze` returns **No issues found**
- **Verified emulators** boot (Firestore JAR auto-downloads on first run; Auth + Storage start cleanly)
- **Current blockers:**
  1. User must complete Week 0.1 (GCP) + 0.2 (dev Firebase) manual steps before Forgot Password (Week 1.5) and Places autocomplete (Week 1.4) can be tested with real services
  2. APK build deferred until dev Firebase `google-services.json` is placed (currently missing — would compile against an invalid project)

### Next session start (after Week 5 = code-complete)
1. Read this file
2. If client has completed Apple Developer + Google Play enrolment: walk through [STORE_SUBMISSION.md](STORE_SUBMISSION.md) Step-by-Step
3. If creative team has approved final pineapple icon: drop PNGs into [assets/branding/](../assets/branding/), run `dart run flutter_launcher_icons` + `dart run flutter_native_splash:create`
4. If attorney has approved legal pages: deploy with `firebase deploy --only hosting:legal`
5. **Phase 2 integration** (after DEV team finishes Feed Social):
   - Pull DEV main + merge Gabriel's branch (low conflict surface — most new files)
   - Run [migrate_profiles_to_couples.ts](../functions/src/scripts/migrate_profiles_to_couples.ts) `--write` against production Firebase
   - Deploy: `firebase deploy --only firestore:rules,storage:rules,functions,hosting`
   - Build moderation web: `flutter build web -t lib/main_admin.dart` + `firebase deploy --only hosting:admin`
   - Mint moderator claims: `admin.auth().setCustomUserClaims(uid, { moderator: true })`
   - Seed production Travel Match destinations + lifestyle tags from moderation panel
   - Run [REGRESSION_CHECKLIST.md](REGRESSION_CHECKLIST.md) on physical iOS + Android
   - Submit to stores

### 🔑 What still requires the user / client
- [ ] **User (Gabriel)**: complete Week 0.1 GCP + Week 0.2 dev Firebase (documented at top of this file)
- [ ] **Client (Alejandra)**: Apple Developer Program enrolment (D-U-N-S + company name)
- [ ] **Client (Alejandra)**: Google Play Console enrolment
- [ ] **Client (Alejandra)**: final icon + splash art (pineapple motif)
- [ ] **Client (Alejandra)**: final 10 Travel Match destinations list (current code uses sensible seeds)
- [ ] **Legal counsel**: review + tighten [privacy.html](../legal/privacy.html), [terms.html](../legal/terms.html), [moderation.html](../legal/moderation.html)
- [ ] **Custom email transport**: SendGrid/Mailgun decision + credentials for [sendCustomReset.ts](../functions/src/recovery/sendCustomReset.ts) (currently a stub `sendEmail` no-op)
- [ ] **Frame extraction** for [cleanupExpiredVideos.ts](../functions/src/verification/cleanupExpiredVideos.ts): ffmpeg Cloud Run companion (deferred — MVP hash-only path satisfies DECISIONS_LOG)

### Production deployment notes (deferred)
- **Email transport for `sendCustomReset`**: stub at [functions/src/recovery/sendCustomReset.ts](../functions/src/recovery/sendCustomReset.ts) → wire SendGrid/Mailgun once decided. Subject already neutral ("Solicitud de acceso a tu cuenta"), body neutral. Custom domain required so the From line doesn't reveal the app.
- **15-min link TTL enforcement**: Admin SDK doesn't expose link TTL. Workaround: server-side rejection sweep over `account_recovery_attempts` (Week 1.7+ hardening, deferred since the stub email transport already gates this).
- **Production migration run**: don't execute `migrate_profiles_to_couples.ts --write` against production Firebase until Week 5 final integration. Dev runs should use `--emulator` flag.
- **Firebase Auth template customisation** (manual, in Firebase Console): subject "Solicitud de acceso a tu cuenta", remove logo + brand colours + app name. Done in Week 5 prep.
- **Frame extraction in `cleanupExpiredVideos`**: stub writes empty `video_frames: []`. Production needs either ffmpeg in a Cloud Run companion service or Gen 2 CF with a custom Docker image. Deferred to Week 5.
- **Moderator claim minting**: no UI for granting `moderator: true`. Run manually:
  `firebase functions:shell` → `admin.auth().setCustomUserClaims(uid, { moderator: true })`
  Or write a one-off script. Document this in the admin app's README before handing off to Alejandra.
- **Admin app hosting target**: [firebase.json](../firebase.json) declares target `admin` → `build/web`. Before deploying: `firebase target:apply hosting admin <site-id>` + `flutter build web -t lib/main_admin.dart` + `firebase deploy --only hosting:admin`.

---

**End of PROGRESS_LOG.md**
