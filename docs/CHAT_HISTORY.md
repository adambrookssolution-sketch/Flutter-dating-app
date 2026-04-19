# AFFINITY — Chat History Summary

> Complete record of all client conversations leading to contract signing
> Client: Alejandra (Workana)
> Period: ~March 10, 2026 → April 18, 2026 (contract signed)

---

## PHASE 1 — INITIAL BIDS (March 10 - 27)

### Project posted (March 10, 2026)
Alejandra posted on Workana looking for Flutter + Firebase developer for 8 security/moderation features on an existing lifestyle dating app for couples. Budget initially "Over USD 3,000", later narrowed to USD 1,000-3,000.

### First proposal sent by Gabriel
- **Bid:** USD 4,073.60
- **Content:** Detailed point-by-point breakdown of all 8 features with technical implementation approach
- **Key differentiators:**
  - Honest about iOS screenshot protection limitations ("100% is impossible")
  - Recommended manual video verification for MVP over AI
  - GeoHash + in-memory interest filter architecture
  - Explicit Apple App Store approval requirements
- **Two questions asked:** Team's state management preference? Video verification = identity match or liveness only?
- **Client response:** Acknowledged receipt, said would review

### Second bid (re-pricing)
- **Bid:** USD 3,066.78
- **Same technical content**, lower price
- **Client response:** Began serious conversation

### Competitor context
- Another freelancer claimed experience with #Open App and Kasidie
- Alejandra asked directly if he had worked on those apps
- Competitor admitted "no, just mentioned as references"
- **Weakened competitor's credibility** — positioning advantage for Gabriel's honesty

## PHASE 2 — POINT-BY-POINT NEGOTIATION (March 27 - April 15)

Alejandra proposed analyzing each of the 8 points in detail before committing. This established the collaborative rhythm.

### Point 1 — Video Verification
**Client vision shared:**
- Registration is per COUPLE (single entity), not individual
- Both partners enter all data in one flow (names, ages, city, description, photos, verification video)
- Single record in database
- "Pending verification" state blocks app access
- Internal team manually reviews + one-click approve/reject in admin panel
- Automatic notifications: approved → COUPLES section / rejected → retry

**Gabriel added:**
- Firestore structure: `couples` collection with `partner_a`, `partner_b` sub-objects
- Status field: `pending_review / approved / rejected / suspended`
- Verification field: video URL, dates, moderator ID, reject reason
- Rejection reason categories (mandatory dropdown)
- Retry limit of 3 attempts (later changed to 2 by client)

**Agreed:** All of the above.

### Point 1 (deep dive) — Video Retention
**Client asked:** Should video be deleted immediately after approval? Kept temporarily? Kept permanently?

**Gabriel's recommendation:** Hybrid approach
- Keep full video 7 days after approval
- Delete via scheduled Cloud Function
- Keep permanently: SHA-256 hash, verification date, moderator ID, 2-3 low-res static frames
- Client reasoning: privacy priority + minimal audit trail

**Agreed:** Hybrid approach accepted.

### Point 2 — Account Recovery
**Gabriel recommended:**
- Email recovery only for MVP (SMS deferred)
- Firebase Auth native email recovery with customization
- **Critical for lifestyle:** email template must NOT mention app name (privacy if family sees email)
- Generic subject "Solicitud de acceso a tu cuenta"
- Link expiration reduced to 15 minutes (Firebase default 1 hour)
- Force logout of all active sessions on recovery (Cloud Function invalidates tokens)
- Register all recovery attempts with IP, device, date
- In-app notification showing recovery attempts

**Client agreed:** Email only for MVP.

### Point 3 — Account Deletion
**Gabriel proposed:**
- Apple REQUIRES this for App Store approval
- Atomic deletion via Cloud Function: couples doc, photos, video, Firebase Auth, matches, conversations, likes, reports
- 30-day grace period: account enters `pending_deletion`, invisible immediately, data purged day 30
- User can cancel deletion with one tap during grace period
- Double confirmation: warning + "I understand this is permanent" checkbox + red button
- Reports archived anonymously (legal protection)
- Messages to other couples: kept visible as "deleted user" (like WhatsApp)

**Client agreed:** All of it.

### Point 4 — Filters + Geolocation + Travel Match (most complex)

**Client shared design mockup** showing:
- Country + City fields
- Age range slider (35-47 shown)
- **Three independent filter groups:**
  1. **Dynamics:** Parallel Play, Soft Swap, Full Swap
  2. **Experience Preferences:** Same Room, Separate Rooms, Voyeur Couple, Exhibition Couple
  3. **Interests:** Voyeur, Exhibitionist, etc. (free tags)
