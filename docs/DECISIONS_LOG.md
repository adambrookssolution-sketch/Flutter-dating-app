# AFFINITY — Decisions Log

> Chronological record of every important decision made during the 8-point negotiation
> All decisions below are FINAL and reflected in the `CONDICIONES GENERALES DEL PROYECTO Affinity.pdf` contract

---

## POINT 1 — VIDEO VERIFICATION

| Decision | Final Value | Who Decided |
|----------|-------------|-------------|
| Verification approach | Manual moderation (human review) | Client (rejected AI option) |
| Registration is per | COUPLE (single entity, not individual) | Client |
| Entry point | Single-screen flow with all data + video | Client |
| Pending state | Full app access blocked until approval | Client |
| Moderation panel | Web admin with one-click approve/reject | Client |
| Rejection reasons | Mandatory dropdown from predefined list | Gabriel → Client agreed |
| Retry limit | **2 attempts** (3rd = permanent block or support) | Client (Gabriel suggested 3, client reduced) |
| Video retention | **7 days** after approval → auto-delete | Client accepted Gabriel's hybrid recommendation |
| Permanent record | SHA-256 hash + date + moderator ID + 2-3 static frames | Gabriel → Client agreed |
| Storage size estimate | ~50 KB per couple permanent record | Gabriel |

---

## POINT 2 — ACCOUNT RECOVERY

| Decision | Final Value | Who Decided |
|----------|-------------|-------------|
| Method | **Email only** for MVP | Gabriel → Client agreed |
| SMS recovery | Deferred to post-MVP phase | Gabriel → Client agreed |
| Email branding | **NO app name, NO logo, neutral language** | Gabriel (lifestyle privacy) → Client agreed |
| Subject | Generic: "Solicitud de acceso a tu cuenta" | Gabriel |
| Link expiration | **15 minutes** (Firebase default is 1 hour) | Gabriel → Client agreed |
| Session management on recovery | Force logout all active sessions via Cloud Function | Gabriel → Client agreed |
| Attempt logging | IP + device + date stored, notification to user | Gabriel → Client agreed |

---

## POINT 3 — ACCOUNT DELETION

| Decision | Final Value | Who Decided |
|----------|-------------|-------------|
| Deletion style | Atomic via Cloud Function (all-or-nothing) | Gabriel |
| Scope of deletion | Profile + photos + video + Auth + conversations + matches + reports + moderation | Gabriel → Client agreed |
| Grace period | **30 days** (invisible immediately, data purged day 30) | Gabriel → Client agreed |
| User cancellation | Possible during grace period | Gabriel → Client agreed |
| Confirmation UI | Double confirmation + "I understand this is permanent" checkbox + red button | Gabriel → Client agreed |
| Reports archival | **Anonymized** (strip PII, keep statistical data for legal protection) | Gabriel → Client agreed |
| Messages in other chats | Preserved on receiver side, profile shown as "usuario eliminado" (WhatsApp-style) | Gabriel → Client agreed |
| Apple requirement | This feature is MANDATORY for App Store approval | Apple policy |

---

## POINT 4 — FILTERS + GEOLOCATION + TRAVEL MATCH

### Filter Categories (from design mockup)
| Category | Matching Logic | Values |
|----------|----------------|--------|
| **Dynamics** | Strict (binary) | Parallel Play, Soft Swap, Full Swap |
| **Experience Preferences** | Strict (binary) | Same Room, Separate Rooms, Voyeur Couple, Exhibition Couple |
| **Interests** | **≥ 50% threshold** (Option B, configurable) | Free tags: Voyeur, Exhibitionist, Kinky, etc. |
| Country + City | Strict match | From Google Places |
| Age | Range slider | Calculated from birth dates |

### Technical Architecture
| Decision | Final Value | Who Decided |
|----------|-------------|-------------|
| Geospatial library | `geoflutterfire2` | Gabriel |
| Query order | 1) GeoHash distance → 2) In-memory interest filter → 3) Order by proximity | Gabriel → Client agreed |
| Scalability roadmap | Start with Firestore + GeoHash; migrate to Algolia/Typesense if >50,000 active couples | Gabriel → Client agreed |
| Interest matching default | 50% configurable via admin panel | Gabriel → Client agreed |

### Travel Match
| Decision | Final Value | Who Decided |
|----------|-------------|-------------|
| Destination pool | ~10 predefined lifestyle Resorts/Cruises | Client |
| Storage | Subcollection `couples/{id}/trips/*` | Gabriel |
| Fields | destination + destination_id + start_date + end_date | Gabriel → Client agreed |
| Match criteria | Same destination + overlapping dates (1-day overlap OK) | Gabriel → Client agreed |
| Combined filters | Travel Match stackable with intereses + edad + país | Gabriel → Client agreed |
| Auto notification on new match | Push: "[N] parejas también viajan a [X] en tus fechas" | Gabriel → Client agreed |
| Advance reminder | Push 7 days before trip start | Gabriel → Client agreed |

