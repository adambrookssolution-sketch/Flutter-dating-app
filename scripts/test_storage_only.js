/**
 * Inspect Anni & Stuart's photo + video storage paths to see why the
 * admin panel can't render them. Lists the actual storage objects (if
 * accessible) and the metadata download tokens.
 */
const dns = require("dns");
dns.setDefaultResultOrder("ipv4first");
try { dns.setServers(["8.8.8.8", "1.1.1.1"]); } catch (_) {}

const admin = require("../functions/node_modules/firebase-admin");

const PROJECT_ID = "affinity-dating-app-cf807";
const BUCKET = `${PROJECT_ID}.firebasestorage.app`;
const COUPLE_ID = "XuYUopZlV5Ny7Ku0IB0e8w0NfS63";

admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: PROJECT_ID,
  storageBucket: BUCKET,
});

(async () => {
  console.log("Inspecting couples/" + COUPLE_ID + " photo + video paths...\n");

  const doc = await admin.firestore().collection("couples").doc(COUPLE_ID).get();
  const d = doc.data();
  console.log("photos array:");
  for (const url of (d.photos || [])) {
    const path = decodeURIComponent(url.split("/o/")[1]?.split("?")[0] || "?");
    const token = url.match(/token=([^&]+)/)?.[1];
    console.log(`  · path: ${path}`);
    console.log(`    token: ${token?.slice(0, 12)}…`);
  }
  console.log("\nvideo:");
  const vurl = d.verification?.video_url || "(none)";
  const vpath = decodeURIComponent(vurl.split("/o/")[1]?.split("?")[0] || "?");
  const vtoken = vurl.match(/token=([^&]+)/)?.[1];
  console.log(`  · path: ${vpath}`);
  console.log(`    token: ${vtoken?.slice(0, 12)}…`);
})().catch(e => { console.error(e.message); process.exit(1); });
