import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app/data/models/report.dart';
import 'blocks_datasource.dart';

/// Submit reports + read own report history.
///
/// Per Security Rules, only Cloud Functions can read other people's reports
/// and update statuses. Threshold checks (5 reports / 30d => suspend, 10
/// reports from one reporter / 7d => disable reporting) live server-side in
/// the `onReportCreated` Cloud Function.
class ReportsDatasource {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Submits a report. When [alsoBlock] is true (the default — checkbox is
  /// pre-checked per DECISIONS_LOG Point 5), atomically inserts a Block doc
  /// using [BlocksDatasource.block] so the user immediately stops seeing
  /// the reported couple.
  ///
  /// Returns the new report document ID.
  static Future<String> submitReport({
    required String reporterCoupleId,
    required String reportedCoupleId,
    required ReportCategory categoria,
    String descripcion = '',
    List<String> evidencia = const [],
    bool alsoBlock = true,
  }) async {
    final reportRef = _db.collection('reports').doc();
    final report = Report(
      id: reportRef.id,
      reporterCouple: reporterCoupleId,
      reportedCouple: reportedCoupleId,
      categoria: categoria,
      descripcion: descripcion,
      evidencia: evidencia,
    );

    if (alsoBlock) {
      // Two writes (different collections) — Firestore batch is the right tool
      final batch = _db.batch();
      batch.set(reportRef, report.toMap());
      BlocksDatasource.addBlockToBatch(
        batch: batch,
        blockerCoupleId: reporterCoupleId,
        blockedCoupleId: reportedCoupleId,
        origin: 'via_reporte',
      );
      await batch.commit();
    } else {
      await reportRef.set(report.toMap());
    }
    return reportRef.id;
  }

  /// Admin-only: mark a report as `reviewed` (kept and action taken)
  /// or `dismissed` (rejected, no action). The accompanying
  /// `accion_tomada` records the moderator's choice (none / warning /
  /// temp_suspension / permanent_ban). Stamps the moderator UID +
  /// review timestamp so the reporter's notification can quote the
  /// exact wording later (client 2026-05-17 #2 — report workflow).
  static Future<void> setReviewedByAdmin({
    required String reportId,
    required ReportStatus status,
    required ReportAction action,
    required String moderatorUid,
  }) async {
    await _db.collection('reports').doc(reportId).update({
      'estado': status.value,
      'accion_tomada': action.value,
      'moderador_id': moderatorUid,
      'reviewed_at': FieldValue.serverTimestamp(),
    });
  }

  /// History of reports submitted BY the current couple.
  /// (We never expose reports filed AGAINST us — DECISIONS_LOG Point 5
  /// total reporter confidentiality.)
  static Stream<List<Report>> streamMyReports(String myCoupleId) {
    return _db
        .collection('reports')
        .where('reporter_couple', isEqualTo: myCoupleId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Report.fromDoc).toList());
  }
}