- **Travel Match:** Resort or Cruise selector + From/To dates
- "Apply Filters" button

**Gabriel corrected earlier assumption:** Intereses are NOT one abstraction but THREE independent filter groups.

**Technical approach agreed:**
- GeoHash stored per couple (`geoflutterfire2` library)
- Query by distance first, filter interests in memory second
- **Dynamics + Experience Preferences:** strict match (binary decisions)
- **Interests (free tags):** 50% threshold, configurable (Option B)
- Roadmap: migrate to Algolia/Typesense if base exceeds 50,000 couples

**Travel Match specifics:**
- Destinations: ~10 predefined lifestyle Resorts/Cruises (not general cities)
- Subcollection `trips` per couple with destination + start_date + end_date
- Matching = same destination + overlapping dates (1-day minimum overlap)
- Auto push notification when new match appears
- 7-day advance reminder before trip start

**Additional feature revealed by client:** Message Request system
- "Start Conversation" creates Request with initial message, not direct message
- Receiver sees preview with photo + interests + sees message
- Can accept or ignore
- Applies to ALL discovery (not just Travel Match)

**Gabriel proposed:**
- `message_requests` collection with full metadata
- 14-day expiration on unanswered requests
- 30-day cooldown between requests to same couple
- Maximum 10 pending outgoing requests per couple
- Silent rejection (receiver unaware of rejection to sender)

**All agreed.**

### Point 5 — Reporting System
**Gabriel proposed:**
- `reports` collection with reporter, reported, category, description, evidence, timestamp, status
- **Categories:** Fake profile, Harassment, Non-consensual content, Suspected minor, Spam, Other
- **Admin actions:** Dismiss, Warning, Suspension
- **Auto-block on report:** B disappears from A's experience immediately
- **Auto-suspension threshold:** 5 reports from different sources in 30 days → `under_review`
- **Anti-abuse:** 10+ reports from same reporter in a week → limit reporting capability
- **Reporter confidentiality:** reported couple NEVER knows who reported
- **Critical for Apple approval:** functional reporting is an App Store requirement

**Client added:** In report flow, show checkbox "Block this couple too" PRE-CHECKED by default.

**Client revealed:** App is for 21+ only (affects "suspected minor" category priority).

### Point 6 — User Blocking
**Gabriel proposed:**
- `blocks` collection: blocker, blocked, date, origin
- **Bidirectional invisible block:** both disappear from each other's experience silently
- **Silent simulation:** blocked user's Requests pretend to send but never arrive
- Block management screen in Settings (Apple requires this)
- No limit on blocks (safety right)

**Two items went to "pending decision" initially:**
1. Auto-block reporters after suspension
2. Restore conversations when unblocking

