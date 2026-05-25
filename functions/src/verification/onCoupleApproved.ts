/**
 * Notify the couple via push + email when a moderator approves them.
 *
 * Client feedback 2026-05-23: "Envío de correo de aprobación cuando un
 * perfil es aprobado, ya que actualmente ese flujo tampoco está
 * funcionando correctamente."
 *
 * Two channels:
 *  1. FCM push — works immediately for any device that registered an
 *     FCM token during the pending_review window. FcmService.register()
 *     fires from navigateAfterSignIn for every signed-in user including
 *     pending_review, so a token is normally on file by the time a
 *     moderator clicks Approve.
 *  2. Email — written to the `mail/{autoId}` collection following the
 *     Firebase Trigger Email extension convention
 *     (https://extensions.dev/extensions/firebase/firestore-send-email).
 *     The extension needs to be installed on the project + SMTP creds
 *     configured before emails actually deliver. Until then docs pile
 *     up harmlessly in `mail/` and we can replay them once SMTP is wired.
 *
 * Trigger: any couples/{uid} doc update where status transitions
 *   pending_review (or under_review / rejected / suspended) -> approved.
 * Same-status writes (status was already approved) are no-ops.
 */
import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

import { db } from "../common/firestore";
import { sendPushToCouple } from "../common/push";

export const onCoupleApproved = onDocumentUpdated(
  {
    document: "couples/{coupleId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const wasApproved = before.status === "approved";
    const isApproved = after.status === "approved";

    if (!isApproved) return;
    if (wasApproved) return; // already approved -> no-op (e.g. cancelDeletion)

    const coupleId = event.params.coupleId;
    logger.info(
      `onCoupleApproved: ${coupleId} transitioned ${before.status} -> approved`
    );

    // Push (in-app + system notification). Fire-and-forget so the email
    // write happens even if FCM has zero tokens.
    sendPushToCouple(coupleId, {
      title: "Tu perfil fue aprobado",
      body: "Bienvenidos a Affinity. Ya puedes acceder a la comunidad.",
      data: { kind: "approval" },
    }).catch((err) => {
      logger.warn(`approval push failed for couple ${coupleId}:`, err);
    });

    // Email. Look up the auth user's email — couples/{uid} doc doesn't
    // store it (privacy: PII stays out of the discovery-readable doc).
    let email: string | undefined;
    try {
      const user = await admin.auth().getUser(coupleId);
      email = user.email ?? undefined;
    } catch (err) {
      logger.warn(`couldn't resolve auth user ${coupleId} for approval email:`, err);
    }

    if (!email) return;

    // Write to mail/ — Firebase Trigger Email extension picks this up.
    // Neutral subject + plain body per the deliverability rules in
    // sendCustomReset.ts (no Affinity branding in subject; lifestyle
    // privacy + spam-filter avoidance).
    await db().collection("mail").add({
      to: email,
      message: {
        subject: "Tu solicitud ha sido aprobada",
        text:
          "Hola,\n\n" +
          "Tu perfil ha sido aprobado. Ya puedes ingresar a la aplicación " +
          "y comenzar a explorar la comunidad.\n\n" +
          "Si no fuiste tú quien realizó esta solicitud, por favor ignora " +
          "este mensaje.\n",
      },
      // Trigger Email extension metadata.
      _approvalFor: coupleId,
      _createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }).catch((err) => {
      // Mail write failure must not abort the function — push already
      // went out and the user is approved in Firestore regardless.
      logger.error(`failed to enqueue approval email for ${coupleId}:`, err);
    });

    logger.info(`approval email + push dispatched for ${coupleId}`);
  }
);
