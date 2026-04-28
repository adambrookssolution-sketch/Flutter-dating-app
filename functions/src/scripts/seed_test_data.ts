/**
 * Seeds the dev Firestore (or emulator) with realistic test data so the
 * APK has something to render on first launch.
 *
 * Writes:
 *   - 5 sample couples (mix of statuses: 4 approved + 1 pending_review)
 *   - 10 lifestyle Travel Match destinations
 *   - 14 tags across 3 categories
 *
 * Run (from d:/app/functions):
 *   npm run build
 *   node lib/scripts/seed_test_data.js --project=<project-id>
 *
 * Or against the local emulator:
 *   node lib/scripts/seed_test_data.js --emulator
 *
 * Idempotent — re-running overwrites existing docs with the same IDs so the
 * data set always reaches a known good baseline.
 */
import * as admin from "firebase-admin";

const args = process.argv.slice(2);
const flag = (n: string) => args.includes(n);
const val = (n: string): string | undefined => {
  const prefix = `${n}=`;
  const found = args.find((a) => a.startsWith(prefix));
  return found ? found.slice(prefix.length) : undefined;
};

const projectId = val("--project");
const useEmulator = flag("--emulator");

if (useEmulator) {
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
  process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
}

admin.initializeApp(projectId ? { projectId } : undefined);

const db = admin.firestore();

// ── Couples ──────────────────────────────────────────────────────────────────

interface SeedCouple {
  id: string;
  partner_a_name: string;
  partner_b_name: string;
  partner_a_birth: string;
  partner_b_birth: string;
  city: string;
  country: string;
  country_code: string;
  lat: number;
  lng: number;
  geohash: string;
  description: string;
  interests: string[];
  open_to_unicorn: boolean;
  open_to_bull: boolean;
  status: string;
}

const couples: SeedCouple[] = [
  {
    id: "demo_ana_luis",
    partner_a_name: "Ana",
    partner_b_name: "Luis",
    partner_a_birth: "14/06/1992",
    partner_b_birth: "03/11/1990",
    city: "Ciudad de México",
    country: "Mexico",
    country_code: "MX",
    lat: 19.4326,
    lng: -99.1332,
    geohash: "9g3w9c1r0",
    description:
      "Pareja aventurera mexicana — viajeros, foodies y curiosos. " +
      "Buscamos parejas con mente abierta para conocernos.",
    interests: [
      "Parallel Play", "Soft Swap",
      "Same Room", "Voyeur Couple",
      "Voyeur",
    ],
    open_to_unicorn: true,
    open_to_bull: false,
    status: "approved",
  },
  {
    id: "demo_maria_carlos",
    partner_a_name: "María",
    partner_b_name: "Carlos",
    partner_a_birth: "22/09/1988",
    partner_b_birth: "11/04/1985",
    city: "Guadalajara",
    country: "Mexico",
    country_code: "MX",
    lat: 20.6597,
    lng: -103.3496,
    geohash: "9eweqgygc",
    description:
      "Disfrutamos las cenas largas, los hoteles bonitos y conversar " +
      "con parejas que también disfrutan la vida lifestyle con respeto.",
    interests: [
      "Full Swap",
      "Same Room", "Exhibition Couple",
      "Exhibitionist",
    ],
    open_to_unicorn: false,
    open_to_bull: true,
    status: "approved",
  },
  {
    id: "demo_sofia_diego",
    partner_a_name: "Sofía",
    partner_b_name: "Diego",
    partner_a_birth: "30/01/1994",
    partner_b_birth: "17/07/1991",
    city: "Buenos Aires",
    country: "Argentina",
    country_code: "AR",
    lat: -34.6037,
    lng: -58.3816,
    geohash: "69y7p8f5p",
    description:
      "Pareja porteña curiosa — recién entrando al lifestyle. Queremos " +
      "amistad primero, lo demás se da o no se da.",
    interests: [
      "Parallel Play",
      "Separate Rooms",
      "Curious",
    ],
    open_to_unicorn: false,
    open_to_bull: false,
    status: "approved",
  },
  {
    id: "demo_isabella_pablo",
    partner_a_name: "Isabella",
    partner_b_name: "Pablo",
    partner_a_birth: "08/12/1989",
    partner_b_birth: "25/05/1987",
    city: "Bogotá",
    country: "Colombia",
    country_code: "CO",
    lat: 4.711,
    lng: -74.0721,
    geohash: "d2g6gzwcf",
    description:
      "Bogotanos viajeros. Vamos seguido a Cancún y Cartagena. Si tienen " +
      "viaje planeado escribinos!",
    interests: [
      "Soft Swap", "Full Swap",
      "Same Room", "Voyeur Couple",
    ],
    open_to_unicorn: true,
    open_to_bull: true,
    status: "approved",
  },
  {
    id: "demo_pending_couple",
    partner_a_name: "Lucía",
    partner_b_name: "Mateo",
    partner_a_birth: "12/03/1996",
    partner_b_birth: "29/08/1993",
    city: "Lima",
    country: "Peru",
    country_code: "PE",
    lat: -12.0464,
    lng: -77.0428,
    geohash: "6mc2hcg2v",
    description:
      "Pareja peruana en proceso de verificación — para probar el flujo " +
      "de moderación.",
    interests: ["Curious"],
    open_to_unicorn: false,
    open_to_bull: false,
    status: "pending_review",
  },
];

