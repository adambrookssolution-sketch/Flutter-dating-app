import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/data/datasource/couples_datasource.dart';
import 'package:app/data/datasource/message_requests_datasource.dart';
import 'package:app/data/models/message_request.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/inbox/message_request_preview_screen.dart';

/// Sliver-shaped section that lists incoming pending [MessageRequest]s.
///
/// Rendered ABOVE the legacy "Requests" section inside
/// [InboxScreen]. Empty state returns a zero-height SliverToBoxAdapter so
/// users who never received a Request don't see extra chrome.
///
/// Each row shows:
///   - Sender's first photo (preview)
///   - Display name
///   - Truncated initial message
///   - Age of the request (relative)
///
/// Tapping opens [MessageRequestPreviewScreen] which has the Accept / Dismiss
/// buttons and full message body.
class MessageRequestsSection extends StatelessWidget {
  const MessageRequestsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return StreamBuilder<List<MessageRequest>>(
      stream: MessageRequestsDatasource.streamReceivedPending(uid),
      builder: (context, snap) {
        final requests = snap.data ?? const <MessageRequest>[];
        if (requests.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverMainAxisGroup(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  const Text(
                    'Message requests',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB31637),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '${requests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList.separated(
            itemCount: requests.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 66, color: Colors.grey[200]),
            itemBuilder: (_, i) => _RequestRow(request: requests[i]),
          ),
        ]);
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  final MessageRequest request;

  const _RequestRow({required this.request});

  Future<void> _open(BuildContext context) async {
    final sender = await CouplesDatasource.getCouple(request.parejaEmisora);
    if (!context.mounted) return;
    if (sender == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.senderProfileUnavailable)),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageRequestPreviewScreen(
          request: request,
          sender: sender,
        ),
      ),
    );
  }

  String _age(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: request.fotoPreview != null
            ? NetworkImage(request.fotoPreview!)
            : null,
        child: request.fotoPreview == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        request.mensajeInicial,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _age(request.fechaEnvio),
        style:
            const TextStyle(fontSize: 12, color: Color(0xFFA4A4AA)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(context),
    );
  }
}
