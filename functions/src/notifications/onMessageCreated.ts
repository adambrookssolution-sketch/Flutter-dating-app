/**
 * Fires when a new document is written to
 * `conversations/{conversationId}/messages/{messageId}` and pushes an
 * FCM notification to whichever participant did NOT send the message.
 *
 * Conversation IDs are formed as `<uid1>_<uid2>` (sorted), so we can
 * derive the recipient from the path + sender_uid field without a
 * round-trip to read the conversation doc.
 *
 * Client feedback 2026-05-17 #10 — push notifications for messages
 * (and for first-message requests, since the agency request flow
 * lazily creates the conversation doc on the very first send and the
 * trigger fires for that same first message).
 */
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

import { sendPushToCouple } from "../common/push";

export const onMessageCreated = onDocumentCreated(
  {
    document: "conversations/{conversationId}/messages/{messageId}",
    region: "us-central1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const conversationId = event.params.conversationId;
    const senderUid = snap.get("sender_uid") as string | undefined;
    if (!senderUid) {
      logger.warn(
        `onMessageCreated: message ${event.params.messageId} has no sender_uid`
      );
      return;
    }

    // Recipient = the other participant in the deterministic
    // <uid1>_<uid2> conversation id.
    const parts = conversationId.split("_");
    if (parts.length !== 2) {
      logger.warn(
        `onMessageCreated: conversationId ${conversationId} is not in <uid>_<uid> form`
      );
      return;
    }
    const recipientUid = parts[0] === senderUid ? parts[1] : parts[0];

    const text = (snap.get("text") as string | undefined) ?? "";
    const hasImage = !!(snap.get("image_url") as string | undefined);
    const preview = text.length > 0 ? text : hasImage ? "📷" : "";

    await sendPushToCouple(recipientUid, {
      title: "Affinity",
      body: preview,
      data: {
        kind: "message",
        conversationId,
        senderUid,
      },
    });
  }
);
