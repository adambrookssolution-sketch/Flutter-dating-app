/**
 * AFFINITY — Migration script: `profiles/*` -> `couples/*`
 *
 * Reads every legacy `profiles/{uid}` document, converts it to the new
 * `couples/{coupleId}` schema (split CSV interests, geocode city, compute
 * geohash + age range, default to status=approved so existing users are
 * grandfathered), and writes the result.
 *
 * Run modes:
 *   --dry-run            : print conversions, write nothing (default)
 *   --write              : actually write to Firestore
 *   --delete-old         : after a successful --write, delete the legacy
 *                          `profiles/*` documents (only run after manual spot-check)
 *   --emulator           : target the local emulator instead of dev/prod
 *   --project=<id>       : override project ID (default: from .firebaserc)
 *   --geocode-key=<key>  : Google Places API key (Server) for geocoding
 *
 * Examples:
 *   ts-node migrate_profiles_to_couples.ts --dry-run --emulator
 *   ts-node migrate_profiles_to_couples.ts --write --geocode-key=$GCP_KEY
 *   ts-node migrate_profiles_to_couples.ts --delete-old
 *
 * IMPORTANT: never run --delete-old on production until you've spot-checked
 * at least 5 random `couples/*` documents and confirmed all fields populated.
 */
import * as admin from "firebase-admin";
import * as ngeohash from "ngeohash";

// ── CLI parsing ──────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const flag = (name: string) => args.includes(name);
const value = (name: string): string | undefined => {
  const prefix = `${name}=`;
  const found = args.find((a) => a.startsWith(prefix));
  return found ? found.slice(prefix.length) : undefined;
};

const dryRun = !flag("--write") && !flag("--delete-old");
const deleteOld = flag("--delete-old");
const useEmulator = flag("--emulator");
const projectId = value("--project");
const geocodeKey = value("--geocode-key") ?? process.env.GCP_PLACES_KEY;

// ── Firebase Admin init ──────────────────────────────────────────────────────
if (useEmulator) {
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
}
admin.initializeApp(projectId ? { projectId } : undefined);
const db = admin.firestore();

// ── Helpers ──────────────────────────────────────────────────────────────────

interface LegacyProfile {
  her_name?: string;
  his_name?: string;
  her_birth?: string;
  his_birth?: string;
  city?: string;
  her_height?: string;
  his_height?: string;
  description?: string;
  interests?: string;
  photos?: string[];
}

interface GeocodeResult {
  lat: number;
  lng: number;
  country: string;
  countryCode: string;
  formattedCity: string;
}

/**
 * Geocode a city string via Google Geocoding API. Returns null on failure
 * (caller should keep going with city-only data; GeoHash will be empty and
 * the couple won't appear in proximity-based filters until they re-edit).
 */
async function geocodeCity(
  city: string,
  apiKey: string
): Promise<GeocodeResult | null> {
  if (!city.trim()) return null;
  const url =
    `https://maps.googleapis.com/maps/api/geocode/json?address=` +
    `${encodeURIComponent(city)}&key=${apiKey}`;
  try {
    const resp = await fetch(url);
    const json = (await resp.json()) as {
      status: string;
      results: Array<{
        geometry: { location: { lat: number; lng: number } };
        address_components: Array<{
          long_name: string;
          short_name: string;
          types: string[];
        }>;
        formatted_address: string;
      }>;
    };
    if (json.status !== "OK" || json.results.length === 0) return null;
    const r = json.results[0];
    const country = r.address_components.find((c) =>
      c.types.includes("country")
    );
    const locality =
      r.address_components.find((c) => c.types.includes("locality")) ??
      r.address_components.find((c) =>
        c.types.includes("administrative_area_level_1")
      );
    return {
      lat: r.geometry.location.lat,
      lng: r.geometry.location.lng,
      country: country?.long_name ?? "",
      countryCode: country?.short_name ?? "",
      formattedCity: locality?.long_name ?? city,
    };
  } catch (err) {
    console.warn(`  geocode failed for "${city}":`, err);
    return null;
  }
}

function parseDdmmyyyy(s?: string): Date | null {
  if (!s) return null;
  const parts = s.split("/");
  if (parts.length !== 3) return null;
  const [d, m, y] = parts.map((p) => parseInt(p, 10));
  if (Number.isNaN(d) || Number.isNaN(m) || Number.isNaN(y)) return null;
  const date = new Date(Date.UTC(y, m - 1, d));
  return Number.isNaN(date.getTime()) ? null : date;
}

function ageFromBirth(birth?: string, today: Date = new Date()): number {
  const d = parseDdmmyyyy(birth);
  if (!d) return 0;
  let age = today.getUTCFullYear() - d.getUTCFullYear();
  const m = today.getUTCMonth() - d.getUTCMonth();
  if (m < 0 || (m === 0 && today.getUTCDate() < d.getUTCDate())) age--;
  return age < 0 ? 0 : age;
}

