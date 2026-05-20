import 'package:app/data/datasource/conversation_datasource.dart';
import 'package:app/data/datasource/couples_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/constants/app_colors.dart';
import 'package:app/presentation/pages/chat/chat_screen.dart';
import 'package:app/presentation/pages/inbox/partner_profile_screen.dart';
import 'package:app/presentation/widgets/conversation_row.dart';
import 'package:app/presentation/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestMatchScreen extends StatefulWidget {
  final String conversationId;
  final UserProfile otherProfile;

  const RequestMatchScreen({
    super.key,
    required this.conversationId,
    required this.otherProfile,
  });

  @override
  State<RequestMatchScreen> createState() => _RequestMatchScreenState();
}

class _RequestMatchScreenState extends State<RequestMatchScreen> {
  UserProfile? _myProfile;
  bool _loading = true;
  bool _accepting = false;
  /// Client feedback 2026-05-19 #3: the request screen must surface the
  /// message Pareja A sent, not just the photos + interests. We fetch
  /// the conversation's earliest message once on mount.
  String? _firstMessage;
  /// Client feedback 2026-05-20: the interests row sometimes came back
  /// empty because UserProfile.interests is the legacy CSV string and
  /// couples that filled in the new Dynamics-split fields write to
  /// the Couple doc instead. Fetch the Couple doc for the other party
  /// and merge `interests`, `dynamicsInterests` and `experience` into
  /// the displayed tag list — far more likely to surface something
  /// the viewer can actually decide on.
  List<String> _otherCoupleTags = const [];

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
    _loadFirstMessage();
    _loadOtherCoupleTags();
  }

  Future<void> _loadOtherCoupleTags() async {
    try {
      final couple =
          await CouplesDatasource.getCouple(widget.otherProfile.uid);
      if (!mounted || couple == null) return;
      final merged = <String>{
        ...couple.interests,
        ...couple.dynamicsInterests,
        ...couple.experience,
      };
      if (merged.isNotEmpty) {
        setState(() => _otherCoupleTags = merged.toList(growable: false));
      }
    } catch (_) {
      // Non-fatal — fall back to UserProfile.interests CSV if available.
    }
  }

  Future<void> _loadMyProfile() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid != null) {
      final profile = await ProfileDatasource.getProfile(myUid);
      if (mounted) {
        setState(() {
          _myProfile = profile;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFirstMessage() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('created_at')
          .limit(1)
          .get();
      if (!mounted || snap.docs.isEmpty) return;
      final text = (snap.docs.first.data()['text'] as String?)?.trim();
      if (text != null && text.isNotEmpty) {
        setState(() => _firstMessage = text);
      }
    } catch (_) {
      // Non-fatal — the screen still works without the message line.
    }
  }

  void _openPartnerProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PartnerProfileScreen(profile: widget.otherProfile),
      ),
    );
  }

  Future<void> _openConversation() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    setState(() => _accepting = true);

    try {
      await ConversationDatasource.acceptRequest(widget.conversationId, myUid);
    } catch (_) {
      if (mounted) setState(() => _accepting = false);
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversation: ConversationModel(
            conversationId: widget.conversationId,
            name1: widget.otherProfile.herName,
            name2: widget.otherProfile.hisName,
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
            gradientIndex: widget.conversationId.hashCode.abs() % 6,
            photoUrl: widget.otherProfile.photos.isNotEmpty
                ? widget.otherProfile.photos.first
                : null,
          ),
          otherProfile: widget.otherProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final other = widget.otherProfile;
    // Prefer the richer Couple-doc tags (loaded on mount); fall back to
    // the legacy CSV in UserProfile when the Couple fetch hasn't
    // arrived yet or the doc has no interests filled. Either way the
    // section always renders so the viewer can use it to decide
    // whether to connect (client feedback 2026-05-20).
    final legacyTags = other.interests.isEmpty
        ? const <String>[]
        : other.interests
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
    final tags =
        _otherCoupleTags.isNotEmpty ? _otherCoupleTags : legacyTags;

    return Column(
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),

        const Spacer(flex: 2),

        // Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "You're about to connect as couples",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // "{hisName} & {herName} like you too"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            '${other.hisName} & ${other.herName} like you too',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Overlapping avatars — tappable so the receiver can open the
        // partner profile detail (photos + interests + everything) and
        // make an informed decision before accepting. Client feedback
        // 2026-05-19 #3.
        GestureDetector(
          onTap: _openPartnerProfile,
          behavior: HitTestBehavior.opaque,
          child: _buildAvatarStack(),
        ),

        const SizedBox(height: 18),

        // First message from Pareja A (the request copy). Surfaces what
        // they actually wrote so the receiver knows the vibe before
        // accepting, instead of just two photos + tags.
        if (_firstMessage != null && _firstMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _firstMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),

        const SizedBox(height: 18),

        // Tags — always rendered (client 2026-05-20). When the other
        // couple hasn't authored any interests yet, surface a soft
        // placeholder instead of just hiding the row, so the viewer
        // doesn't wonder whether the data simply hasn't loaded.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: tags.isNotEmpty
              ? Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map(_buildTag).toList(),
                )
              : Text(
                  AppLocalizations.of(context)!
                      .requestMatchNoInterestsListed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),

        const Spacer(flex: 3),

        // Buttons — same style as auth_screen
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // "Open conversation" → mainLogin (white bg, dark text)
              _accepting
                  ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(250),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.buttonTextColor,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    )
                  : CustomButton(
                      buttonText: 'Open conversation',
                      type: ButtonType.mainLogin,
                      onTap: _openConversation,
                    ),
              const SizedBox(height: 13),
              // "Not now" → secondaryLogin (transparent bg, white border+text)
              CustomButton(
                buttonText: 'Not now',
                type: ButtonType.secondaryLogin,
                onTap: _accepting ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildAvatarStack() {
    const double size = 92.0;
    const double overlap = 30.0;
    const double totalWidth = size * 2 - overlap;

    final otherPhoto = widget.otherProfile.photos.isNotEmpty
        ? widget.otherProfile.photos.first
        : null;
    final myPhoto =
        _myProfile != null && _myProfile!.photos.isNotEmpty
            ? _myProfile!.photos.first
            : null;

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          // Other couple avatar (left / behind)
          Positioned(
            left: 0,
            child: _CircleAvatar(photoUrl: otherPhoto, size: size),
          ),
          // My avatar (right / in front)
          Positioned(
            left: size - overlap,
            child: _CircleAvatar(photoUrl: myPhoto, size: size),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.splashGradientStart,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Circle avatar widget ──────────────────────────────────────────────────────

class _CircleAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;

  const _CircleAvatar({required this.photoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: AppColors.splashGradientEnd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _FallbackIcon(),
              )
            : const _FallbackIcon(),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.splashGradientEnd,
      child: const Center(
        child: Icon(Icons.favorite, color: Colors.white38, size: 36),
      ),
    );
  }
}
