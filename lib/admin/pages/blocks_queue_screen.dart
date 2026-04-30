import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:app/admin/admin_app.dart';

/// Blocks queue — the global view of who has blocked whom. Read-only.
///
/// Useful when investigating a complaint chain ("did the same couple
/// trigger blocks from multiple users in a short window?"). Auto-blocks
/// triggered by the `onSuspension` Cloud Function show up alongside
/// manual blocks the same way.
///
/// Queries: `blocks order by created_at desc limit 200`.
class BlocksQueueScreen extends StatelessWidget {
  const BlocksQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('blocks')
          .orderBy('created_at', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _Msg(
            icon: Icons.error_outline,
            title: 'No se pudo cargar',
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
          return const _Msg(
            icon: Icons.block,
            title: 'Sin bloqueos',
            body: 'Aún no se han registrado bloqueos en la plataforma.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _BlockCard(data: docs[i].data()),
        );
      },
    );
  }
}

class _BlockCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BlockCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final blocker = (data['blocker_couple_id'] as String?) ?? '';
    final blocked = (data['blocked_couple_id'] as String?) ?? '';
    final origin = (data['origin'] as String?) ?? 'manual';
    final created = (data['created_at'] as Timestamp?)?.toDate();
    final auto = origin == 'auto' || origin == 'suspension';
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
                    color: auto
                        ? AdminApp.purple.withValues(alpha: 0.18)
                        : AdminApp.burgundy.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: auto
                          ? AdminApp.purple.withValues(alpha: 0.4)
                          : AdminApp.burgundy.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    auto ? 'auto · suspensión' : 'manual',
                    style: TextStyle(
                      color: auto
                          ? AdminApp.purple
                          : AdminApp.burgundyLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (created != null)
                  Text(
                    _rel(created),
                    style: const TextStyle(
                        color: AdminApp.textMuted, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _kv('Bloqueador', blocker),
            const SizedBox(height: 4),
            _kv('Bloqueada', blocked),
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

  String _rel(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'ahora';
    if (d.inHours < 1) return '${d.inMinutes} min';
    if (d.inDays < 1) return '${d.inHours} h';
    return '${d.inDays} d';
  }
}

class _Msg extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Msg({required this.icon, required this.title, required this.body});

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
