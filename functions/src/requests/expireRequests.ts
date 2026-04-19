/**
 * Daily sweep — flips message_requests with status=pending and
 * fecha_expiracion <= now to status=expired.
 *
 * DECISIONS_LOG Point 4: 14-day expiration. The receiver gets no extra
 * notification — the request just disappears from their inbox once expired.
 *
 * Schedule: 05:00 UTC, after the deletion + cleanup sweeps so the daily
 * server-side housekeeping is grouped together.
 */
import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";

import { db, COLLECTIONS } from "../common/firestore";

const BATCH_LIMIT = 400;

export const expireRequests = onSchedule(
  {
    schedule: "every day 05:00",
    timeZone: "Etc/UTC",
    region: "us-central1",
    timeoutSeconds: 540,
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    let totalExpired = 0;
    let cursor: FirebaseFirestore.QueryDocumentSnapshot | null = null;

    while (true) {
      let q = db()
        .collection(COLLECTIONS.messageRequests)
        .where("estado", "==", "pending")
        .where("fecha_expiracion", "<=", now)
        .orderBy("fecha_expiracion")
        .limit(BATCH_LIMIT);
      if (cursor) q = q.startAfter(cursor);

      const snap = await q.get();
      if (snap.empty) break;

      const batch = db().batch();
      snap.docs.forEach((d) => batch.update(d.ref, { estado: "expired" }));
      await batch.commit();
      totalExpired += snap.size;

      if (snap.size < BATCH_LIMIT) break;
      cursor = snap.docs[snap.docs.length - 1];
    }
    logger.info(`expireRequests: expired ${totalExpired} pending requests`);
  }
);
