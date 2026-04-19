# AFFINITY — Source Code Analysis

> Detailed analysis of the codebase received from DEV team via Google Drive
> Analyzed: 2026-04-17
> Base path: `D:\app`

---

## 1. PROJECT STRUCTURE

```
D:\app\
├── analysis_options.yaml
├── android/
├── app.iml
├── assets/
│   └── images/
├── build/
├── firebase.json
├── ios/
├── l10n.yaml
├── lib/
│   ├── core/
│   │   └── serve           ← only file in folder, no Dart code
│   ├── data/
│   │   ├── datasource/
│   │   │   ├── auth_datasource.dart
│   │   │   ├── conversation_datasource.dart
│   │   │   ├── profile_datasource.dart
│   │   │   └── tags_datasource.dart
│   │   └── models/
│   │       ├── chat_conversation.dart
│   │       ├── firestore_message.dart
│   │       └── user_profile.dart
│   ├── dependency_injections/     ← EMPTY
│   ├── device/                    ← EMPTY
│   ├── domain/                    ← EMPTY
│   ├── firebase_options.dart
│   ├── l10n/
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_en.dart
│   │   └── app_localizations_es.dart
│   ├── main.dart
│   └── presentation/
│       ├── constants/
│       │   ├── app_colors.dart
│       │   └── app_dimensions.dart
│       ├── layouts/
│       │   └── system_layout.dart
│       ├── pages/
│       │   ├── auth/
│       │   │   ├── auth_by_email/
│       │   │   │   ├── auth_by_email_screen.dart
│       │   │   │   ├── sign_in_form.dart
│       │   │   │   └── sign_up_form.dart
│       │   │   ├── auth_screen.dart
│       │   │   └── widgets/
│       │   │       └── form_title.dart
│       │   ├── chat/
│       │   │   └── chat_screen.dart
│       │   ├── community/
│       │   │   ├── community_option.dart
│       │   │   └── community_screen.dart
│       │   ├── couples/
│       │   │   ├── couples_option.dart
│       │   │   └── couples_screen.dart
│       │   ├── forgot_password/
│       │   │   ├── forgot_password_screen.dart
│       │   │   ├── step_code.dart
│       │   │   ├── step_success.dart
│       │   │   ├── step_verify.dart
│       │   │   └── widget/text_information.dart
│       │   ├── inbox/
│       │   │   ├── inbox_screen.dart
│       │   │   └── request_match_screen.dart
│       │   ├── pages.dart
│       │   ├── profile/
│       │   │   └── profile_screen.dart
│       │   ├── profile_setup/
│       │   │   └── profile_setup_screen.dart
│       │   └── splash/
│       │       └── splash_screen.dart
│       ├── router/
│       │   └── app_routes.dart
│       ├── utils/
│       │   ├── apple_sign_in_action.dart
│       │   ├── google_sign_in_action.dart
│       │   └── navigate_after_sign_in.dart
│       └── widgets/
│           ├── conversation_row.dart
│           ├── couple_card.dart
│           ├── custom_button.dart
│           ├── custom_input.dart
│           ├── custom_select.dart
│           ├── match_overlay.dart
│           └── widgets.dart
├── pubspec.lock
├── pubspec.yaml
├── test/
├── watch_l10n.sh
├── web/
└── windows/, linux/, macos/
```

### Architecture observations

- **Clean Architecture attempted, abandoned:** `core/`, `domain/`, `dependency_injections/`, `device/` folders are empty or near-empty. Previous developer planned clean architecture but did not execute it.
- **Actual structure:** 2-layer (`data/` → `presentation/`) with no domain/use-case/repository abstraction.
- **No state management library** — pure `StatefulWidget` + `setState` throughout.
- **No dependency injection** — all datasources are `static` methods (untestable without modification).
- **Routing** — basic `MaterialPageRoute` + manual `AppRoutes` map with 4 tabs.

---

## 2. PUBSPEC.YAML (dependencies)

