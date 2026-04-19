# AFFINITY — Technical Specifications

> Detailed technical specifications for all 8 agreed features + supporting infrastructure
> Source: Client's `CONDICIONES GENERALES DEL PROYECTO Affinity.pdf` + negotiation history

---

## 0. CROSS-CUTTING PRINCIPLES

- **Couple as single entity:** all operations at couple-level, never individual partner
- **Privacy-first:** minimize stored data, anonymize audit trails, silent protections
- **Manual moderation:** human review for verification and reports
- **Apple-approval-ready:** functional moderation, +21 verification, conservative positioning

---

## 1. VIDEO VERIFICATION

### Registration Flow (per couple)
1. Single-screen registration for both partners
2. Fields: names (both), ages (both), city, country, description, photos of both, verification video
3. All saved as single document in `couples` collection
4. Profile enters `pending_review` status
5. User sees waiting screen, no app access

### Moderation Panel (web admin)
- Queue view of pending verifications
- One-click approve / reject
- Mandatory rejection reason (from predefined list)
- Moderator ID tracked on every decision

### Notifications
- Approved → access to COUPLES section
- Rejected → can retry
- Rejected 2nd time → permanent block or support contact

### Retry Rules
- 2 attempts total
- 3rd rejection → permanent block or support channel

### Video Retention (HYBRID approach)
1. Full video stored 7 days after approval
2. After 7 days, Cloud Function automatically deletes from Storage
3. Permanent record kept:
   - SHA-256 hash of video
   - Verification date
   - Moderator ID
   - 2-3 low-resolution static frames

### Firestore Structure
```javascript
couples/{coupleId} {
  partner_a: { name, birth, height, ... },
  partner_b: { name, birth, height, ... },
  status: "pending_review" | "approved" | "rejected" | "suspended",
  verification: {
    video_url: string,        // null after 7 days
    sent_at: timestamp,
    reviewed_at: timestamp,
    moderator_id: string,
    reject_reason: string,
    attempts: number,
    video_hash: string,       // permanent
    video_frames: [url, url, url]  // 2-3 low-res frames, permanent
  }
}
```

### Cloud Function: `cleanup_expired_videos`
- Triggered daily
- Queries `couples` where `verification.reviewed_at < NOW - 7 days` AND `verification.video_url != null`
- Deletes video from Firebase Storage
- Sets `verification.video_url = null`
- Keeps hash + frames intact

---

## 2. ACCOUNT RECOVERY

### Strategy
- **Email only** for MVP (SMS deferred)
- Firebase Auth native recovery with customization
- **Privacy-critical:** email must NOT mention "Affinity" or app branding

### Email Template Customization (Firebase Console)
- **Subject:** "Solicitud de acceso a tu cuenta" (generic, no app name)
- **Body:** No logo, no brand colors, no app name
- **From:** Neutral email (e.g., `noreply@[custom-domain]`)
- **Link:** Generic wording: "Haz clic aquí para restablecer tu acceso"

### Link Configuration
- Expiration: **15 minutes** (not Firebase default 1 hour)
- Configure via Firebase Admin SDK `generatePasswordResetLink` with custom action code settings

### On Recovery Completion (Cloud Function)
1. Invalidate all active sessions (Firebase Auth `revokeRefreshTokens`)
2. All devices force-logout automatically
3. User must re-authenticate

### Attempt Logging
Every recovery attempt logged in `account_recovery_attempts` collection:
```javascript
{
  couple_id: string,
  ip: string,
  device: string,     // User-Agent
  date: timestamp,
  completed: boolean
}
```

### In-App Notification
On next successful login after recovery attempt:
- Show dialog: "Recovery attempted on [date] from [device]"
- If not user → prompt to change password + contact support

---

## 3. ACCOUNT DELETION

### Flow
1. User taps "Delete Account" in Settings > Security
2. Warning screen with full consequences list
3. Mandatory checkbox: "I understand this is permanent"
4. Red confirmation button
5. Account enters `pending_deletion` state
6. Immediately invisible to other users
7. User can cancel deletion anytime during 30-day grace period
8. Day 30: Cloud Function atomic deletion

