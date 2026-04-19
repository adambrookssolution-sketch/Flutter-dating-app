/**
 * Fires when a new trip doc is created under `couples/{coupleId}/trips/*`.
 * Finds every other couple whose trips overlap on the same destination
 * and sends them an FCM push.
 *
 * Copy: "[N] parejas también viajan a [Destino] en tus fechas"
 * (mirrors DECISIONS_LOG Point 4).
 */
import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

import { COLLECTIONS } from "../common/firestore";

export const onTripCreated = onDocumentCreated(
  {
    document: "couples/{coupleId}/trips/{tripId}",
    region: "us-central1",
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const newCoupleId = event.params.coupleId;
    const destinationId = data.destination_id as string | undefined;
    const startTs = data.start_date as admin.firestore.Timestamp | undefined;
    const endTs = data.end_date as admin.firestore.Timestamp | undefined;
    const destinationName = (data.destination as string) ?? "your destination";
    if (!destinationId || !startTs || !endTs) return;

    const myStart = startTs.toDate();
    const myEnd = endTs.toDate();

    // Find overlapping trips — same query shape as findMatches, but we
    // return notification targets (the OTHER couples) rather than the
    // caller's summary.
    const candidates = await admin
      .firestore()
      .collectionGroup("trips")
      .where("destination_id", "==", destinationId)
      .where("start_date", "<=", admin.firestore.Timestamp.fromDate(myEnd))
      .get();

    const targets = new Set<string>();
    for (const tripDoc of candidates.docs) {
      const parentRef = tripDoc.ref.parent.parent;
      if (!parentRef) continue;
      if (parentRef.id === newCoupleId) continue;
      const end = (tripDoc.get("end_date") as admin.firestore.Timestamp).toDate();
      if (end < myStart) continue;
      targets.add(parentRef.id);
    }

    if (targets.size === 0) {
      logger.info(`onTripCreated: no overlapping couples for ${newCoupleId}`);
      return;
    }

    // Notify the NEW couple about how many existing matches they just got.
    await sendPushToCouple(newCoupleId, {
      title: "New travel matches!",
      body: `${targets.size} ${
        targets.size === 1 ? "pareja también viaja" : "parejas también viajan"
      } a ${destinationName} en tus fechas`,
      data: { type: "travel_match_initial", destinationId },
    });

    // Notify the EXISTING couples — one new match each.
    for (const otherId of targets) {
      await sendPushToCouple(otherId, {
        title: "New travel match!",
        body: `Otra pareja también viaja a ${destinationName} en tus fechas`,
        data: { type: "travel_match_new", destinationId },
      });
    }
  }
);

async function sendPushToCouple(
  coupleId: string,
  msg: { title: string; body: string; data?: Record<string, string> }
): Promise<void> {
  const tokens = await admin
    .firestore()
    .collection(COLLECTIONS.couples)
    .doc(coupleId)
    .collection("fcm_tokens")
    .get();
  if (tokens.empty) return;
  const tokenList = tokens.docs
    .map((d) => d.get("token") as string | undefined)
    .filter((t): t is string => !!t);
  if (tokenList.length === 0) return;

  try {
    await admin.messaging().sendEachForMulticast({
      tokens: tokenList,
      notification: { title: msg.title, body: msg.body },
      data: msg.data ?? {},
    });
  } catch (err) {
    logger.warn(`push failed for ${coupleId}`, err);
  }
}
