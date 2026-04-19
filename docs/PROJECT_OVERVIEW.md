# AFFINITY — Project Overview

> **Complete project documentation for Gabriel's development work on Affinity**
> Last updated: 2026-04-18

---

## 1. PROJECT IDENTITY

- **App Name:** Affinity
- **Type:** Social dating app exclusively for couples in the lifestyle community
- **Target audience:** Couples only, 21+ (enforced in-app)
- **Region focus:** Latin America (Spanish-speaking markets, Mexico primary)
- **Brand color:** Burgundy `#B31637`
- **Domain logo:** Pineapple icon (traditional lifestyle symbol)

## 2. CLIENT

- **Name:** Alejandra (Project Owner / PM, non-technical)
- **Contact channel:** Workana chat
- **Email (Google Cloud account):** `affinitysocialclub@gmail.com`
- **Team structure:**
  - Alejandra (Owner / creative direction)
  - Existing DEV / agency (currently building Phase 2 — Feed Social)
  - **Gabriel (me)** — Security, privacy, moderation specialist (new hire)

## 3. CONTRACT STATUS

- **Platform:** Workana
- **Contract status:** ✅ **Active** (awarded and accepted)
- **Bid amount:** USD 3,066.78 (accepted)
- **Payment condition:** 100% against final delivery (per Condiciones Generales document)
- **Post-delivery support:** 2-3 months free adjustments
- **Timeline:** 5 weeks of active development
- **Collaboration model:** Gabriel works **locally and isolated** during 3-4 weeks. Existing DEV continues Phase 2 in parallel on the main Firebase platform. After DEV finishes, Gabriel is responsible for migrating/integrating his work into the main Firebase platform.

## 4. TECHNOLOGY STACK (NON-NEGOTIABLE)

### Current
- **Framework:** Flutter 3.8.1 (Dart)
- **UI:** Material Design, custom brand theming
- **Backend:** Firebase (Core 4.4, Auth 6.1, Firestore 6.1, Storage 13.0)
- **Authentication:** Google Sign-In, Apple Sign-In, Email/Password
- **Localization:** English + Spanish (`flutter_localizations`)
- **Images:** `image_picker`, `flutter_svg`

### To be added (agreed)
- **Location autocomplete:** Google Places Autocomplete API (confirmed)
- **Geospatial queries:** `geoflutterfire2` (GeoHash-based)
- **State management:** Riverpod (progressive introduction)
- **Push notifications:** `firebase_messaging` + Firebase Cloud Messaging
- **Serverless logic:** Firebase Cloud Functions
- **Platform channel:** Flutter `MethodChannel` ↔ native Swift/Kotlin (for screenshot protection)

## 5. HIGH-LEVEL ARCHITECTURE

### Core principles (client-approved)
- **Couple-as-single-entity:** one Firestore document per couple, containing `partner_a` and `partner_b` sub-objects
- **Privacy-first:** minimize stored data, silent protections, anonymized audit trails
- **Manual moderation:** human review for video verification and reports
- **Apple-approval-ready:** conservative positioning, functional moderation, demo accounts

### Target Firestore schema (to migrate into)
```
couples/{coupleId}
  ├── partner_a: { name, birth, height }
  ├── partner_b: { name, birth, height }
  ├── city, country, country_code
  ├── lat, lng, geohash
  ├── description
  ├── photos: [url, url, ...]
  ├── dynamics: []             ← separated array
  ├── experience_preferences: []  ← separated array
  ├── interests: []            ← separated array
  ├── status: pending_review | approved | rejected | suspended | pending_deletion | under_review
  ├── verification: {
  │     video_url, sent_at, reviewed_at, moderator_id,
  │     reject_reason, attempts, video_hash, video_frames: []
  │   }
  ├── created_at, updated_at
  └── trips/ (subcollection)
        destination, start_date, end_date

message_requests/{requestId}
  pareja_emisora, pareja_receptora, mensaje_inicial,
  foto_preview, intereses_visibles,
  estado (pending | accepted | rejected | expired),
  origen (travel_match | busqueda | perfil),
  fecha_envio, fecha_expiracion

conversations/{coupleA_coupleB}
  participants, initiated_by,
  last_message, last_message_by, last_message_time,
  replied_by, created_at
    messages/ (subcollection)
      text, sender_uid, created_at

reports/{reportId}
  pareja_reportante, pareja_reportada,
  categoria, descripcion, evidencia: [...],
  fecha, estado, accion_tomada,
  moderador_id

blocks/{blockId}
  pareja_que_bloquea, pareja_bloqueada,
  fecha, origen (manual | via_reporte | auto_por_suspension)

tags/{tagId}
  name, category (dynamics | experience | interests), order
```

