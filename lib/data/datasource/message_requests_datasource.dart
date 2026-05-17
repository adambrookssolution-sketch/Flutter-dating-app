import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app/data/models/message_request.dart';

/// "Start Conversation" creates a [MessageRequest] in this collection rather
/// than an empty conversations doc — receiver previews the initial message,
/// photo, and visible interests before deciding to chat.
///
/// Business rules (DECISIONS_LOG Point 4):
/// - 14-day expiration (handled server-side by `expireRequests` Cloud Function)
/// - 30-day cooldown after rejection (enforced here in [canSend])
/// - Max 10 pending outgoing requests at any time
/// - Silent rejection: sender never learns that the receiver dismissed them
class MessageRequestsDatasource {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Pre-flight check before showing the "Send Request" UI. Returns null if
  /// the send is allowed; otherwise a localised reason string the UI can
  /// display.
  ///
  /// NOTE: silent rejection means we DO NOT tell the sender if they were
  /// recently rejected — instead the UI shows the same "request sent" toast
  /// and we just skip the actual write. That special-case is handled by
  /// [sendRequest] returning successfully without touching Firestore.
  static Future<RequestPreflight> canSend({
    required String senderCoupleId,
    required String receiverCoupleId,
  }) async {
    if (senderCoupleId == receiverCoupleId) {
      return const RequestPreflight.deny('cannot_request_self');
    }

    // Pending outgoing limit (10)
    final pendingOutgoing = await _db
        .collection('message_requests')
        .where('pareja_emisora', isEqualTo: senderCoupleId)
        .where('estado', isEqualTo: RequestStatus.pending.value)
        .count()
        .get();
    if ((pendingOutgoing.count ?? 0) >= 10) {
      return const RequestPreflight.deny('too_many_pending');
    }

    // 30-day cooldown after a rejection from this same receiver
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = await _db
        .collection('message_requests')
        .where('pareja_emisora', isEqualTo: senderCoupleId)
        .where('pareja_receptora', isEqualTo: receiverCoupleId)
        .where('estado', isEqualTo: RequestStatus.rejected.value)
        .where('fecha_envio', isGreaterThan: Timestamp.fromDate(cutoff))
        .limit(1)
        .get();
    if (recent.docs.isNotEmpty) {
      // Silent rejection: sender must be told it WORKED.
      return const RequestPreflight.silent();
    }

    return const RequestPreflight.allow();
  }

  /// Sends the request. When the preflight returned [RequestPreflight.silent],
  /// callers should NOT actually call this — they should just show the
  /// success UI without writing. We re-check preflight defensively here.
  static Future<String?> sendRequest({
    required String senderCoupleId,
    required String receiverCoupleId,
    required String mensajeInicial,
    String? fotoPreview,
    List<String> interesesVisibles = const [],
    RequestOrigin origen = RequestOrigin.busqueda,
  }) async {
    final pre = await canSend(
      senderCoupleId: senderCoupleId,
      receiverCoupleId: receiverCoupleId,
    );
    if (pre.kind == RequestPreflightKind.deny) return null;
    if (pre.kind == RequestPreflightKind.silent) return null;

    final ref = _db.collection('message_requests').doc();
    final req = MessageRequest(
      id: ref.id,
      parejaEmisora: senderCoupleId,
      parejaReceptora: receiverCoupleId,
      mensajeInicial: mensajeInicial,
      fotoPreview: fotoPreview,
      interesesVisibles: interesesVisibles,
      origen: origen,
      fechaExpiracion: MessageRequest.defaultExpiration(),
    );
    await ref.set(req.toMap());
    return ref.id;
  }

  /// Receiver accepts — updates the request, then the conversation creation
  /// is performed by the calling layer (which also seeds the first message).
  static Future<void> accept(String requestId) async {
    await _db.collection('message_requests').doc(requestId).update({
      'estado': RequestStatus.accepted.value,
    });
  }

  /// Silent rejection — sender is never told.
  static Future<void> reject(String requestId) async {
    await _db.collection('message_requests').doc(requestId).update({
      'estado': RequestStatus.rejected.value,
    });
  }

  /// IDs of every couple [myCoupleId] has sent a request to and that
  /// request is still pending or accepted. Used by the discovery feed
  /// to filter out couples we've already engaged with — once a request
  /// goes out, the recipient shouldn't reappear at the top of the
  /// stack (client feedback 2026-05-17 #9).
  static Future<Set<String>> getSentRequestReceiverIds(
    String myCoupleId,
  ) async {
    final snap = await _db
        .collection('message_requests')
        .where('pareja_emisora', isEqualTo: myCoupleId)
        .where('estado', whereIn: [
          RequestStatus.pending.value,
          RequestStatus.accepted.value,
        ])
        .get();
    return snap.docs
        .map((d) => (d.data()['pareja_receptora'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  /// Pending requests RECEIVED by [myCoupleId].
  static Stream<List<MessageRequest>> streamReceivedPending(
    String myCoupleId,
  ) {
    return _db
        .collection('message_requests')
        .where('pareja_receptora', isEqualTo: myCoupleId)
        .where('estado', isEqualTo: RequestStatus.pending.value)
        .orderBy('fecha_envio', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MessageRequest.fromDoc).toList());
  }
}

/// Preflight result for [MessageRequestsDatasource.canSend].
enum RequestPreflightKind { allow, deny, silent }

class RequestPreflight {
  final RequestPreflightKind kind;
  final String? reason;

  const RequestPreflight._(this.kind, [this.reason]);

  const RequestPreflight.allow() : this._(RequestPreflightKind.allow);
  const RequestPreflight.deny(String reason)
      : this._(RequestPreflightKind.deny, reason);
  const RequestPreflight.silent() : this._(RequestPreflightKind.silent);
}
