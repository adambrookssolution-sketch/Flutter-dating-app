/**
 * Rules tests for `conversations` and the nested `messages` subcollection.
 * Both must be participant-gated; non-participants must see nothing.
 */
import { assertFails, assertSucceeds } from "@firebase/rules-unit-testing";

import { getEnv, teardown, seedCouple } from "./setup";

const A = "couple_a";
const B = "couple_b";
const C = "couple_c"; // outsider

afterAll(teardown);

const convId = `${A}_${B}`;

describe("conversations", () => {
  it("participant can read", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A);
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`conversations/${convId}`).set({
        participants: [A, B],
        initiated_by: A,
      });
    });
    const a = env.authenticatedContext(A).firestore();
    await assertSucceeds(a.doc(`conversations/${convId}`).get());
  });

  it("non-participant cannot read", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`conversations/${convId}`).set({
        participants: [A, B],
        initiated_by: A,
      });
    });
    const c = env.authenticatedContext(C).firestore();
    await assertFails(c.doc(`conversations/${convId}`).get());
  });

  it("participant can create message; non-participant cannot", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`conversations/${convId}`).set({
        participants: [A, B],
        initiated_by: A,
      });
    });
    const a = env.authenticatedContext(A).firestore();
    await assertSucceeds(
      a.collection(`conversations/${convId}/messages`).add({
        text: "hello",
        sender_uid: A,
      })
    );
    const c = env.authenticatedContext(C).firestore();
    await assertFails(
      c.collection(`conversations/${convId}/messages`).add({
        text: "intrusion",
        sender_uid: C,
      })
    );
  });

  it("cannot send message claiming to be someone else", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`conversations/${convId}`).set({
        participants: [A, B],
        initiated_by: A,
      });
    });
    const a = env.authenticatedContext(A).firestore();
    await assertFails(
      a.collection(`conversations/${convId}/messages`).add({
        text: "spoof",
        sender_uid: B,
      })
    );
  });

  it("messages are immutable", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    let msgId = "";
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`conversations/${convId}`).set({
        participants: [A, B],
        initiated_by: A,
      });
      const ref = await ctx
        .firestore()
        .collection(`conversations/${convId}/messages`)
        .add({ text: "original", sender_uid: A });
      msgId = ref.id;
    });
    const a = env.authenticatedContext(A).firestore();
    await assertFails(
      a
        .doc(`conversations/${convId}/messages/${msgId}`)
        .update({ text: "edited" })
    );
    await assertFails(
      a.doc(`conversations/${convId}/messages/${msgId}`).delete()
    );
  });
});
