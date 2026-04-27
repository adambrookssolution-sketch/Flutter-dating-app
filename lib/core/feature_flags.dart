/// Compile-time feature flags.
///
/// Every feature added by Gabriel's branch is gated behind a flag here.
/// In production, if any feature misbehaves, flip its flag to `false`
/// and redeploy — the rest of the app keeps running unaffected.
///
/// Why compile-time and not Remote Config:
///   1. Zero runtime cost — the dead branches get tree-shaken out.
///   2. No network dependency — works on first launch before any
///      Remote Config fetch completes.
///   3. The agency dev never has to wonder "is the flag fetching".
///
/// When the team is ready to switch to Remote Config (post-launch
/// experimentation), the migration is straightforward: replace each
/// `static const bool` with a getter that reads from
/// `FirebaseRemoteConfig.instance`. The call sites don't change.
class FeatureFlags {
  FeatureFlags._();

  // ─── Subscriptions module ────────────────────────────────────────────
  /// Master switch for the Stripe-based subscription system. Stays
  /// `false` until the client approves the proposal AND Stripe is
  /// live in production. When `false`, paywall and "Tu plan" screens
  /// are inaccessible and every gate behaves as if the user had no
  /// paid plan.
  static const bool subscriptionsEnabled = false;

  /// Show the "Tu plan" entry in Profile → Account settings even
  /// when subscriptions are off (read-only, shows "Free"). Useful
  /// during soft launches.
  static const bool subscriptionStatusVisible = false;

  // ─── Discovery features ──────────────────────────────────────────────
  /// Travel Match section in the filter panel + the trip subcollection
  /// reads. Always-on once shipped.
  static const bool travelMatchEnabled = true;

  /// Advanced filters: dynamics, experience preferences, interests.
  /// On Free plan these will be visually disabled (subscription gate).
  static const bool advancedFiltersEnabled = true;

  /// Pineapple top-right filter trigger. Off → fall back to a plain
  /// IconButton. Off only as an emergency.
  static const bool pineappleFilterButton = true;

  // ─── Privacy ─────────────────────────────────────────────────────────
  /// Native screenshot protection (FLAG_SECURE on Android,
  /// SecureView on iOS). Off → screens render normally without
  /// the protection.
  static const bool screenshotProtectionEnabled = true;

  /// Invisible LSB watermark on rendered images. Off → images go
  /// through `Image.network` directly. Watermark is expensive on
  /// low-end devices; this lets us skip it if we ever see crashes.
  static const bool watermarkingEnabled = true;

  // ─── Notifications ───────────────────────────────────────────────────
  /// FCM push registration on sign-in + cleanup on sign-out. Off →
  /// no push tokens written, no notifications sent. Useful in dev
  /// environments without Cloud Functions.
  static const bool fcmEnabled = true;

  // ─── Verification ────────────────────────────────────────────────────
  /// Video verification flow: record → upload → moderation queue →
  /// approve/reject. Off → newly-registered couples skip directly
  /// to `approved` status (only safe in dev). Production: always on.
  static const bool videoVerificationEnabled = true;

  // ─── Account lifecycle ───────────────────────────────────────────────
  /// 30-day grace deletion + cancel deletion screens. Apple required;
  /// keep on in production.
  static const bool accountDeletionEnabled = true;

  /// Custom 15-minute password reset (vs Firebase default 1 hour).
  /// Off → Firebase default email is used.
  static const bool customPasswordResetEnabled = true;

  // ─── Reports + blocks ────────────────────────────────────────────────
  /// Report flow with predefined reasons + Cloud Function thresholds.
  /// Always-on in production (App Store requirement).
  static const bool reportsEnabled = true;

  /// User-to-user blocking with bidirectional silent invisibility.
  /// Always-on in production.
  static const bool blocksEnabled = true;

  // ─── Admin panel ─────────────────────────────────────────────────────
  /// Show "Tu plan" / "Manage Trips" / "Security" / "Account
  /// settings" entries on the Profile menu. Off → fall back to the
  /// agency's original profile menu entries only.
  ///
  /// This is the single switch that hides ALL of Gabriel's UI
  /// additions if something breaks during a soft launch.
  static const bool gabrielProfileEntriesEnabled = true;

  // ─── Helpers ─────────────────────────────────────────────────────────
  /// True when the build should treat itself as production-ready.
  /// Used to skip development-only safety nets like "skip storage
  /// upload on failure".
  static const bool isProductionBuild =
      bool.fromEnvironment('AFFINITY_PRODUCTION', defaultValue: false);
}