```yaml
name: app
version: 1.0.0+1
environment:
  sdk: ^3.8.1

dependencies:
  flutter: sdk: flutter
  flutter_localizations: sdk: flutter
  intl: any
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.10+1
  image_picker: ^1.1.2
  firebase_core: ^4.4.0
  firebase_auth: ^6.1.4
  cloud_firestore: ^6.1.2
  firebase_storage: ^13.0.6
  google_sign_in: ^6.2.2
  sign_in_with_apple: ^7.0.1
  crypto: ^3.0.3

dev_dependencies:
  flutter_test: sdk: flutter
  flutter_lints: ^5.0.0
```

### Missing packages (must add)
- `geoflutterfire2` — GeoHash + Firestore geospatial queries
- State management (Riverpod recommended): `flutter_riverpod`
- `firebase_messaging` — push notifications
- `firebase_functions` — Cloud Functions SDK (if invoking from app)
- `google_places_flutter` or `flutter_google_places_sdk` — location autocomplete
- HTTP client: `dio` or `http`
- `cached_network_image` — but this needs careful config to NOT cache sensitive images
- `flutter_secure_storage` — for API keys and tokens
- `video_player` + `camera` — for video verification recording
- `permission_handler` — for camera/location permissions

---

## 3. CURRENT FIRESTORE SCHEMA (as implemented)

### Collection: `profiles/{uid}`
```javascript
{
  her_name: string,
  his_name: string,
  her_birth: string,      // "DD/MM/YYYY"
  his_birth: string,
  city: string,           // from hardcoded 16-city list
  her_height: string,     // "175 cm" or "5'7\""
  his_height: string,
  description: string,
  interests: string,      // ← CSV! "Travel Lovers, Foodies, Romantic"
  photos: string[]        // URLs
}
```

**Problems:**
- `uid` = Firebase Auth UID → one auth account per couple (both partners share)
- `interests` as CSV string → CANNOT BE QUERIED
- No `country`, `lat`, `lng`, `geohash`, `status`, `verification`, `dynamics`, `experience_preferences`, `trips`

### Collection: `conversations/{docId}`
Doc ID = `[uid1, uid2].sort().join('_')` (deterministic, prevents duplicates — clever)

```javascript
{
  participants: [uid1, uid2],
  initiated_by: uid,
  last_message: string,
  last_message_by: uid,
  last_message_time: timestamp,
  replied_by: [uid, uid],    // tracks who has replied
  created_at: timestamp
}
```

### Subcollection: `conversations/{docId}/messages/{messageId}`
```javascript
{
  text: string,
  sender_uid: uid,
  created_at: timestamp
}
```

### Collection: `tags/{id}`
```javascript
{
  name: string,
  order: number
}
```

Hardcoded fallback if empty:
```dart
['Travel Lovers', 'Foodies', 'Adventure', 'Night Life', 'Fun', 'Romantic']
```

**Problem:** Generic dating tags, not lifestyle-specific. Mismatches the design mockup with Dynamics/Experience/Interests categories.

---

## 4. FEATURE STATUS vs 8 AGREED POINTS

| # | Feature | Status | Details |
|---|---------|--------|---------|
| 1 | Video verification | **0%** | No screens, no flow, no storage structure, no Cloud Functions |
| 2 | Account recovery | **30%** | 3-step UI exists (step_verify, step_code, step_success) but NOT connected to Firebase Auth. Pure placeholder. |
| 3 | Account deletion | **0%** | Only logout exists. Critical Apple requirement missing. |
| 4 | Geo + Filters + Travel Match | **5%** | 16 hardcoded cities dropdown only. No GeoHash, no filters, no Travel Match. |
| 5 | Report system | **0%** | No collection, no UI, no moderation panel |
| 6 | User blocking | **0%** | No collection, no UI, no silent logic |
| 7 | Screenshot protection | **0%** | No FLAG_SECURE, no SecureView, no MethodChannel, no watermarking, no cache config |
| 8 | Store publishing | **0%** | Package name still `app`, no +21 check, no privacy labels, no assets |

