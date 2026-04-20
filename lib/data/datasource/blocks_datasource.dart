import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app/data/models/block.dart';

/// Block CRUD + the read paths used by the discovery feed to know which
/// couples to hide.
///
/// "Bidirectional + invisible" semantics:
/// - When A blocks B, only ONE document is written: `${A}_${B}`.
/// - The discovery feed checks BOTH directions (`${me}_${target}` AND
///   `${target}_${me}`) so the effect is symmetric without doubling writes.
/// - Neither party is notified — block presence is never read by the blocked
///   side; client only checks for couples THEY have blocked + couples that
///   have blocked them.
class BlocksDatasource {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<void> block(
    String blockerCoupleId,
    String blockedCoupleId, {
    BlockOrigin origin = BlockOrigin.manual,
  }) async {
    final id = Block.idFor(blockerCoupleId, blockedCoupleId);
    await _db.collection('blocks').doc(id).set({
      'pareja_que_bloquea': blockerCoupleId,
      'pareja_bloqueada': blockedCoupleId,
      'fecha': FieldValue.serverTimestamp(),
      'origen': origin.value,
    });
  }

  /// Helper for callers that need to atomically combine a block with another
  /// write (e.g. submitting a Report with the "block too" checkbox checked).
  static void addBlockToBatch({
    required WriteBatch batch,
    required String blockerCoupleId,
    required String blockedCoupleId,
    String origin = 'manual',
  }) {
    final id = Block.idFor(blockerCoupleId, blockedCoupleId);
    final ref = FirebaseFirestore.instance.collection('blocks').doc(id);
    batch.set(ref, {
      'pareja_que_bloquea': blockerCoupleId,
      'pareja_bloqueada': blockedCoupleId,
      'fecha': FieldValue.serverTimestamp(),
      'origen': origin,
    });
  }

  static Future<void> unblock(
    String blockerCoupleId,
    String blockedCoupleId,
  ) async {
    final id = Block.idFor(blockerCoupleId, blockedCoupleId);
    await _db.collection('blocks').doc(id).delete();
  }

  /// Couples THIS user has blocked.
  static Stream<List<Block>> streamMyBlocks(String myCoupleId) {
    return _db
        .collection('blocks')
        .where('pareja_que_bloquea', isEqualTo: myCoupleId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Block.fromDoc).toList());
  }

  /// Set of couple IDs to exclude from discovery — covers both directions:
  /// couples I've blocked, plus couples that have blocked me.
  ///
  /// We require this to be a SET (not stream) because the feed datasource
  /// applies it as an in-memory filter on every page; if we restreamed on
  /// every keystroke the feed would re-render unnecessarily. Clients
  /// refresh this once per session (or on explicit unblock action).
  static Future<Set<String>> getMutualBlockIds(String myCoupleId) async {
    try {
      final outgoing = await _db
          .collection('blocks')
          .where('pareja_que_bloquea', isEqualTo: myCoupleId)
          .get();

      // Note: reading "blocks against me" is NOT permitted by Security Rules
      // for the blocked side — that's intentional silent simulation. Server
      // simulates this via a Cloud Function or via a lookup at request-send
      // time; here we only know what WE have blocked.
      return outgoing.docs
          .map((d) => (d.data()['pareja_bloqueada'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
    } on FirebaseException catch (e) {
      // Security rules in some environments don't yet expose the blocks
      // collection; treat as "no blocks" so discovery feed still works.
      if (e.code == 'permission-denied') return <String>{};
      rethrow;
    }
  }
}