### Message Requests
| Decision | Final Value | Who Decided |
|----------|-------------|-------------|
| Request collection | `message_requests` | Client (revealed flow) |
| Start Conversation behavior | Must include initial message (NOT empty) | Client |
| Preview fields to receiver | foto_preview + intereses_visibles + mensaje_inicial | Client |
| Expiration | **14 days** unanswered → auto `expired` | Gabriel → Client agreed |
| Cooldown after rejection | **30 days** before sender can re-request same receiver | Gabriel → Client agreed |
| Silent rejection | Sender NEVER knows Request was rejected | Gabriel → Client agreed |
| Max pending outgoing requests | 10 per couple at a time | Gabriel → Client agreed |

---

## POINT 5 — REPORTING SYSTEM

### Structure
| Decision | Final Value |
|----------|-------------|
| Collection name | `reports` |
| Categories | Perfil falso, Acoso, Contenido no consensuado, Menor de edad, Spam, Otro |
| Admin actions | Dismiss / Warning / Suspension |
| Moderator tracking | `moderator_id` on every decision |

### Business Rules
| # | Rule | Final Value | Who Decided |
|---|------|-------------|-------------|
| 1 | Auto-block on report | YES, immediate (no wait for review) | Gabriel → Client agreed |
| 2 | Checkbox in report flow | "Block this couple too" PRE-CHECKED by default | Client (addition) |
| 3 | Auto-suspension threshold | 5 reports from different sources in 30 days → `under_review` | Gabriel → Client agreed |
| 4 | Anti-abuse threshold | 10+ reports from same reporter in 7 days → disable reporting | Gabriel → Client agreed |
| 5 | Reporter confidentiality | **TOTAL** — reported couple NEVER learns reporter identity | Gabriel → Client agreed |
| 6 | Suspension notification | Generic reason category only, no reporter identity | Gabriel → Client agreed |

### App Store Context
Client confirmed app is **21+ only**. This elevates importance of "Menor de edad" category. Apple requires functional reporting for dating app approval.

---

## POINT 6 — USER BLOCKING