**Final decisions (captured in contract document):**
- Auto-block after suspension: **YES** (client decided despite Gabriel's later concern about reporter anonymity)
- Conversation restoration on unblock: **NO** (clean start)

### Point 7 — Screenshot Protection
**Client's clarification:** Wants Telegram-style behavior where screenshot results in blank/black image.

**Gabriel explained the "secure layer" technique:**
- iOS: Native `UITextField` with `isSecureTextEntry = true` → iOS marks the layer as system-protected
- Wrap sensitive content in this protected layer as subview
- Implementation via Flutter `MethodChannel` + Swift code
- Reusable widget `SecureView` for the team
- Works iOS 13+

**Android:** `FLAG_SECURE` — blocks screenshots + screen recording

**Client decisions:**
- Applied only to sensitive screens (other profiles, chat, image gallery, Travel Match, Request preview)
- **NO user notification when screenshot attempted** (avoid friction)
- Invisible watermarking: each image rendered with imperceptible pixel pattern encoding viewer's couple ID
- No local cache for sensitive images (fetch to memory, discard on close)

**MVP scope confirmed:** Messages + images only. Video calls = Phase 2.

### Point 8 — App Store + Google Play Publishing

**Client's hard requirement:** *"Apple rejection is not an option."*

**Gabriel initially proposed PWA option for iOS** (to avoid Apple risk).

**Client asked detailed questions about PWA UX on iPhone.**

**After client said "Apple rejection is not an option"**, Gabriel **updated recommendation to native app only** with aggressive approval strategy:

1. Store listing positioning: never use swinger/lifestyle/swap terms publicly; position as "social network for couples"
2. Category 17+ (Apple max, 21+ enforced in-app)
3. Documented functional moderation (Points 5+6 cover this)
4. +21 verification at registration
5. Public moderation policy webpage
6. Honest detailed Privacy Labels
7. Demo account for Apple reviewer
8. Direct support to review team during rejection cycles

**Probability estimate:** 75-85% approval on first or second attempt. Never 100% (honest).

**Client accepted** native strategy.

## PHASE 3 — CODE ACCESS + VIDEO CALL (April 15-17)

### Source code shared
- Alejandra sent Google Drive link with full source code ("el archivo tal cual me lo envio el DEV")
- Gabriel downloaded, analyzed, built, and tested the APK locally

### Video call scheduled
- Meeting code: `akx-fjgy-vzd`
- Time: Wednesday 11:00 AM Cancun
- Client asked about Gabriel's language (profile English, but Spanish strong)
- Gabriel confirmed Philippines-based but works LatAm hours

### Pre-call briefing
Gabriel sent comprehensive written analysis before the call in case of language friction:
- Tech stack reality (no state management, no DI, empty architecture folders)
- Critical findings: CSV interests, unscaleable feed, UI-only Forgot Password
- Gap analysis: 7 of 8 points at 0%, only Point 2 at 30% (UI only)
- Proposed 5-week reordered timeline

### Video call (Wed 11 AM Cancun)
Call was productive. All technical points aligned.

## PHASE 4 — CONTRACT DOCUMENT (April 17)

### Client sent "CONDICIONES GENERALES DEL PROYECTO Affinity" PDF
Complete formal agreement document containing:
- Work commitment principles
- Payment condition: 100% on final delivery
- 2-3 months free post-delivery support
- All 8 agreed points in detail
- Additional technical points (migration, Riverpod, pagination, push, renaming, missing screens)
- Design approval process
- 5-week chronological work order
- Long-term partnership intention note

Client requested: *"confirma explícitamente que estás de acuerdo con TODO"*

## PHASE 5 — CONTRACT ACTIVATION (April 18)

### Gabriel confirmed agreement
Gabriel accepted the conditions explicitly.

### Workana project awarded
Alejandra officially awarded the project to Gabriel on Workana. Contract active.

## PHASE 6 — FIRST TECHNICAL REQUESTS (April 18 onwards)

### Request #1: City autocomplete
Client noticed the hardcoded 16-city dropdown and requested dynamic global autocomplete (like any modern app — user types, system suggests cities/countries worldwide).

**Gabriel confirmed:**
- Viable, fits naturally in Week 1 scope
- Recommended: Google Places Autocomplete API
- Cost: USD 200 Google Cloud free credit, then ~USD 17 per 1000 sessions
- Alternative: OpenStreetMap Nominatim (free but lower quality)

**Client decided:** Google Places. Use email `affinitysocialclub@gmail.com` for Google Cloud account.

### Collaboration model clarified
Client stated explicitly:
- Gabriel works **locally** in isolation during 3-4 weeks
- DEV team continues Phase 2 (Feed Social) on main Firebase platform
- When DEV finishes, Gabriel is responsible for migrating/integrating his work into main Firebase
- DEV won't be available to help with integration

**Gabriel accepted.** This protects both workstreams from collision and allows independent progress.

---

## KEY INSIGHTS FROM CLIENT BEHAVIOR

1. **Highly structured negotiator:** prefers point-by-point analysis, confirmations before moving forward
2. **Product-oriented, not technical:** relies on Gabriel's technical judgment but has strong UX vision
3. **Privacy-focused:** every decision evaluated through lifestyle community safety lens
4. **Quality > speed:** willing to pay more for right execution (never negotiated price down despite USD 66 over stated ceiling)
5. **Long-term thinking:** explicitly mentioned memberships/payments Phase 2, wants ongoing partnership
6. **Team-oriented:** has established DEV team, runs standard hiring video interviews
7. **Trust earned through honesty:** Gabriel's admission that Apple 100% approval is impossible is what won the trust vs. competitors who oversold

## GABRIEL'S WINNING POSITIONING

- Admitted technical limitations honestly (iOS screenshot 100% impossible, Apple approval 75-85%)
- Contrasted with competitors who lied about Feeld/#Open references
- Provided specific implementation details (isSecureTextEntry trick, MethodChannel, geoflutterfire2)
- Handled language barrier proactively (sent written analysis before call in case of friction)
- Respected existing DEV's work (positioned as integration, not replacement)
- Long-term framing (MVP as beginning, not endpoint)

---

**Contract signed, development starting.**
