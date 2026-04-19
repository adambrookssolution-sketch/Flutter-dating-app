/**
 * Shared Firestore helpers used by multiple Cloud Functions.
 * Kept thin — each function module owns its own business logic.
 */
import { getFirestore } from "firebase-admin/firestore";

export const db = () => getFirestore();

export const COLLECTIONS = {
  couples: "couples",
  conversations: "conversations",
  messageRequests: "message_requests",
  reports: "reports",
  blocks: "blocks",
  destinations: "destinations",
  tags: "tags",
  recoveryAttempts: "account_recovery_attempts",
  usersMeta: "users_meta",
} as const;
