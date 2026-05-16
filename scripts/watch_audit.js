/**
 * Tail the function_audit collection — shows every moderateVerification
 * call attempt with its step trace + outcome. Run while the client tests
 * the admin panel to see exactly what's happening server-side.
 *
 * Usage:
 *   node scripts/watch_audit.js
 *
 * Exits with Ctrl+C.
 */
const admin = require("../functions/node_modules/firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: "affinity-dating-app-cf807",
});

(async () => {
  console.log("Watching function_audit (newest 5 first, then live tail)...\n");

  // Show the most recent 5 entries so we have context.
  const recent = await admin
    .firestore()
    .collection("function_audit")
    .orderBy("at", "desc")
    .limit(5)
    .get();

  if (recent.empty) {
    console.log("(no audit entries yet — the function hasn't been called since the new code deployed)");
  } else {
    console.log("Most recent 5 entries:");
    for (const doc of [...recent.docs].reverse()) {
      const d = doc.data();
      const t = d.at?.toDate?.()?.toISOString?.() || "(no ts)";
      console.log(`\n  [${t}] ${d.fn} → ${d.outcome}`);
      if (d.uid) console.log(`    uid: ${d.uid}`);
      if (d.coupleId) console.log(`    couple: ${d.coupleId}`);
      if (d.claims) console.log(`    claims: ${JSON.stringify(d.claims)}`);
      if (d.error) console.log(`    error: ${d.error}`);
      if (d.trace) console.log(`    trace: ${JSON.stringify(d.trace)}`);
    }
  }

  console.log("\n\nNow live-tailing for new entries (Ctrl+C to stop)...\n");

  const seen = new Set(recent.docs.map((d) => d.id));

  admin
    .firestore()
    .collection("function_audit")
    .orderBy("at", "desc")
    .limit(20)
    .onSnapshot(
      (snap) => {
        for (const change of snap.docChanges()) {
          if (change.type !== "added") continue;
          if (seen.has(change.doc.id)) continue;
          seen.add(change.doc.id);
          const d = change.doc.data();
          const t = d.at?.toDate?.()?.toISOString?.() || "(no ts)";
          console.log(`\n🔔 [${t}] ${d.fn} → ${d.outcome}`);
          if (d.uid) console.log(`   uid: ${d.uid}`);
          if (d.coupleId) console.log(`   couple: ${d.coupleId}`);
          if (d.claims) console.log(`   claims: ${JSON.stringify(d.claims)}`);
          if (d.error) console.log(`   error: ${d.error}`);
          if (d.stack) console.log(`   stack: ${d.stack.slice(0, 500)}`);
          if (d.trace) console.log(`   trace:`);
          if (d.trace) for (const s of d.trace) console.log(`     · ${s}`);
        }
      },
      (err) => {
        console.error("Snapshot listener error:", err.message);
        process.exit(1);
      }
    );
})().catch((e) => {
  console.error("FATAL:", e.message);
  process.exit(1);
});
