/**
 * Fires when a user adds another couple to their favourites
 * (`users/{myUid}/favorites/{favoriteUid}` create) and pushes an FCM
 * notification to the favourited couple so they know they've been
 * saved.
 *
 * Client feedback 2026-05-17 #10 — receive notifications when someone
 * adds us to their favourites.
 */
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

import { sendPushToCouple } from "../common/push";

export const onFavoriteAdded = onDocumentCreated(
  {
    document: "users/{myUid}/favorites/{favoriteUid}",
    region: "us-central1",
  },
  async (event) => {
    const myUid = event.params.myUid;
    const favoriteUid = event.params.favoriteUid;

    if (!favoriteUid || favoriteUid === myUid) {
      logger.warn(
        `onFavoriteAdded: skipping self-favourite or empty target (${myUid} → ${favoriteUid})`
      );
      return;
    }

    await sendPushToCouple(favoriteUid, {
      title: "Affinity",
      body: "Una pareja te agregó a sus favoritos",
      data: {
        kind: "favorite",
        favoritedByUid: myUid,
      },
    });
  }
);
