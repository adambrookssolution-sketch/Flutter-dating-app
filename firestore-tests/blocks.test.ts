/**
 * Rules tests for `blocks` — bidirectional silent semantics enforced at
 * read level (the blocked party can never see the doc).
 */
import { assertFails, assertSucceeds } from "@firebase/rules-unit-testing";

import { getEnv, teardown, seedCouple } from "./setup";

const A = "couple_a";
const B = "couple_b";

afterAll(teardown);

describe("blocks", () => {
  it("blocker can create a block doc with the canonical id", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A);
    const a = env.authenticatedContext(A).firestore();
    await assertSucceeds(
      a.doc(`blocks/${A}_${B}`).set({
        pareja_que_bloquea: A,
        pareja_bloqueada: B,
      })
    );
  });

  it("blocker can list their own blocks", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A);
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`blocks/${A}_${B}`).set({
        pareja_que_bloquea: A,
        pareja_bloqueada: B,
      });
    });
    const a = env.authenticatedContext(A).firestore();
    await assertSucceeds(a.doc(`blocks/${A}_${B}`).get());
  });

  it("the BLOCKED party cannot read the block doc (silent)", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`blocks/${A}_${B}`).set({
        pareja_que_bloquea: A,
        pareja_bloqueada: B,
      });
    });
    const b = env.authenticatedContext(B).firestore();
    await assertFails(b.doc(`blocks/${A}_${B}`).get());
  });

  it("third party cannot read", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`blocks/${A}_${B}`).set({
        pareja_que_bloquea: A,
        pareja_bloqueada: B,
      });
    });
    const c = env.authenticatedContext("couple_c").firestore();
    await assertFails(c.doc(`blocks/${A}_${B}`).get());
  });

  it("doc id must match canonical ${blocker}_${blocked}", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A);
    const a = env.authenticatedContext(A).firestore();
    await assertFails(
      a.doc(`blocks/wrong_id`).set({
        pareja_que_bloquea: A,
        pareja_bloqueada: B,
      })
    );
  });

  it("you cannot block yourself", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A);
    const a = env.authenticatedContext(A).firestore();
    await assertFails(
      a.doc(`blocks/${A}_${A}`).set({
        pareja_que_bloquea: A,
        pareja_bloqueada: A,
      })
    );
  });
});
