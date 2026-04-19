/// Lifecycle states of a couple's account.
///
/// Drives access control across the app (e.g. `pending_review` blocks the
/// COUPLES feed, `pending_deletion` hides the profile from discovery while
/// preserving cancel-deletion ability for 30 days).
///
/// String values match the Firestore field exactly — never change them
/// without writing a migration.
enum CoupleStatus {
  pendingReview('pending_review'),
  approved('approved'),
  rejected('rejected'),
  suspended('suspended'),
  underReview('under_review'),
  pendingDeletion('pending_deletion');

  const CoupleStatus(this.value);

  final String value;

  static CoupleStatus fromString(String? raw) {
    for (final s in CoupleStatus.values) {
      if (s.value == raw) return s;
    }
    return CoupleStatus.pendingReview;
  }
}
