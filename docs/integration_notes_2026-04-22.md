# Integration notes — Affinity deliverables (2026-04-22)

Each component below is **standalone**: it lives in its own file and has
no dependency on other project-specific state containers. The notes tell
the agency how to drop each piece into the current codebase in the
shortest possible way.

All paths are relative to the Flutter app root.

---

## 1. Pineapple filter button

**File:** `lib/presentation/widgets/pineapple_filter_button.dart`
**Asset:** `assets/images/pineapple_filter_button.jpeg`

### How to use

```dart
import 'package:app/presentation/widgets/pineapple_filter_button.dart';

Stack(
  children: [
    YourFeedBody(),
    const Positioned(
      top: 12,
      right: 16,
      child: PineappleFilterButton(),
    ),
  ],
);
```

### Props
- `onTap` — override the default navigation to the filters screen.
- `activeCount` — show a burgundy badge with the number of applied filters.
- `size` — override the 56-px default if the layout needs a larger icon.

### Integration in our build
Hooked into `lib/presentation/pages/couples/couples_option.dart`
inside the existing `Stack` on the feed screen. The old circular `_FilterButton`
was deleted — the replacement carries the active-filter count and is pinned
to the same `top: 8, right: 16` anchor.

---

## 2. Notification bell on Profile header

**File:** `lib/presentation/pages/profile/profile_screen.dart`
**Extra screen:** `lib/presentation/pages/notifications/notifications_screen.dart`

The bell is a private `_NotificationBellButton` class inside the profile
screen file (it's specific enough to the header gradient that extracting
it felt premature). If the agency wants to reuse it elsewhere, copying the
60-line widget is the fastest path.

### Where it lives
Placed to the right of the "Profile" title inside the header `Row`. The
row was previously just a `Text("Profile")`; now it's:

```dart
Row(
  children: [
    Text(l10n.navProfile, ...),
    const Spacer(),
    _NotificationBellButton(onTap: _openNotifications),
  ],
);
```

