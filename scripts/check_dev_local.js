// Quick inspection of affinity-dev-local Firestore state.
// Prints counts of seeded test data so we know what's there.

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS to a service account key path');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'affinity-dev-local',
});

const db = admin.firestore();

async function check() {
  const collections = ['couples', 'profiles', 'tags', 'destinations', 'conversations'];
  for (const c of collections) {
    try {
      const snap = await db.collection(c).get();
      console.log(`${c}: ${snap.size} documents`);
      if (snap.size > 0 && snap.size <= 3) {
        snap.forEach(doc => console.log(`  - ${doc.id}: ${JSON.stringify(doc.data()).slice(0, 100)}`));
      } else if (snap.size > 0) {
        let i = 0;
        snap.forEach(doc => {
          if (i++ < 3) console.log(`  - ${doc.id}`);
        });
      }
    } catch (e) {
      console.log(`${c}: ERROR ${e.message}`);
    }
  }
  process.exit(0);
}
check();
