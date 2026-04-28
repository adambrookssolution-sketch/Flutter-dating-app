/**
 * Creates/updates a `couples/{uid}` document with status='approved' so the
 * user can pass `isApproved()` rule checks (needed for message_requests,
 * reports, trips, etc.).
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=D:\app\sa-key.json \
 *     node lib/scripts/promote_user_to_approved.js \
 *     --project=affinity-test-f4c84 \
 *     --uid=uAmjfWGdv3gtng4aVETaegBydv43
 */
import * as admin from "firebase-admin";

const args = process.argv.slice(2);
const val = (n: string): string | undefined => {
  const prefix = `${n}=`;
  const found = args.find((a) => a.startsWith(prefix));
  return found ? found.slice(prefix.length) : undefined;
};
const projectId = val("--project");
const uid = val("--uid");
if (!uid) {
  console.error("Missing --uid=<firebase auth uid>");
  process.exit(1);
}
admin.initializeApp(projectId ? { projectId } : undefined);
const db = admin.firestore();

async function main() {
  console.log(`Target: ${projectId ?? "default"}, uid=${uid}`);

  // Read existing profile (from the legacy collection) so we mirror the user's
  // real data into the couples doc — keeps the UI consistent.
  const profileDoc = await db.collection("profiles").doc(uid!).get();
  const p = profileDoc.exists ? profileDoc.data()! : {};

  const couplesRef = db.collection("couples").doc(uid!);
  await couplesRef.set(
    {
      partner_a: {
        name: p.her_name ?? "Her",
        birth: p.her_birth ?? "1995-01-01",
        height: p.her_height ?? "165 cm",
      },
      partner_b: {
        name: p.his_name ?? "Him",
        birth: p.his_birth ?? "1993-01-01",
        height: p.his_height ?? "180 cm",
      },
      city: p.city ?? "Mexico City",
      country: "Mexico",
      country_code: "MX",
      lat: 19.4326,
      lng: -99.1332,
      geohash: "9g3w9",
      description: p.description ?? "",
      photos: p.photos ?? [],
      interests:
        typeof p.interests === "string"
          ? p.interests
              .split(",")
              .map((s: string) => s.trim())
              .filter((s: string) => s.length > 0)
          : [],
      open_to_unicorn: false,
      open_to_bull: false,
      status: "approved",
      verification: null,
      age_range: { min: 28, max: 38 },
      deletion_requested_at: null,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      geo: {
        geohash: "9g3w9",
        geopoint: new admin.firestore.GeoPoint(19.4326, -99.1332),
      },
    },
    { merge: true }
  );

  console.log(`  + couples/${uid} upgraded to status=approved`);
  console.log("Done.");
  process.exit(0);
}
main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});