---

## 5. WHAT'S IMPLEMENTED AND WORKING

### 5.1 Authentication (100%)
- Email/password sign-up + sign-in via Firebase Auth
- Google Sign-In (uses `google_sign_in` package)
- Apple Sign-In with nonce + SHA256 (proper implementation)
- Sign-out (with Google Sign-In sign-out)

File: `lib/data/datasource/auth_datasource.dart`

### 5.2 Profile Setup (90%)
- 6-photo grid with drag-and-drop reorder (uses `LongPressDraggable` + `DragTarget`)
- "Main" badge on first photo
- Remove photo button
- Her/His name fields
- Her/His date of birth fields
- City dropdown (16 hardcoded cities) ← TO REPLACE with Google Places
- Her/His height (cm or ft/in toggle)
- Description textarea
- Tags section (multi-select chips + add custom tag dialog)
- Form validation with red borders
- Photo upload to Firebase Storage at `profiles/{uid}/photo_{index}.jpg`

File: `lib/presentation/pages/profile_setup/profile_setup_screen.dart` (1027 lines)

### 5.3 Couples Feed (70%)
- Fetches `getAllProfiles()` → loads ALL couples into memory
- Excludes self + existing conversation partners
- Randomly shuffles
- Card UI with story-style top progress bar, photo background, overlay with names/age/city/description/tags
- "Start Conversation" button at bottom (creates Request)

File: `lib/presentation/pages/couples/couples_option.dart`

**⚠️ Scaling issue:** `getAllProfiles()` will crash app with >1000 couples. Must replace with pagination.

### 5.4 Request System (80%)

Clever state machine using only `conversations` collection:

- **Start Conversation** → creates empty `conversations` doc with `initiated_by = me`, no initial message
- Receiver sees it in Inbox as Request (because `initiated_by != me && !replied_by.contains(me)`)
- Tap Request → opens `RequestMatchScreen` ("You're about to connect as couples")
- Shows overlapping avatars of both couples + tags of the other couple
- Two buttons: "Open conversation" (accept) or "Not now" (dismiss)
- Accept → adds my uid to `replied_by` array → Request becomes Chat
- Navigate to ChatScreen

**Files:**
- `lib/presentation/pages/couples/couples_option.dart` (creates Request)
- `lib/presentation/pages/inbox/inbox_screen.dart` (displays Requests + Chats separately)
- `lib/presentation/pages/inbox/request_match_screen.dart` (acceptance UI)

**Gaps vs agreed spec:**
- No `mensaje_inicial` in Request (agreement says Request should carry message preview)
- No `rejected` state (only accept or ignore)
- No expiration (14 days)
- No cooldown (30 days)
- No 10-Request limit
- Hardcoded English "quick starters" suggestions (breaks i18n)

### 5.5 Inbox (90%)
- Real-time stream of conversations via `conversationsStream`
- Caches profile data per UID to avoid re-fetches
- Separates into "Requests" (not yet replied) and "Chat Messages" (replied)
- Collapsible sections with count badges
- Pull-to-refresh
- Tap Request → RequestMatchScreen
- Tap Chat → ChatScreen

File: `lib/presentation/pages/inbox/inbox_screen.dart` (388 lines)

### 5.6 Chat (95%)
- Real-time messages stream (`messagesStream`)
- Message bubbles (my/theirs with different colors)
- Tail on last message of sequence
- Date chips ("Today", "Yesterday", "DD/MM/YYYY") grouping messages
- Scroll to bottom on new message
- "Quick starter" suggestion when empty
- Text input + send button
- AppBar with other couple's avatar and names

File: `lib/presentation/pages/chat/chat_screen.dart` (518 lines)

**Gap:** Suggestions hardcoded in English (6 strings), contradicts i18n setup.

