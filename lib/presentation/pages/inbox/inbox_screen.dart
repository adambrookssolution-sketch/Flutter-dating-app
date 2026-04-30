import 'dart:async';

import 'package:app/data/datasource/conversation_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/chat_conversation.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/layouts/system_layout.dart';
import 'package:app/presentation/pages/chat/chat_screen.dart';
import 'package:app/presentation/pages/inbox/message_requests_section.dart';
import 'package:app/presentation/pages/inbox/request_match_screen.dart';
import 'package:app/presentation/widgets/conversation_row.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ── Internal data class ───────────────────────────────────────────────────────

class _InboxItem {
  final ChatConversation conversation;
  final UserProfile otherProfile;
  final bool isRequest;

  const _InboxItem({
    required this.conversation,
    required this.otherProfile,
    required this.isRequest,
  });

  ConversationModel toConversationModel() => ConversationModel(
        conversationId: conversation.id,
        name1: otherProfile.herName,
        name2: otherProfile.hisName,
        lastMessage: conversation.lastMessage,
        lastMessageTime: conversation.lastMessageTime ??
            conversation.createdAt ??
            DateTime.now(),
        unreadCount: 0,
        gradientIndex: conversation.id.hashCode.abs() % 6,
        isRequest: isRequest,
        photoUrl: otherProfile.photos.isNotEmpty
            ? otherProfile.photos.first
            : null,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<_InboxItem>? _items;
  bool _loading = true;
  String? _error;

  // Section collapse state
  bool _requestsExpanded = true;
  bool _chatsExpanded = true;

  // Client request 2026-04-30 (#1): search bar across the conversation
  // list so moderators / power users can quickly find a couple by name
  // even when the inbox grows large.
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  StreamSubscription<List<ChatConversation>>? _convSub;
  // Cache so we don't re-fetch profiles on every stream event
  final Map<String, UserProfile> _profileCache = {};

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _convSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesQuery(_InboxItem item, String q) {
    if (q.isEmpty) return true;
    final ql = q.toLowerCase();
    final p = item.otherProfile;
    if (p.herName.toLowerCase().contains(ql)) return true;
    if (p.hisName.toLowerCase().contains(ql)) return true;
    final pair = '${p.hisName} & ${p.herName}'.toLowerCase();
    if (pair.contains(ql)) return true;
    return item.conversation.lastMessage.toLowerCase().contains(ql);
  }

  // ── Stream subscription ───────────────────────────────────────────────────

  void _subscribe() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      setState(() => _loading = false);
      return;
    }

    _convSub = ConversationDatasource.conversationsStream(myUid).listen(
      (conversations) => _onConversations(conversations, myUid),
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _loading = false;
          });
        }
      },
    );
  }

  Future<void> _onConversations(
    List<ChatConversation> conversations,
    String myUid,
  ) async {
    // Load profiles for any uid not yet cached
    final missing = <String>{};
    for (final conv in conversations) {
      final other = _otherUid(conv, myUid);
      if (other.isNotEmpty && !_profileCache.containsKey(other)) {
        missing.add(other);
      }
    }

    if (missing.isNotEmpty) {
      await Future.wait(missing.map((uid) async {
        final p = await ProfileDatasource.getProfile(uid);
        if (p != null) _profileCache[uid] = p;
      }));
    }

    final items = <_InboxItem>[];
    for (final conv in conversations) {
      final other = _otherUid(conv, myUid);
      final profile = _profileCache[other];
      if (profile == null) continue;

      final isByOther =
          conv.initiatedBy.isNotEmpty && conv.initiatedBy != myUid;
      final iHaveReplied = conv.repliedBy.contains(myUid);

      items.add(_InboxItem(
        conversation: conv,
        otherProfile: profile,
        isRequest: isByOther && !iHaveReplied,
      ));
    }

    // Sort: most recent last_message_time first
    items.sort((a, b) {
      final ta = a.conversation.lastMessageTime ??
          a.conversation.createdAt ??
          DateTime(0);
      final tb = b.conversation.lastMessageTime ??
          b.conversation.createdAt ??
          DateTime(0);
      return tb.compareTo(ta);
    });

    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    }
  }

  String _otherUid(ChatConversation conv, String myUid) =>
      conv.participants.firstWhere((uid) => uid != myUid, orElse: () => '');

  // ── Pull-to-refresh ───────────────────────────────────────────────────────

  Future<void> _refresh() async {
    _profileCache.clear();
    await _convSub?.cancel();
    _convSub = null;
    _subscribe();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openItem(_InboxItem item) {
    if (item.isRequest) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RequestMatchScreen(
            conversationId: item.conversation.id,
            otherProfile: item.otherProfile,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(conversation: item.toConversationModel()),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SystemLayout(
      appBarTitle: Row(
        children: [
          Text(
            l10n.navInbox,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      activeTab: NavTab.inbox,
      child: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB01030)),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFFB01030),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.error_outline, color: Colors.black38, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Could not load conversations',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final items = _items ?? [];
    final filtered =
        items.where((i) => _matchesQuery(i, _searchQuery)).toList();
    final requests = filtered.where((i) => i.isRequest).toList();
    final chats = filtered.where((i) => !i.isRequest).toList();

    // Note: empty state used to short-circuit here, but now that the
    // MessageRequestsSection can surface requests independently we always
    // render the sliver layout. A footer sliver below handles the fully-
    // empty case (no conversations + no pending requests).
    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFFB01030),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.chatSearchHint,
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF888888)),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear,
                              color: Color(0xFF888888)),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F6),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          // ── NEW: Message Requests (from message_requests/*) ───────────────
          const MessageRequestsSection(),

          // ── Legacy Requests (from conversations where replied_by lacks me) ─
          if (requests.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _CollapsibleSectionHeader(
                title: 'Requests',
                count: requests.length,
                expanded: _requestsExpanded,
                onToggle: () =>
                    setState(() => _requestsExpanded = !_requestsExpanded),
              ),
            ),
            if (_requestsExpanded)
              SliverList.separated(
                itemCount: requests.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, indent: 66, color: Colors.grey[200]),
                itemBuilder: (_, i) => ConversationRow(
                  conversation: requests[i].toConversationModel(),
                  onTap: () => _openItem(requests[i]),
                ),
              ),
          ],

          // ── Chat Messages ──────────────────────────────────────────────────
          if (chats.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _CollapsibleSectionHeader(
                title: l10n.chatMessageQuickStarters,
                count: chats.length,
                expanded: _chatsExpanded,
                onToggle: () =>
                    setState(() => _chatsExpanded = !_chatsExpanded),
              ),
            ),
            if (_chatsExpanded)
              SliverList.separated(
                itemCount: chats.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, indent: 66, color: Colors.grey[200]),
                itemBuilder: (_, i) => ConversationRow(
                  conversation: chats[i].toConversationModel(),
                  onTap: () => _openItem(chats[i]),
                ),
              ),
          ],

          if (requests.isEmpty && chats.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No conversations yet.\nStart connecting with couples!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Collapsible section header ────────────────────────────────────────────────

class _CollapsibleSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  const _CollapsibleSectionHeader({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFB01030),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0.0 : 0.5,
              duration: const Duration(milliseconds: 220),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 24,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