function splitCsvInterests(csv?: string): string[] {
  if (!csv) return [];
  return csv
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

// ── Main migration ───────────────────────────────────────────────────────────

interface MigrationStats {
  total: number;
  converted: number;
  skipped: number;
  geocoded: number;
  geocodeFailed: number;
  errors: Array<{ uid: string; reason: string }>;
}

async function migrate(): Promise<MigrationStats> {
  console.log(`\n=== AFFINITY migration: profiles -> couples ===`);
  console.log(`Mode:        ${dryRun ? "DRY-RUN" : deleteOld ? "DELETE-OLD" : "WRITE"}`);
  console.log(`Target:      ${useEmulator ? "EMULATOR (127.0.0.1:8080)" : projectId ?? "default"}`);
  console.log(`Geocoding:   ${geocodeKey ? "ENABLED" : "DISABLED (city-only data)"}`);
  console.log("");

  const stats: MigrationStats = {
    total: 0,
    converted: 0,
    skipped: 0,
    geocoded: 0,
    geocodeFailed: 0,
    errors: [],
  };

  if (deleteOld) {
    return await deleteLegacyProfiles(stats);
  }

  const snap = await db.collection("profiles").get();
  stats.total = snap.size;
  console.log(`Found ${stats.total} legacy profile documents.\n`);

  const batch = db.batch();
  let batchCount = 0;
  const BATCH_LIMIT = 400; // Firestore hard limit is 500; leave headroom

  for (const doc of snap.docs) {
    const uid = doc.id;
    const legacy = doc.data() as LegacyProfile;
    try {
      // Skip if already migrated (idempotency)
      const existing = await db.collection("couples").doc(uid).get();
      if (existing.exists) {
        console.log(`  [skip] ${uid} — already exists in couples/`);
        stats.skipped++;
        continue;
      }

      // Geocode (best-effort)
      let lat: number | null = null;
      let lng: number | null = null;
      let country = "";
      let countryCode = "";
      let geohash: string | null = null;
      let cityFinal = legacy.city ?? "";

      if (geocodeKey && legacy.city) {
        const geo = await geocodeCity(legacy.city, geocodeKey);
        if (geo) {
          lat = geo.lat;
          lng = geo.lng;
          country = geo.country;
          countryCode = geo.countryCode;
          cityFinal = geo.formattedCity;
          geohash = ngeohash.encode(lat, lng, 9);
          stats.geocoded++;
        } else {
          stats.geocodeFailed++;
        }
      }

      const ageA = ageFromBirth(legacy.her_birth);
      const ageB = ageFromBirth(legacy.his_birth);

      const couple = {
        partner_a: {
          name: legacy.her_name ?? "",
          birth: legacy.her_birth ?? "",
          height: legacy.her_height ?? "",
        },
        partner_b: {
          name: legacy.his_name ?? "",
          birth: legacy.his_birth ?? "",
          height: legacy.his_height ?? "",
        },
        city: cityFinal,
        country,
        country_code: countryCode,
        lat,
        lng,
        geohash,
        description: legacy.description ?? "",
        photos: legacy.photos ?? [],
        dynamics: [], // unknown from legacy — user fills on next edit
        experience_preferences: [], // unknown from legacy
        interests: splitCsvInterests(legacy.interests),
        status: "approved", // grandfather existing users
        verification: null, // existing users grandfathered out of verification
        age_range: { min: Math.min(ageA, ageB), max: Math.max(ageA, ageB) },
        deletion_requested_at: null,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      console.log(`  [${dryRun ? "dry" : "write"}] ${uid} — ${cityFinal}, ${country}`);

      if (!dryRun) {
        batch.set(db.collection("couples").doc(uid), couple);
        batchCount++;
        if (batchCount >= BATCH_LIMIT) {
          await batch.commit();
          batchCount = 0;
        }
      }
      stats.converted++;
    } catch (err) {
      console.error(`  [error] ${uid}:`, err);
      stats.errors.push({ uid, reason: String(err) });
    }
  }

  if (!dryRun && batchCount > 0) {
    await batch.commit();
  }

  return stats;
}

async function deleteLegacyProfiles(
  stats: MigrationStats
): Promise<MigrationStats> {
  console.log("=== DELETE-OLD mode ===");
  console.log("Verifying every profiles/* doc has a corresponding couples/* doc...\n");

  const snap = await db.collection("profiles").get();
  stats.total = snap.size;
  const missing: string[] = [];
  for (const doc of snap.docs) {
    const exists = await db.collection("couples").doc(doc.id).get();
    if (!exists.exists) missing.push(doc.id);
  }

  if (missing.length > 0) {
    console.error(`ABORT: ${missing.length} profiles have no matching couple:`);
    missing.slice(0, 10).forEach((id) => console.error(`  - ${id}`));
    process.exit(2);
  }

  console.log(`All ${stats.total} profiles confirmed migrated. Deleting legacy collection...`);

  const batch = db.batch();
  let batchCount = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    batchCount++;
    if (batchCount >= 400) {
      await batch.commit();
      batchCount = 0;
    }
  }
  if (batchCount > 0) await batch.commit();

  console.log(`Deleted ${stats.total} legacy profile documents.`);
  stats.converted = stats.total;
  return stats;
}

// ── Entry ────────────────────────────────────────────────────────────────────
migrate()
  .then((stats) => {
    console.log("\n=== Migration summary ===");
    console.log(`Total legacy profiles:  ${stats.total}`);
    console.log(`Converted:              ${stats.converted}`);
    console.log(`Skipped (already done): ${stats.skipped}`);
    console.log(`Geocoded:               ${stats.geocoded}`);
    console.log(`Geocode failed:         ${stats.geocodeFailed}`);
    console.log(`Errors:                 ${stats.errors.length}`);
    if (stats.errors.length > 0) {
      console.log("\nErrors:");
      stats.errors.forEach((e) => console.log(`  ${e.uid}: ${e.reason}`));
    }
    process.exit(stats.errors.length > 0 ? 1 : 0);
  })
  .catch((err) => {
    console.error("FATAL:", err);
    process.exit(2);
  });