## 6. CURRENT CODE STATE (as received from DEV)

### What works well ✓
- Login flows (Google, Apple, Email) — fully functional
- Profile Setup screen with 6 photos drag-and-drop reorder
- Real-time chat with message bubbles and date separators
- Request/Accept flow (clever state machine using `initiated_by` + `replied_by`)
- Inbox with collapsible sections for Requests vs Chats
- Brand identity consistent across screens
- i18n infrastructure ready (EN + ES)

### What's missing (7 of 8 agreed features are 0%)
| # | Feature | Current State |
|---|---------|---------------|
| 1 | Video verification | 0% |
| 2 | Account recovery | 30% (UI only, not connected to Firebase) |
| 3 | Account deletion | 0% |
| 4 | Geo + Filters + Travel Match | 5% (city dropdown only, 16 hardcoded cities) |
| 5 | Report system | 0% |
| 6 | User blocking | 0% |
| 7 | Screenshot protection | 0% |
| 8 | Store publishing | 0% |

### Known technical issues
1. **`interests` stored as CSV string** — cannot be queried, must migrate to arrays
2. **`getAllProfiles()` loads entire collection** — crashes with scale, needs pagination
3. **Forgot Password is UI-only** — not connected to Firebase Auth
4. **Clean architecture folders empty** (`domain/`, `dependency_injections/`, `device/`)
5. **No state management library** — raw `setState` everywhere
6. **No Firestore Security Rules** in repo (critical)
7. **Package name still `app`** — not rebranded
8. **16 hardcoded cities** in profile setup (Madrid, Barcelona, Buenos Aires, CDMX, Bogotá, Lima, Santiago, Caracas, Miami, NY, LA, London, Paris, Berlin, São Paulo, Other)
9. **Dummy test data** throughout ("Stuart Yang & Stuart Yang", "Her & His")
10. **Chat suggestions hardcoded in English** (breaks i18n)

## 7. DEVELOPMENT TIMELINE (5 weeks)

### Week 1 — Foundation (backend/data invisible to user)
- [ ] Data model migration: `profiles` collection → rename to `couples` semantic, keep same structure
- [ ] Split `interests` CSV into three arrays: `dynamics[]`, `experience_preferences[]`, `interests[]`
- [ ] Add missing fields: `country`, `country_code`, `lat`, `lng`, `geohash`, `status`, `age_range`
- [ ] Create `trips` subcollection schema
- [ ] Google Places Autocomplete integration for city/country field (global coverage, real-time suggestions)
- [ ] Google Cloud Platform account setup with `affinitysocialclub@gmail.com`
- [ ] Connect Forgot Password UI to real Firebase Auth (currently placeholder)
- [ ] Email template customization (no branding, generic subject, neutral link) — critical for lifestyle privacy
- [ ] Account deletion flow with 30-day grace period + Cloud Function atomic delete
- [ ] Deploy Firestore Security Rules (currently missing)

### Week 2 — Verification + Moderation Core
- [ ] Video verification: recording UI, upload to Firebase Storage, pending_review state
- [ ] Admin web panel for moderators (approve/reject with one click)
- [ ] 7-day video retention policy + Cloud Function cleanup
- [ ] Hash + 2-3 frames permanent record
- [ ] Report system: `reports` collection, categories, moderation panel
- [ ] User blocking: `blocks` collection, bidirectional silent logic
- [ ] Integration of block checkbox (default ON) in report flow

### Week 3 — Filters + Travel Match
- [ ] Filters screen UI (matching the design mockup)
- [ ] GeoHash query implementation (`geoflutterfire2`)
- [ ] Three independent filter groups (Dynamics, Experience, Interests)
- [ ] Age range slider + Country/City filters
- [ ] Travel Match subsystem with `trips` subcollection
- [ ] Matching algorithm: same destination + overlapping dates
- [ ] Travel Match push notifications (on new match + 7-day advance reminder)

### Week 4 — Privacy + Performance
- [ ] iOS SecureView (MethodChannel + Swift with `isSecureTextEntry` trick)
- [ ] Android FLAG_SECURE
- [ ] Apply to: profiles, chat, images, gallery zoom, Travel Match, Request preview
- [ ] Invisible watermarking on rendered images (client-side pixel pattern encoding viewer couple ID)
- [ ] No local cache policy for sensitive images
- [ ] Firebase Cloud Messaging integration
- [ ] Feed pagination (replace `getAllProfiles()` with cursor-based queries)
- [ ] Progressive Riverpod introduction for new complex state

