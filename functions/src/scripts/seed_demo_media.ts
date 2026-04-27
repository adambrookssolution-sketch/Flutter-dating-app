/**
 * Demo media injector — gives the moderation panel something real to
 * render in the test environment.
 *
 * Why this exists: in the test Firebase project (`affinity-test-f4c84`)
 * Cloud Storage is on the Spark plan and disabled, so couples that
 * register here end up with `photos: []` and no `verification.video_url`.
 * The panel's media tiles render the "no disponible" fallbacks, which
 * is correct behaviour but doesn't let us demo the full review flow
 * during the verification phase.
 *
 * This script writes external HTTPS URLs (publicly hosted sample
 * videos + photos) directly into the existing `pending_review` couple
 * documents so the panel can play and display them. Production never
 * runs this — production uses real user uploads via Storage.
 *
 * Run:
 *   ts-node functions/src/scripts/seed_demo_media.ts \
 *     --project=affinity-test-f4c84
 *
 * Idempotent: re-running overwrites with the same values. Use
 * --revert to wipe the demo URLs back to empty.
 */
import * as admin from "firebase-admin";

// ── CLI parsing ──────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const flag = (name: string) => args.includes(name);
const value = (name: string): string | undefined => {
  const prefix = `${name}=`;
  const found = args.find((a) => a.startsWith(prefix));
  return found ? found.slice(prefix.length) : undefined;
};

const projectId = value("--project") ?? "affinity-test-f4c84";
const revert = flag("--revert");

admin.initializeApp({ projectId });
const db = admin.firestore();

// ── Sample asset library ─────────────────────────────────────────────────────

/**
 * Public sample video URLs. Big Buck Bunny + similar Creative-Commons
 * test videos hosted by sample-videos.com — small files, MP4, no DRM.
 * If any of these go offline, swap them for fresh URLs from
 * https://sample-videos.com or https://gtv-videos-bucket.storage.googleapis.com.
 */
const SAMPLE_VIDEOS = [
  "https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_1mb.mp4",
  "https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_1mb.mp4",
  "https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_1mb.mp4",
  "https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_2mb.mp4",
];

/**
 * Public sample photo URLs from Unsplash's source service. Stable,
 * royalty-free, and the URL parameters keep the response small.
 */
const SAMPLE_PHOTO_SETS = [
  [
    "https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=400",
    "https://images.unsplash.com/photo-1529635343929-37b34e9ee1eb?w=400",
    "https://images.unsplash.com/photo-1469371670807-013ccf25f16a?w=400",
    "https://images.unsplash.com/photo-1521798552670-c4ea1ea53c2a?w=400",
  ],
  [
    "https://images.unsplash.com/photo-1604881991720-f91add269bed?w=400",
    "https://images.unsplash.com/photo-1583341655423-094bc6a0f74c?w=400",
    "https://images.unsplash.com/photo-1583341612089-2bd5b3d29c70?w=400",
  ],
  [
    "https://images.unsplash.com/photo-1502635385003-ee1e6a1a742d?w=400",
    "https://images.unsplash.com/photo-1521577352947-9bb58764b69a?w=400",
    "https://images.unsplash.com/photo-1517438476312-10d79c077509?w=400",
    "https://images.unsplash.com/photo-1494774157365-9e04c6720e47?w=400",
  ],
  [
    "https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=400",
    "https://images.unsplash.com/photo-1503516459261-40c66117780a?w=400",
    "https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=400",
  ],
];

// ── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log(`Target: ${projectId} ${revert ? "(--revert)" : "(write)"}`);

  const snap = await db
    .collection("couples")
    .where("status", "==", "pending_review")
    .get();

  if (snap.empty) {
    console.log("  No pending_review couples — nothing to seed.");
    return;
  }

  console.log(`  Found ${snap.size} pending_review couples.`);

  let i = 0;
  for (const doc of snap.docs) {
    const ref = doc.ref;

    if (revert) {
      await ref.update({
        photos: [],
        "verification.video_url": admin.firestore.FieldValue.delete(),
      });
      console.log(`  - reverted ${doc.id}`);
      continue;
    }

    const videoUrl = SAMPLE_VIDEOS[i % SAMPLE_VIDEOS.length];
    const photoSet = SAMPLE_PHOTO_SETS[i % SAMPLE_PHOTO_SETS.length];

    // Read existing verification map so we don't blow away other fields
    // (sent_at, attempts, moderator_id, etc.).
    const existing = (doc.data().verification ?? {}) as Record<string, unknown>;
    const newVerification = { ...existing, video_url: videoUrl };

    await ref.update({
      photos: photoSet,
      verification: newVerification,
    });
    console.log(
      `  + seeded ${doc.id}: ${photoSet.length} photos, video=${videoUrl
        .split("/")
        .pop()}`,
    );
    i++;
  }

  console.log("Done.");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
