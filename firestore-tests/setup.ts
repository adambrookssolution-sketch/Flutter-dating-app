/**
 * Shared harness for Firestore Security Rules unit tests.
 *
 * Boots one in-memory test environment per test file; each test gets a
 * fresh authenticated context (or unauth context) so tests are independent.
 *
 * Run: `npm test` from this directory while the Firestore emulator is
 * available (the npm script wraps it with `firebase emulators:exec`).
 */
import * as fs from "fs";
import * as path from "path";
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";

let env: RulesTestEnvironment | null = null;

export async function getEnv(): Promise<RulesTestEnvironment> {
  if (env) return env;
  const rulesPath = path.resolve(__dirname, "..", "firestore.rules");
  env = await initializeTestEnvironment({
    projectId: "demo-affinity",
    firestore: {
      rules: fs.readFileSync(rulesPath, "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
  return env;
}

export async function teardown(): Promise<void> {
  if (env) {
    await env.cleanup();
    env = null;
  }
}

/** Convenience seed — drops a couple doc with the given status into Firestore
 *  via a privileged context so rules don't block setup. */
export async function seedCouple(
  e: RulesTestEnvironment,
  uid: string,
  status: string = "approved",
  extra: Record<string, unknown> = {}
): Promise<void> {
  await e.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection("couples")
      .doc(uid)
      .set({ status, ...extra });
  });
}

export async function seedBlock(
  e: RulesTestEnvironment,
  blocker: string,
  blocked: string
): Promise<void> {
  await e.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection("blocks")
      .doc(`${blocker}_${blocked}`)
      .set({ pareja_que_bloquea: blocker, pareja_bloqueada: blocked });
  });
}