### What it does
Taps into `NotificationsScreen` — currently a placeholder that renders
an empty-state message. Wiring the real list to a Firestore subscription
is part of the integration pass (the spec hasn't been finalised yet).

---

## 3. Sticky bottom actions (`Start Conversation` + `Filters`)

**File:** `lib/presentation/widgets/sticky_feed_actions.dart`

### How to use

```dart
import 'package:app/presentation/widgets/sticky_feed_actions.dart';

Scaffold(
  body: Column(
    children: [
      Expanded(child: YourCouplesPageView(...)),
      StickyFeedActions(
        onStartConversation: () => _sendRequest(currentCoupleId),
        onFilters: _openFilters,
      ),
    ],
  ),
);
```

### Props
- `startConversationLabel` / `filtersLabel` — pass `l10n.startConversation`
  etc. for localisation.
- `enabled` — disable both buttons temporarily (e.g. while a request is in flight).

### Parent responsibility
The parent tracks which couple is currently front-and-centre and passes
that into the `onStartConversation` callback. The widget itself is
stateless — this keeps it compatible with any state management pattern
(Riverpod, Provider, InheritedWidget, plain setState…).

### Design match
Rounded-pill buttons, burgundy (#B31637) CTA + outlined secondary, 52-px
height — matches the 2026-04-20 mock pixel-for-pixel (within ±2 px on
padding).

---

## 4. Country filter + Travel Match in filters screen

**File:** `lib/presentation/pages/filters/filters_screen.dart`
**Provider changes:** `lib/providers/filters_provider.dart`
  - new fields: `travelDestinationId`, `travelFrom`, `travelTo`
  - new mutators: `setTravelMatch(...)`, `clearTravelMatch()`
  - reset-on-logout behaviour added (see §9)

### What's new in the filter panel
1. **Country dropdown** (`_CountryDropdown`) — populates from the
   `destinations` collection, deduplicated and alphabetised. Includes
   an "Any country" option.
2. **Travel Match block** (`_TravelMatchSection`) — resort/cruise
   dropdown plus From/To date pickers. Shows a clear-button when any
   field is active so users can cancel a travel filter without resetting
   the whole panel.

Both sections are rendered inline in the existing filters panel; the
overall layout matches the mock order (Country+City → Age → Dynamics →
Experience → Interests → Travel Match → Apply).

### Feed-side consumption
The existing `_applyFilters` in `couples_option.dart` continues to work
against the `profiles` collection (city+age only for legacy docs). Travel
Match filtering will be wired when the feed migrates to the `couples`
collection (scheduled work item, out of scope here).

---

## 5. Registration flow — photo / height / video rules

**File:** `lib/presentation/pages/profile_setup/profile_setup_screen.dart`

### Behavioural changes
| Field | Before | Now |
|-------|--------|-----|
| Photos (on signup) | optional | **min 3 required** |
| Photos couple-together hint | absent | shown below "Photos" label |
| Height | required | **optional** (label reads "Her/His height (optional)") |
| Primary CTA label | "Save" | **"Verification Video"** on signup, "Save" in edit mode |
| Post-save navigation | CouplesScreen | **VerificationIntroScreen** on signup |
| Couple doc status | not written on signup | **`pending_review` written** via `CouplesDatasource.createCouple` |

### Editing existing profiles
None of the above strictness applies in edit mode — users can add or
remove photos freely, leave height blank, and the save button stays the
familiar "Save" with a plain `pop(true)` to the caller.

### L10n keys added (both en + es)
- `photoMinError` — "Add at least 3 photos" / "Agrega al menos 3 fotos"
- `photosCoupleTogetherHint` — new
- `herHeight` / `hisHeight` — now include "(optional)"
- `goToVerificationVideo` — "Verification Video" / "Video de Verificación"

---

## 6. Verification video recording (3–5 s + head-turn prompt)

**File:** `lib/presentation/pages/verification/video_record_screen.dart`
**Intro:** `lib/presentation/pages/verification/verification_intro_screen.dart`

### Timing constants
```dart
static const int _minSeconds = 3;
static const int _maxSeconds = 5;
```

### Head-turn prompt
A new overlay appears at the top of the camera view while recording:
- 0–2 s  →  "Look at the camera"
- 2–4 s  →  "Turn your head to the right"
- 4–5 s  →  "Turn your head to the left"

The prompt is driven by the existing `_elapsed` state field that ticks
once per second, so no new timer or animation controller was added.

### Intro screen checklist
Rewritten to match the client's spec:
- "Ideally both partners appear — one is also allowed"
- "Look at the camera, then turn your head to the right, then to the left"
- "Recording lasts between 3 and 5 seconds"

---

## 7. Moderation panel — closed rejection reasons

**File:** `lib/admin/pages/moderation_review_screen.dart`
**Cloud Function:** `functions/src/verification/moderateVerification.ts`

### Closed list (Spanish, agreed 2026-04-21)
| Key | Display |
|-----|---------|
| `fotos_no_coinciden` | Las fotos no coinciden entre sí |
| `video_poco_claro` | El video es poco claro |
| `perfil_sospechoso` | Perfil sospechoso |
| `fotos_inapropiadas` | Fotos con contenido inapropiado |
| `solo_una_persona` | Solo aparece una persona en las fotos/video |
| `menor_de_edad` | Se sospecha que una de las personas es menor de edad |
| `calidad_baja` | Calidad del video demasiado baja |
| `otro` | Otro (ver guía de moderación) |

The same set is enforced in the Cloud Function (`ALLOWED_REASONS`) so
malformed reasons submitted from a rogue client are rejected server-side.

---

## 8. Third-rejection auto-block

**Cloud Function:** `functions/src/verification/moderateVerification.ts`
**Model:** `lib/data/models/verification.dart` (new `finalRejection` bool)
**UI:** `lib/presentation/pages/verification/verification_rejected_screen.dart`

### Behaviour
- Client tracks `attempts` on each submission.
- On the **third** reject action, the function writes:
  - `status: "suspended"` (was `rejected`)
  - `verification.final_rejection: true`
- The rejected screen checks `finalRejection` (or `attempts >= 3`) and
  renders the permanent-block variant: no retry button, only a "Contact
  support" CTA plus sign-out.

### Retry policy summary
1st rejection → "try again" CTA, 2 attempts remaining.
2nd rejection → "try again" CTA, 1 attempt remaining.
3rd rejection → permanent block.

---

## 9. Session-scoped filters

**File:** `lib/providers/filters_provider.dart`

The `FiltersNotifier` subscribes to `FirebaseAuth.authStateChanges` and
resets to `const FiltersState()` whenever the user signs out. That means:
- User A signs in → applies filters → signs out → User B signs in on the
  same device → filters start fresh, not carrying A's selections.
- Works across app restarts the moment auth stream re-emits.

No extra plumbing on screens — Riverpod already rebuilds the filters
screen when state is reset.

---

## Minimal integration shopping list for the agency

1. Copy `lib/presentation/widgets/pineapple_filter_button.dart` → add the
   asset, update `pubspec.yaml` assets block, drop into feed stack.
2. Copy `lib/presentation/widgets/sticky_feed_actions.dart` → wire to
   the feed `Column`.
3. Copy the notification bell snippet into the existing profile header
   `Row`; include the `NotificationsScreen` placeholder file.
4. Apply the filter-screen diff (country dropdown + travel match block)
   and update the filters provider with the three new fields.
5. Apply the registration-flow changes (photo min 3, height optional,
   verification video button, couple doc pending_review).
6. Apply the video recording + intro screen text changes.
7. Replace `ALLOWED_REASONS` in the moderateVerification Cloud Function
   and the `_reasons` map in the admin review screen.
8. Apply the `finalRejection` field in the Verification model and the
   corresponding check in the rejected screen.
9. Add the auth-state listener in the filters provider.

Each item is independent — you can cherry-pick in any order.

---

**Contact:** Gabriel — ready for the integration pass whenever the
agency is done with phase 2.
