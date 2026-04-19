/**
 * Rules tests for `reports` — only approved couples can submit; nobody can
 * read (Cloud Functions only) → guarantees total reporter confidentiality.
 */
import { assertFails, assertSucceeds } from "@firebase/rules-unit-testing";

import { getEnv, teardown, seedCouple } from "./setup";

const A = "couple_a";
const B = "couple_b";

afterAll(teardown);

describe("reports", () => {
  it("approved A can report B", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "approved");
    const a = env.authenticatedContext(A).firestore();
    await assertSucceeds(
      a.collection("reports").add({
        reporter_couple: A,
        reported_couple: B,
        categoria: "spam",
      })
    );
  });

  it("pending_review A cannot report (must be approved)", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "pending_review");
    const a = env.authenticatedContext(A).firestore();
    await assertFails(
      a.collection("reports").add({
        reporter_couple: A,
        reported_couple: B,
        categoria: "spam",
      })
    );
  });

  it("cannot impersonate someone else as reporter", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "approved");
    const a = env.authenticatedContext(A).firestore();
    await assertFails(
      a.collection("reports").add({
        reporter_couple: "someone_else",
        reported_couple: B,
        categoria: "spam",
      })
    );
  });

  it("cannot report yourself", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "approved");
    const a = env.authenticatedContext(A).firestore();
    await assertFails(
      a.collection("reports").add({
        reporter_couple: A,
        reported_couple: A,
        categoria: "spam",
      })
    );
  });

  it("nobody can read reports — even the reporter", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "approved");
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("reports").add({
        reporter_couple: A,
        reported_couple: B,
        categoria: "spam",
      });
    });
    const a = env.authenticatedContext(A).firestore();
    const snap = await a
      .collection("reports")
      .where("reporter_couple", "==", A)
      .get()
      .catch(() => null);
    expect(snap).toBeNull();
  });
});
