/**
 * Firebase Hosting deploy via direct REST API — bypasses firebase CLI.
 *
 * Why this exists: the user's local PowerShell environment has lost
 * firebase-tools after a user-profile reset, npm install fails with
 * socket timeouts on the unstable connection, and the firepit standalone
 * binary's first-run setup also times out. The REST API path issues many
 * small requests with explicit retry instead of one long socket session,
 * which survives transient network instability that breaks firebase CLI.
 *
 * Uses firebase-admin (already in functions/node_modules) only to mint an
 * OAuth access token from the production SA key; everything else is
 * straight HTTPS to https://firebasehosting.googleapis.com/v1beta1.
 *
 * Run from D:\app:
 *   node scripts/deploy_admin_hosting.js
 */
const admin = require("../functions/node_modules/firebase-admin");
const fetch = require("../functions/node_modules/node-fetch");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const zlib = require("zlib");

const SA_KEY = "D:/app/sa-key-prod.json";
const PROJECT_ID = "affinity-dating-app-cf807";
const SITE_ID = "affinity-dating-app-cf807";
const WEB_DIR = "D:/app/build/web";

if (!fs.existsSync(WEB_DIR)) {
  console.error(`FAIL: ${WEB_DIR} not found — run "flutter build web" first.`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(SA_KEY)),
  projectId: PROJECT_ID,
});

async function withRetry(label, fn, attempts = 6) {
  let lastErr;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      lastErr = e;
      const wait = Math.min(2000 * Math.pow(2, i), 30000);
      console.log(
        `  [${label}] attempt ${i + 1}/${attempts} failed (${e.message}); retrying in ${wait}ms`
      );
      await new Promise((r) => setTimeout(r, wait));
    }
  }
  throw lastErr;
}

async function getAccessToken() {
  const t = await admin.app().options.credential.getAccessToken();
  return t.access_token;
}

function walkDir(dir, base = dir, files = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walkDir(full, base, files);
    else {
      const rel = "/" + path.relative(base, full).replace(/\\/g, "/");
      files.push({ rel, full });
    }
  }
  return files;
}

function fmtBytes(n) {
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / 1024 / 1024).toFixed(2)} MB`;
}

async function main() {
  console.log("=== Affinity admin hosting deploy via REST ===");
  console.log(`Project: ${PROJECT_ID}`);
  console.log(`Site:    ${SITE_ID}`);
  console.log(`Source:  ${WEB_DIR}`);
  console.log("");

  console.log("[1/8] Minting access token from SA key...");
  const token = await withRetry("token", () => getAccessToken());
  console.log("      ok");

  console.log("[2/8] Walking source tree...");
  const files = walkDir(WEB_DIR);
  console.log(`      ${files.length} files found`);

  console.log("[3/8] Hashing + gzipping each file...");
  const manifest = {};
  const blobs = new Map(); // hash -> gzipped Buffer
  let totalGz = 0;
  for (const f of files) {
    const data = fs.readFileSync(f.full);
    const gz = zlib.gzipSync(data, { level: 9 });
    const hash = crypto.createHash("sha256").update(gz).digest("hex");
    manifest[f.rel] = hash;
    if (!blobs.has(hash)) {
      blobs.set(hash, gz);
      totalGz += gz.length;
    }
  }
  console.log(`      ${blobs.size} unique blobs, ${fmtBytes(totalGz)} total compressed`);

  const baseUrl = "https://firebasehosting.googleapis.com/v1beta1";

  console.log("[4/8] Creating new version...");
  const versionRes = await withRetry("createVersion", async () => {
    const r = await fetch(`${baseUrl}/sites/${SITE_ID}/versions`, {
      method: "POST",
      headers: {
        Authorization: "Bearer " + token,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ config: {} }),
      timeout: 60000,
    });
    if (!r.ok) throw new Error(`createVersion HTTP ${r.status}: ${await r.text()}`);
    return r.json();
  });
  const versionName = versionRes.name; // sites/{site}/versions/{vid}
  console.log(`      ${versionName}`);

  console.log("[5/8] Posting file manifest (populateFiles)...");
  const popRes = await withRetry("populateFiles", async () => {
    const r = await fetch(`${baseUrl}/${versionName}:populateFiles`, {
      method: "POST",
      headers: {
        Authorization: "Bearer " + token,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ files: manifest }),
      timeout: 120000,
    });
    if (!r.ok) throw new Error(`populateFiles HTTP ${r.status}: ${await r.text()}`);
    return r.json();
  });
  const required = popRes.uploadRequiredHashes || [];
  const uploadBase = popRes.uploadUrl; // base URL for blob uploads
  console.log(`      ${required.length} blobs need uploading (${fmtBytes(required.reduce((s, h) => s + (blobs.get(h)?.length || 0), 0))})`);

  console.log("[6/8] Uploading blobs...");
  for (let i = 0; i < required.length; i++) {
    const hash = required[i];
    const buf = blobs.get(hash);
    process.stdout.write(`      ${i + 1}/${required.length} ${hash.slice(0, 8)} (${fmtBytes(buf.length)})... `);
    await withRetry(`upload ${hash.slice(0, 8)}`, async () => {
      const r = await fetch(`${uploadBase}/${hash}`, {
        method: "POST",
        headers: {
          Authorization: "Bearer " + token,
          "Content-Type": "application/octet-stream",
        },
        body: buf,
        timeout: 180000,
      });
      if (!r.ok) throw new Error(`upload HTTP ${r.status}: ${await r.text()}`);
    });
    process.stdout.write("ok\n");
  }

  console.log("[7/8] Finalizing version...");
  await withRetry("finalize", async () => {
    const r = await fetch(`${baseUrl}/${versionName}?update_mask=status`, {
      method: "PATCH",
      headers: {
        Authorization: "Bearer " + token,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ status: "FINALIZED" }),
      timeout: 60000,
    });
    if (!r.ok) throw new Error(`finalize HTTP ${r.status}: ${await r.text()}`);
  });
  console.log("      ok");

  console.log("[8/8] Releasing version...");
  await withRetry("release", async () => {
    const r = await fetch(
      `${baseUrl}/sites/${SITE_ID}/releases?versionName=${encodeURIComponent(versionName)}`,
      {
        method: "POST",
        headers: { Authorization: "Bearer " + token },
        timeout: 60000,
      }
    );
    if (!r.ok) throw new Error(`release HTTP ${r.status}: ${await r.text()}`);
  });
  console.log("      ok");

  console.log("");
  console.log("✓ Deploy complete!");
  console.log(`  https://${SITE_ID}.web.app`);
}

main().catch((e) => {
  console.error("\nFATAL:", e.message);
  if (e.stack) console.error(e.stack);
  process.exit(1);
});
