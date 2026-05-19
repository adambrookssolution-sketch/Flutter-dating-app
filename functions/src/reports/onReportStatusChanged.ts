/**
 * Fires when a moderator updates a `reports/{id}` document — specifically
 * when the `estado` field transitions away from `pending` (e.g. to
 * `reviewed` or `dismissed`). Sends a push notification to the reporter
 * letting them know their case was handled (client 2026-05-17 #2 —
 * report workflow follow-up).
 *
 * We deliberately do NOT reveal what action was taken against the
 * reported couple — DECISIONS_LOG Point 5 enforces total reporter
 * confidentiality and the reverse should also hold (no leakage of
 * moderation actions back to the reporter beyond "we looked at it").
 */
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

import { sendPushToCouple } from "../common/push";

export const onReportStatusChanged = onDocumentUpdated(
  {
    document: "reports/{reportId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const wasPending = (before.estado as string | undefined) === "pending";
    const nowDecided =
      (after.estado as string | undefined) !== "pending" &&
      !!after.estado;
    if (!wasPending || !nowDecided) {
      // Either the moderator updated some other field, or this was a
      // re-decide (already non-pending) — only fire on the first
      // transition out of pending.
      return;
    }

    const reporterUid = after.reporter_couple as string | undefined;
    if (!reporterUid) {
      logger.warn(
        `onReportStatusChanged: report ${event.params.reportId} has no reporter_couple — skipping push`
      );
      return;
    }

    const estado = after.estado as string;
    // Neutral, non-revealing copy. Spanish primary (most testers are
    // Mexican); l10n on the client side picks whichever the user's
    // locale matches.
    const body =
      estado === "reviewed"
        ? "Tu reporte fue revisado y nuestro equipo tomó acción. Gracias por ayudarnos a mantener Affinity segura."
        : estado === "dismissed"
          ? "Revisamos tu reporte y, tras analizarlo, decidimos no tomar acción esta vez. Si tienes más información, puedes volver a reportar."
          : "Tu reporte fue actualizado.";

    await sendPushToCouple(reporterUid, {
      title: "Affinity",
      body,
      data: {
        kind: "report_decision",
        reportId: event.params.reportId,
        estado,
      },
    });
  }
);
