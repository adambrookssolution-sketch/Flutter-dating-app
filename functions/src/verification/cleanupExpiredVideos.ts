/**
 * Daily sweep that enforces the 7-day video retention policy.
 *
 * DECISIONS_LOG Point 1 (hybrid retention):
 *   - Full video stored 7 days after approval.
 *   - This function:
 *       1. Downloads the video file.
 *       2. Computes a SHA-256 hash (permanent auditable record).
 *       3. (TODO) Extracts 2-3 low-resolution frames and uploads them to
 *          `verification_frames/{coupleId}/*` as the permanent visual record.
 *       4. Deletes the source video file from Storage.
 *       5. Updates `couples/{id}.verification`: nulls video_url, writes
 *          video_hash + video_frames.
 *
 * Frame extraction note: running ffmpeg inside a Cloud Function requires
 * either a custom Docker image (Gen 2 CFs support this) or a companion
 * Cloud Run service. Both exceed the scope of Week 2 and are better wired
 * once we have real verification data to tune against. For now we write
 * `video_frames: []` and let the hash carry the audit weight. Week 4 or
 * Week 5 hardening: add ffmpeg-based frame extraction.
 *
 * Runs daily at 04:00 UTC — an hour offset from executeDeletion so the two
 * sweeps don't compete for Firestore read budget.
 */
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import { File as StorageFile } from "@google-cloud/storage";

import { db, COLLECTIONS } from "../common/firestore";

const RETENTION_DAYS = 7;

export const cleanupExpiredVideos = onSchedule(
  {
    schedule: "every day 04:00",
    timeZone: "Etc/UTC",
    region: "us-central1",
    timeoutSeconds: 540,
    memory: "1GiB", // video download needs headroom
  },
  async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000)
    );

    // Only look at couples whose video has been REVIEWED already — no point
    // deleting a video that's still in the moderation queue.
    const due = await db()
      .collection(COLLECTIONS.couples)
      .where("verification.reviewed_at", "<=", cutoff)
      .limit(100)
      .get();

    if (due.empty) {
      logger.info("cleanupExpiredVideos: nothing due today");
      return;
    }

    let processed = 0;
    for (const doc of due.docs) {
      const data = doc.data();
      const v = data.verification as Record<string, unknown> | undefined;
      const url = v?.video_url as string | undefined;
      if (!url) continue; // already cleaned

      try {
        await cleanupOne(doc.id);
        processed++;
      } catch (err) {
        logger.error(`cleanup failed for ${doc.id}`, err);
      }
    }
    logger.info(`cleanupExpiredVideos: processed ${processed}`);
  }
);

async function cleanupOne(coupleId: string): Promise<void> {
  const bucket = admin.storage().bucket();

  // Find the object path — we store as `verifications/{coupleId}/{ts}.mp4`.
  // List everything under the couple's folder and pick the newest.
  const [files] = await bucket.getFiles({
    prefix: `verifications/${coupleId}/`,
  });
  if (files.length === 0) {
    // Already gone — still clean up the Firestore pointer for consistency.
    await db().collection(COLLECTIONS.couples).doc(coupleId).update({
      "verification.video_url": null,
    });
    return;
  }

  files.sort((a, b) => b.name.localeCompare(a.name));
  const target = files[0];

  // 1. Stream the file and compute SHA-256
  const hash = await hashFile(target);

  // 2. Frame extraction placeholder — see module docstring.
  const frames: string[] = [];

  // 3. Delete the video from Storage
  await target.delete({ ignoreNotFound: true });

  // 4. Update Firestore
  await db().collection(COLLECTIONS.couples).doc(coupleId).update({
    "verification.video_url": null,
    "verification.video_hash": hash,
    "verification.video_frames": frames,
  });
}

function hashFile(file: StorageFile): Promise<string> {
  return new Promise<string>((resolve, reject) => {
    const hash = crypto.createHash("sha256");
    const stream = file.createReadStream();
    stream.on("data", (chunk: Buffer) => hash.update(chunk));
    stream.on("end", () => resolve(hash.digest("hex")));
    stream.on("error", reject);
  });
}
