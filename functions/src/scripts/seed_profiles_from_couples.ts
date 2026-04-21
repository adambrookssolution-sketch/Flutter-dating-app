/**
 * Mirrors seeded `couples/*` docs into the legacy `profiles/*` collection so
 * the current Couples feed (which still reads `profiles`) finds test data.
 *
 * Run (from d:/app/functions):
 *   GOOGLE_APPLICATION_CREDENTIALS=D:\app\sa-key.json node lib/scripts/seed_profiles_from_couples.js --project=affinity-test-f4c84
 *
 * Idempotent — re-running overwrites the same profile doc IDs.
 */
import * as admin from "firebase-admin";

const args = process.argv.slice(2);
const val = (n: string): string | undefined => {
  const prefix = `${n}=`;
  const found = args.find((a) => a.startsWith(prefix));
  return found ? found.slice(prefix.length) : undefined;
};
const projectId = val("--project");
admin.initializeApp(projectId ? { projectId } : undefined);
const db = admin.firestore();

async function main() {
  console.log(`Target: ${projectId ?? "default"}`);
  const couplesSnap = await db.collection("couples").get();
  console.log(`\n=== mirroring ${couplesSnap.size} couples into profiles ===`);
  const batch = db.batch();
  for (const doc of couplesSnap.docs) {
    const c = doc.data();
    // Only mirror approved couples into legacy profiles (feed shows approved).
    if (c.status !== "approved") {
      console.log(`  - skipping ${doc.id} (status=${c.status})`);
      continue;
    }
    const profileRef = db.collection("profiles").doc(doc.id);
    batch.set(profileRef, {
      her_name: c.partner_a?.name ?? "",
      his_name: c.partner_b?.name ?? "",
      her_birth: c.partner_a?.birth ?? "",
      his_birth: c.partner_b?.birth ?? "",
      her_height: c.partner_a?.height ?? "",
      his_height: c.partner_b?.height ?? "",
      city: c.city ?? "",
      description: c.description ?? "",
      interests: Array.isArray(c.interests) ? c.interests.join(", ") : "",
      photos: c.photos ?? [],
    });
    console.log(`  + ${doc.id}: ${c.partner_a?.name} & ${c.partner_b?.name}`);
  }
  await batch.commit();
  console.log("\nDone.");
  process.exit(0);
}
main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});
