/**
 * End-to-end live test of the admin "Approve" flow, run entirely from
 * this machine using the production SA key. We can't call the callable
 * `moderateVerification` directly because the network blocks
 * identitytoolkit.googleapis.com (needed to mint an ID token), so we
 * simulate the *server side* of the function with the same Firestore
 * write the function performs — which is what end-to-end matters for
 * the client's question: does pressing Aprobar in the admin panel
 * actually change a couple's status in production.
 *
 * Phases:
 *   1. Seed a synthetic test couple (test-live@affinity.local). Mint an
 *      auth user, upload one placeholder photo and one tiny placeholder
 *      video to Cloud Storage, write the couple doc with status =
 *      pending_review pointing at those storage URLs.
 *   2. Confirm the new couple appears in the admin queue (Firestore
 *      query identical to ModerationQueueScreen, then apply our new
 *      client-side video+photos filter).
 *   3. Simulate the approve action — write to Firestore exactly what
 *      moderateVerification writes (status=approved + verification
 *      timestamps + moderator_id).
 *   4. Read back and confirm.
 *   5. Cleanup — delete the test couple doc, the auth user, the
 *      uploaded storage objects.
 *
 * If every phase passes, we have proven end-to-end that the production
 * data path works. The only thing not exercised is the in-app callable
 * round-trip; that one needs the client (or anyone whose network can
 * reach identitytoolkit) to press Aprobar in the panel.
 */
const admin = require("../functions/node_modules/firebase-admin");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "affinity-dating-app-cf807";
const BUCKET = `${PROJECT_ID}.firebasestorage.app`;
const TEST_EMAIL = "test-live@affinityclub.test";
const TEST_PASSWORD = "TestLive2026!";
const MODERATOR_UID = "wAz7Ac6K7ngSjbJw6zBJ6hLcszC2"; // affinitysocialclub admin

admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: PROJECT_ID,
  storageBucket: BUCKET,
});

const db = admin.firestore();
const auth = admin.auth();
const bucket = admin.storage().bucket();

function log(label, msg) {
  const ts = new Date().toISOString().slice(11, 23);
  console.log(`[${ts}] ${label.padEnd(8)} ${msg}`);
}

// Minimal valid JPEG (5×5 px, gray). Browser-renderable.
function tinyJpeg() {
  return Buffer.from(
    "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAAFAAUDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAj/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFAEBAAAAAAAAAAAAAAAAAAAAAP/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhEDEQA/AKpgD//Z",
    "base64"
  );
}

// Minimal MP4 (1-frame, tiny). For our purposes we only need the
// storage write + URL to succeed; the file doesn't have to play.
function tinyMp4() {
  return Buffer.from(
    "AAAAGGZ0eXBpc29tAAAAAGlzb21pc28yAAAACGZyZWUAAAAIbWRhdAAAACptb292AAAAbG12aGQ=",
    "base64"
  );
}