### 5.7 Profile Screen (60%)
- Wave-clipped header with gradient (`#B31637` → `#4D0918`)
- Avatar (first photo) + edit pencil
- Couple display name: `"${hisName} & ${herName}"`
- Settings list with icons:
  - Edit profile → functional (navigates to ProfileSetupScreen)
  - Manage trips → `onTap: () {}` (placeholder)
  - View favorite or saved couples → placeholder
  - Account Settings → placeholder
  - Security → placeholder
  - Help → placeholder
  - Log out → functional (with confirmation dialog)
- Bottom nav: Couples / Inbox / Profile

File: `lib/presentation/pages/profile/profile_screen.dart` (478 lines)

**Gap:** 5 of 7 menu items are non-functional placeholders. Many security/privacy features need these screens.

### 5.8 Forgot Password (30% — UI only)
- 3-step wizard: StepVerify → StepCode → StepSuccess
- Uses images from `assets/images/forgot_password_*.png`
- UI complete, animations in place
- **NOT CONNECTED** to Firebase Auth
- Must be connected + email template customization applied (Week 1)

Files: `lib/presentation/pages/forgot_password/*.dart`

### 5.9 Community Tab (10%)
- Basic `CommunityScreen` exists
- Toggle between Couples vs Community in `CouplesScreen`
- Community content = `CommunityOption` widget — not implemented
- **Phase 2 work by existing DEV — NOT Gabriel's scope**

### 5.10 Splash Screen (100%)
- Branded splash with gradient
- Checks Firebase Auth `currentUser` on app start
- Routes to Auth or directly to Couples if logged in

### 5.11 Localization (100% infrastructure, 80% strings)
- EN + ES support configured
- `app_localizations_en.dart` and `app_localizations_es.dart` have all main strings
- Some strings hardcoded in English (chat suggestions, error messages in a few spots)

---

## 6. CRITICAL ISSUES TO ADDRESS

### Issue 1: `interests` CSV string
**File:** `lib/data/models/user_profile.dart:11`
```dart
final String interests;
```
**Fix:** Migrate to:
```dart
final List<String> dynamics;
final List<String> experiencePreferences;
final List<String> interests;
```

### Issue 2: `getAllProfiles()` scalability
**File:** `lib/data/datasource/profile_datasource.dart:34-40`
```dart
static Future<List<UserProfile>> getAllProfiles() async {
  final snap = await FirebaseFirestore.instance.collection('profiles').get();
  return snap.docs.map(...)...
}
```
**Fix:** Replace with paginated + filtered query using GeoHash + cursor.

### Issue 3: Forgot Password placeholder
**Files:** `lib/presentation/pages/forgot_password/*.dart`
**Fix:** Connect to `FirebaseAuth.instance.sendPasswordResetEmail()` with custom action code settings. Customize email template in Firebase Console.

### Issue 4: Missing data fields
Need to add to `couples` document:
- `country`, `country_code`
- `lat`, `lng`, `geohash`
- `status`
- `verification` object
- `age_range` calculated field

### Issue 5: No Firestore Security Rules
**Risk:** Any authenticated user can read/write any profile.
**Fix:** Deploy comprehensive rules (see `TECHNICAL_SPEC.md` Section 9).

### Issue 6: Hardcoded cities
**File:** `lib/presentation/pages/profile_setup/profile_setup_screen.dart:17-34`
```dart
const _kCities = [
  'Madrid', 'Barcelona', 'Buenos Aires', 'Ciudad de México', 'Bogotá',
  'Lima', 'Santiago', 'Caracas', 'Miami', 'New York', 'Los Angeles',
  'London', 'Paris', 'Berlin', 'Sao Paulo', 'Other',
];
```
**Fix:** Replace dropdown with Google Places autocomplete field.

### Issue 7: Package name `app`
Generic default. Rebrand before store submission:
- `com.affinitysocialclub.app` or similar
- Requires changes in `android/app/build.gradle`, iOS bundle ID, pubspec.yaml

