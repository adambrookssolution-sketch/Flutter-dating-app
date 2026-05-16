const admin = require("../functions/node_modules/firebase-admin");
const fetch = require("../functions/node_modules/node-fetch");

admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: "affinity-dating-app-cf807",
});

(async () => {
  const t = await admin.app().options.credential.getAccessToken();
  console.log("Token obtained, length:", t.access_token.length);

  // Cloud Functions v2 metadata
  const url = "https://cloudfunctions.googleapis.com/v2/projects/affinity-dating-app-cf807/locations/us-central1/functions/moderateVerification";
  try {
    const r = await fetch(url, {
      headers: { Authorization: "Bearer " + t.access_token },
      timeout: 30000,
    });
    const j = await r.json();
    console.log("HTTP", r.status);
    console.log("Function metadata:");
    console.log("  name:", j.name);
    console.log("  state:", j.state);
    console.log("  updateTime:", j.updateTime);
    console.log("  buildConfig.runtime:", j.buildConfig?.runtime);
    console.log("  buildConfig.entryPoint:", j.buildConfig?.entryPoint);
    console.log("  buildConfig.build:", j.buildConfig?.build);
    console.log("  serviceConfig.uri:", j.serviceConfig?.uri);
  } catch (e) {
    console.log("FAIL:", e.message);
  }
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
