/**
 * Grants `moderator: true` custom claim to a user — required to log into
 * the moderation web panel and to call the `moderateVerification` Cloud
 * Function.
 *
 * Run (from d:/app/functions, after `npm run build`):
 *   node lib/scripts/grant_moderator.js --email=you@example.com --project=<id>
 *
 * Or against the local emulator:
 *   node lib/scripts/grant_moderator.js --emulator --email=you@example.com
 *
 * The user must already exist (i.e. has signed up via the app or via
 * `seed_demo_account`). Re-running is safe — claims are idempotent.
 */
import * as admin from "firebase-admin";

const args = process.argv.slice(2);
const flag = (n: string) => args.includes(n);
const val = (n: string): string | undefined => {
  const prefix = `${n}=`;
  const found = args.find((a) => a.startsWith(prefix));
  return found ? found.slice(prefix.length) : undefined;
};

const emailArg = val("--email");
const projectId = val("--project");
const useEmulator = flag("--emulator");

if (!emailArg) {
  console.error("Usage: node grant_moderator.js --email=<x> [--project=<id>] [--emulator]");
  process.exit(2);
}
const email: string = emailArg;

if (useEmulator) {
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
  process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
}

admin.initializeApp(projectId ? { projectId } : undefined);

async function main() {
  const auth = admin.auth();
  const user = await auth.getUserByEmail(email);
  await auth.setCustomUserClaims(user.uid, { moderator: true });
  console.log(`✅ moderator claim granted to ${email} (uid: ${user.uid})`);
  console.log("⚠️  user must sign out + sign back in for the claim to take effect.");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("FATAL:", err);
    process.exit(1);
  });
