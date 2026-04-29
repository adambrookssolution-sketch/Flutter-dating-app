import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class ConversationModel {
  final String conversationId;
  final String name1;
  final String name2;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final int gradientIndex;
  final bool isRequest;
  final String? photoUrl;

  const ConversationModel({
    required this.conversationId,
    required this.name1,
    required this.name2,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.gradientIndex,
    this.isRequest = false,
    this.photoUrl,
  });
}

// ── Widget ────────────────────────────────────────────────────────────────────

class ConversationRow extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback? onTap;

  const ConversationRow({super.key, required this.conversation, this.onTap});

  static const List<List<Color>> _gradients = [
    [Color(0xFFFF6B9D), Color(0xFFC44CFF)],
    [Color(0xFF4ECAFF), Color(0xFF3B82F6)],
    [Color(0xFF66BB6A), Color(0xFF26A69A)],
    [Color(0xFFFF8A65), Color(0xFFE91E63)],
    [Color(0xFFFFB74D), Color(0xFFE64A19)],
    [Color(0xFF9C27B0), Color(0xFF3F51B5)],
  ];

  static const Color _badgeColor = Color(0xFFB01030);
  static const double _avatarSize = 54.0;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(time.year, time.month, time.day);
    return msgDay == today
        ? DateFormat('HH:mm').format(time)
        : DateFormat('d/M/y').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(context)),
            const SizedBox(width: 8),
            _buildTimestamp(),
          ],
        ),
      ),
    );
  }

  // ── Avatar + unread badge ──────────────────────────────────────────────────

  Widget _buildAvatar() {
    final colors = _gradients[conversation.gradientIndex % _gradients.length];
    final photoUrl = conversation.photoUrl;

    Widget circle;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      circle = ClipOval(
        child: Image.network(
          photoUrl,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _gradientCircle(colors),
        ),
      );
    } else {
      circle = _gradientCircle(colors);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        if (conversation.unreadCount > 0)
          Positioned(
            bottom: -2,
            right: -2,
            child: _buildBadge(),
          ),
      ],
    );
  }

  Widget _gradientCircle(List<Color> colors) {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.favorite, color: Colors.white30, size: 22),
      ),
    );
  }

  Widget _buildBadge() {
    final n = conversation.unreadCount;
    final label = n > 99 ? '99+' : '$n';
    // Pill for "99+", circle for 1–99
    final isWide = n > 99;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 4 : 0,
        vertical: 0,
      ),
      constraints: BoxConstraints(
        minWidth: 18,
        minHeight: 18,
        maxWidth: isWide ? 32 : 18,
        maxHeight: 18,
      ),
      decoration: BoxDecoration(
        color: _badgeColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }

  // ── Name + last message ────────────────────────────────────────────────────

  Widget _buildInfo(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${conversation.name1} & ${conversation.name2}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          conversation.lastMessage,
          style: TextStyle(
            fontSize: 13,
            color: hasUnread
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Timestamp ─────────────────────────────────────────────────────────────

  Widget _buildTimestamp() {
    final hasUnread = conversation.unreadCount > 0;
    return Text(
      _formatTime(conversation.lastMessageTime),
      style: TextStyle(
        fontSize: 11.5,
        color: hasUnread ? _badgeColor : Colors.grey[400],
        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