### Cloud Function: `execute_deletion`
Triggered daily, processes couples where `status = pending_deletion` AND `deletion_requested_at < NOW - 30 days`:

1. **Firestore deletes (atomic batch):**
   - `couples/{coupleId}` document
   - All subcollections (`trips`, etc.)
   - `conversations` where participants includes coupleId
   - `messages` subcollections of those conversations
   - `message_requests` where pareja_emisora OR pareja_receptora = coupleId
   - `likes` involving coupleId
   - `blocks` where involves coupleId

2. **Storage deletes:**
   - All photos in `couples/{coupleId}/photos/*`
   - Verification video (if still present)
   - Verification frames

3. **Firebase Auth:**
   - Delete Auth account (`admin.auth().deleteUser(uid)`)

4. **Report anonymization (legal preservation):**
   - Reports WHERE reported_couple = coupleId → strip personal data, keep statistical metadata

5. **In other couples' chats:**
   - Profile reference replaced with "usuario eliminado"
   - Conversation history NOT deleted (other user keeps context)

### Apple Requirement
This feature is MANDATORY for App Store approval. Cannot skip.

---

## 4. FILTERS + GEO + TRAVEL MATCH

### Filter Logic Flow
1. **GeoHash query** — narrow by distance first (reduces dataset)
2. **Query by distance** — Firestore `where` clause using `geoflutterfire2`
3. **In-memory filter** — apply interest/age/etc. filters on client side after geo query
4. **Order by proximity** — sort by distance ascending

### Filter Categories (three independent arrays)

#### Dynamics (strict match)
- Parallel Play
- Soft Swap
- Full Swap

#### Experience Preferences (strict match)
- Same Room
- Separate Rooms
- Voyeur Couple
- Exhibition Couple

#### Interests (flexible match, ≥ 50% threshold, configurable)
- Free tags (Voyeur, Exhibitionist, Kinky, Hot Wife, Curious, Vanilla, etc.)
- Admin panel configurable threshold

### Additional Filters
- **Country** (from Google Places autocomplete)
- **City** (from Google Places autocomplete)
- **Age range** (slider)

### Travel Match

#### Subcollection: `couples/{coupleId}/trips/{tripId}`
```javascript
{
  destination: string,    // from predefined list (~10 lifestyle resorts/cruises)
  destination_id: string,
  start_date: timestamp,
  end_date: timestamp,
  created_at: timestamp
}
```

#### Predefined Destinations
- ~10 lifestyle Resorts/Cruises (client will provide final list)
- Stored in `destinations` collection for admin management

#### Matching Logic
- Same `destination_id`
- Overlapping date ranges (even 1-day overlap = match)
- Can be combined with all other filters (intereses, edad, país, etc.)

#### Push Notifications
- **On new match:** when couple registers trip, system queries existing trips, sends push to matching couples: *"[N] parejas también viajan a [Destino] en tus fechas"*
- **7-day advance reminder:** 7 days before `start_date`, push to both couples with confirmed matches

### Message Requests System

#### Collection: `message_requests/{requestId}`
```javascript
{
  pareja_emisora: coupleId,
  pareja_receptora: coupleId,
  mensaje_inicial: string,      // NOT optional — must have content
  foto_preview: url,
  intereses_visibles: [string],
  estado: "pending" | "accepted" | "rejected" | "expired",
  origen: "travel_match" | "busqueda" | "perfil",
  fecha_envio: timestamp,
  fecha_expiracion: timestamp   // 14 days from fecha_envio
}
```

#### Rules
- **Expiration:** 14 days unanswered → automatic `expired` state
- **Cooldown:** after rejection, 30 days before sender can request same receiver again
- **Silent rejection:** sender never sees rejection; receiver just dismisses
- **Acceptance:** creates `conversation` document, Request closes

---

## 5. REPORTING SYSTEM

