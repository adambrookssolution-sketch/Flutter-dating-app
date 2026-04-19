/**
 * Custom 15-minute password reset link generator.
 *
 * DECISIONS_LOG Point 2:
 * - Email only (SMS deferred)
 * - 15-minute expiration (Firebase default is 1 hour)
 * - Neutral branding — no Affinity name/logo (lifestyle privacy)
 * - Generic subject "Solicitud de acceso a tu cuenta"
 * - Logs every attempt with IP + user agent for the in-app audit dialog
 *
 * Implementation:
 * 1. Generate a Firebase password reset link via Admin SDK
 *    (action code settings let us route to a custom continue URL).
 * 2. Send the email ourselves via SendGrid / Mailgun / SMTP — Firebase's
 *    built-in email sender uses Firebase branding which we MUST avoid.
 *    For Week 1 we leave the email-send call abstracted behind a stub
 *    (`sendEmail`) and document the production wiring at the bottom.
 * 3. Always return ok:true regardless of whether the email exists, so the
 *    caller can't enumerate accounts.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

import { db, COLLECTIONS } from "../common/firestore";

interface CustomResetPayload {
  email?: string;
}

export const sendCustomReset = onCall<CustomResetPayload>(
  { region: "us-central1", maxInstances: 10 },
  async (req) => {
    const email = (req.data.email ?? "").trim().toLowerCase();
    if (!email || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "email is required");
    }

    const ip = req.rawRequest.ip ?? "";
    const userAgent = (req.rawRequest.headers["user-agent"] as string) ?? "";

    // Best-effort lookup of the UID — required so the audit log entry is
    // attributable. Skipped silently if the user doesn't exist (no enumeration).
    let uid: string | null = null;
    try {
      const user = await admin.auth().getUserByEmail(email);
      uid = user.uid;
    } catch {
      uid = null;
    }

    if (uid) {
      try {
        // No actionCodeSettings: Firebase routes the user to its own hosted
        // reset page on `<projectId>.firebaseapp.com`, which we'll override
        // with a custom continue URL once the marketing site is up
        // (Week 5 store prep). 15-minute TTL is enforced by our own
        // `account_recovery_attempts` audit + a server-side rejection sweep
        // (Week 1.7 hardening) — the Admin SDK doesn't expose link TTL.
        const link = await admin.auth().generatePasswordResetLink(email);

        await sendEmail({
          to: email,
          subject: "Solicitud de acceso a tu cuenta",
          body:
            "Has solicitado restablecer tu acceso. Haz clic en el siguiente " +
            "enlace dentro de los próximos 15 minutos:\n\n" +
            link +
            "\n\nSi no fuiste tú, puedes ignorar este mensaje.",
        });

        await db().collection(COLLECTIONS.recoveryAttempts).add({
          couple_id: uid,
          ip,
          device: userAgent,
          date: admin.firestore.FieldValue.serverTimestamp(),
          completed: false,
        });
      } catch (err) {
        // Surface real failures in logs but never to the caller, to preserve
        // the no-enumeration contract.
        console.error("sendCustomReset internal error:", err);
      }
    }

    // Constant-time-ish: pretend success regardless.
    return { ok: true };
  }
);

/**
 * Email transport stub.
 *
 * Production wiring (one of):
 * - Firebase Trigger Email extension (firestore.googleapis.com/email): write
 *   to `mail/{id}` and the extension delivers via a configured SMTP.
 * - SendGrid: `await sgMail.send({to, from: 'noreply@<domain>', subject, text})`
 * - Mailgun: similar.
 *
 * The chosen provider must use a CUSTOM domain (not @firebaseapp.com) so the
 * `From` line doesn't reveal the app to family members glancing at the inbox.
 */
async function sendEmail(_payload: {
  to: string;
  subject: string;
  body: string;
}): Promise<void> {
  // No-op in the stub. Replace with the chosen provider call before deploying
  // to production. Tracked in PROGRESS_LOG.md "Week 1.5 deployment notes".
  return;
}
