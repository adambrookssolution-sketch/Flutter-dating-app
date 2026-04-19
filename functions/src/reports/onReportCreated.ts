/**
 * Post-report bookkeeping (DECISIONS_LOG Point 5).
 *
 * Fires on every `reports/{id}` creation and enforces two thresholds:
 *
 *  (a) If the reported couple has >= 5 reports from DIFFERENT reporters in
 *      the last 30 days, move them to `status: under_review`. This hides
 *      them from discovery while a moderator sorts it out.
 *
 *  (b) If the reporter has filed >= 10 reports in the last 7 days, disable
 *      their reporting capability by stamping
 *      `users_meta/{reporter}.reportingDisabledUntil`. Client-side UX is
 *      expected to respect this, but the ultimate enforcement is in a
 *      future Security-Rules update (Week 3 hardening) that rejects report
 *      writes when that field is in the future.
 */
import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

import { db, COLLECTIONS } from "../common/firestore";

const REPORTS_THRESHOLD_UNIQUE = 5;
const SUSPECT_WINDOW_DAYS = 30;
const REPORTER_LIMIT = 10;
const REPORTER_WINDOW_DAYS = 7;
const REPORTER_COOLDOWN_DAYS = 7;

export const onReportCreated = onDocumentCreated(
  {
    document: "reports/{reportId}",
    region: "us-central1",
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const reporter = data.reporter_couple as string;
    const reported = data.reported_couple as string;
    if (!reporter || !reported) return;

    await Promise.all([
      checkReportedThreshold(reported),
      checkReporterLimit(reporter),
    ]);
  }
);

async function checkReportedThreshold(coupleId: string): Promise<void> {
  const since = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - SUSPECT_WINDOW_DAYS * 24 * 60 * 60 * 1000)
  );
  const snap = await db()
    .collection(COLLECTIONS.reports)
    .where("reported_couple", "==", coupleId)
    .where("fecha", ">=", since)
    .get();

  // Distinct reporters in the window
  const unique = new Set<string>();
  snap.forEach((d) => {
    const r = d.get("reporter_couple") as string | undefined;
    if (r) unique.add(r);
  });

  if (unique.size < REPORTS_THRESHOLD_UNIQUE) return;

  // Flip to under_review but only if currently approved — don't clobber a
  // manual moderator decision (suspended, pending_review, etc.).
  const ref = db().collection(COLLECTIONS.couples).doc(coupleId);
  await db().runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (!doc.exists) return;
    if (doc.get("status") !== "approved") return;
    tx.update(ref, {
      status: "under_review",
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  logger.info(
    `couple ${coupleId} moved to under_review after ${unique.size} unique reports`
  );
}

async function checkReporterLimit(reporter: string): Promise<void> {
  const since = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - REPORTER_WINDOW_DAYS * 24 * 60 * 60 * 1000)
  );
  const snap = await db()
    .collection(COLLECTIONS.reports)
    .where("reporter_couple", "==", reporter)
    .where("fecha", ">=", since)
    .count()
    .get();

  if ((snap.data().count ?? 0) < REPORTER_LIMIT) return;

  const cooldownUntil = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + REPORTER_COOLDOWN_DAYS * 24 * 60 * 60 * 1000)
  );
  await db().collection(COLLECTIONS.usersMeta).doc(reporter).set(
    {
      reportingDisabledUntil: cooldownUntil,
      reportingDisabledReason: "rate_limit",
      reportingDisabledAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  logger.warn(
    `reporter ${reporter} rate-limited: ${REPORTER_LIMIT}+ reports in ${REPORTER_WINDOW_DAYS}d`
  );
}
