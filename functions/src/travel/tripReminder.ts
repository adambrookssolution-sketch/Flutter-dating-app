/**
 * Daily sweep — sends a 7-day advance reminder to every couple whose trip
 * starts in exactly 7 days, PLUS to each couple that has a confirmed match
 * (overlapping trip on the same destination).
 *
 * Reminder copy: "Your trip to [Destino] starts in 7 days" + "[N] parejas
 * también viajan contigo".
 *
 * Schedule: 08:00 UTC — comfortably past our nightly deletion/cleanup
 * windows (03:00 / 04:00) and before LATAM morning peak.
 */
import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";

import { COLLECTIONS } from "../common/firestore";

export const tripReminder = onSchedule(
  {
    schedule: "every day 08:00",
    timeZone: "Etc/UTC",
    region: "us-central1",
    timeoutSeconds: 540,
  },
  async () => {
    const now = new Date();
    const windowStart = new Date(now);
    windowStart.setUTCDate(windowStart.getUTCDate() + 7);
    windowStart.setUTCHours(0, 0, 0, 0);
    const windowEnd = new Date(windowStart);
    windowEnd.setUTCDate(windowEnd.getUTCDate() + 1);

    const trips = await admin
      .firestore()
      .collectionGroup("trips")
      .where(
        "start_date",
        ">=",
        admin.firestore.Timestamp.fromDate(windowStart)
      )
      .where(
        "start_date",
        "<",
        admin.firestore.Timestamp.fromDate(windowEnd)
      )
      .get();

    if (trips.empty) {
      logger.info("tripReminder: no trips starting in 7 days");
      return;
    }

    for (const doc of trips.docs) {
      const coupleRef = doc.ref.parent.parent;
      if (!coupleRef) continue;
      const destinationName =
        (doc.get("destination") as string) ?? "your destination";

      // Count overlapping matches
      const overlapping = await admin
        .firestore()
        .collectionGroup("trips")
        .where("destination_id", "==", doc.get("destination_id"))
        .where("start_date", "<=", doc.get("end_date"))
        .get();
      let matchCount = 0;
      const myStart = (doc.get("start_date") as admin.firestore.Timestamp).toDate();
      for (const other of overlapping.docs) {
        const otherParent = other.ref.parent.parent;
        if (!otherParent || otherParent.id === coupleRef.id) continue;
        const otherEnd = (other.get(
          "end_date"
        ) as admin.firestore.Timestamp).toDate();
        if (otherEnd < myStart) continue;
        matchCount++;
      }

      const body =
        matchCount === 0
          ? `Your trip to ${destinationName} starts in 7 days!`
          : `Your trip to ${destinationName} starts in 7 days — ${matchCount} ${
              matchCount === 1 ? "match" : "matches"
            } waiting.`;

      await sendPush(coupleRef.id, {
        title: "Trip coming up",
        body,
        data: {
          type: "trip_reminder",
          destinationId: (doc.get("destination_id") as string) ?? "",
        },
      });
    }
    logger.info(`tripReminder: processed ${trips.size} trips`);
  }
);

async function sendPush(
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
    logger.warn(`tripReminder push failed for ${coupleId}`, err);
  }
}
