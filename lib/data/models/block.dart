import 'package:cloud_firestore/cloud_firestore.dart';

/// How a block came to exist — drives audit trail and (in the case of
/// `auto_por_suspension`) lets the system explain to the blocker why a
/// previously-visible couple disappeared.
enum BlockOrigin {
  manual('manual'),
  viaReporte('via_reporte'),
  autoPorSuspension('auto_por_suspension');

  const BlockOrigin(this.value);
  final String value;

  static BlockOrigin fromString(String? raw) {
    for (final o in BlockOrigin.values) {
      if (o.value == raw) return o;
    }
    return BlockOrigin.manual;
  }
}

/// Blocks are bidirectional + invisible: when A blocks B, both A and B
/// disappear from each other's experience and neither is notified.
///
/// Document ID convention: `${blockerCoupleId}_${blockedCoupleId}` so we can
/// check existence cheaply with a single `exists()` call (see Security Rules).
class Block {
  final String id;
  final String parejaQueBloquea;
  final String parejaBloqueada;
  final DateTime? fecha;
  final BlockOrigin origen;

  const Block({
    required this.id,
    required this.parejaQueBloquea,
    required this.parejaBloqueada,
    this.fecha,
    this.origen = BlockOrigin.manual,
  });

  /// Deterministic doc ID (one direction). Pair check requires both
  /// `${a}_${b}` and `${b}_${a}` because blocks are recorded directionally
  /// even though their effect is bidirectional.
  static String idFor(String blocker, String blocked) => '${blocker}_$blocked';

  Map<String, dynamic> toMap() => {
        'pareja_que_bloquea': parejaQueBloquea,
        'pareja_bloqueada': parejaBloqueada,
        'fecha': fecha == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(fecha!),
        'origen': origen.value,
      };

  factory Block.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return Block(
      id: doc.id,
      parejaQueBloquea: (m['pareja_que_bloquea'] as String?) ?? '',
      parejaBloqueada: (m['pareja_bloqueada'] as String?) ?? '',
      fecha: (m['fecha'] as Timestamp?)?.toDate(),
      origen: BlockOrigin.fromString(m['origen'] as String?),
    );
  }
}
