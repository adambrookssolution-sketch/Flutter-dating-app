/**
 * Moderator action endpoint — approve or reject a couple's verification video.
 *
 * Deploy marker: 2026-05-12-v2 (audit logging + force-refresh integration)
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

// Kept in lockstep with `_reasons` in lib/admin/pages/moderation_review_screen.dart.
// Client agreed on a closed list (2026-04-21) so notifications stay consistent.
const ALLOWED_REASONS = new Set([
  "fotos_no_coinciden",
  "video_poco_claro",
  "perfil_sospechoso",
  "fotos_inapropiadas",
  "solo_una_persona",
  "menor_de_edad",
  "calidad_baja",
  "otro",
]);

/// Client spec (2026-04-21): after the first rejection a couple has two
/// more attempts. The THIRD rejection locks the account permanently.
const MAX_VERIFICATION_ATTEMPTS = 3;

// Write a step marker into function_audit/{autoId} so we can trace
// what's happening from Firestore alone — Cloud Functions logs aren't
// always reachable from the dev network. Each call writes one doc
// containing the sequence of steps and the final outcome.
async function audit(payload: Record<string, unknown>): Promise<void> {
  try {
    await admin.firestore().collection("function_audit").add({
      fn: "moderateVerification",
      at: admin.firestore.FieldValue.serverTimestamp(),
      ...payload,
    });
  } catch (_) {
    // Audit must never break the actual flow.
  }
}

export const moderateVerification = onCall<Payload>(
  { region: "us-central1", maxInstances: 10 },
  async (req) => {
    const trace: string[] = [];
    const note = (s: string) => trace.push(s);
    try {
      note("entered");
      if (!req.auth) {
        note("no auth");
        await audit({ outcome: "unauthenticated", trace });
        throw new HttpsError("unauthenticated", "sign in required");
      }
      note(`auth uid=${req.auth.uid}`);
      const claims = req.auth.token;
      note(`claims keys=${Object.keys(claims).join(",")}`);
      note(`moderator=${claims.moderator}`);
      if (claims.moderator !== true) {
        await audit({
          outcome: "permission-denied",
          uid: req.auth.uid,
          claims: { moderator: claims.moderator, admin: claims.admin },
          trace,
        });
        throw new HttpsError("permission-denied", "moderator claim required");
      }

      const { coupleId, decision, reason } = req.data;
      note(`payload coupleId=${coupleId} decision=${decision} reason=${reason ?? "n/a"}`);
      if (!coupleId) {
        await audit({ outcome: "invalid-argument", reason: "missing coupleId", trace });
        throw new HttpsError("invalid-argument", "coupleId required");
      }
      if (decision !== "approve" && decision !== "reject") {
        await audit({ outcome: "invalid-argument", reason: "bad decision", decision, trace });
        throw new HttpsError("invalid-argument", "decision must be approve|reject");
      }
      if (decision === "reject") {
        if (!reason || !ALLOWED_REASONS.has(reason)) {
          await audit({ outcome: "invalid-argument", reason: "bad reject reason", trace });
          throw new HttpsError(
            "invalid-argument",
            "reject decision requires a valid reason"
          );
        }
      }

      const ref = db().collection(COLLECTIONS.couples).doc(coupleId);
      const snap = await ref.get();
      note(`couple exists=${snap.exists}`);
      if (!snap.exists) {
        await audit({ outcome: "not-found", coupleId, trace });
        throw new HttpsError("not-found", "couple not found");
      }

      const now = admin.firestore.FieldValue.serverTimestamp();

    let update: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData>;
    if (decision === "approve") {
      update = {
        status: "approved",
        "verification.reviewed_at": now,
        "verification.moderator_id": req.auth.uid,
        "verification.reject_reason": null,
        updated_at: now,
      };
    } else {
      // Read the current attempt count to decide whether this rejection
      // should transition to "rejected" (user may retry) or "suspended"
      // (permanent block after the 3rd failed attempt).
      const data = snap.data() ?? {};
      const verification = (data.verification ?? {}) as Record<string, unknown>;
      const attempts = typeof verification.attempts === "number"
        ? (verification.attempts as number)
        : 0;
      const isFinalRejection = attempts >= MAX_VERIFICATION_ATTEMPTS;

      update = {
        status: isFinalRejection ? "suspended" : "rejected",
        "verification.reviewed_at": now,
        "verification.moderator_id": req.auth.uid,
        "verification.reject_reason": reason!,
        "verification.final_rejection": isFinalRejection,
        updated_at: now,
      };
    }

      note("about to update");
      await ref.update(update);
      note("update done");
      await audit({
        outcome: "success",
        coupleId,
        decision,
        uid: req.auth.uid,
        trace,
      });
      return { ok: true };
    } catch (e: unknown) {
      // Re-throw HttpsError as-is so the client sees the right code.
      // Anything else gets wrapped as `internal` AND audited so we know
      // the exact internal error from Firestore-side.
      if (e instanceof HttpsError) throw e;
      const msg = e instanceof Error ? e.message : String(e);
      const stack = e instanceof Error ? e.stack : undefined;
      await audit({ outcome: "internal", error: msg, stack, trace });
      throw new HttpsError("internal", msg);
    }
  }
);
