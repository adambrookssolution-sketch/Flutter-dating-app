import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/data/datasource/message_requests_datasource.dart';
import 'package:app/data/models/message_request.dart';

/// Dialog shown when tapping "Start Conversation" — instead of creating an
/// empty conversation doc, the couple writes a Message Request with an
/// initial message (DECISIONS_LOG Point 4: Request must contain content).
///
/// The receiver later sees the message preview in their Inbox; they accept
/// to spin up a conversation or silently dismiss.
///
/// `canSend` is queried before show so we can short-circuit:
///   - `deny` → user sees a friendly error (too many pending, can't request
///     self, etc.)
///   - `silent` → user is in cooldown after a rejection; we DON'T tell them,
///     we just pretend the request was sent (DECISIONS_LOG Point 4 silent
///     rejection rule).
class SendRequestDialog extends StatefulWidget {
  final String receiverCoupleId;
  final String receiverDisplayName;
  final String? receiverPhotoUrl;
  final List<String> receiverVisibleInterests;
  final RequestOrigin origen;

  const SendRequestDialog({
    super.key,
    required this.receiverCoupleId,
    required this.receiverDisplayName,
    this.receiverPhotoUrl,
    this.receiverVisibleInterests = const [],
    this.origen = RequestOrigin.busqueda,
  });

  /// Returns true when the flow completed (request sent or silently faked).
  /// Returns false/null when the user cancelled.
  static Future<bool?> show(
    BuildContext context, {
    required String receiverCoupleId,
    required String receiverDisplayName,
    String? receiverPhotoUrl,
    List<String> receiverVisibleInterests = const [],
    RequestOrigin origen = RequestOrigin.busqueda,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SendRequestDialog(
          receiverCoupleId: receiverCoupleId,
          receiverDisplayName: receiverDisplayName,
          receiverPhotoUrl: receiverPhotoUrl,
          receiverVisibleInterests: receiverVisibleInterests,
          origen: origen,
        ),
      ),
    );
  }

  @override
  State<SendRequestDialog> createState() => _SendRequestDialogState();
}

class _SendRequestDialogState extends State<SendRequestDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  static const int _minChars = 10;
  static const int _maxChars = 280;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.length < _minChars) {
      setState(() =>
          _error = 'Write at least $_minChars characters to introduce you.');
      return;
    }
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final pre = await MessageRequestsDatasource.canSend(
        senderCoupleId: me,
        receiverCoupleId: widget.receiverCoupleId,
      );

      switch (pre.kind) {
        case RequestPreflightKind.allow:
          await MessageRequestsDatasource.sendRequest(
            senderCoupleId: me,
            receiverCoupleId: widget.receiverCoupleId,
            mensajeInicial: text,
            fotoPreview: widget.receiverPhotoUrl,
            interesesVisibles: widget.receiverVisibleInterests,
            origen: widget.origen,
          );
          if (!mounted) return;
          Navigator.pop(context, true);
        case RequestPreflightKind.silent:
          // Cooldown — show success anyway, don't actually write.
          if (!mounted) return;
          Navigator.pop(context, true);
        case RequestPreflightKind.deny:
          setState(() {
            _busy = false;
            _error = _reasonMessage(pre.reason);
          });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not send request: $e';
      });
    }
  }

  String _reasonMessage(String? reason) => switch (reason) {
        'cannot_request_self' => "You can't send a request to yourself.",
        'too_many_pending' =>
          "You already have 10 pending requests. Wait for replies before sending more.",
        _ => 'Could not send request.',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFA4A4AA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Send a message to ${widget.receiverDisplayName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your message + first photo + visible interests will be shown '
            'as a Request in their Inbox.',
            style: TextStyle(fontSize: 12, color: Color(0xFFA4A4AA)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 5,
            maxLength: _maxChars,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Introduce yourselves — shared interests, trip plans…',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB01030),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(250),
                ),
              ),
              onPressed: _busy ? null : _send,
              child: Text(_busy ? 'Sending…' : 'Send request'),
            ),
          ),
        ],
      ),
    );
  }
}
