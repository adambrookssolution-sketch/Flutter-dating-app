/**
 * When a couple is moved to `status: suspended` by a moderator (via the
 * moderation panel), automatically create a Block doc for every couple that
 * reported them in the previous 90 days.
 *
 * DECISIONS_LOG Point 6 — Auto-block after suspension: YES. The client
 * explicitly chose this behaviour despite the indirect-reveal risk (a
 * reporter seeing the reported couple silently vanish from their feed is
 * effectively a weak confirmation that their report landed). Gabriel's
 * worry was noted and the decision logged; this is the final behaviour.
 */
import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

import { db, COLLECTIONS } from "../common/firestore";

const LOOKBACK_DAYS = 90;
const BATCH_LIMIT = 400;

export const onSuspension = onDocumentUpdated(
  {
    document: "couples/{coupleId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== "suspended") return;

    const suspendedId = event.params.coupleId;
    const since = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - LOOKBACK_DAYS * 24 * 60 * 60 * 1000)
    );

    const reports = await db()
      .collection(COLLECTIONS.reports)
      .where("reported_couple", "==", suspendedId)
      .where("fecha", ">=", since)
      .get();

    const reporters = new Set<string>();
    reports.forEach((r) => {
      const who = r.get("reporter_couple") as string | undefined;
      if (who && who !== suspendedId) reporters.add(who);
    });

    if (reporters.size === 0) {
      logger.info(
        `onSuspension: ${suspendedId} suspended but had no reports in window`
      );
      return;
    }

    logger.info(
      `onSuspension: auto-blocking ${reporters.size} reporters of ${suspendedId}`
    );

    const firestore = db();
    let batch = firestore.batch();
    let count = 0;
    for (const reporter of reporters) {
      const id = `${reporter}_${suspendedId}`;
      batch.set(
        firestore.collection(COLLECTIONS.blocks).doc(id),
        {
          pareja_que_bloquea: reporter,
          pareja_bloqueada: suspendedId,
          fecha: admin.firestore.FieldValue.serverTimestamp(),
          origen: "auto_por_suspension",
        },
        { merge: false }
      );
      count++;
      if (count >= BATCH_LIMIT) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }
);