| Decision | Final Value | Who Decided |
|----------|-------------|-------------|
| Collection name | `blocks` | Gabriel |
| Effect | Bidirectional + invisible (both disappear, neither notified) | Gabriel → Client agreed |
| Silent simulation | Blocked user's Requests appear sent to them but never arrive | Gabriel → Client agreed |
| Existing conversations | Hidden on both sides, not deleted (preserved for investigation) | Gabriel → Client agreed |
| Block management screen | In Settings (Perfil > Seguridad), list + unblock option | Gabriel → Client agreed |
| Block limit | **No limit** (safety right) | Gabriel → Client agreed |
| Auto-block after suspension | **YES** (client overrode Gabriel's later concern) | Client decided |
| Conversation restoration on unblock | **NO** (clean start, emotional noise avoided) | Gabriel → Client agreed |

### Note on auto-block decision
Gabriel initially recommended YES, then reconsidered and recommended NO (out of concern for indirect reveal of reporter identity). Client considered and decided **YES**, prioritizing the protective UX over the indirect reveal risk. **Client's decision is final.**

---

## POINT 7 — SCREENSHOT PROTECTION

### Technical Approach
| Platform | Technique |
|----------|-----------|
| iOS | SecureView via `UITextField` with `isSecureTextEntry = true` (Telegram-style) |
| Android | `FLAG_SECURE` |
| Integration | Flutter `MethodChannel` ↔ native Swift/Kotlin |

### Applied Screens
| Decision | Value | Who Decided |
|----------|-------|-------------|
| Scope | Only sensitive screens, NOT app-wide | Gabriel → Client agreed |
| List | Perfiles ajenos, Chat, Imágenes, Galería ampliada, Travel Match, Request preview | Client |

### User Notifications on Screenshot Attempt
**Decision: NO notifications** (client explicitly rejected)
Reason: *"No queremos alertar ni generar fricción o incomodidad en la experiencia"*

### Additional Privacy Layers
| Feature | Decision |
|---------|----------|
| Invisible watermarking | YES — pixel pattern encoding viewer's couple ID |
| No local cache | YES — sensitive images in memory only |

### MVP Scope
- **Messages + images only** in MVP
- Video calls deferred to Phase 2 (client decision)

### iOS Minimum Version
iOS 13+

### Honest Limitation (disclosed to client)
Cannot prevent someone photographing the screen with another device. No app can — not even Netflix. Invisible watermarking mitigates this via traceability.

---

## POINT 8 — APP STORE + GOOGLE PLAY

### Strategy
| Decision | Value |
|----------|-------|
| App type | **Native Flutter** (PWA rejected by client) |
| Rejection is | **NOT an option** (client's hard requirement) |
| Target Apple approval probability | 75-85% on 1st or 2nd attempt (Gabriel's honest estimate) |

### Apple Strategy (8-pillar approach)
1. Conservative store listing — NEVER mention swinger/lifestyle/swap terms
2. Position as "social network for couples"
3. Category 17+ (Apple max), 21+ enforced in-app
4. Functional moderation (Points 5+6) required at submission
5. +21 verification at registration
6. Public moderation policy webpage
7. Honest detailed Privacy Labels
8. Demo account for reviewer + direct support during review

### Google Play
- Straightforward approval (1-3 days expected)
- Dating app declaration form
- Moderation confirmed functional

### Deliverables (included in scope)
- Apple Developer + Google Play Console accounts setup
- Store assets (icons, screenshots, descriptions EN+ES)
- Legal templates (Privacy Policy + Terms) for lawyer review
- TestFlight beta
- Submission packages
- Review team response support

### Deferred to Phase 2
- PWA alternative
- Videollamadas (video calls)
- Subscription/payment systems (Stripe vs Apple IAP debate)
- Advanced Apple approval strategies if needed

---

## POST-CONTRACT DECISIONS

### City Autocomplete (April 18)
| Decision | Value |
|----------|-------|
| Service | **Google Places Autocomplete API** |
| Alternative considered | OpenStreetMap Nominatim (rejected — lower quality) |
| Google Cloud account | `affinitysocialclub@gmail.com` (client-provided) |
| Cost | USD 200 free monthly credit + ~$17/1000 sessions beyond |
| Storage saved from API | city + country + country_code + lat + lng + geohash |
| Fits in scope | Yes — part of Week 1 data migration work (no extra cost) |

### Collaboration Model (April 18)
| Decision | Value |
|----------|-------|
| Work location | Gabriel works **locally** in isolation |
| Duration | 3-4 weeks (until DEV finishes Phase 2) |
| Firebase access | Gabriel uses separate dev Firebase project (not touching production) |
| GitHub access | Gabriel uses local copy (not shared repo during this phase) |
| Integration responsibility | **Gabriel** migrates/integrates his work into main platform after DEV finishes |
| DEV support during integration | **Not available** — integration is solely Gabriel's responsibility |
| Coordination | Via Alejandra if needed |

---

## CLIENT'S NON-NEGOTIABLE REQUIREMENTS

Per `CONDICIONES GENERALES`:

1. ✅ Responsabilidad y compromiso (commitment)
2. ✅ Comunicación directa y constante (direct, constant communication)
3. ✅ Entrega sólida y bien cuidada (solid, well-crafted delivery)
4. ✅ Soporte post-entrega 2-3 meses sin costo adicional
5. ✅ **INDISPENSABLE:** calidad mejor que propuestas habituales

### Payment Condition
- **100% against final delivery**
- Final delivery = fully functional + Apple/Google requirements met
- Paid via Workana escrow

### Design Approval Process
- Developer responsible for UI/UX of new screens
- Must follow existing visual system
- **Prior approval required** for all new screens/components/flows
- No unilateral design changes
- Proposals welcome but subject to approval

---

## LONG-TERM PARTNERSHIP INTENT (client-stated)

> *"De nuestra parte buscamos construir una relación de trabajo a largo plazo. Si este proyecto se ejecuta correctamente y con la calidad esperada, nuestra intención es seguir desarrollando futuras funcionalidades y evolución del producto conforme Affinity vaya creciendo."*

### Phase 2 Topics (mentioned, deferred)
- Subscription/memberships
- Recurring payments (Stripe vs Apple IAP — hybrid legal models)
- Feed Social (currently being built by DEV)
- Video calls
- PWA fallback

---

## DECISION AUTHORITY MATRIX

| Area | Final Authority |
|------|-----------------|
| Business logic / product decisions | **Client (Alejandra)** |
| Technical implementation choices | **Gabriel** (with client visibility) |
| UI/UX for new screens | **Client approves**, Gabriel proposes |
| Schema / data model | **Gabriel proposes**, client approves major changes |
| Scope changes | **Mutual agreement required** |
| Design system changes | **Client (creative team)** |

---

**End of decisions log.**
