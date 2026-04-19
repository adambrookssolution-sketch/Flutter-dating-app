/**
 * Triggered when a user's password changes (via Firebase Auth's password
 * reset link or direct profile update). Revokes all refresh tokens so every
 * other device is signed out — DECISIONS_LOG Point 2 "force logout all
 * active sessions on recovery".
 *
 * Auth blocking triggers (`beforeUserCreated`, `beforeUserSignedIn`) are
 * the cleanest option here, but they require Identity Platform upgrade.
 * Without that, we can't directly hook "password changed" — we instead
 * catch sign-ins from new IPs/devices and prompt the user to re-verify.
 *
 * Practical workaround for MVP: this function is exposed as a callable that
 * the post-reset client can invoke if needed. A future hardening step will
 * either move to Identity Platform blocking triggers or run a daily sweep
 * over `account_recovery_attempts` to revoke tokens for completed entries.
 */
import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

import { db, COLLECTIONS } from "../common/firestore";

export const markRecoveryCompleted = onCall(
  { region: "us-central1", maxInstances: 10 },
  async (req) => {
    if (!req.auth) return { ok: false, reason: "unauthenticated" };
    const uid = req.auth.uid;

    // Revoke all refresh tokens — every other device falls back to sign-in.
    await admin.auth().revokeRefreshTokens(uid);

    // Best-effort marking of the most recent attempt as completed.
    const recent = await db()
      .collection(COLLECTIONS.recoveryAttempts)
      .where("couple_id", "==", uid)
      .where("completed", "==", false)
      .orderBy("date", "desc")
      .limit(1)
      .get();
    if (!recent.empty) {
      await recent.docs[0].ref.update({ completed: true });
    }

    return { ok: true };
  }
);
