import 'dart:io';

import 'package:app/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:app/data/datasource/community_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/comment_data.dart';
import 'package:app/data/models/community_post.dart';
import 'package:app/data/models/reply_data.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/presentation/pages/inbox/partner_profile_screen.dart';

// ignore_for_file: use_build_context_synchronously

// ── Option ────────────────────────────────────────────────────────────────────

class CommunityOption extends StatefulWidget {
  const CommunityOption({super.key});

  @override
  State<CommunityOption> createState() => _CommunityOptionState();
}

class _CommunityOptionState extends State<CommunityOption> {
  static const List<List<Color>> _gradients = [
    [Color(0xFFFF6B9D), Color(0xFFC44CFF)],
    [Color(0xFF4ECAFF), Color(0xFF3B82F6)],
    [Color(0xFF66BB6A), Color(0xFF26A69A)],
    [Color(0xFFFF8A65), Color(0xFFE91E63)],
    [Color(0xFFFFB74D), Color(0xFFE64A19)],
    [Color(0xFF9C27B0), Color(0xFF3F51B5)],
  ];

  UserProfile? _profile;
  List<CommunityPost> _posts = [];
  bool _loading = true;
  bool _hasError = false;
  /// Client feedback 2026-05-17 #7: the explicit-content filter lives
  /// here on the community feed (it was previously misplaced on the
  /// Couples filter). When true the feed shows ONLY posts tagged
  /// explicit; when false (default) explicit posts are hidden.
  bool _showExplicitFeed = false;
  final Set<String> _processingLikes = {};
  final Map<String, String?> _profilePhotoCache = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchPosts();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await ProfileDatasource.getProfile(uid);
    if (mounted) {
      setState(() {
        _profile = profile;
        if (profile != null && profile.photos.isNotEmpty) {
          _profilePhotoCache[uid] = profile.photos.first;
        }
      });
    }
  }

  Future<void> _fetchPosts() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final posts = await CommunityDatasource.fetchPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
        // Prefetch unique author photos
        final uids = posts.map((p) => p.uid).toSet();
        for (final uid in uids) {
          if (!_profilePhotoCache.containsKey(uid)) {
            _loadAuthorPhoto(uid);
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadAuthorPhoto(String uid) async {
    try {
      final profile = await ProfileDatasource.getProfile(uid);
      if (mounted && profile != null) {
        setState(() {
          _profilePhotoCache[uid] =
              profile.photos.isNotEmpty ? profile.photos.first : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _onPost(String text, XFile? image, bool isExplicit) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final authorPhotoUrl = (_profile != null && _profile!.photos.isNotEmpty)
        ? _profile!.photos.first
        : null;

    await CommunityDatasource.createPost(
      uid: uid,
      herName: _profile?.herName ?? '',
      hisName: _profile?.hisName ?? '',
      authorPhotoUrl: authorPhotoUrl,
      text: text,
      image: image,
      explicit: isExplicit,
    );
    await _fetchPosts();
  }

  Future<void> _toggleLike(int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final post = _posts[index];
    if (_processingLikes.contains(post.id)) return;

    final likedByMe = post.likedBy.contains(uid);

    setState(() {
      _processingLikes.add(post.id);
      _posts[index] = post.copyWith(
        likesCount: likedByMe
            ? (post.likesCount > 0 ? post.likesCount - 1 : 0)
            : post.likesCount + 1,
        likedBy: likedByMe
            ? post.likedBy.where((u) => u != uid).toList()
            : [...post.likedBy, uid],
      );
    });

    try {
      await CommunityDatasource.toggleLike(post.id, uid);
    } catch (_) {
      if (mounted) setState(() => _posts[index] = post);
    } finally {
      if (mounted) setState(() => _processingLikes.remove(post.id));
    }
  }

  Future<void> _deletePost(int index) async {
    final post = _posts[index];
    setState(() => _posts.removeAt(index));
    await CommunityDatasource.deletePost(post.id, post.imageUrl);
  }

  int _gradientFor(String uid) {
    if (uid.isEmpty) return 0;
    return uid.codeUnits.reduce((a, b) => a + b) % _gradients.length;
  }

  void _onCommentAdded(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    setState(() {
      _posts[index] = _posts[index].copyWith(
        commentsCount: _posts[index].commentsCount + 1,
      );
    });
  }

  void _openComments(CommunityPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(
        postId: post.id,
        postAuthorUid: post.uid,
        currentUid: FirebaseAuth.instance.currentUser?.uid ?? '',
        profile: _profile,
        gradients: _gradients,
        photoCache: _profilePhotoCache,
        onCommentAdded: () => _onCommentAdded(post.id),
      ),
    );
  }

  Future<void> _openProfile(String uid) async {
    final profile = await ProfileDatasource.getProfile(uid);
    if (profile != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PartnerProfileScreen(profile: profile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Apply the explicit-feed split (client 2026-05-17 #7):
    // _showExplicitFeed=false  → only non-explicit posts (default feed)
    // _showExplicitFeed=true   → only explicit posts (opt-in surface)
    final visiblePosts = _posts
        .where((p) => p.explicit == _showExplicitFeed)
        .toList(growable: false);

    return Column(
      children: [
        const SizedBox(height: 8),
        _FloatingComposer(onPost: _onPost),
        const SizedBox(height: 6),
        // Explicit-feed toggle. Sits between the composer and the feed
        // so the surface change is obvious. When OFF (default) the
        // main feed shows non-explicit posts; when ON it switches to
        // the dedicated explicit-only view.
        GestureDetector(
          onTap: () =>
              setState(() => _showExplicitFeed = !_showExplicitFeed),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _showExplicitFeed
                  ? const Color(0xFFB31637)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _showExplicitFeed
                      ? Icons.visibility
                      : Icons.visibility_outlined,
                  size: 18,
                  color: _showExplicitFeed
                      ? Colors.white
                      : Colors.black54,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.communityShowExplicit,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _showExplicitFeed
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
                Switch(
                  value: _showExplicitFeed,
                  onChanged: (v) => setState(() => _showExplicitFeed = v),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.black26,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchPosts,
            color: const Color(0xFFB31637),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFB31637),
                    ),
                  )
                : _hasError
                    ? _buildError()
                    : visiblePosts.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: visiblePosts.length,
                            separatorBuilder: (_, __) => const SizedBox(
                              height: 10,
                              child: ColoredBox(color: Color(0xFFF5F5F5)),
                            ),
                            itemBuilder: (context, i) => _PostCard(
                              post: visiblePosts[i],
                              gradients: _gradients,
                              gradientIndex:
                                  _gradientFor(visiblePosts[i].uid),
                              currentUid: uid,
                              commentCount: visiblePosts[i].commentsCount,
                              authorPhotoUrl:
                                  _profilePhotoCache[visiblePosts[i].uid] ??
                                      visiblePosts[i].authorPhotoUrl,
                              onLike: () => _toggleLike(
                                  _posts.indexOf(visiblePosts[i])),
                              onComment: () =>
                                  _openComments(visiblePosts[i]),
                              onAvatarTap: () =>
                                  _openProfile(visiblePosts[i].uid),
                              onDelete: visiblePosts[i].uid == uid
                                  ? () => _deletePost(
                                      _posts.indexOf(visiblePosts[i]))
                                  : null,
                            ),
                          ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Text(
                l10n.errorLoadPosts,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _fetchPosts,
                child: Text(
                  l10n.retry,
                  style: const TextStyle(
                    color: Color(0xFFB31637),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Text(
            l10n.noPosts,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final List<List<Color>> gradients;
  final int gradientIndex;
  final String currentUid;
  final int commentCount;
  final String? authorPhotoUrl;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onDelete;

  const _PostCard({
    required this.post,
    required this.gradients,
    required this.gradientIndex,
    required this.currentUid,
    required this.commentCount,
    this.authorPhotoUrl,
    required this.onLike,
    required this.onComment,
    this.onAvatarTap,
    this.onDelete,
  });

  static const Color _grey = Color(0xFFB9B9B9);

  bool get _likedByMe => post.likedBy.contains(currentUid);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),
          if (post.text.isNotEmpty)
            Text(
              post.text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.45,
              ),
            ),
          if (post.imageUrl != null) ...[
            if (post.text.isNotEmpty) const SizedBox(height: 10),
            _buildImage(),
          ],
          const SizedBox(height: 12),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = gradients[gradientIndex % gradients.length];
    final date = DateFormat('dd/MM/yyyy • hh:mm a')
        .format(post.createdAt)
        .toLowerCase();
    final name = post.hisName.isEmpty
        ? post.herName
        : '${post.herName} & ${post.hisName}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: _AvatarCircle(
            size: 44,
            colors: colors,
            photoUrl: authorPhotoUrl,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFFB9B9B9)),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: Color(0xFFB9B9B9), size: 20),
            onSelected: (value) async {
              if (value != 'delete') return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    AppLocalizations.of(ctx)!.deletePostTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: Text(
                    AppLocalizations.of(ctx)!.cannotBeUndone,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        AppLocalizations.of(ctx)!.cancel,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        AppLocalizations.of(ctx)!.delete,
                        style: const TextStyle(
                          color: Color(0xFFB31637),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) onDelete!();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline,
                        color: Color(0xFFB31637), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(ctx)!.deletePost,
                      style: const TextStyle(color: Color(0xFFB31637)),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        post.imageUrl!,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: const Color(0xFFF1F1F1),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFFB31637),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        _LikeButton(
          likedByMe: _likedByMe,
          likesCount: post.likesCount,
          onTap: onLike,
        ),
        const SizedBox(width: 22),
        GestureDetector(
          onTap: onComment,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Icon(
                Icons.mode_comment_outlined,
                color: _grey,
                size: 22,
              ),
              const SizedBox(width: 5),
              Text(
                '$commentCount',
                style: const TextStyle(
                  fontSize: 13,
                  color: _grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Comments Sheet ────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final String postAuthorUid;
  final String currentUid;
  final UserProfile? profile;
  final List<List<Color>> gradients;
  final Map<String, String?> photoCache;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({
    required this.postId,
    required this.postAuthorUid,
    required this.currentUid,
    required this.profile,
    required this.gradients,
    required this.photoCache,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();
  bool _sending = false;

  String? _replyingToCommentId;
  String? _replyingToName;
  String? _replyingToUid;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setReply({
    required String commentId,
    String? replyToName,
    String? replyToUid,
  }) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToName = replyToName;
      _replyingToUid = replyToUid;
    });
    _focus.requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToName = null;
      _replyingToUid = null;
    });
  }

  Future<void> _openProfile(String uid) async {
    final profile = await ProfileDatasource.getProfile(uid);
    if (profile != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PartnerProfileScreen(profile: profile),
        ),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    await CommunityDatasource.deleteComment(widget.postId, commentId);
  }

  Future<void> _deleteReply(String commentId, String replyId) async {
    await CommunityDatasource.deleteReply(widget.postId, commentId, replyId);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _ctrl.clear();
    });
    final authorPhotoUrl =
        (widget.profile != null && widget.profile!.photos.isNotEmpty)
            ? widget.profile!.photos.first
            : null;
    try {
      if (_replyingToCommentId != null) {
        await CommunityDatasource.addReply(
          postId: widget.postId,
          commentId: _replyingToCommentId!,
          uid: widget.currentUid,
          herName: widget.profile?.herName ?? '',
          hisName: widget.profile?.hisName ?? '',
          authorPhotoUrl: authorPhotoUrl,
          text: text,
          replyToName: _replyingToName,
          replyToUid: _replyingToUid,
        );
        _clearReply();
      } else {
        await CommunityDatasource.addComment(
          postId: widget.postId,
          uid: widget.currentUid,
          herName: widget.profile?.herName ?? '',
          hisName: widget.profile?.hisName ?? '',
          authorPhotoUrl: authorPhotoUrl,
          text: text,
        );
        widget.onCommentAdded();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) _ctrl.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardH = mq.viewInsets.bottom;
    final safeBottom = mq.padding.bottom;
    final screenH = mq.size.height;
    final listMaxH =
        (screenH * 0.45 - keyboardH).clamp(80.0, screenH * 0.45);

    return Padding(
      padding: EdgeInsets.only(
        bottom: keyboardH > 0 ? keyboardH : safeBottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                AppLocalizations.of(context)!.comments,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),

            // Real-time comment list
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: listMaxH),
              child: StreamBuilder<List<CommentData>>(
                stream: CommunityDatasource.streamComments(widget.postId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFB31637),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final comments = snap.data ?? [];
                  if (comments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(ctx)!.noComments,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.black38, fontSize: 14),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      final canDelete = widget.currentUid == c.uid ||
                          widget.currentUid == widget.postAuthorUid;
                      return _CommentRow(
                        key: ValueKey(c.id),
                        postId: widget.postId,
                        comment: c,
                        gradients: widget.gradients,
                        currentUid: widget.currentUid,
                        postAuthorUid: widget.postAuthorUid,
                        canDelete: canDelete,
                        authorPhotoUrl:
                            widget.photoCache[c.uid] ?? c.authorPhotoUrl,
                        photoCache: widget.photoCache,
                        onDelete:
                            canDelete ? () => _deleteComment(c.id) : null,
                        onAvatarTap: _openProfile,
                        onDeleteReply: (replyId) =>
                            _deleteReply(c.id, replyId),
                        onReply: ({replyToName, replyToUid}) => _setReply(
                          commentId: c.id,
                          replyToName: replyToName,
                          replyToUid: replyToUid,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Reply pill
            if (_replyingToCommentId != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.reply,
                        size: 15, color: Color(0xFFB31637)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _replyingToName != null
                            ? AppLocalizations.of(context)!.replyingTo(_replyingToName!)
                            : AppLocalizations.of(context)!.replyingToComment,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB31637),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearReply,
                      child: const Icon(Icons.close,
                          size: 15, color: Color(0xFFB31637)),
                    ),
                  ],
                ),
              ),

            // Input bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        enabled: !_sending,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.addComment,
                          hintStyle: TextStyle(
                              color: Colors.black38, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB31637),
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Comment Row ───────────────────────────────────────────────────────────────

class _CommentRow extends StatefulWidget {
  final String postId;
  final CommentData comment;
  final List<List<Color>> gradients;
  final String currentUid;
  final String postAuthorUid;
  final bool canDelete;
  final String? authorPhotoUrl;
  final Map<String, String?> photoCache;
  final VoidCallback? onDelete;
  final void Function(String uid) onAvatarTap;
  final void Function(String replyId) onDeleteReply;
  final void Function({String? replyToName, String? replyToUid}) onReply;

  const _CommentRow({
    super.key,
    required this.postId,
    required this.comment,
    required this.gradients,
    required this.currentUid,
    required this.postAuthorUid,
    required this.canDelete,
    this.authorPhotoUrl,
    required this.photoCache,
    this.onDelete,
    required this.onAvatarTap,
    required this.onDeleteReply,
    required this.onReply,
  });

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow> {
  bool _showReplies = false;

  static String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'ahora';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    if (d.inDays < 28) return '${d.inDays ~/ 7}sem';
    if (d.inDays < 365) return '${d.inDays ~/ 30}mes';
    return '${d.inDays ~/ 365}a';
  }

  int _gradientFor(String uid) {
    if (uid.isEmpty) return 0;
    return uid.codeUnits.reduce((a, b) => a + b) % widget.gradients.length;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(ctx)!.deleteCommentTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(AppLocalizations.of(ctx)!.cannotBeUndone,
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx)!.cancel,
                style: const TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(ctx)!.delete,
                style: const TextStyle(
                    color: Color(0xFFB31637),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    final colors =
        widget.gradients[_gradientFor(c.uid) % widget.gradients.length];
    final name =
        c.hisName.isEmpty ? c.herName : '${c.herName} & ${c.hisName}';

    return InkWell(
      onLongPress:
          widget.canDelete ? () => _confirmDelete(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => widget.onAvatarTap(c.uid),
              child: _AvatarCircle(
                size: 36,
                colors: colors,
                photoUrl: widget.authorPhotoUrl,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _relTime(c.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.text,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  // Reply button
                  GestureDetector(
                    onTap: () => widget.onReply(
                        replyToName: null, replyToUid: null),
                    child: Text(
                      AppLocalizations.of(context)!.reply,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Toggle replies
                  if (c.repliesCount > 0) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showReplies = !_showReplies),
                      child: Row(
                        children: [
                          Container(
                              width: 24, height: 1, color: Colors.black26),
                          const SizedBox(width: 8),
                          Text(
                            _showReplies
                                ? AppLocalizations.of(context)!.hideReplies
                                : c.repliesCount == 1
                                    ? AppLocalizations.of(context)!.viewReply
                                    : AppLocalizations.of(context)!.viewReplies(c.repliesCount),
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Replies list
                  if (_showReplies)
                    StreamBuilder<List<ReplyData>>(
                      stream: CommunityDatasource.streamReplies(
                          widget.postId, c.id),
                      builder: (ctx, snap) {
                        final replies = snap.data ?? [];
                        if (snap.connectionState ==
                                ConnectionState.waiting &&
                            replies.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFB31637)),
                            ),
                          );
                        }
                        return Column(
                          children: replies.map((r) {
                            final canDeleteReply =
                                widget.currentUid == r.uid ||
                                    widget.currentUid ==
                                        widget.postAuthorUid ||
                                    widget.currentUid == c.uid;
                            final replyName = r.hisName.isEmpty
                                ? r.herName
                                : '${r.herName} & ${r.hisName}';
                            return _ReplyRow(
                              reply: r,
                              gradients: widget.gradients,
                              canDelete: canDeleteReply,
                              authorPhotoUrl: widget.photoCache[r.uid] ??
                                  r.authorPhotoUrl,
                              onDelete: canDeleteReply
                                  ? () => widget.onDeleteReply(r.id)
                                  : null,
                              onAvatarTap: () =>
                                  widget.onAvatarTap(r.uid),
                              onReply: () => widget.onReply(
                                replyToName: replyName,
                                replyToUid: r.uid,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reply Row ─────────────────────────────────────────────────────────────────

class _ReplyRow extends StatelessWidget {
  final ReplyData reply;
  final List<List<Color>> gradients;
  final bool canDelete;
  final String? authorPhotoUrl;
  final VoidCallback? onDelete;
  final VoidCallback onAvatarTap;
  final VoidCallback onReply;

  const _ReplyRow({
    required this.reply,
    required this.gradients,
    required this.canDelete,
    this.authorPhotoUrl,
    this.onDelete,
    required this.onAvatarTap,
    required this.onReply,
  });

  static String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'ahora';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    if (d.inDays < 28) return '${d.inDays ~/ 7}sem';
    if (d.inDays < 365) return '${d.inDays ~/ 30}mes';
    return '${d.inDays ~/ 365}a';
  }

  int _gradientFor() {
    if (reply.uid.isEmpty) return 0;
    return reply.uid.codeUnits.reduce((a, b) => a + b) % gradients.length;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(ctx)!.deleteReplyTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(AppLocalizations.of(ctx)!.cannotBeUndone,
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx)!.cancel,
                style: const TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(ctx)!.delete,
                style: const TextStyle(
                    color: Color(0xFFB31637),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = gradients[_gradientFor()];
    final name = reply.hisName.isEmpty
        ? reply.herName
        : '${reply.herName} & ${reply.hisName}';

    return InkWell(
      onLongPress: canDelete ? () => _confirmDelete(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: _AvatarCircle(
                size: 28,
                colors: colors,
                photoUrl: authorPhotoUrl,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _relTime(reply.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (reply.replyToName != null)
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '@${reply.replyToName} ',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB31637),
                              fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: reply.text,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.35),
                        ),
                      ]),
                    )
                  else
                    Text(
                      reply.text,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.35),
                    ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onReply,
                    child: Text(
                      AppLocalizations.of(context)!.reply,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating Composer ─────────────────────────────────────────────────────────

class _FloatingComposer extends StatefulWidget {
  final Future<void> Function(String text, XFile? image, bool isExplicit)
      onPost;

  const _FloatingComposer({required this.onPost});

  @override
  State<_FloatingComposer> createState() => _FloatingComposerState();
}

class _FloatingComposerState extends State<_FloatingComposer> {
  bool _expanded = false;
  bool _isPosting = false;
  XFile? _pickedImage;
  /// Client feedback 2026-05-17 #7: posts must be tagged as explicit
  /// when applicable, so the community feed can split them into the
  /// dedicated explicit surface. Defaults to false; the user toggles
  /// it on if their post belongs there.
  bool _isExplicit = false;
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _expanded = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _collapse() {
    setState(() {
      _expanded = false;
      _pickedImage = null;
      _isExplicit = false;
      _isPosting = false;
      _ctrl.clear();
    });
    _focus.unfocus();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _pickedImage == null) return;
    setState(() => _isPosting = true);
    try {
      await widget.onPost(text, _pickedImage, _isExplicit);
      if (mounted) _collapse();
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorPosting(e.toString())),
            backgroundColor: const Color(0xFFB31637),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(ctx)!.gallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(AppLocalizations.of(ctx)!.camera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );

    if (image != null && mounted) {
      setState(() => _pickedImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: _expanded ? null : _expand,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFB31637),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _expanded ? _buildExpanded() : _buildCollapsed(),
        ),
      ),
    );
  }

  Widget _buildCollapsed() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.shareWithCommunity,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.edit, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  minLines: 3,
                  maxLines: 6,
                  enabled: !_isPosting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.whatsOnYourMind,
                    hintStyle:
                        TextStyle(color: Colors.white60, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Image preview or add-image button
          if (_pickedImage != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(
                      File(_pickedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap:
                        _isPosting ? null : () => setState(() => _pickedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _isPosting ? null : _pickImage,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                AppLocalizations.of(context)!.addImage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          const SizedBox(height: 12),

          // Explicit-content tag (client feedback 2026-05-17 #7).
          // Posts marked here go to the dedicated explicit feed only;
          // the main community feed filters them out by default.
          GestureDetector(
            onTap: _isPosting
                ? null
                : () => setState(() => _isExplicit = !_isExplicit),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isExplicit
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!
                          .communityMarkExplicitTag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Share button
          ElevatedButton(
            onPressed: _isPosting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: _isPosting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFB31637),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send, size: 17, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.postToCommunity,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Like button with scale animation ─────────────────────────────────────────

class _LikeButton extends StatefulWidget {
  final bool likedByMe;
  final int likesCount;
  final VoidCallback onTap;

  const _LikeButton({
    required this.likedByMe,
    required this.likesCount,
    required this.onTap,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  static const Color _grey = Color(0xFFB9B9B9);
  static const Color _red = Color(0xFFB31637);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.3,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          ScaleTransition(
            scale: _scale,
            child: Icon(
              widget.likedByMe ? Icons.favorite : Icons.favorite_border,
              color: widget.likedByMe ? _red : _grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${widget.likesCount}',
            style: TextStyle(
              fontSize: 13,
              color: widget.likedByMe ? _red : _grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared avatar ─────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final double size;
  final List<Color> colors;
  final String? photoUrl;

  const _AvatarCircle({
    required this.size,
    required this.colors,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.favorite,
        color: Colors.white30,
        size: size * 0.4,
      ),
    );
  }
}
