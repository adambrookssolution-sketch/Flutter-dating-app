import 'package:cloud_firestore/cloud_firestore.dart';

/// State of a Message Request lifecycle.
///
/// `expired` is set by a daily Cloud Function when `fecha_expiracion` passes
/// without action — the sender is never told (silent rejection rule).
enum RequestStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired');

  const RequestStatus(this.value);
  final String value;

  static RequestStatus fromString(String? raw) {
    for (final s in RequestStatus.values) {
      if (s.value == raw) return s;
    }
    return RequestStatus.pending;
  }
}

/// Where the request was initiated from — affects analytics and (later) the
/// visible badge in the receiver's inbox ("Travel Match request" vs regular).
enum RequestOrigin {
  travelMatch('travel_match'),
  busqueda('busqueda'),
  perfil('perfil');

  const RequestOrigin(this.value);
  final String value;

  static RequestOrigin fromString(String? raw) {
    for (final o in RequestOrigin.values) {
      if (o.value == raw) return o;
    }
    return RequestOrigin.busqueda;
  }
}

/// "Start Conversation" creates one of these — never an empty `conversations`
/// doc directly. The Conversation is created only when the receiver accepts.
///
/// Spanish field names match what the client requested in negotiation
/// (DECISIONS_LOG Point 4) and the agreed Firestore schema.
class MessageRequest {
  final String id;
  final String parejaEmisora;
  final String parejaReceptora;
  final String mensajeInicial;
  final String? fotoPreview;
  final List<String> interesesVisibles;
  final RequestStatus estado;
  final RequestOrigin origen;
  final DateTime? fechaEnvio;
  final DateTime? fechaExpiracion;

  const MessageRequest({
    required this.id,
    required this.parejaEmisora,
    required this.parejaReceptora,
    required this.mensajeInicial,
    this.fotoPreview,
    this.interesesVisibles = const [],
    this.estado = RequestStatus.pending,
    this.origen = RequestOrigin.busqueda,
    this.fechaEnvio,
    this.fechaExpiracion,
  });

  Map<String, dynamic> toMap() => {
        'pareja_emisora': parejaEmisora,
        'pareja_receptora': parejaReceptora,
        'mensaje_inicial': mensajeInicial,
        'foto_preview': fotoPreview,
        'intereses_visibles': interesesVisibles,
        'estado': estado.value,
        'origen': origen.value,
        'fecha_envio': fechaEnvio == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(fechaEnvio!),
        'fecha_expiracion': fechaExpiracion == null
            ? null
            : Timestamp.fromDate(fechaExpiracion!),
      };

  factory MessageRequest.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return MessageRequest(
      id: doc.id,
      parejaEmisora: (m['pareja_emisora'] as String?) ?? '',
      parejaReceptora: (m['pareja_receptora'] as String?) ?? '',
      mensajeInicial: (m['mensaje_inicial'] as String?) ?? '',
      fotoPreview: m['foto_preview'] as String?,
      interesesVisibles:
          List<String>.from(m['intereses_visibles'] as List? ?? []),
      estado: RequestStatus.fromString(m['estado'] as String?),
      origen: RequestOrigin.fromString(m['origen'] as String?),
      fechaEnvio: (m['fecha_envio'] as Timestamp?)?.toDate(),
      fechaExpiracion: (m['fecha_expiracion'] as Timestamp?)?.toDate(),
    );
  }

  /// Default expiration: 14 days from now (DECISIONS_LOG Point 4).
  static DateTime defaultExpiration({DateTime? from}) =>
      (from ?? DateTime.now()).add(const Duration(days: 14));
}
