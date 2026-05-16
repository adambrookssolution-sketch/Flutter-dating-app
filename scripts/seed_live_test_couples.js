/**
 * Seeds three full test couples directly into Firestore using external
 * placeholder photo + video URLs. Bypasses Cloud Storage entirely
 * (which is currently blocked by billing propagation, returning
 * HTTP 402). The admin panel reads photo/video URLs as opaque strings,
 * so it doesn't care whether they live in Storage or on another host.
 *
 * Three different couples, three different cities, distinct interests
 * — gives the user something realistic to click through in the
 * moderation panel without waiting for billing to clear.
 *
 * Test couples (all status=pending_review, all with video + photos
 * so they pass the new queue filter):
 *
 *   couples/__live_test_madrid_001:
 *     Camila & Diego, Madrid, ES
 *   couples/__live_test_buenos_aires_002:
 *     Sofía & Mateo, Buenos Aires, AR
 *   couples/__live_test_cdmx_003:
 *     Valentina & Andrés, Ciudad de México, MX
 *
 * To remove:
 *   node scripts/seed_live_test_couples.js --cleanup
 */
const admin = require("../functions/node_modules/firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: "affinity-dating-app-cf807",
});

const db = admin.firestore();
const NOW = admin.firestore.FieldValue.serverTimestamp;

// Public 5-second MP4 sample (CORS-friendly, no auth, ~2.8 MB):
const SAMPLE_VIDEO = "https://download.samplelib.com/mp4/sample-5s.mp4";

// placehold.co — deterministic placeholder images, CORS=*, no redirects.
function photoSet(label) {
  const enc = encodeURIComponent(label);
  return [
    `https://placehold.co/600x800/2A2A2A/FFFFFF.png?text=${enc}+1`,
    `https://placehold.co/600x800/3A1F2E/FFFFFF.png?text=${enc}+2`,
    `https://placehold.co/600x800/1F2E3A/FFFFFF.png?text=${enc}+3`,
  ];
}

const COUPLES = [
  {
    id: "__live_test_madrid_001",
    partner_a: { name: "Camila", birth: "07/03/1991", height: "166 cm" },
    partner_b: { name: "Diego", birth: "21/08/1989", height: "178 cm" },
    city: "Madrid",
    country: "Spain",
    country_code: "ES",
    lat: 40.4168,
    lng: -3.7038,
    geohash: "ezjmgr64j",
    description:
      "Curiosos y abiertos a conocer parejas con buena onda. Nos gusta " +
      "viajar, salir a cenar y conocer gente nueva sin prisa.",
    interests: ["Soft Swap", "Same Room", "Travel", "Foodies"],
    open_to_unicorn: true,
    open_to_bull: false,
    explicit: false,
    language: "es",
    photos: photoSet("Camila & Diego"),
    age_range: { min: 34, max: 36 },
  },
  {
    id: "__live_test_buenos_aires_002",
    partner_a: { name: "Sofía", birth: "12/11/1988", height: "170 cm" },
    partner_b: { name: "Mateo", birth: "05/04/1985", height: "183 cm" },
    city: "Buenos Aires",
    country: "Argentina",
    country_code: "AR",
    lat: -34.6037,
    lng: -58.3816,
    geohash: "6e9rqgh4n",
    description:
      "Pareja porteña, nos divertimos en eventos, fiestas privadas y " +
      "encuentros con buena vibra. Sin compromiso, con respeto.",
    interests: ["Full Swap", "Separate Rooms", "Adventure", "Night Life"],
    open_to_unicorn: false,
    open_to_bull: true,
    explicit: true,
    language: "es",
    photos: photoSet("Sofia & Mateo"),
    age_range: { min: 36, max: 39 },
  },
  {
    id: "__live_test_cdmx_003",
    partner_a: { name: "Valentina", birth: "29/06/1993", height: "162 cm" },
    partner_b: { name: "Andrés", birth: "14/01/1990", height: "175 cm" },
    city: "Ciudad de México",
    country: "Mexico",
    country_code: "MX",
    lat: 19.4326,
    lng: -99.1332,
    geohash: "9g3w9c1r0",
    description:
      "Recién entrando al estilo de vida, buscando primeras experiencias " +
      "con parejas pacientes. Nos encanta la música y los viajes.",
    interests: ["Parallel Play", "Voyeur Couple", "Curious"],
    open_to_unicorn: true,
    open_to_bull: true,
    explicit: false,
    language: "es",
    photos: photoSet("Valentina & Andres"),
    age_range: { min: 32, max: 35 },
  },
];

async function seed() {
  console.log(`Seeding ${COUPLES.length} live test couples...\n`);
  for (const c of COUPLES) {
    const docRef = db.collection("couples").doc(c.id);
    await docRef.set({
      partner_a: c.partner_a,
      partner_b: c.partner_b,
      city: c.city,
      country: c.country,
      country_code: c.country_code,
      lat: c.lat,
      lng: c.lng,
      geohash: c.geohash,
      description: c.description,
      photos: c.photos,
      interests: c.interests,
      open_to_unicorn: c.open_to_unicorn,
      open_to_bull: c.open_to_bull,
      explicit: c.explicit,
      language: c.language,
      age_range: c.age_range,
      status: "pending_review",
      verification: {
        sent_at: NOW(),
        video_url: SAMPLE_VIDEO,
        reviewed_at: null,
        moderator_id: null,
        reject_reason: null,
        attempts: 1,
      },
      deletion_requested_at: null,
      created_at: NOW(),
      updated_at: NOW(),
    });
    console.log(`  ✓ couples/${c.id}: ${c.partner_a.name} & ${c.partner_b.name} (${c.city})`);
  }

  console.log("\nVerifying queue visibility (status=pending_review + video + photos)...\n");
  const snap = await db
    .collection("couples")
    .where("status", "==", "pending_review")
    .get();
  let visibleCount = 0;
  for (const doc of snap.docs) {
    const d = doc.data();
    const hasVideo = !!d?.verification?.video_url;
    const hasPhotos = Array.isArray(d.photos) && d.photos.length > 0;
    if (hasVideo && hasPhotos) {
      visibleCount++;
      console.log(`  · ${doc.id} VISIBLE: ${d.partner_a?.name} & ${d.partner_b?.name} | ${d.city}`);
    } else {
      console.log(`  · ${doc.id} HIDDEN (incomplete): video=${hasVideo} photos=${hasPhotos}`);
    }
  }
  console.log(
    `\nTotal visible in moderation queue: ${visibleCount} of ${snap.size} pending_review couples.`
  );
}

async function cleanup() {
  console.log("Removing live test couples...\n");
  for (const c of COUPLES) {
    await db.collection("couples").doc(c.id).delete();
    console.log(`  ✓ deleted couples/${c.id}`);
  }
}

const cmd = process.argv[2];
(cmd === "--cleanup" ? cleanup() : seed())
  .then(() => {
    console.log("\nDone.");
    process.exit(0);
  })
  .catch((e) => {
    console.error("FATAL:", e.message);
    process.exit(1);
  });
