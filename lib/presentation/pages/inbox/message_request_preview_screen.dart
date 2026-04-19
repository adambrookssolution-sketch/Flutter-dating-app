import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/data/datasource/conversation_datasource.dart';
import 'package:app/data/datasource/message_requests_datasource.dart';
import 'package:app/data/models/couple.dart';
import 'package:app/data/models/message_request.dart';
import 'package:app/presentation/widgets/secure_view.dart';

/// Receiver-side preview of a [MessageRequest].
///
/// Accept → marks the request accepted AND creates a conversation doc so
/// the existing Inbox "Chat messages" section picks it up immediately.
/// Dismiss → silent rejection (sender never learns the outcome per
/// DECISIONS_LOG Point 4).
class MessageRequestPreviewScreen extends StatefulWidget {
  final MessageRequest request;
  final Couple sender;

  const MessageRequestPreviewScreen({
    super.key,
    required this.request,
    required this.sender,
  });

  @override
  State<MessageRequestPreviewScreen> createState() =>
      _MessageRequestPreviewScreenState();
}

class _MessageRequestPreviewScreenState
    extends State<MessageRequestPreviewScreen> {
  bool _busy = false;

  Future<void> _accept() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    setState(() => _busy = true);
    try {
      await MessageRequestsDatasource.accept(widget.request.id);
      // Promote the Request to a real Conversation so existing inbox UI
      // picks it up. The sender gets a new "Chat" row; the receiver (us)
      // sees the conversation appear in the "Chat Messages" section.
      await ConversationDatasource.createConversation(
        me,
        widget.request.parejaEmisora,
      );
      // Seed the first message with the Request's initial content so the
      // conversation isn't empty.
      await ConversationDatasource.sendMessage(
        _deterministicConvId(me, widget.request.parejaEmisora),
        widget.request.parejaEmisora,
        widget.request.mensajeInicial,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not accept: $e')),
      );
    }
  }

  Future<void> _dismiss() async {
    setState(() => _busy = true);
    try {
      await MessageRequestsDatasource.reject(widget.request.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dismiss: $e')),
      );
    }
  }

  static String _deterministicConvId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  @override
  Widget build(BuildContext context) {
    final sender = widget.sender;
    final photo =
        sender.photos.isNotEmpty ? sender.photos.first : null;
    return SecureView(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Message request'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      photo != null ? NetworkImage(photo) : null,
                  child: photo == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${sender.partnerA.name} & ${sender.partnerB.name}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  sender.city,
                  style:
                      const TextStyle(color: Color(0xFFA4A4AA), fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.request.interesesVisibles.isNotEmpty) ...[
                const Text(
                  'Visible interests',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFFA4A4AA)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.request.interesesVisibles
                      .map((i) => Chip(
                            label: Text(i),
                            backgroundColor: const Color(0xFFF5E6EA),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'Their message',
                style:
                    TextStyle(fontSize: 13, color: Color(0xFFA4A4AA)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.request.mensajeInicial,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _dismiss,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(250),
                        ),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB31637),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(250),
                        ),
                      ),
                      onPressed: _busy ? null : _accept,
                      child:
                          Text(_busy ? 'Working…' : 'Accept + chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