### Week 5 — Store Preparation + Launch
- [ ] Apple Developer account setup
- [ ] Google Play Console setup
- [ ] App assets (icons, splash, store screenshots) in EN + ES
- [ ] Conservative store positioning ("social network for couples", never mention lifestyle/swinger terms publicly)
- [ ] Category 17+ declaration (Apple max; 21+ enforced in-app)
- [ ] Privacy labels (detailed, honest)
- [ ] Public moderation policy webpage
- [ ] +21 verification flow at registration
- [ ] Demo account for Apple reviewer
- [ ] TestFlight beta
- [ ] Google Play submission
- [ ] Apple submission with direct support to review team

## 8. INTEGRATION PHASE (after Week 5, when DEV finishes Phase 2)

- [ ] Pull latest DEV code from main branch
- [ ] Merge Gabriel's local work into main codebase
- [ ] Migrate Firebase data from local dev project to production Firebase
- [ ] Resolve any schema conflicts between Gabriel's changes and DEV's Phase 2 feed work
- [ ] End-to-end testing with both workstreams integrated
- [ ] Deploy integrated version
- **This phase is Gabriel's responsibility** (agreed with client)

## 9. KEY DESIGN CONSTRAINTS

- **Design approval required:** New screens/components/flows must be presented to creative team for approval before being final
- **No unilateral design changes:** Cannot change colors, typography, layouts, interaction without prior validation
- **Follow existing visual system:** Burgundy `#B31637`, wave clippers, gradient backgrounds, card-based UI
- **Proposals welcome:** Design improvements can be suggested, but implementation requires approval

## 10. COMMUNICATION PROTOCOL

- **Primary channel:** Workana chat (escalate to Slack/Discord/WhatsApp once DEV is introduced)
- **Language:** Spanish with client (my main is English, but Spanish is strong for written/technical)
- **Tone:** Open, constant, proactive — client explicitly wants communication without friction
- **Client philosophy:** *"Preferimos trabajar con flexibilidad en pequeños ajustes o mejoras"*

## 11. KEY AGREED DECISIONS (from 8-point negotiation)

See `DECISIONS_LOG.md` for full history. Summary of final decisions:

| Area | Decision |
|------|----------|
| Video verification | Manual moderation, 2 retry attempts, 3rd = permanent block |
| Video retention | 7 days + hash/frames permanent |
| Account recovery | Email only for MVP, no app-name branding, 15-min link expiration |
| Account deletion | 30-day grace, double confirmation, atomic Cloud Function |
| Filter matching | Dynamics + Experience = strict, Interests = 50% (Option B) |
| Travel Match | Predefined resorts/cruises + date range + auto notifications |
| Reporting | Auto-block on report, 5 reports/30d = auto-suspend, 10 reports/week = abuse flag |
| Block system | Bidirectional silent, auto-block after suspension, no limit |
| Screenshot protection | Tech only (no user notifications) — FLAG_SECURE + isSecureTextEntry + watermark + no cache |
| App Store strategy | Native Flutter, 17+ rating, conservative positioning, demo account, direct review team support |
| Video calls | NOT in MVP — deferred to Phase 2 |
| Couple login | Shared account (one Firebase Auth per couple) — intentional for MVP |
| Long-term partnership | Client wants continued collaboration after MVP for memberships + payments (Phase 2) |

## 12. RISKS & MITIGATIONS

| Risk | Mitigation |
|------|------------|
| 100% back-end payment | Workana escrow protection; deliver milestones to show progress |
| 2-3 month free support scope creep | Document scope clearly (bug fixes + store rejection response only); new features = separate quote |
| Apple rejection | Conservative positioning strategy (Feeld/#Open playbook); 75-85% first-attempt approval target; not 100% guaranteed |
| Integration complexity after DEV finishes | Keep changes surgical, documented, and reversible; maintain compatibility with DEV's schema |
| DEV's Phase 2 conflicts with my data migration | Coordinate via Alejandra when critical; document all schema changes |
| Design approval delays | Present early mockups; batch approvals; follow existing design system strictly |

## 13. REFERENCE DOCUMENTS

- `CONDICIONES GENERALES DEL PROYECTO "Affinity".pdf` — client-provided contract base (D:\BID folder)
- `DECISIONS_LOG.md` — Full history of 8-point negotiation decisions
- `CHAT_HISTORY.md` — Summary of all client conversations
- `CODE_ANALYSIS.md` — Technical analysis of received source code
- `TECHNICAL_SPEC.md` — Detailed technical specifications per feature

---

**Status:** Contract active. Week 1 development starting.
**Next action:** Google Cloud Platform setup + begin data model migration.
