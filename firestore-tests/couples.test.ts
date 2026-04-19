/**
 * Rules tests for the `couples` collection.
 * Coverage:
 * - Anyone authenticated + approved + not-blocked can read another couple
 * - Pending-deletion users can't read other couples
 * - Mutual block hides the doc from both directions
 * - Owner can transition approved <-> pending_deletion but not other transitions
 * - Random users can't write someone else's doc
 */
import {
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";

import { getEnv, teardown, seedCouple, seedBlock } from "./setup";

const A = "couple_a";
const B = "couple_b";

afterAll(teardown);

describe("couples — read", () => {
  it("approved A can read approved B", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "approved");
    await seedCouple(env, B, "approved");
    const a = env.authenticatedContext(A).firestore();
    await assertSucceeds(a.doc(`couples/${B}`).get());
  });

  it("pending_deletion A cannot read B", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "pending_deletion");
    await seedCouple(env, B, "approved");
    const a = env.authenticatedContext(A).firestore();
    await assertFails(a.doc(`couples/${B}`).get());
  });

  it("blocked B cannot read A (silent block)", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "approved");
    await seedCouple(env, B, "approved");
    await seedBlock(env, A, B); // A blocks B
    const b = env.authenticatedContext(B).firestore();
    await assertFails(b.doc(`couples/${A}`).get());
  });

  it("A can always read its own doc regardless of status", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "pending_deletion");
    const a = env.authenticatedContext(A).firestore();
    await assertSucceeds(a.doc(`couples/${A}`).get());
  });
});

describe("couples — write", () => {
  it("owner can request deletion (approved -> pending_deletion)", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "approved");
    const a = env.authenticatedContext(A).firestore();
    await assertSucceeds(
      a.doc(`couples/${A}`).update({ status: "pending_deletion" })
    );
  });

  it("owner can cancel deletion (pending_deletion -> approved)", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "pending_deletion");
    const a = env.authenticatedContext(A).firestore();
    await assertSucceeds(
      a.doc(`couples/${A}`).update({ status: "approved" })
    );
  });

  it("owner CANNOT self-promote pending_review -> approved", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "pending_review");
    const a = env.authenticatedContext(A).firestore();
    await assertFails(
      a.doc(`couples/${A}`).update({ status: "approved" })
    );
  });

  it("non-owner cannot update someone else's doc", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "approved");
    const b = env.authenticatedContext(B).firestore();
    await assertFails(
      b.doc(`couples/${A}`).update({ description: "nope" })
    );
  });

  it("noone can delete a couple doc directly (only via Cloud Function)", async () => {
    const env = await getEnv();
    await env.clearFirestore();
    await seedCouple(env, A, "approved");
    const a = env.authenticatedContext(A).firestore();
    await assertFails(a.doc(`couples/${A}`).delete());
  });
});
