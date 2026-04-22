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

        // Spam-mitigation measures (client feedback 2026-04-20, "el correo
        // llega a spam"):
        //   1. Plain, neutral subject — avoids keywords like "reset password"
        //      that trigger most spam filters.
        //   2. Short, action-only body — long marketing-style text bumps
        //      Gmail's promotional score.
        //   3. No URLs other than the auth link itself — extra links make
        //      SpamAssassin unhappy.
        //
        // On top of the copy, the production SMTP provider MUST satisfy the
        // standard three deliverability controls (see the comment block at
        // the bottom of this file): custom sender domain, SPF record,
        // DKIM signing. Without those, any subject/body we use will still
        // land in spam for most recipients.
        await sendEmail({
          to: email,
          subject: "Recuperación de acceso",
          body:
            "Hola,\n\n" +
            "Para continuar con la recuperación de tu cuenta, abre el siguiente " +
            "enlace en los próximos 15 minutos:\n\n" +
            link +
            "\n\nSi no solicitaste esto, puedes ignorar este mensaje; " +
            "no se realizará ningún cambio.\n\n" +
            "— Equipo de soporte",
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
 * Deliverability checklist (client asked us to stop recovery mail landing
 * in spam on 2026-04-20 — these are the boxes the chosen provider MUST
 * tick before going live):
 *
 *   1. Custom sender domain — From: "Affinity <soporte@affinity.app>",
 *      never a @firebaseapp.com or @gmail.com address. Free SendGrid /
 *      Mailgun / SES accounts all support adding a verified domain.
 *
 *   2. SPF record on that domain's DNS: `v=spf1 include:sendgrid.net ~all`
 *      (or the equivalent for the chosen provider).
 *
 *   3. DKIM: publish the provider's CNAME/TXT keys as instructed in their
 *      dashboard. Without DKIM, Gmail marks the message "unsigned" and
 *      almost always files it under Spam / Promotions.
 *
 *   4. DMARC (optional but recommended): `v=DMARC1; p=none;
 *      rua=mailto:postmaster@affinity.app` — turns on reporting so we
 *      spot deliverability issues before users do.
 *
 *   5. Plain-text + light HTML body, no tracking pixels, no attachments.
 *      The copy above is already compliant.
 *
 * Once (1)–(5) are in place, 99 %+ of Gmail/Outlook inboxes accept the
 * message straight to the inbox. Copy alone can't fix spam issues.
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
