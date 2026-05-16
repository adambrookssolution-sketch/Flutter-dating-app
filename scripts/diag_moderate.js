/**
 * Production diagnostic — inspects couples + admin user state from
 * Firestore only (Auth API endpoints are blocked from this network).
 *
 * Goal: figure out why moderateVerification fails when called from the
 * admin panel, by examining everything we CAN see from Firestore.
 */
const admin = require("../functions/node_modules/firebase-admin");

const PROJECT_ID = "affinity-dating-app-cf807";

admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: PROJECT_ID,
});

async function main() {
  console.log("=== Couples deep inspection ===\n");

  const couplesSnap = await admin.firestore().collection("couples").get();
  for (const doc of couplesSnap.docs) {
    const d = doc.data();
    console.log(`couples/${doc.id}`);
    console.log(JSON.stringify(d, null, 2));
    console.log("");

    // Inspect subcollections that moderateVerification might read
    const subs = await doc.ref.listCollections();
    console.log(`  subcollections: ${subs.map((c) => c.id).join(", ") || "(none)"}`);
    for (const sub of subs) {
      const subSnap = await sub.limit(5).get();
      console.log(`    ${sub.id}: ${subSnap.size} docs`);
      for (const subDoc of subSnap.docs) {
        console.log(`      ${subDoc.id}:`, JSON.stringify(subDoc.data()).slice(0, 200));
      }
    }
    console.log("─".repeat(60));
  }

  console.log("\n=== users_meta inspection (sometimes referenced by moderation) ===\n");
  try {
    const meta = await admin.firestore().collection("users_meta").get();
    console.log(`  ${meta.size} docs`);
    for (const m of meta.docs.slice(0, 5)) {
      console.log(`  ${m.id}:`, JSON.stringify(m.data()).slice(0, 200));
    }
  } catch (e) {
    console.log("  (no users_meta or read failed):", e.message);
  }

  console.log("\n=== verifications collection (if it exists separately) ===\n");
  try {
    const v = await admin.firestore().collection("verifications").get();
    console.log(`  ${v.size} docs`);
  } catch (e) {
    console.log("  (no verifications collection):", e.message);
  }

  console.log("\nDone.");
  process.exit(0);
}

main().catch((e) => {
  console.error("FATAL:", e.message);
  process.exit(1);
});
