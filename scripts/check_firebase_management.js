/**
 * Diagnostic: hits the same Firebase Management endpoint that `firebase
 * deploy --only hosting` calls under the hood to look up project metadata.
 *
 * If this returns 200, the SA + IAM are fine and the workflow failure is
 * elsewhere (firebase-tools version bug, network path on GH runner, etc).
 * If 403, the SA is missing a specific role despite the broader grants.
 * If timeout, the local network can't reach firebase.googleapis.com.
 */
const admin = require("../functions/node_modules/firebase-admin");
const fetch = require("../functions/node_modules/node-fetch");

admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: "affinity-dating-app-cf807",
});

(async () => {
  console.log("Minting access token...");
  const t = await admin.app().options.credential.getAccessToken();
  console.log("  ok, token prefix:", t.access_token.slice(0, 20) + "...");

  const url =
    "https://firebase.googleapis.com/v1beta1/projects/affinity-dating-app-cf807";
  console.log(`GET ${url}`);

  try {
    const r = await fetch(url, {
      headers: { Authorization: "Bearer " + t.access_token },
      timeout: 30000,
    });
    console.log("  HTTP", r.status);
    const body = await r.text();
    console.log("  body:", body.slice(0, 2000));
  } catch (e) {
    console.log("  NETWORK FAIL:", e.message);
  }

  // Also try the hosting-specific endpoint
  const hUrl =
    "https://firebasehosting.googleapis.com/v1beta1/sites/affinity-dating-app-cf807";
  console.log(`\nGET ${hUrl}`);
  try {
    const r = await fetch(hUrl, {
      headers: { Authorization: "Bearer " + t.access_token },
      timeout: 30000,
    });
    console.log("  HTTP", r.status);
    const body = await r.text();
    console.log("  body:", body.slice(0, 2000));
  } catch (e) {
    console.log("  NETWORK FAIL:", e.message);
  }
  process.exit(0);
})().catch((e) => {
  console.error("FATAL:", e.message);
  process.exit(1);
});
