import 'dart:async';
import 'dart:io';

import 'package:app/data/datasource/conversation_datasource.dart';
import 'package:app/data/datasource/couples_datasource.dart';
import 'package:app/data/models/firestore_message.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/report/report_screen.dart';
import 'package:app/presentation/widgets/conversation_row.dart';
import 'package:app/presentation/widgets/secure_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// ── Local display model ────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final DateTime time;
  final bool isMe;
  /// Optional attached image URL (agency feature). When set, the bubble
  /// renders the image above any text (text may be empty for
  /// image-only sends).
  final String? imageUrl;

  const ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
    this.imageUrl,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  /// When set, lets the chat header tap into the partner's full profile
  /// detail screen (agency-merged 2026-05-16). Null disables the tap.
  final UserProfile? otherProfile;

  /// Pre-fills the message composer with this text (used when the user
  /// taps a quick-starter template before opening the chat).
  final String? initialMessage;

  const ChatScreen({
    super.key,
    required this.conversation,
    this.otherProfile,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color _myBubble = Color(0xFFB01030);
  static const Color _theirBubble = Color(0xFFF1F1F1);
  static const Color _inputBg = Color(0xFFF1F1F1);

  static const List<List<Color>> _gradients = [
    [Color(0xFFFF6B9D), Color(0xFFC44CFF)],
    [Color(0xFF4ECAFF), Color(0xFF3B82F6)],
    [Color(0xFF66BB6A), Color(0xFF26A69A)],
    [Color(0xFFFF8A65), Color(0xFFE91E63)],
    [Color(0xFFFFB74D), Color(0xFFE64A19)],
    [Color(0xFF9C27B0), Color(0xFF3F51B5)],
  ];

  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final String _myUid;
  late final int _suggestionIndex;

  StreamSubscription<List<FirestoreMessage>>? _msgSubscription;
  List<ChatMessage> _messages = [];
  bool _messagesLoading = true;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Pick a stable suggestion index for this conversation. Resolved to a
    // localised string lazily during build via [_suggestionFor].
    _suggestionIndex =
        widget.conversation.conversationId.hashCode.abs() % 6;
    _listenMessages();
  }

  /// Localised quick-reply suggestion for the empty-chat hero. Pulls
  /// `chatSuggestion1` … `chatSuggestion6` from [AppLocalizations] using
  /// the per-conversation index chosen in [initState].
  String _suggestionFor(AppLocalizations l) {
    switch (_suggestionIndex) {
      case 0:
        return l.chatSuggestion1;
      case 1:
        return l.chatSuggestion2;
      case 2:
        return l.chatSuggestion3;
      case 3:
        return l.chatSuggestion4;
      case 4:
        return l.chatSuggestion5;
      default:
        return l.chatSuggestion6;
    }
  }

  @override
  void dispose() {
    _msgSubscription?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Firestore message stream ───────────────────────────────────────────────

  void _listenMessages() {
    final convId = widget.conversation.conversationId;
    if (convId.isEmpty) {
      setState(() => _messagesLoading = false);
      return;
    }
    _msgSubscription =
        ConversationDatasource.messagesStream(convId).listen((firestoreMsgs) {
      if (!mounted) return;
      final mapped = firestoreMsgs
          .map((m) => ChatMessage(
                text: m.text,
                time: m.createdAt,
                isMe: m.senderUid == _myUid,
                imageUrl: m.imageUrl,
              ))
          .toList();
      setState(() {
        _messages = mapped;
        _messagesLoading = false;
      });
      if (_messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }, onError: (_) {
      if (mounted) setState(() => _messagesLoading = false);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Color> get _avatarGradient =>
      _gradients[widget.conversation.gradientIndex % _gradients.length];

  String _dateLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(time.year, time.month, time.day);
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    return DateFormat('dd/MM/yyyy').format(time);
  }

  List<Object> get _flatList {
    final items = <Object>[];
    DateTime? lastDay;
    for (final msg in _messages) {
      final day = DateTime(msg.time.year, msg.time.month, msg.time.day);
      if (lastDay == null || day != lastDay) {
        items.add(_dateLabel(msg.time));
        lastDay = day;
      }
      items.add(msg);
    }
    return items;
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _myUid.isEmpty) return;
    _textCtrl.clear();
    ConversationDatasource.sendMessage(
      widget.conversation.conversationId,
      _myUid,
      text,
    );
  }

  /// Pick → upload → send as image message. The bucket path follows the
  /// same `chats/{conversationId}/...` convention agency uses so both
  /// clients can read each other's attachments without rule changes
  /// (the catch-all rule `request.auth != null` already covers it).
  Future<void> _attachImage() async {
    if (_myUid.isEmpty) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;
    final convId = widget.conversation.conversationId;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref()
        .child('chats/$convId/$stamp.jpg');
    try {
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await ConversationDatasource.sendMessage(
        convId,
        _myUid,
        '',
        imageUrl: url,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image send failed: $e')),
      );
    }
  }

  void _useSuggestion() {
    final l10n = AppLocalizations.of(context)!;
    _textCtrl.text = _suggestionFor(l10n);
    _textCtrl.selection =
        TextSelection.collapsed(offset: _textCtrl.text.length);
    _focusNode.requestFocus();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SecureView(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_messagesLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFB01030),
        ),
      );
    }
    return _messages.isEmpty ? _buildEmptyState() : _buildMessageList();
  }

  // ── AppBar avatar ─────────────────────────────────────────────────────────

  Widget _buildAppBarAvatar() {
    final photoUrl = widget.conversation.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _gradientAvatar(),
        ),
      );
    }
    return _gradientAvatar();
  }

  Widget _gradientAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _avatarGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.favorite, color: Colors.white30, size: 16),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.black87,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _buildAppBarAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${widget.conversation.name1} & ${widget.conversation.name2}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: (value) async {
            if (value == 'report') await _openReport();
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'report',
              child: Text(AppLocalizations.of(ctx)!.reportCouple),
            ),
          ],
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5E5E5)),
      ),
    );
  }

  /// Derives the other couple's ID from the deterministic conversation ID
  /// (`[uidA, uidB].sort().join('_')`) and opens the Report screen.
  Future<void> _openReport() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    final parts = widget.conversation.conversationId.split('_');
    final otherId = parts.firstWhere(
      (p) => p != me,
      orElse: () => '',
    );
    if (otherId.isEmpty) return;

    final other = await CouplesDatasource.getCouple(otherId);
    if (!mounted) return;
    if (other == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotLoadCoupleProfile)),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportScreen(reported: other)),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final timeLabel =
        'Today  ${DateFormat('HH:mm').format(DateTime.now())}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateChip(label: timeLabel),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Start your conversation…\nyour story begins here. 🌟',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black45,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _useSuggestion,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _myBubble,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _suggestionFor(AppLocalizations.of(context)!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    final items = _flatList;
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is String) return _DateChip(label: item);
        if (item is ChatMessage) return _buildBubble(item, items, i);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBubble(ChatMessage msg, List<Object> items, int index) {
    final next =
        index + 1 < items.length && items[index + 1] is ChatMessage
            ? items[index + 1] as ChatMessage
            : null;
    final isTail = next == null || next.isMe != msg.isMe;

    const full = Radius.circular(18);
    const tip = Radius.circular(4);

    final borderRadius = msg.isMe
        ? BorderRadius.only(
            topLeft: full,
            topRight: full,
            bottomLeft: full,
            bottomRight: isTail ? tip : full,
          )
        : BorderRadius.only(
            topLeft: full,
            topRight: full,
            bottomLeft: isTail ? tip : full,
            bottomRight: full,
          );

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: isTail ? 6 : 2,
            left: msg.isMe ? 60 : 0,
            right: msg.isMe ? 0 : 60,
          ),
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
          decoration: BoxDecoration(
            color: msg.isMe ? _myBubble : _theirBubble,
            borderRadius: borderRadius,
          ),
          child: Column(
            crossAxisAlignment:
                msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    msg.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : const SizedBox(
                            height: 120,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                if (msg.text.isNotEmpty) const SizedBox(height: 6),
              ],
              if (msg.text.isNotEmpty)
                Text(
                  msg.text,
                  style: TextStyle(
                    color: msg.isMe ? Colors.white : Colors.black87,
                    fontSize: 14.5,
                    height: 1.35,
                  ),
                )
              else if (msg.imageUrl == null || msg.imageUrl!.isEmpty)
                Text(
                  msg.text,
                  style: TextStyle(
                    color: msg.isMe ? Colors.white : Colors.black87,
                    fontSize: 14.5,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 3),
              Text(
                DateFormat('HH:mm').format(msg.time),
                style: TextStyle(
                  color: msg.isMe
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.35),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach-image button — gallery picker, uploads to
            // chats/{conversationId}/{ts}.jpg in Storage, then sends
            // the image as a message with imageUrl set.
            GestureDetector(
              onTap: _attachImage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _inputBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: Color(0xFFB01030),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textCtrl,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type something...',
                    hintStyle:
                        TextStyle(color: Colors.black38, fontSize: 14.5),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _inputBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFB01030),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date chip ─────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
