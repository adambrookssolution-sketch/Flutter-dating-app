const admin = require("../functions/node_modules/firebase-admin");
admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: "affinity-dating-app-cf807",
});
(async () => {
  const snap = await admin.firestore().collection("function_audit").orderBy("at", "desc").limit(5).get();
  console.log(`Total recent audit docs: ${snap.size}\n`);
  for (const doc of snap.docs) {
    const d = doc.data();
    const t = d.at?.toDate?.()?.toISOString?.() || "(no ts)";
    console.log("=".repeat(70));
    console.log(`[${t}] ${d.fn} → ${d.outcome}`);
    if (d.uid) console.log(`  uid: ${d.uid}`);
    if (d.coupleId) console.log(`  couple: ${d.coupleId}`);
    if (d.claims) console.log(`  claims: ${JSON.stringify(d.claims)}`);
    if (d.error) console.log(`  error: ${d.error}`);
    if (d.stack) console.log(`  stack: ${d.stack.substring(0, 800)}`);
    if (d.trace) {
      console.log(`  trace:`);
      for (const s of d.trace) console.log(`    · ${s}`);
    }
  }
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