### Issue 8: No video verification flow
Completely missing. Must build from scratch: recording screen, upload, storage, pending state UI, moderation panel.

### Issue 9: No report/block infrastructure
No `reports` or `blocks` collections, no UI. Must build end-to-end.

### Issue 10: No screenshot protection
Neither Android FLAG_SECURE nor iOS SecureView. Must implement MethodChannel + native code.

---

## 7. DEV's STRENGTHS (to preserve)

Things the previous developer did well that should NOT be refactored:

1. **Apple Sign-In proper nonce+SHA256** — security-correct implementation
2. **Deterministic conversation doc IDs** — prevents duplicates cleverly
3. **Request/Chat state machine using `initiated_by` + `replied_by`** — elegant, no extra collection needed
4. **Profile photo drag-and-drop reorder** — polished UX with haptic feedback
5. **Real-time Firestore streams + profile caching** in Inbox — efficient
6. **Chat message bubble tail logic** — professional detail
7. **Consistent branding** — `#B31637` burgundy used cleanly throughout
8. **i18n infrastructure** — set up correctly even if not fully populated
9. **Form validation pattern** — consistent red border + error message approach
10. **Height dual-unit toggle** (cm / ft-in) — well-handled

---

## 8. CONSTANTS AND DESIGN TOKENS

### File: `lib/presentation/constants/app_colors.dart`
- Primary: `#B31637` (burgundy/dark red)
- Splash gradient start: `splashGradientStart`
- Splash gradient end: `splashGradientEnd`
- Button text color: `buttonTextColor`

### File: `lib/presentation/constants/app_dimensions.dart`
- `AppDimensions.systemMargin` — standard padding

### Typography
Material Design default (not customized in pubspec fonts section)

---

## 9. REUSABLE WIDGETS

Located in `lib/presentation/widgets/`:

- `CustomButton` — with types: `mainSystem`, `mainLogin`, `secondaryLogin`, `link`
- `CustomInput` — with types: `text`, `date`, `textarea`
- `CustomSelect<T>` — generic dropdown
- `CoupleCard` — the main discovery card
- `ConversationRow` — inbox list item
- `MatchOverlay` — unused? verify usage
- `SystemLayout` — standard scaffold with app bar + bottom nav + navigation tabs

These should be reused for new screens, not re-created.

---

## 10. BUILD VERIFICATION

✅ **APK builds successfully**
✅ **Runs on Android emulator/device**
✅ **Core flows functional:** login, profile creation, couples discovery, Request, chat

Gabriel has confirmed the build works and has tested the app manually before accepting the contract.

---

## 11. GABRIEL'S STARTING PLAN

Given the analysis, Gabriel's Week 1 should:

1. **Day 1:**
   - Set up Google Cloud Platform with `affinitysocialclub@gmail.com`
   - Enable Places API
   - Create API key with platform restrictions
   - Set up local Firebase dev project (separate from production)

2. **Day 2-3:**
   - Design migration script (offline, runs locally against test data)
   - Migrate `profiles` schema → `couples` schema with all new fields
   - Parse CSV interests → 3 arrays
   - Calculate GeoHash from lat/lng (with defaults for existing data)

3. **Day 4-5:**
   - Integrate Google Places Autocomplete into profile setup screen
   - Replace hardcoded cities dropdown
   - Save country, lat/lng, geohash from Places response

4. **Day 6-7:**
   - Connect Forgot Password flow to Firebase Auth
   - Customize email template in Firebase Console (generic, no branding)
   - Configure 15-min link expiration
   - Add session invalidation Cloud Function
   - Build in-app recovery attempts notification

5. **Day 7-8:**
   - Build Account Deletion flow (Settings > Security entry)
   - Double confirmation UI
   - `pending_deletion` state handling
   - Cloud Function for 30-day delayed atomic deletion

6. **End of Week 1:** Deploy Firestore Security Rules

---

**End of code analysis.**
