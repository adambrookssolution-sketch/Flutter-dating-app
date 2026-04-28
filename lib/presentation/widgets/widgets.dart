// Public widget barrel — agency / app code imports this single file.
//
// All widgets exported here are stable integration entry points: they
// can be dropped into the agency's screens with a single line, behave
// safely when the underlying feature is disabled via FeatureFlags, and
// don't pull external dependencies into the agency's compile graph.
//
// New widgets that should be visible to the agency must be added here.
// Internal helpers stay private (no export).

// ── Original (agency-compatible) widgets ─────────────────────────────────
export 'package:app/presentation/widgets/conversation_row.dart';
export 'package:app/presentation/widgets/couple_card.dart';
export 'package:app/presentation/widgets/custom_button.dart';
export 'package:app/presentation/widgets/custom_input.dart';
export 'package:app/presentation/widgets/custom_select.dart';
export 'package:app/presentation/widgets/match_overlay.dart';

// ── Drop-in integration entry points (added by Gabriel) ──────────────────
export 'package:app/presentation/widgets/affinity_profile_menu.dart';
export 'package:app/presentation/widgets/affinity_session_listener.dart';
export 'package:app/presentation/widgets/pineapple_filter_button.dart';
export 'package:app/presentation/widgets/sticky_feed_actions.dart';

// ── Privacy primitives ───────────────────────────────────────────────────
export 'package:app/presentation/widgets/no_cache_image.dart';
export 'package:app/presentation/widgets/secure_view.dart';
export 'package:app/presentation/widgets/watermarked_image.dart';

// ── Subscription gating ──────────────────────────────────────────────────
export 'package:app/presentation/widgets/subscription_gate.dart';

// ── Form fields + dialogs ────────────────────────────────────────────────
export 'package:app/presentation/widgets/places_autocomplete_field.dart';
export 'package:app/presentation/widgets/recovery_attempts_dialog.dart';
export 'package:app/presentation/widgets/send_request_dialog.dart';
