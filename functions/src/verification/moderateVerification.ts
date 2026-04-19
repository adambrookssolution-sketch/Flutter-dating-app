/**
 * Moderator action endpoint — approve or reject a couple's verification video.
 *
 * Called from the moderation web panel (Flutter Web, [admin] entry point).
 * Auth gate: only Firebase users with custom claim `moderator: true` can
 * invoke. Claims are set out-of-band (via the Firebase Admin CLI or a
 * one-off CF during deploys), never from the app.
 *
 * Inputs:
 *   coupleId : string  — target couple document
 *   decision : "approve" | "reject"
 *   reason   : string  — required when decision == "reject" (predefined list)
 *
 * Side effects:
 *   approve : status=approved, verification.reviewed_at=now, moderator_id=me
 *   reject  : status=rejected, verification.reviewed_at=now, reject_reason set.
 *             Attempts already incremented at submit time, so the client reads
 *             it back and decides whether to show "try again" or permanent block.
 */
import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { db, COLLECTIONS } from "../common/firestore";

type Decision = "approve" | "reject";

interface Payload {
  coupleId?: string;
  decision?: Decision;
  reason?: string;
}

const ALLOWED_REASONS = new Set([
  "inappropriate",
  "fake",
  "single_person",
  "minor_suspected",
  "quality_low",
  "other",
]);

export const moderateVerification = onCall<Payload>(
  { region: "us-central1", maxInstances: 10 },
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "sign in required");
    const claims = req.auth.token;
    if (claims.moderator !== true) {
      throw new HttpsError("permission-denied", "moderator claim required");
    }

    const { coupleId, decision, reason } = req.data;
    if (!coupleId) throw new HttpsError("invalid-argument", "coupleId required");
    if (decision !== "approve" && decision !== "reject") {
      throw new HttpsError("invalid-argument", "decision must be approve|reject");
    }
    if (decision === "reject") {
      if (!reason || !ALLOWED_REASONS.has(reason)) {
        throw new HttpsError(
          "invalid-argument",
          "reject decision requires a valid reason"
        );
      }
    }

    const ref = db().collection(COLLECTIONS.couples).doc(coupleId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "couple not found");
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const update: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> =
      decision === "approve"
        ? {
            status: "approved",
            "verification.reviewed_at": now,
            "verification.moderator_id": req.auth.uid,
            "verification.reject_reason": null,
            updated_at: now,
          }
        : {
            status: "rejected",
            "verification.reviewed_at": now,
            "verification.moderator_id": req.auth.uid,
            "verification.reject_reason": reason!,
            updated_at: now,
          };

    await ref.update(update);
    return { ok: true };
  }
);
