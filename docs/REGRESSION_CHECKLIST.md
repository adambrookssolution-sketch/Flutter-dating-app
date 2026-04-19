# AFFINITY — 7-Flow Regression Checklist

> Run against a freshly installed build on BOTH platforms before every
> store submission. Any failure blocks release.

**Environment:**
- Target: dev Firebase (`affinity-dev-local`) OR the emulator — never production
- Device: physical hardware, not simulator (Apple rejects simulator-only builds)
- Network: Wi-Fi + cellular tested separately for the Travel Match flow

**Test accounts:**
- `qa-couple-a@affinitysocialclub.com` (approved, pre-seeded)
- `qa-couple-b@affinitysocialclub.com` (approved, pre-seeded)
- `qa-couple-c@affinitysocialclub.com` (pending_review, for verification flow)

---

## Flow 1 — Couple registration + video verification

| Step | Expected |
|------|----------|
| 1. Fresh install, tap "Create account" | Navigates to email sign-up |
| 2. Enter email + password, submit | Auth user created, navigates to profile setup |
| 3. Upload 6 photos, fill all fields, set both births ≥ 21 years ago | Save enabled |
| 4. Hit save | Navigates to verification intro |
| 5. Start recording, speak, stop at 12s, submit | Upload progresses to 100%, status transitions to `pending_review` |
| 6. Pending screen appears | Spinner + "Verification in review" copy |
| 7. (As moderator on admin panel) approve the video | Phone screen auto-transitions to Couples feed within ~2s |
| 8. (Repeat with rejection reason "inappropriate") | Phone transitions to rejected screen; Try again CTA visible |
| 9. Retry, get rejected again | Phone shows "permanent block" UI; no retry button |

**Hard fails:**
- [ ] Age under 21 on either partner → save must show red border
- [ ] Permission denied for camera → dedicated permission-denied screen, not crash
- [ ] Closing app mid-upload → on reopen, status still reflects the last submission

---

## Flow 2 — Password recovery

| Step | Expected |
|------|----------|
| 1. Sign out, go to email login, tap "Forgot password" | Navigates to step_verify |
| 2. Enter a registered email | Submit button spinner → navigates to step_code |
| 3. step_code screen | "Check your email" instructional copy, "Go to login" button |
| 4. Check real email inbox | Generic subject ("Solicitud de acceso a tu cuenta"), no Affinity branding |
| 5. Click link | Firebase default reset page opens in browser |
| 6. Set new password | Success |
| 7. Return to app, log in with NEW password | Succeeds, couples feed loads |
| 8. After login, a dialog surfaces recovery activity | Confirm with OK |
| 9. Enter an UNREGISTERED email in step 2 | Same UX as step 2-3 (no enumeration leak) |

**Hard fails:**
- [ ] Any "user not found" error message exposed to the user
- [ ] Email contains "Affinity" / logo / brand colours (must be neutral)

---

## Flow 3 — Request → Accept → Chat

| Step | Expected |
|------|----------|
| 1. Couple A finds couple B in feed | Card visible with photo, names, age, city, chips |
| 2. Tap "Start Conversation" | SendRequestDialog opens, prompts 10-280 char message |
| 3. Type a message, send | Dialog dismisses, toast "Request sent to …", B's card removed from A's feed |
| 4. Sign in as B (new device or after sign-out) | Inbox shows the request under "Message requests" sliver |
| 5. Tap the request | Preview screen opens with A's photo, name, interests chips, message |
| 6. Tap Accept + chat | Screen pops to inbox; "Chat messages" section now shows the new thread |
| 7. Tap the new chat | Chat screen opens with the initial message already seeded |
| 8. Send a reply | Bubble appears below initial message |
| 9. Sign back in as A | Inbox "Chat messages" shows the same conversation with B's reply |

**Hard fails:**
- [ ] A can re-send a Request to B within 30 days of rejection (cooldown must apply)
- [ ] Chat suggestion text in English even when locale is `es` (TODO until Week 5 ARB pass)

---

## Flow 4 — Filters + geo

| Step | Expected |
|------|----------|
| 1. Tap filter button top-right | FiltersScreen opens, all empty |
| 2. Set Dynamics = "Soft Swap", Interests = "Travel" | Chips highlight burgundy |
| 3. Apply | Feed returns, filter badge shows "2" |
| 4. Scroll to the end | Footer loader; next page loads |
| 5. Tap Reset | Badge disappears; full feed returns |

**Hard fails:**
- [ ] Filters leak across sign-out (must reset on new sign-in)
- [ ] Feed crashes if zero results (empty state required)

---

## Flow 5 — Travel Match

| Step | Expected |
|------|----------|
| 1. Profile → Manage trips → Add trip | Destination picker + date picker work |
| 2. Pick "Hedonism II" + dates starting next week | Trip listed under Manage trips |
| 3. Tap the trip | Travel Match screen runs `findMatches` callable |
| 4. If no other couples with overlap | "No matches yet" empty state |
| 5. Sign in as B, add the same destination + overlapping dates | Within seconds A should receive a push: "N parejas también viajan…" |
| 6. A taps the trip | Match list now includes B with correct "overlap days" value |
| 7. 7 days before start_date (fast-forward via scheduled-trigger manual run) | A + B both receive the "Trip coming up" push |

**Hard fails:**
- [ ] Deleted trip still returns matches (cleanup on delete)
- [ ] Destination id mismatch (must match exactly across couples)

---

## Flow 6 — Report + block

| Step | Expected |
|------|----------|
| 1. In an open chat, tap ⋮ → Report couple | ReportScreen opens |
| 2. Pick "Harassment", leave description empty | Submit succeeds |
| 3. Return to chat | Chat header normal; chat still visible (legacy) but report recorded |
| 4. Go back to feed | The reported couple no longer appears |
| 5. Profile → Security | Blocked couple listed with "via_reporte" badge |
| 6. Tap Unblock | Row disappears from security list |
| 7. Feed refresh | Reported couple reappears in discovery |
| 8. (Manual cloud side) Run `onReportCreated` threshold test — 5 reports from different couples within 30d | Reported couple status → `under_review` |

**Hard fails:**
- [ ] Reported couple sees any indication a report was filed
- [ ] Reporter identity visible anywhere on the reported side

---

## Flow 7 — Account deletion + recovery

| Step | Expected |
|------|----------|
| 1. Profile → Account settings → Delete account | Warning screen with consequences list |
| 2. Try to submit without checkbox | Red button disabled |
| 3. Tick "I understand this is permanent" | Red button enables |
| 4. Tap Delete | "Deletion pending" screen, auto sign-out |
| 5. Sign back in with same credentials (< 30 days) | CancelDeletionScreen appears with days-left count |
| 6. Tap "Cancel deletion" | Couples feed loads normally |
| 7. Repeat deletion, wait (or fast-forward 31 days via scheduler manual run) | `executeDeletion` Cloud Function purges all data; Firebase Auth user gone; email reusable for a fresh sign-up |

**Hard fails:**
- [ ] Deletion without the checkbox clicked
- [ ] Cloud Function partial delete (storage remnants, conversation leftovers) — grep the DB after

---

## 🚦 Exit criteria

Submission is blocked until:
- All 7 flows pass on iOS physical device
- All 7 flows pass on Android physical device
- `flutter analyze` clean
- `functions` + `firestore-tests` green
- Legal pages reachable over HTTPS
- Moderation panel login works with a moderator claim
- Demo account credentials pasted into App Store Connect + Play Console

If any item fails, file the cause in PROGRESS_LOG.md under "Open items"
and do not submit until resolved.