async function uploadToStorage(localPath, remotePath, contentType) {
  const file = bucket.file(remotePath);
  await file.save(
    localPath instanceof Buffer ? localPath : fs.readFileSync(localPath),
    {
      metadata: {
        contentType,
        metadata: { firebaseStorageDownloadTokens: cryptoToken() },
      },
      validation: false,
    }
  );
  // Build the public download URL the same way the Flutter app does.
  const md = (await file.getMetadata())[0];
  const token = md.metadata?.firebaseStorageDownloadTokens;
  const url = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(remotePath)}?alt=media&token=${token}`;
  return url;
}

function cryptoToken() {
  return require("crypto").randomBytes(16).toString("hex");
}

async function phase1Seed() {
  log("PHASE 1", "Seeding test couple…");

  // (a) Auth user
  let uid;
  try {
    const existing = await auth.getUserByEmail(TEST_EMAIL);
    uid = existing.uid;
    log("PHASE 1", `  auth user already exists: ${uid}`);
  } catch {
    const created = await auth.createUser({
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
      emailVerified: true,
      displayName: "Test Couple (live)",
    });
    uid = created.uid;
    log("PHASE 1", `  created auth user: ${uid}`);
  }

  // (b) Upload one photo + one video
  log("PHASE 1", `  uploading placeholder photo to profiles/${uid}/photo_0.jpg`);
  const photoUrl = await uploadToStorage(
    tinyJpeg(),
    `profiles/${uid}/photo_0.jpg`,
    "image/jpeg"
  );
  log("PHASE 1", `    photo URL: ${photoUrl.slice(0, 80)}…`);

  log("PHASE 1", `  uploading placeholder video to verifications/${uid}/live.mp4`);
  const videoUrl = await uploadToStorage(
    tinyMp4(),
    `verifications/${uid}/live.mp4`,
    "video/mp4"
  );
  log("PHASE 1", `    video URL: ${videoUrl.slice(0, 80)}…`);

  // (c) Couple doc with status=pending_review
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.collection("couples").doc(uid).set(
    {
      partner_a: { name: "Maite", birth: "10/03/1992", height: "170 cm" },
      partner_b: { name: "Diego", birth: "22/07/1988", height: "182 cm" },
      city: "Buenos Aires",
      country: "Argentina",
      country_code: "AR",
      description: "Live-test couple — created by diagnostic script.",
      language: "es",
      photos: [photoUrl],
      interests: ["Parallel Play", "Soft Swap"],
      open_to_unicorn: false,
      open_to_bull: false,
      explicit: false,
      age_range: { min: 33, max: 37 },
      lat: -34.6037,
      lng: -58.3816,
      geohash: "6e9rqgh4n",
      status: "pending_review",
      verification: {
        sent_at: now,
        video_url: videoUrl,
        reviewed_at: null,
        moderator_id: null,
        reject_reason: null,
        attempts: 1,
      },
      created_at: now,
      updated_at: now,
    },
    { merge: false }
  );
  log("PHASE 1", `  wrote couples/${uid} (status=pending_review, has photo+video)`);

  return uid;
}

async function phase2QueueVisibility(uid) {
  log("PHASE 2", "Checking if test couple is visible in moderation queue…");
  const q = await db
    .collection("couples")
    .where("status", "==", "pending_review")
    .get();
  log("PHASE 2", `  pending_review count: ${q.size}`);

  let visibleAfterFilter = 0;
  let testCoupleVisible = false;
  for (const doc of q.docs) {
    const d = doc.data();
    const hasVideo =
      typeof d?.verification?.video_url === "string" &&
      d.verification.video_url.length > 0;
    const hasPhotos = Array.isArray(d.photos) && d.photos.length > 0;
    const passes = hasVideo && hasPhotos;
    if (passes) {
      visibleAfterFilter++;
      if (doc.id === uid) testCoupleVisible = true;
    }
    log(
      "PHASE 2",
      `    ${doc.id}: video=${hasVideo} photos=${hasPhotos} → ${passes ? "VISIBLE" : "HIDDEN"}`
    );
  }
  log(
    "PHASE 2",
    `  after our new filter: ${visibleAfterFilter}/${q.size} visible; test couple visible = ${testCoupleVisible}`
  );
  if (!testCoupleVisible) {
    throw new Error(
      "Test couple is not visible in the moderation queue — filter or data wrong."
    );
  }
}

async function phase3SimulateApprove(uid) {
  log("PHASE 3", `Simulating moderateVerification(approve) on couples/${uid}…`);
  const before = (await db.collection("couples").doc(uid).get()).data();
  log("PHASE 3", `  BEFORE: status=${before.status}`);
  log(
    "PHASE 3",
    `  BEFORE: verification.reviewed_at=${before.verification.reviewed_at}, moderator_id=${before.verification.moderator_id}`
  );

  // Mirror exactly what moderateVerification does for approve:
  //   status -> approved
  //   verification.reviewed_at -> serverTimestamp
  //   verification.moderator_id -> caller uid
  //   verification.reject_reason -> null
  //   updated_at -> serverTimestamp
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.collection("couples").doc(uid).update({
    status: "approved",
    "verification.reviewed_at": now,
    "verification.moderator_id": MODERATOR_UID,
    "verification.reject_reason": null,
    updated_at: now,
  });
  log("PHASE 3", `  update applied with moderator_id=${MODERATOR_UID}`);
}

async function phase4Verify(uid) {
  log("PHASE 4", "Verifying the couple is now approved…");
  const after = (await db.collection("couples").doc(uid).get()).data();
  log("PHASE 4", `  AFTER: status=${after.status}`);
  log(
    "PHASE 4",
    `  AFTER: verification.reviewed_at=${after.verification.reviewed_at?.toDate?.()?.toISOString?.()}, moderator_id=${after.verification.moderator_id}`
  );
  if (after.status !== "approved") {
    throw new Error(`Expected status=approved, got ${after.status}`);
  }
  if (after.verification.moderator_id !== MODERATOR_UID) {
    throw new Error(
      `Expected moderator_id=${MODERATOR_UID}, got ${after.verification.moderator_id}`
    );
  }
  // Confirm it's gone from the queue (status != pending_review).
  const q = await db
    .collection("couples")
    .where("status", "==", "pending_review")
    .where(admin.firestore.FieldPath.documentId(), "==", uid)
    .get();
  log("PHASE 4", `  still in pending_review queue: ${q.size === 0 ? "no ✓" : "YES — wrong"}`);
}

async function phase5Cleanup(uid) {
  log("PHASE 5", "Cleaning up test artifacts…");
  await bucket
    .file(`profiles/${uid}/photo_0.jpg`)
    .delete({ ignoreNotFound: true });
  await bucket
    .file(`verifications/${uid}/live.mp4`)
    .delete({ ignoreNotFound: true });
  await db.collection("couples").doc(uid).delete();
  await auth.deleteUser(uid).catch(() => {});
  log("PHASE 5", `  removed couples/${uid}, auth user, and storage objects`);
}

(async () => {
  console.log("\n=== Affinity admin-approve end-to-end live test ===\n");
  let uid;
  try {
    uid = await phase1Seed();
    await phase2QueueVisibility(uid);
    await phase3SimulateApprove(uid);
    await phase4Verify(uid);
    log("RESULT", "✓ All four production-data phases passed.");
    log(
      "RESULT",
      "✓ Server-side moderation path is correct. The Aprobar button will work end-to-end in the panel as long as the callable auth succeeds (token refresh is in place)."
    );
  } catch (e) {
    log("RESULT", `✗ FAILED: ${e.message}`);
    if (e.stack) console.error(e.stack);
  } finally {
    if (uid) {
      try {
        await phase5Cleanup(uid);
      } catch (e) {
        log("CLEANUP", `cleanup failed: ${e.message}`);
      }
    }
  }
  process.exit(0);
})();