### Collection: `reports/{reportId}`
```javascript
{
  reporter_couple: coupleId,
  reported_couple: coupleId,
  categoria: "perfil_falso" | "acoso" | "contenido_no_consensuado"
           | "menor_edad" | "spam" | "otro",
  descripcion: string,           // optional for most, required for "otro"
  evidencia: [string],           // screenshot URLs or message IDs
  fecha: timestamp,
  estado: "pending" | "reviewed" | "dismissed",
  accion_tomada: "none" | "warning" | "temp_suspension" | "permanent_ban",
  moderador_id: string,          // filled when reviewed
  reviewed_at: timestamp
}
```

### Categories (predefined, closed list)
1. Perfil falso
2. Acoso
3. Contenido no consensuado
4. Menor de edad (CRITICAL given +21 policy)
5. Spam
6. Otro (requires description)

### Admin Actions
- **Dismiss** — no action, report closed
- **Warning** — notify reported couple with generic reason
- **Suspension** — temporary (configurable days) or permanent

### Business Rules

#### 1. Automatic Block on Report
- When couple A reports couple B, B immediately disappears from A's experience
- No waiting for manual moderation review
- Applies to: search, matches, Travel Match, existing conversations
- **Report flow UI:** checkbox "Block this couple too" PRE-CHECKED by default (user can uncheck)

#### 2. Auto-Suspension (threshold)
- 5 reports from different sources in 30 days → auto `under_review` status
- Profile invisible to all users until moderator decides

#### 3. Anti-Abuse (reporter limit)
- Couple sending 10+ reports in 7 days → reporting temporarily disabled
- Moderation team notified

