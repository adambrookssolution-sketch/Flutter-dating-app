/**
 * Travel Match query.
 *
 * Client sends its own trip (destinationId + date range). We query every
 * other couple's `trips/*` subcollection via `collectionGroup('trips')`,
 * filter to same-destination + overlapping ranges, exclude blocks, and
 * return a trimmed couple-summary per match.
 *
 * Why this is server-side:
 *   - `collectionGroup('trips')` would otherwise need collection-group
 *     Security Rules that read parent couple status + block state per doc.
 *     Those are per-read `get()` calls and burn latency fast. Doing it
 *     here lets us return exactly the fields the client UI needs and
 *     avoid exposing the raw trips collection group to the client.
 */
import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { db, COLLECTIONS } from "../common/firestore";

interface Payload {
  tripId?: string;
  destinationId?: string;
  startDate?: string; // ISO-8601
  endDate?: string;
}

export const findMatches = onCall<Payload>(
  { region: "us-central1", maxInstances: 10 },
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "sign in required");
    const myId = req.auth.uid;
    const { destinationId, startDate, endDate } = req.data;
    if (!destinationId || !startDate || !endDate) {
      throw new HttpsError(
        "invalid-argument",
        "destinationId, startDate, endDate are required"
      );
    }
    const myStart = new Date(startDate);
    const myEnd = new Date(endDate);
    if (Number.isNaN(myStart.getTime()) || Number.isNaN(myEnd.getTime())) {
      throw new HttpsError("invalid-argument", "bad date format");
    }

    // Candidate trips: same destination, start_date <= myEnd.
    // We finish filtering (end_date >= myStart) in-memory because Firestore
    // can't range-filter on two fields at once.
    const candidates = await admin
      .firestore()
      .collectionGroup("trips")
      .where("destination_id", "==", destinationId)
      .where("start_date", "<=", admin.firestore.Timestamp.fromDate(myEnd))
      .get();

    const matches: Array<Record<string, unknown>> = [];
    const seenCouples = new Set<string>();

    // Precompute our outgoing blocks so we can exclude those couples fast.
    const myOutgoingBlocks = await db()
      .collection(COLLECTIONS.blocks)
      .where("pareja_que_bloquea", "==", myId)
      .get();
    const blockedByMe = new Set<string>(
      myOutgoingBlocks.docs.map(
        (d) => d.get("pareja_bloqueada") as string
      )
    );

    // And incoming blocks too (silent — we still filter them out here).
    const incoming = await db()
      .collection(COLLECTIONS.blocks)
      .where("pareja_bloqueada", "==", myId)
      .get();
    const blockedMe = new Set<string>(
      incoming.docs.map((d) => d.get("pareja_que_bloquea") as string)
    );

    for (const tripDoc of candidates.docs) {
      const otherCoupleRef = tripDoc.ref.parent.parent;
      if (!otherCoupleRef) continue;
      const otherId = otherCoupleRef.id;
      if (otherId === myId) continue;
      if (seenCouples.has(otherId)) continue;
      if (blockedByMe.has(otherId) || blockedMe.has(otherId)) continue;

      const end = (tripDoc.get("end_date") as admin.firestore.Timestamp).toDate();
      const start = (tripDoc.get("start_date") as admin.firestore.Timestamp).toDate();
      if (end < myStart) continue; // no overlap

      // Load the couple doc for the summary
      const couple = await otherCoupleRef.get();
      if (!couple.exists) continue;
      if (couple.get("status") !== "approved") continue;

      const photos = (couple.get("photos") as string[] | undefined) ?? [];
      const overlapStart = myStart > start ? myStart : start;
      const overlapEnd = myEnd < end ? myEnd : end;
      const overlapDays =
        Math.max(
          0,
          Math.floor(
            (overlapEnd.getTime() - overlapStart.getTime()) /
              (1000 * 60 * 60 * 24)
          )
        ) + 1;

      matches.push({
        coupleId: otherId,
        partnerA: couple.get("partner_a.name"),
        partnerB: couple.get("partner_b.name"),
        city: couple.get("city"),
        photo: photos.length > 0 ? photos[0] : null,
        overlapDays,
        tripId: tripDoc.id,
      });
      seenCouples.add(otherId);
      if (matches.length >= 50) break; // cap
    }

    return { matches };
  }
);
