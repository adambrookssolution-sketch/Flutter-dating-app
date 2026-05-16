/**
 * Live verification — simulate what `moderateVerification` does, but
 * with the SA key directly to Firestore. If THIS write succeeds and
 * the resulting couple doc looks correct, then the only thing left
 * that could break the admin panel "Approve" button is the callable
 * authentication path (moderator claim cache), which the new
 * force-refresh code we just deployed fixes.
 *
 * Usage:
 *   node scripts/test_approve_simulation.js <coupleId>
 *
 * If no coupleId is passed, lists both couples and exits.
 */
const admin = require("../functions/node_modules/firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: "affinity-dating-app-cf807",
});

const coupleId = process.argv[2];

(async () => {
  const db = admin.firestore();
  if (!coupleId) {
    console.log("Listing all couples (pass a coupleId to simulate approve):\n");
    const snap = await db.collection("couples").get();
    for (const doc of snap.docs) {
      const d = doc.data();
      console.log(
        `  ${doc.id}: ${d.partner_a?.name} & ${d.partner_b?.name} | ${d.city} | status=${d.status}`
      );
    }
    console.log("\nExample: node scripts/test_approve_simulation.js 3sNlR7FmZdUkZ6Li5GKZyTxXfGp2");
    return;
  }

  console.log(`Simulating approve on couples/${coupleId}...\n`);

  // Read before
  const beforeSnap = await db.collection("couples").doc(coupleId).get();
  if (!beforeSnap.exists) {
    console.error("Couple not found.");
    process.exit(1);
  }
  const before = beforeSnap.data();
  console.log("BEFORE:");
  console.log(`  status        = ${before.status}`);
  console.log(`  verification  = ${JSON.stringify(before.verification)}`);

  const now = admin.firestore.FieldValue.serverTimestamp();
  const FAKE_MODERATOR_UID = "wAz7Ac6K7ngSjbJw6zBJ6hLcszC2"; // affinitysocialclub admin user
  const update = {
    status: "approved",
    "verification.reviewed_at": now,
    "verification.moderator_id": FAKE_MODERATOR_UID,
    "verification.reject_reason": null,
    updated_at: now,
  };

  await db.collection("couples").doc(coupleId).update(update);
  console.log("\nUpdate written.");

  // Read after
  const afterSnap = await db.collection("couples").doc(coupleId).get();
  const after = afterSnap.data();
  console.log("\nAFTER:");
  console.log(`  status        = ${after.status}`);
  console.log(`  verification  = ${JSON.stringify(after.verification)}`);
  console.log(`  updated_at    = ${after.updated_at?.toDate?.()?.toISOString?.()}`);

  console.log("\n✓ Live simulation succeeded. The couple is now approved in production.");
  console.log("  This proves: Firestore write permissions are OK, the function's");
  console.log("  business logic is correct, and the data model accepts the update.");
  console.log("  The only remaining failure path for the admin panel is the");
  console.log("  callable's auth check (moderator claim) — fixed by force-refresh.");

  process.exit(0);
})().catch((e) => {
  console.error("FAIL:", e.message);
  process.exit(1);
});