async function seedCouples() {
  console.log(`\n=== seeding ${couples.length} couples ===`);
  const batch = db.batch();
  for (const c of couples) {
    const ref = db.collection("couples").doc(c.id);
    batch.set(ref, {
      partner_a: { name: c.partner_a_name, birth: c.partner_a_birth, height: "168 cm" },
      partner_b: { name: c.partner_b_name, birth: c.partner_b_birth, height: "180 cm" },
      city: c.city,
      country: c.country,
      country_code: c.country_code,
      lat: c.lat,
      lng: c.lng,
      geohash: c.geohash,
      description: c.description,
      photos: [],
      interests: c.interests,
      open_to_unicorn: c.open_to_unicorn,
      open_to_bull: c.open_to_bull,
      status: c.status,
      verification:
        c.status === "pending_review"
          ? {
              video_url: "https://example.com/placeholder.mp4",
              sent_at: admin.firestore.FieldValue.serverTimestamp(),
              attempts: 1,
            }
          : null,
      age_range: { min: 28, max: 38 },
      deletion_requested_at: null,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      geo: {
        geohash: c.geohash,
        geopoint: new admin.firestore.GeoPoint(c.lat, c.lng),
      },
    });
    console.log(`  + ${c.id}: ${c.partner_a_name} & ${c.partner_b_name} (${c.status})`);
  }
  await batch.commit();
}

// ── Destinations ────────────────────────────────────────────────────────────

const destinations = [
  { id: "hedonism_ii", name: "Hedonism II", kind: "resort", country: "Jamaica", country_code: "JM", order: 0 },
  { id: "desire_riviera_maya", name: "Desire Riviera Maya", kind: "resort", country: "Mexico", country_code: "MX", order: 1 },
  { id: "desire_pearl", name: "Desire Pearl", kind: "resort", country: "Mexico", country_code: "MX", order: 2 },
  { id: "temptation_cancun", name: "Temptation Cancun", kind: "resort", country: "Mexico", country_code: "MX", order: 3 },
  { id: "cap_dagde", name: "Cap d'Agde Naturist Village", kind: "resort", country: "France", country_code: "FR", order: 4 },
  { id: "bliss_cruise", name: "Bliss Cruise", kind: "cruise", country: "International", country_code: "", order: 5 },
  { id: "original_sin_cruise", name: "Original Sin Cruise", kind: "cruise", country: "International", country_code: "", order: 6 },
  { id: "naughty_in_nawlins", name: "Naughty in N'Awlins", kind: "event", country: "United States", country_code: "US", order: 7 },
  { id: "sdc_takeover", name: "SDC Takeover", kind: "event", country: "International", country_code: "", order: 8 },
  { id: "lifestyles_convention", name: "Lifestyles Convention", kind: "event", country: "United States", country_code: "US", order: 9 },
];

async function seedDestinations() {
  console.log(`\n=== seeding ${destinations.length} destinations ===`);
  const batch = db.batch();
  for (const d of destinations) {
    const ref = db.collection("destinations").doc(d.id);
    batch.set(ref, d);
    console.log(`  + ${d.id}: ${d.name}`);
  }
  await batch.commit();
}

// ── Tags ────────────────────────────────────────────────────────────────────

const tags = [
  // Dynamics
  { id: "dyn_parallel", name: "Parallel Play", category: "dynamics", order: 0 },
  { id: "dyn_soft_swap", name: "Soft Swap", category: "dynamics", order: 1 },
  { id: "dyn_full_swap", name: "Full Swap", category: "dynamics", order: 2 },
  // Experience
  { id: "exp_same_room", name: "Same Room", category: "experience", order: 0 },
  { id: "exp_separate_rooms", name: "Separate Rooms", category: "experience", order: 1 },
  { id: "exp_voyeur_couple", name: "Voyeur Couple", category: "experience", order: 2 },
  { id: "exp_exhibition_couple", name: "Exhibition Couple", category: "experience", order: 3 },
  // Interests
  { id: "int_voyeur", name: "Voyeur", category: "interests", order: 0 },
  { id: "int_exhibitionist", name: "Exhibitionist", category: "interests", order: 1 },
  { id: "int_kinky", name: "Kinky", category: "interests", order: 2 },
  { id: "int_hot_wife", name: "Hot Wife", category: "interests", order: 3 },
  { id: "int_curious", name: "Curious", category: "interests", order: 4 },
  { id: "int_travel", name: "Travel", category: "interests", order: 5 },
  { id: "int_foodies", name: "Foodies", category: "interests", order: 6 },
];

async function seedTags() {
  console.log(`\n=== seeding ${tags.length} tags ===`);
  const batch = db.batch();
  for (const t of tags) {
    const ref = db.collection("tags").doc(t.id);
    batch.set(ref, { name: t.name, category: t.category, order: t.order });
    console.log(`  + ${t.id}: ${t.name} [${t.category}]`);
  }
  await batch.commit();
}

// ── Main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`Target: ${useEmulator ? "EMULATOR" : projectId ?? "default"}`);
  await seedCouples();
  await seedDestinations();
  await seedTags();
  console.log("\n✅ seed complete");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("FATAL:", err);
    process.exit(1);
  });
