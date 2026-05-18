import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:app/admin/admin_app.dart';

/// Reports queue — every report submitted by users, newest first.
///
/// Read-only for now: when the moderator wants to act on a report they
/// open the reported couple's verification card from the moderation tab.
/// The auto-suspension rule (5 reports / 30 days) still runs server-side
/// in `onReportCreated`; this screen exists so moderators can see the
/// stream of incoming complaints and intervene early when needed.
///
/// Queries: `reports order by created_at desc limit 200`.
class ReportsQueueScreen extends StatelessWidget {
  const ReportsQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Reports are timestamped on the `fecha` field, not `created_at`
      // (see [Report.toMap]). The previous orderBy('created_at')
      // silently dropped every document because Firestore excludes
      // docs missing the ordered field — that's why submitted reports
      // appeared to vanish on the admin side (client 2026-05-17 #2).
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('fecha', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _AdminMessage(
            icon: Icons.error_outline,
            title: 'No se pudo cargar la cola',
            body: snap.error.toString(),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const _AdminMessage(
            icon: Icons.report_gmailerrorred_rounded,
            title: 'Sin reportes',
            body: 'No hay denuncias pendientes en este momento.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ReportCard(data: docs[i].data()),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReportCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Field names match Report.toMap: snake_case but without the
    // `_id` suffix the older admin-card draft expected, and timestamps
    // live on `fecha` rather than `created_at`. Aligning these
    // resolved client 2026-05-17 #2 (submitted reports never showed up
    // in the admin queue — the read paths simply didn't match the
    // write paths).
    final category = (data['categoria'] as String?) ?? '—';
    final reason = (data['descripcion'] as String?) ?? '';
    final reporter = (data['reporter_couple'] as String?) ?? '';
    final reported = (data['reported_couple'] as String?) ?? '';
    final created = (data['fecha'] as Timestamp?)?.toDate();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminApp.burgundy.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AdminApp.burgundy.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: AdminApp.burgundyLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (created != null)
                  Text(
                    _formatRelative(created),
                    style: const TextStyle(
                        color: AdminApp.textMuted, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (reason.isNotEmpty)
              Text(
                reason,
                style: const TextStyle(color: AdminApp.textPrimary),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _kv('Reportada', reported),
                _kv('Reportante', reporter),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style:
                  const TextStyle(color: AdminApp.textMuted, fontSize: 12)),
          Text(value.isEmpty ? '—' : value,
              style: const TextStyle(
                  color: AdminApp.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );

  String _formatRelative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'ahora';
    if (d.inHours < 1) return '${d.inMinutes} min';
    if (d.inDays < 1) return '${d.inHours} h';
    return '${d.inDays} d';
  }
}

class _AdminMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _AdminMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AdminApp.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                  color: AdminApp.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminApp.textMuted)),
          ],
        ),
      ),
    );
  }
}
