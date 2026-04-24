/**
 * Seed a Free-plan subscription document whenever a new couple is created.
 *
 * This guarantees that any UI path reading `subscriptions/{coupleId}`
 * finds a doc — no nullability special cases on the client.
 *
 * Runs as an onCreate Firestore trigger rather than being embedded in
 * the registration flow so it applies equally to:
 *   - Normal signup via the app
 *   - Admin-created couples
 *   - Seeded demo accounts
 *   - Migrations (migrate_profiles_to_couples.ts)
 */
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";

import { db, COLLECTIONS } from "../common/firestore";
import { SUBSCRIPTIONS_COLLECTION } from "./types";

export const onCoupleCreatedSeedSubscription = onDocumentCreated(
  {
    document: `${COLLECTIONS.couples}/{coupleId}`,
    region: "us-central1",
  },
  async (event) => {
    const coupleId = event.params.coupleId;
    const ref = db().collection(SUBSCRIPTIONS_COLLECTION).doc(coupleId);
    const snap = await ref.get();
    if (snap.exists) return; // already seeded (e.g. via migration)

    await ref.set({
      plan: "free",
      status: "active",
      cancel_at_period_end: false,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
  },
);
