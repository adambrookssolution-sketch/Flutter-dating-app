/**
 * AFFINITY — Cloud Functions entry point
 *
 * Function organisation (one file per concern, all re-exported here):
 *   recovery/      — password reset link with 15-min TTL + session invalidation
 *   deletion/      — atomic 30-day delayed account deletion
 *   verification/  — moderation result hooks + 7-day video cleanup
 *   reports/       — report aggregation + auto-suspension thresholds
 *   moderation/    — auto-block on suspension + admin actions
 *   travel/        — trip match query + push notifications
 *   requests/      — message request expiration
 *   notifications/ — generic FCM dispatch helpers
 *
 * Each module is committed empty in Week 0; implementations land in the week
 * indicated by the file's leading docstring.
 */
import { initializeApp } from "firebase-admin/app";
import * as admin from "firebase-admin";

initializeApp();

// Boot marker — written every time a Cloud Function instance cold-starts.
// Lets us verify from Firestore alone whether the latest deploy actually
// took effect, without depending on Cloud Functions logs (which our local
// network can't always reach).
(async () => {
  try {
    await admin.firestore().collection("function_audit").add({
      fn: "__boot__",
      at: admin.firestore.FieldValue.serverTimestamp(),
      marker: "2026-05-12-v3",
    });
  } catch (_) {
    // ignore — boot audit must never break startup
  }
})();

// Re-export every callable / scheduled / triggered function below as work lands.
// Keeping the entry file empty for now is intentional — deploying with no
// exports is valid and avoids accidental triggers in dev.

// Week 1 — Recovery + Deletion
export { sendCustomReset } from "./recovery/sendCustomReset";
export { markRecoveryCompleted } from "./recovery/onPasswordChange";
export { executeDeletion } from "./deletion/executeDeletion";

// Week 2 — Verification + Reports + Blocks
export { moderateVerification } from "./verification/moderateVerification";
export { cleanupExpiredVideos } from "./verification/cleanupExpiredVideos";
export { onCoupleApproved } from "./verification/onCoupleApproved";
export { onReportCreated } from "./reports/onReportCreated";
export { onReportStatusChanged } from "./reports/onReportStatusChanged";
export { onSuspension } from "./moderation/onSuspension";

// Week 3 — Travel Match + Requests
export { findMatches } from "./travel/findMatches";
export { onTripCreated } from "./travel/onTripCreated";
export { tripReminder } from "./travel/tripReminder";
export { expireRequests } from "./requests/expireRequests";

// Push notifications — client feedback 2026-05-17 #10.
export { onMessageCreated } from "./notifications/onMessageCreated";
export { onFavoriteAdded } from "./notifications/onFavoriteAdded";

// Subscriptions module — Stripe wiring.
// Temporarily disabled in production until STRIPE_* secrets are populated
// in Secret Manager. Re-enable by uncommenting these exports once secrets
// are configured; the function source files themselves are unchanged.
// export { stripeWebhook } from "./subscriptions/stripeWebhook";
// export { createCheckoutSession } from "./subscriptions/createCheckoutSession";
// export { cancelSubscription } from "./subscriptions/cancelSubscription";
// export { onCoupleCreatedSeedSubscription } from "./subscriptions/onCoupleCreated";
