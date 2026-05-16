/**
 * Comprehensive Firestore-only live verification of the production state.
 *
 * Our local node can talk to firestore.googleapis.com (admin SDK reuses
 * a cached service-account token) but cannot reach
 * www.googleapis.com/oauth2/v4/token to mint a fresh token for Storage.
 * So this script only probes what Firestore alone can prove, but it
 * probes it thoroughly:
 *
 *   1. Couples collection — current docs + their data shape
 *   2. function_audit collection — every moderateVerification call so far
 *   3. Reports / blocks / message_requests / trips — agency-side data
 *      coexistence
 *   4. Auth user listing — moderator + demo accounts present
 *   5. CoupleStatus distribution — pending_review couples that are
 *      incomplete (no video/photos) vs complete
 */
const dns = require("dns");
dns.setDefaultResultOrder("ipv4first");
try { dns.setServers(["8.8.8.8", "1.1.1.1"]); } catch (_) {}

const admin = require("../functions/node_modules/firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: "affinity-dating-app-cf807",
});

const db = admin.firestore();

function divider(label) {
  console.log("\n" + "═".repeat(70));
  console.log(" " + label);
  console.log("═".repeat(70));
}

(async () => {
  divider("1. Couples — current state");
  const couples = await db.collection("couples").get();
  console.log(`Total couples: ${couples.size}\n`);
  const statusCounts = {};
  let completeQueueCandidates = 0;
  for (const doc of couples.docs) {
    const d = doc.data();
    const status = d.status || "(none)";
    statusCounts[status] = (statusCounts[status] || 0) + 1;
    const hasVideo = !!d?.verification?.video_url;
    const hasPhotos = Array.isArray(d.photos) && d.photos.length > 0;
    const queueable =
      status === "pending_review" && hasVideo && hasPhotos;
    if (queueable) completeQueueCandidates++;
    console.log(
      `  ${doc.id} | ${(d.partner_a?.name || "?")} & ${(d.partner_b?.name || "?")} | ${d.city || "?"} | status=${status} | video=${hasVideo} photos=${hasPhotos}`
    );
  }
  console.log("\nStatus distribution:", statusCounts);
  console.log(
    `Couples that pass the new admin-queue filter (video + photos): ${completeQueueCandidates}`
  );

  divider("2. function_audit — every moderateVerification call");
  const audit = await db
    .collection("function_audit")
    .orderBy("at", "desc")
    .limit(20)
    .get();
  if (audit.empty) {
    console.log("  No audit entries — moderateVerification has NOT been called since the new code was deployed.");
  } else {
    for (const doc of audit.docs) {
      const d = doc.data();
      const t = d.at?.toDate?.()?.toISOString?.() || "(no ts)";
      console.log(`  [${t}] ${d.fn || "?"} → ${d.outcome || "?"}`);
      if (d.uid) console.log(`    uid: ${d.uid}`);
      if (d.coupleId) console.log(`    couple: ${d.coupleId}`);
      if (d.error) console.log(`    error: ${d.error}`);
      if (d.trace) console.log(`    trace: ${JSON.stringify(d.trace)}`);
    }
  }

  divider("3. Agency-side collections coexisting in this project");
  for (const c of ["users", "profiles", "community_posts"]) {
    try {
      const snap = await db.collection(c).limit(1).count().get();
      console.log(`  ${c}: ${snap.data().count} docs (sampled to 1 — actual could be larger)`);
    } catch (_) {
      // count() not supported on emulator etc. — fallback
      const snap = await db.collection(c).limit(1).get();
      console.log(`  ${c}: at least ${snap.size} doc(s)`);
    }
  }

  divider("4. Our own ancillary collections");
  for (const c of [
    "reports",
    "blocks",
    "message_requests",
    "conversations",
    "messages",
    "subscriptions",
    "account_recovery_attempts",
    "users_meta",
  ]) {
    try {
      const snap = await db.collection(c).count().get();
      console.log(`  ${c}: ${snap.data().count}`);
    } catch (e) {
      console.log(`  ${c}: ERR ${e.message.slice(0, 60)}`);
    }
  }

  divider("5. Tags + destinations seed data");
  for (const c of ["tags", "destinations"]) {
    try {
      const snap = await db.collection(c).count().get();
      console.log(`  ${c}: ${snap.data().count}`);
    } catch (e) {
      console.log(`  ${c}: ERR ${e.message.slice(0, 60)}`);
    }
  }

  divider("6. Auth users — moderator + demo accounts");
  try {
    for (const email of [
      "affinitysocialclub@gmail.com",
      "demo@affinitysocialclub.com",
    ]) {
      try {
        const u = await admin.auth().getUserByEmail(email);
        console.log(`  ${email}`);
        console.log(`    uid: ${u.uid}`);
        console.log(`    emailVer: ${u.emailVerified}, disabled: ${u.disabled}`);
        console.log(`    claims: ${JSON.stringify(u.customClaims || {})}`);
        console.log(
          `    lastSignIn: ${u.metadata?.lastSignInTime || "(never)"}`
        );
      } catch (e) {
        console.log(`  ${email}: ${e.code || e.message}`);
      }
    }
  } catch (e) {
    console.log(`  auth lookup failed (oauth2 timeout?): ${e.message.slice(0, 100)}`);
  }

  console.log("\nDone.\n");
  process.exit(0);
})().catch((e) => {
  console.error("FATAL:", e.message);
  process.exit(1);
});
