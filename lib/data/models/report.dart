import 'package:cloud_firestore/cloud_firestore.dart';

/// Closed list of report categories. "menor_edad" (suspected minor) is
/// elevated priority because the app is 21+ only.
enum ReportCategory {
  perfilFalso('perfil_falso'),
  acoso('acoso'),
  contenidoNoConsensuado('contenido_no_consensuado'),
  menorEdad('menor_edad'),
  spam('spam'),
  otro('otro');

  const ReportCategory(this.value);
  final String value;

  static ReportCategory fromString(String? raw) {
    for (final c in ReportCategory.values) {
      if (c.value == raw) return c;
    }
    return ReportCategory.otro;
  }
}

enum ReportStatus {
  pending('pending'),
  reviewed('reviewed'),
  dismissed('dismissed');

  const ReportStatus(this.value);
  final String value;

  static ReportStatus fromString(String? raw) {
    for (final s in ReportStatus.values) {
      if (s.value == raw) return s;
    }
    return ReportStatus.pending;
  }
}

enum ReportAction {
  none('none'),
  warning('warning'),
  tempSuspension('temp_suspension'),
  permanentBan('permanent_ban');

  const ReportAction(this.value);
  final String value;

  static ReportAction fromString(String? raw) {
    for (final a in ReportAction.values) {
      if (a.value == raw) return a;
    }
    return ReportAction.none;
  }
}

/// Reporter's identity is NEVER exposed to the reported couple
/// (DECISIONS_LOG Point 5 — total reporter confidentiality).
///
/// Field names use English snake_case for new fields; legacy contract docs
/// referenced Spanish names (pareja_reportante etc.) but we standardise here
/// — the migration guarantees no mismatch since this collection is created
/// fresh for the new feature.
class Report {
  final String id;
  final String reporterCouple;
  final String reportedCouple;
  final ReportCategory categoria;
  final String descripcion;
  final List<String> evidencia;
  final DateTime? fecha;
  final ReportStatus estado;
  final ReportAction accionTomada;
  final String? moderadorId;
  final DateTime? reviewedAt;

  const Report({
    required this.id,
    required this.reporterCouple,
    required this.reportedCouple,
    required this.categoria,
    this.descripcion = '',
    this.evidencia = const [],
    this.fecha,
    this.estado = ReportStatus.pending,
    this.accionTomada = ReportAction.none,
    this.moderadorId,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() => {
        'reporter_couple': reporterCouple,
        'reported_couple': reportedCouple,
        'categoria': categoria.value,
        'descripcion': descripcion,
        'evidencia': evidencia,
        'fecha': fecha == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(fecha!),
        'estado': estado.value,
        'accion_tomada': accionTomada.value,
        'moderador_id': moderadorId,
        'reviewed_at':
            reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      };

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return Report(
      id: doc.id,
      reporterCouple: (m['reporter_couple'] as String?) ?? '',
      reportedCouple: (m['reported_couple'] as String?) ?? '',
      categoria: ReportCategory.fromString(m['categoria'] as String?),
      descripcion: (m['descripcion'] as String?) ?? '',
      evidencia: List<String>.from(m['evidencia'] as List? ?? []),
      fecha: (m['fecha'] as Timestamp?)?.toDate(),
      estado: ReportStatus.fromString(m['estado'] as String?),
      accionTomada: ReportAction.fromString(m['accion_tomada'] as String?),
      moderadorId: m['moderador_id'] as String?,
      reviewedAt: (m['reviewed_at'] as Timestamp?)?.toDate(),
    );
  }
}
