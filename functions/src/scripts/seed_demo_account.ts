/**
 * Creates a pre-verified demo couple account for Apple / Google reviewers.
 *
 * The account:
 *   - has `status: approved` so the verification gate is bypassed
 *   - has sample photos + interests so the discovery feed renders properly
 *   - is idempotent — running twice updates rather than duplicating
 *
 * Run (from d:/app/functions):
 *   ts-node src/scripts/seed_demo_account.ts --email=demo@...
 *          --password=... --project=affinity-dev-local
 *
 * Or with emulator:
 *   ts-node src/scripts/seed_demo_account.ts --emulator --email=... --password=...
 *
 * Pastes the credentials back into App Store Connect reviewer notes per
 * [docs/STORE_SUBMISSION.md] "Demo account for reviewers".
 */
import * as admin from "firebase-admin";

const args = process.argv.slice(2);
const flag = (n: string) => args.includes(n);
const val = (n: string): string | undefined => {
  const prefix = `${n}=`;
  const hit = args.find((a) => a.startsWith(prefix));
  return hit ? hit.slice(prefix.length) : undefined;
};

const emailArg = val("--email");
const passwordArg = val("--password");
const projectId = val("--project");
const useEmulator = flag("--emulator");

if (!emailArg || !passwordArg) {
  console.error(
    "Usage: ts-node seed_demo_account.ts --email=<x> --password=<y> [--project=<id>] [--emulator]"
  );
  process.exit(2);
}
// After the guard the values are narrowed to non-null — re-bind as const
// strings so downstream uses don't need `!` assertions.
const email: string = emailArg;
const password: string = passwordArg;

if (useEmulator) {
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
  process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
  process.env.FIREBASE_STORAGE_EMULATOR_HOST = "127.0.0.1:9199";
}

admin.initializeApp(projectId ? { projectId } : undefined);

async function main() {
  const auth = admin.auth();
  const db = admin.firestore();

  // Create or reuse the auth user
  let uid: string;
  try {
    const existing = await auth.getUserByEmail(email);
    uid = existing.uid;
    await auth.updateUser(uid, { password });
    console.log(`demo account exists — reusing uid ${uid} and rotating password`);
  } catch {
    const created = await auth.createUser({
      email,
      password,
      emailVerified: true,
      displayName: "Demo Couple (reviewer)",
    });
    uid = created.uid;
    console.log(`created demo uid ${uid}`);
  }

  // Upsert the couple doc
  const doc = {
    partner_a: { name: "Ana", birth: "14/06/1992", height: "168 cm" },
    partner_b: { name: "Luis", birth: "03/11/1990", height: "180 cm" },
    city: "Ciudad de México",
    country: "Mexico",
    country_code: "MX",
    lat: 19.4326,
    lng: -99.1332,
    geohash: "9g3w9c1r0", // approximate
    description:
      "Adventurous couple excited to meet like-minded couples — travel, " +
      "food, and new friendships.",
    photos: [],
    dynamics: ["Parallel Play"],
    experience_preferences: ["Same Room"],
    interests: ["Travel", "Foodies", "Adventure"],
    status: "approved",
    verification: null,
    age_range: { min: 33, max: 35 },
    deletion_requested_at: null,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    geo: {
      geohash: "9g3w9c1r0",
      geopoint: new admin.firestore.GeoPoint(19.4326, -99.1332),
    },
  };
  await db.collection("couples").doc(uid).set(doc, { merge: true });
  console.log(`demo couples/${uid} written`);

  console.log("\n=== paste into store reviewer notes ===");
  console.log(`Email:    ${email}`);
  console.log(`Password: ${password}`);
  console.log(`Couple ID: ${uid}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
