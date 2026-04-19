/**
 * Atomic 30-day delayed account deletion.
 *
 * DECISIONS_LOG Point 3 — scope of deletion:
 *   - couples/{coupleId} document + all subcollections (trips, fcm_tokens)
 *   - conversations where participants includes coupleId (+ messages subcollection)
 *   - message_requests where pareja_emisora OR pareja_receptora == coupleId
 *   - blocks where either side == coupleId
 *   - Storage: photos/* + verification video (if still present) + frames
 *   - Firebase Auth user
 *   - Reports against this couple: PII stripped, statistical metadata kept
 *     (legal protection: another couple's report shouldn't vanish on the
 *     reported user's deletion).
 *
 * Other couples' chats keep the message history visible — sender/receiver
 * just renders as "deleted user" client-side (WhatsApp behaviour). We do NOT
 * delete those messages because they belong to the other couple.
 *
 * Schedule: every day at 03:00 UTC. Window of execution well outside peak
 * usage hours for LATAM (the primary market).
 */
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions";

import { db, COLLECTIONS } from "../common/firestore";

const GRACE_DAYS = 30;
const BATCH_LIMIT = 400; // Firestore hard cap is 500; keep headroom.

export const executeDeletion = onSchedule(
  {
    schedule: "every day 03:00",
    timeZone: "Etc/UTC",
    region: "us-central1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - GRACE_DAYS * 24 * 60 * 60 * 1000)
    );

    const due = await db()
      .collection(COLLECTIONS.couples)
      .where("status", "==", "pending_deletion")
      .where("deletion_requested_at", "<=", cutoff)
      .limit(50) // process up to 50 deletions per daily run
      .get();

    if (due.empty) {
      logger.info("executeDeletion: nothing due today");
      return;
    }

    logger.info(`executeDeletion: purging ${due.size} couples`);
    for (const doc of due.docs) {
      try {
        await purgeCouple(doc.id);
        logger.info(`purged ${doc.id}`);
      } catch (err) {
        logger.error(`failed to purge ${doc.id}`, err);
        // Don't rethrow — keep going so one bad doc doesn't block the others.
      }
    }
  }
);

async function purgeCouple(coupleId: string): Promise<void> {
  const firestore = db();
  const auth = admin.auth();
  const storage = admin.storage();

  // 1. Subcollections under couples/{id}
  await deleteSubcollection(firestore, `couples/${coupleId}/trips`);
  await deleteSubcollection(firestore, `couples/${coupleId}/fcm_tokens`);

  // 2. The couple document itself
  await firestore.doc(`couples/${coupleId}`).delete();

  // 3. Conversations + nested messages
  const convs = await firestore
    .collection(COLLECTIONS.conversations)
    .where("participants", "array-contains", coupleId)
    .get();
  for (const c of convs.docs) {
    await deleteSubcollection(firestore, `conversations/${c.id}/messages`);
    await c.ref.delete();
  }

  // 4. Message requests in either direction
  await deleteWhere(firestore, COLLECTIONS.messageRequests, "pareja_emisora", coupleId);
  await deleteWhere(firestore, COLLECTIONS.messageRequests, "pareja_receptora", coupleId);

  // 5. Blocks in either direction
  await deleteWhere(firestore, COLLECTIONS.blocks, "pareja_que_bloquea", coupleId);
  await deleteWhere(firestore, COLLECTIONS.blocks, "pareja_bloqueada", coupleId);

  // 6. Anonymise reports filed AGAINST this couple — keep statistical data,
  //    erase any free-form description that could re-identify them.
  const againstReports = await firestore
    .collection(COLLECTIONS.reports)
    .where("reported_couple", "==", coupleId)
    .get();
  for (const r of againstReports.docs) {
    await r.ref.update({
      reported_couple: "deleted_user",
      descripcion: "",
      evidencia: [],
    });
  }
  // Reports filed BY this couple: anonymise reporter.
  const byReports = await firestore
    .collection(COLLECTIONS.reports)
    .where("reporter_couple", "==", coupleId)
    .get();
  for (const r of byReports.docs) {
    await r.ref.update({ reporter_couple: "deleted_user" });
  }

  // 7. Recovery audit log entries
  await deleteWhere(firestore, COLLECTIONS.recoveryAttempts, "couple_id", coupleId);

  // 8. Storage objects — best-effort, swallow individual failures so
  //    the Firestore + Auth purge still proceeds.
  const bucket = storage.bucket();
  for (const prefix of [
    `couples/${coupleId}/`,
    `profiles/${coupleId}/`, // legacy path
    `verifications/${coupleId}/`,
    `verification_frames/${coupleId}/`,
  ]) {
    try {
      await bucket.deleteFiles({ prefix });
    } catch (err) {
      logger.warn(`storage delete failed for ${prefix}`, err);
    }
  }

  // 9. Firebase Auth user — must come last so a transient failure earlier
  //    leaves the data side cleanable on retry.
  try {
    await auth.deleteUser(coupleId);
  } catch (err) {
    logger.warn(`auth.deleteUser(${coupleId}) failed`, err);
  }
}

async function deleteSubcollection(
  firestore: FirebaseFirestore.Firestore,
  path: string
): Promise<void> {
  const ref = firestore.collection(path);
  while (true) {
    const snap = await ref.limit(BATCH_LIMIT).get();
    if (snap.empty) break;
    const batch = firestore.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    if (snap.size < BATCH_LIMIT) break;
  }
}

async function deleteWhere(
  firestore: FirebaseFirestore.Firestore,
  collectionName: string,
  field: string,
  value: string
): Promise<void> {
  while (true) {
    const snap = await firestore
      .collection(collectionName)
      .where(field, "==", value)
      .limit(BATCH_LIMIT)
      .get();
    if (snap.empty) break;
    const batch = firestore.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    if (snap.size < BATCH_LIMIT) break;
  }
}
