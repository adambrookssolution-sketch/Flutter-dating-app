/**
 * Shared FCM push helper. Reads the recipient couple's FCM tokens from
 * `couples/{coupleId}/fcm_tokens/*` and fan-outs a single multicast.
 * Failures are logged, never thrown — a missed push must not abort
 * the upstream Firestore trigger.
 *
 * Added on 2026-05-17 alongside the new onMessageCreated and
 * onFavoriteAdded triggers (client feedback #10 — receive notifications
 * for messages / requests / favourites).
 */
import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";

import { COLLECTIONS } from "./firestore";

export async function sendPushToCouple(
  coupleId: string,
  msg: { title: string; body: string; data?: Record<string, string> }
): Promise<void> {
  if (!coupleId) return;

  const tokensSnap = await admin
    .firestore()
    .collection(COLLECTIONS.couples)
    .doc(coupleId)
    .collection("fcm_tokens")
    .get();

  if (tokensSnap.empty) return;

  const tokens = tokensSnap.docs
    .map((d) => d.get("token") as string | undefined)
    .filter((t): t is string => !!t);

  if (tokens.length === 0) return;

  try {
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: msg.title, body: msg.body },
      data: msg.data ?? {},
    });
  } catch (err) {
    logger.warn(`push failed for couple ${coupleId}`, err);
  }
}