#### 4. Total Reporter Confidentiality
- Reported couple NEVER learns who reported
- Not even indirectly (e.g., don't auto-block reporters visibly)
- **Note:** Client decided YES on auto-block after suspension despite Gabriel's concern about indirect reveal

#### 5. Generic Reason on Suspension Notice
- User sees reason category (e.g., "Reportes por comportamiento inapropiado")
- Never shows reporter identity, specific details, or message quotes

### Apple App Store Context
Functional reporting is a REQUIREMENT for App Store approval of dating apps.

---

## 6. USER BLOCKING

### Collection: `blocks/{blockId}`
```javascript
{
  pareja_que_bloquea: coupleId,
  pareja_bloqueada: coupleId,
  fecha: timestamp,
  origen: "manual" | "via_reporte" | "auto_por_suspension"
}
```

### Effect: Bidirectional + Invisible
When couple A blocks couple B:
- B disappears from A's experience completely
- A disappears from B's experience completely
- **NEITHER party is notified**
- B sees no indication of block

### Affected Areas
- Search / discovery feed
- Travel Match results
- Existing conversations hidden (not deleted — kept for investigation)
- Existing Requests hidden
- Future Requests from B to A silently simulated (appear sent to B but never arrive to A)

### Silent Simulation Example
- B tries to send Request to A → UI shows "Request sent" ✓
- Server-side: no document created, no notification to A
- Prevents B from detecting block through testing

### Management Screen (Perfil > Seguridad)
- List of all blocked couples
- One-tap unblock option
- Only shows date, no other details
- **Apple requires this for dating apps**

### Rules
1. **No limit** on number of blocks (safety right)
2. **Auto-block after suspension:** when moderation suspends couple B, all couples who reported B automatically block B going forward (client decision)
3. **Conversation restoration on unblock:** NO — clean start, old conversations stay hidden permanently in database but not visible

---

## 7. PRIVACY PROTECTION (Screenshots)

### iOS: SecureView (Telegram-style)

#### Technique
1. Create native `UITextField` with `isSecureTextEntry = true`
2. iOS marks that layer as system-protected content
3. Embed sensitive content (images, text) as subview inside that layer
4. Screenshots capture the layer as **black/empty**

#### Implementation
- Native Swift code in iOS module
- Flutter `MethodChannel` bridge Dart → Swift
- Reusable Flutter widget `SecureView` wrapping any Widget
- Team uses `SecureView(child: ...)` without touching native code

#### Minimum iOS version
iOS 13+

### Android: FLAG_SECURE

#### Technique
- Set `WindowManager.LayoutParams.FLAG_SECURE` on Activity window
- Or set per-screen via Flutter plugin
- Blocks screenshots AND screen recording globally on the screen

### Applied Screens (not app-wide)
- Other couple's profile view
- Chat conversations
- Image gallery / zoom view
- Travel Match screen (with photos)
- Incoming Request preview screen

### NOT applied (maintains UX)
- Settings, Help, Terms screens
- Own profile (the couple may want to screenshot their own profile)

### Invisible Watermarking

#### Purpose
If a photo leaks outside the app, we can identify the source couple by decoding the watermark.

#### Implementation (client-side on render)
1. Image loaded from Firebase Storage
2. Before display, apply imperceptible pixel pattern encoding viewer's coupleId
3. Pattern strong enough to survive screenshot + compression
4. Subtle enough to be imperceptible to human eye

#### Decoder
- Internal tool accepts suspected leaked image
- Runs reverse algorithm → extracts coupleId
- Flags source couple for moderation review

### No Local Cache for Sensitive Images
- Other couples' photos NOT stored in device cache
- Fetch to memory → display → discard on screen close
- Small data cost, huge privacy benefit
- Prevents someone with physical device access from recovering images

### NO User Notifications on Screenshot Attempt
**Client decision:** do NOT notify when screenshot attempted (avoids creating friction/discomfort)

---

## 8. APP STORE + GOOGLE PLAY PUBLICATION

### Google Play
- Straightforward approval (1-3 days)
- Dating app declaration form
- Moderation systems functional (Points 5+6 cover this)
- User safety policy published
- **Lanzamiento inmediato** after submission

### Apple App Store (CRITICAL — client's hard requirement: "rejection is not an option")

#### Strategy (Feeld/#Open playbook)

1. **Store listing positioning (public-facing)**
   - App description: "Social network for couples" or "Community for adventurous couples"
   - Screenshots: show safe content only
   - **NEVER mention:** swinger, lifestyle, swap, hot wife, Parallel Play, Soft Swap, Full Swap
   - Metadata keywords: dating, couples, community, social

2. **Category declaration**
   - 17+ (Apple max, no 21+ option)
   - Honestly marked: "Infrequent/Mild Sexual Content and Nudity", "Infrequent/Mild Suggestive Themes"
   - 21+ enforced in-app at registration (Apple values this)

3. **Functional moderation**
   - Points 5 (reports) + 6 (blocks) fully working at submission time
   - Apple reviewer WILL test these

4. **+21 verification at registration**
   - Self-declaration + date of birth validation
   - No ID verification (privacy)

5. **Public moderation policy webpage**
   - Explain what content is allowed
   - Response times
   - Appeals process
   - Apple reviewer reads this

6. **Honest Privacy Labels**
   - Declare all data collection accurately
   - Mismatch = auto-rejection

7. **Demo account for Apple reviewer**
   - Pre-verified couple account
   - Let reviewer test without registration friction
   - Credentials shared via App Store Connect notes

8. **Direct support to review team**
   - Monitor App Store Connect for rejection
   - Respond technically with argumentation in each cycle
   - I've handled this before — Apple appreciates informed responses

### Estimated Approval Probability
- **75-85%** on 1st or 2nd attempt with this strategy
- **NOT 100%** — honest estimate, no developer can truthfully promise certainty
- Rejection cycles typically 2-5 days each

### Developer Accounts
- **Apple Developer Program:** USD 99/year — required before submission
- **Google Play Developer:** USD 25 one-time fee
- **Ownership:** under Affinity company name (Alejandra to provide details)

### Included Deliverables
- Developer accounts setup
- App assets (icons, splash, store screenshots in EN + ES)
- Store listing descriptions
- Privacy policy + Terms of Service (legal templates, lawyer review recommended)
- TestFlight beta configuration
- Google Play internal testing track
- Submission packages
- Review team communication support

---

## 9. SUPPORTING INFRASTRUCTURE

### Data Migration (one-time script)

#### Source (current state)
```javascript
profiles/{uid} {
  her_name, his_name,
  her_birth, his_birth,
  city,                          // from 16-item hardcoded list
  her_height, his_height,
  description,
  interests: "CSV, string",      // ← problematic
  photos: [url, ...]
}
```

#### Target (migrated state)
```javascript
couples/{coupleId} {
  partner_a: { name, birth, height },
  partner_b: { name, birth, height },
  city: string,
  country: string,
  country_code: string,
  lat: number,
  lng: number,
  geohash: string,              // calculated from lat/lng
  description,
  photos: [url, ...],
  dynamics: [string],            // ← empty initially, user fills later
  experience_preferences: [string],
  interests: [string],           // ← parsed from CSV
  status: "approved",            // default for existing couples
  age_range: { min, max },       // calculated from births
  verification: null,            // existing users grandfathered
  created_at: timestamp,
  updated_at: timestamp
}
```

#### Migration Script Steps
1. Read all `profiles/*` documents
2. For each:
   - Generate new `coupleId` (or keep UID)
   - Parse CSV `interests` string into array
   - Calculate `age_range` from birth dates
   - Geocode `city` string to lat/lng via Google Places API
   - Calculate `geohash` from lat/lng
   - Leave `dynamics` + `experience_preferences` empty (users fill via profile edit later)
   - Write to new `couples/{coupleId}` document
3. Verify counts match (no data loss)
4. Switch app code to read from `couples` collection
5. Delete old `profiles` collection (after verification)

### State Management (Riverpod, progressive)

#### Approach
- DO NOT refactor existing screens
- Introduce Riverpod for NEW features (Week 2+ work)
- Progressive migration over time

#### Structure
```
lib/
  providers/
    couples_provider.dart
    verification_provider.dart
    reports_provider.dart
    blocks_provider.dart
    trips_provider.dart
  ...existing code unchanged...
```

### Feed Pagination

#### Current (broken for scale)
```dart
// profile_datasource.dart
static Future<List<UserProfile>> getAllProfiles() async {
  final snap = await FirebaseFirestore.instance.collection('profiles').get();
  // Loads EVERYTHING into memory
}
```

#### Target
```dart
// couples_datasource.dart (new)
static Future<List<Couple>> getFilteredCouples({
  required String lastCoupleId,
  required Filters filters,
  int limit = 20,
}) async {
  Query q = FirebaseFirestore.instance.collection('couples')
    .where('status', isEqualTo: 'approved')
    .orderBy('geohash')  // or other stable field
    .limit(limit);

  if (lastCoupleId != null) {
    final lastDoc = await FirebaseFirestore.instance
      .collection('couples').doc(lastCoupleId).get();
    q = q.startAfterDocument(lastDoc);
  }

  // Apply filters (geo, age, interests) via compound where clauses + in-memory
  return (await q.get()).docs.map(Couple.fromDoc).toList();
}
```

### Push Notifications (Firebase Cloud Messaging)

#### Required for
- New match notifications
- Travel Match notifications (immediate + 7-day reminder)
- Moderation notifications (verification result, report result, suspension)
- Request notifications (new, accepted)
- Account recovery attempts

#### Setup
- `firebase_messaging` Flutter package
- APNs configuration for iOS
- FCM token stored in `couples/{coupleId}/fcm_tokens/{deviceId}`
- Cloud Functions trigger sends via FCM Admin SDK

### Missing Profile Screens (to build)

Currently all `onTap: () {}` placeholders:

1. **Manage Trips** — CRUD for `trips` subcollection (Travel Match)
2. **View Favorite Couples** — favorites list (stretch feature)
3. **Account Settings** — password change, email change, account deletion entry
4. **Security** — block management list, 2FA (if added), recovery history
5. **Help** — static FAQ content

### Firestore Security Rules

#### Current State
**MISSING.** Critical security risk.

#### Target Rules Structure
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helpers
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(coupleId) {
      return isAuthenticated() && request.auth.uid == coupleId;
    }

    function isApproved(coupleId) {
      return get(/databases/$(database)/documents/couples/$(coupleId))
        .data.status == 'approved';
    }

    function isNotBlocked(targetId) {
      return !exists(/databases/$(database)/documents/blocks/
        $(request.auth.uid + '_' + targetId));
    }

    // Couples
    match /couples/{coupleId} {
      allow read: if isApproved(coupleId) && isNotBlocked(coupleId);
      allow create: if isOwner(coupleId);
      allow update: if isOwner(coupleId);
      allow delete: if false; // only Cloud Functions
    }

    // Conversations
    match /conversations/{convId} {
      allow read, write: if isAuthenticated()
        && request.auth.uid in resource.data.participants;
    }

    // Reports
    match /reports/{reportId} {
      allow create: if isAuthenticated()
        && request.resource.data.reporter_couple == request.auth.uid;
      allow read, update: if false; // only moderators via Cloud Functions
    }

    // Blocks
    match /blocks/{blockId} {
      allow read, create, delete: if isAuthenticated()
        && request.resource.data.pareja_que_bloquea == request.auth.uid;
    }

    // Message requests
    match /message_requests/{requestId} {
      allow read: if isAuthenticated()
        && (request.auth.uid == resource.data.pareja_emisora
            || request.auth.uid == resource.data.pareja_receptora);
      allow create: if isAuthenticated()
        && request.resource.data.pareja_emisora == request.auth.uid;
      allow update: if isAuthenticated()
        && request.auth.uid == resource.data.pareja_receptora;
    }
  }
}
```

---

## 10. GOOGLE PLACES AUTOCOMPLETE INTEGRATION

### Package
`google_places_flutter` or `flutter_google_places_sdk`

### API Setup
- Google Cloud Platform account: `affinitysocialclub@gmail.com`
- Enable "Places API"
- Create API key with restrictions (Android package, iOS bundle ID)
- Store in Flutter secure config (NOT committed to repo)

### User Experience
1. User types city name in profile setup
2. Real-time suggestions appear below field
3. Shows city name + country (e.g., "Barcelona, Spain")
4. Selection populates:
   - `city`: "Barcelona"
   - `country`: "Spain"
   - `country_code`: "ES"
   - `lat`, `lng`: exact coordinates from Google
   - `geohash`: calculated from lat/lng

### Cost Management
- USD 200 free Google Cloud monthly credit
- Autocomplete: ~USD 17 per 1000 sessions after free tier
- Session-based billing (grouping keystrokes into one "session")
- Expected volume in first months: well within free tier

### Fallback
If API fails or offline:
- Show "Select city" dropdown with popular cities as backup
- Never block registration

---

## 11. APP PACKAGE + BRANDING

### Current State
- Package name: `app` (generic, default)
- No app icon rebranded
- No splash screen customized
- No store assets

### Target (Week 5)
- Package name: `com.affinitysocialclub.app` (or similar)
- App icon: Affinity brand (pineapple motif?)
- Splash screen with brand colors
- Launch image per platform
- Adaptive icon for Android

---

## 12. TESTING STRATEGY

### Unit Tests
- Critical business logic: verification retries, block logic, report thresholds, GeoHash calculations, Request expiration

### Integration Tests
- Firebase Auth flows
- Firestore reads/writes
- Cloud Function triggers (emulator)

### Manual Testing (pre-submission)
- Full couple registration + verification flow
- Report + moderation cycle
- Block + silent simulation
- Screenshot protection (verify iOS shows black, Android blocked)
- Apple reviewer demo account walkthrough

### Emulator Setup
- Firebase Local Emulator Suite for local dev
- Simulates Firestore, Auth, Storage, Functions
- No production Firebase touched during Gabriel's local phase

---

## 13. INTEGRATION TO PRODUCTION (after Week 5)

When DEV finishes Phase 2 (Feed Social), Gabriel's responsibility:

1. **Code merge**
   - Pull DEV's latest main branch
   - Rebase Gabriel's local work onto DEV's main
   - Resolve any file-level conflicts
   - Reconcile any schema differences

2. **Firebase migration**
   - Export data from Gabriel's local dev Firebase (if any test data)
   - Run migration script on production Firebase (profiles → couples)
   - Verify integrity

3. **Feature flags**
   - Deploy new features behind flags initially
   - Gradual rollout

4. **End-to-end testing**
   - Feed Social (DEV's work) + Gabriel's 8 features together
   - Full user flow from registration to match to chat

5. **Production deployment**
   - Firestore Security Rules
   - Cloud Functions
   - App store submissions

---

**End of technical specifications.**
