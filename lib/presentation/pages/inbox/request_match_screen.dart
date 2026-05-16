import 'package:app/data/datasource/conversation_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/presentation/constants/app_colors.dart';
import 'package:app/presentation/pages/chat/chat_screen.dart';
import 'package:app/presentation/widgets/conversation_row.dart';
import 'package:app/presentation/widgets/custom_button.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
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
    final tags = other.interests.isNotEmpty
        ? other.interests
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList()
        : <String>[];

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

        // Overlapping avatars
        _buildAvatarStack(),

        const SizedBox(height: 32),

        // Tags
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: tags.map(_buildTag).toList(),
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
