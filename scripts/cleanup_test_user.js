const admin = require("../functions/node_modules/firebase-admin");
admin.initializeApp({
  credential: admin.credential.cert(require("D:/app/sa-key-prod.json")),
  projectId: "affinity-dating-app-cf807",
});
(async () => {
  try {
    const u = await admin.auth().getUserByEmail("test-live@affinityclub.test");
    await admin.auth().deleteUser(u.uid);
    console.log("deleted auth user", u.uid);
    try {
      await admin.firestore().collection("couples").doc(u.uid).delete();
      console.log("deleted couple doc (if existed)");
    } catch (_) {}
  } catch (e) {
    console.log("nothing to clean:", e.code || e.message);
  }
  process.exit(0);
})();
