import 'package:flutter/material.dart';

/// Data passed into a [CoupleCard] — kept deliberately flat so the card
/// widget has no dependency on the Firestore models and can be reused
/// in previews / storybook / admin screens.
class CoupleProfile {
  final String uid;
  final String name1;
  final int age1;
  final String name2;
  final int age2;
  final String location;
  final String description;
  final List<String> tags;
  final List<String> photos;

  /// Optional "March 15-22, 2026" string displayed below the location on
  /// the 2026-04-20 reference mock. Empty = nothing rendered.
  final String tripDateRange;

  int get photoCount => photos.isEmpty ? 1 : photos.length;

  const CoupleProfile({
    required this.uid,
    required this.name1,
    required this.age1,
    required this.name2,
    required this.age2,
    required this.location,
    required this.description,
    required this.tags,
    this.photos = const [],
    this.tripDateRange = '',
  });
}

/// Discovery feed couple card — **black background + burgundy border**
/// per the client's 2026-04-20 reference mock.
///
/// Layout matches the mock:
///   • Photo fills the full card (or solid black if no photos).
///   • White-circle heart button pinned to the top centre.
///   • At the bottom: names ("Lucy, 32 & Ray (33)"), location, trip dates,
///     description, then a row of filled burgundy tag chips.
///
/// The card deliberately has no per-card action buttons — the "Start
/// Conversation" and "Filters" CTAs live in the parent [StickyFeedActions]
/// widget so they operate on whichever couple is currently in view.
class CoupleCard extends StatefulWidget {
  final CoupleProfile profile;

  /// Kept for backwards-compat; the feed now uses the parent
  /// [StickyFeedActions] instead, but some callers still pass it.
  final VoidCallback? onStartConversation;

  const CoupleCard({
    super.key,
    required this.profile,
    this.onStartConversation,
  });

  @override
  State<CoupleCard> createState() => _CoupleCardState();
}

class _CoupleCardState extends State<CoupleCard> {
  static const Color _burgundy = Color(0xFFB31637);

  bool _isFavorite = false;
  // Photo index will be mutable once we re-introduce left/right tap
  // navigation between photos; keep as non-final to avoid churn later.
  // ignore: prefer_final_fields
  int _currentPhoto = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: _burgundy, width: 4),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPhotoLayer(p),
          _buildBottomGradient(),
          // Heart (favourite) button, centred near the top.
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(child: _favouriteBubble()),
          ),
          // Bottom text block — names, location, trip dates, description,
          // tags. Sits on the gradient so white text always reads.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: _buildInfoBlock(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoLayer(CoupleProfile p) {
    if (p.photos.isEmpty) {
      // No uploaded photo yet → solid black panel (matches mock).
      return const DecoratedBox(
        decoration: BoxDecoration(color: Colors.black),
      );
    }
    final url = p.photos[_currentPhoto % p.photos.length];
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const DecoratedBox(decoration: BoxDecoration(color: Colors.black)),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  // Soft black→transparent gradient so the text at the bottom stays legible
  // regardless of photo contents.
  Widget _buildBottomGradient() {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.55, 1.0],
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
        ),
      ),
    );
  }

  Widget _favouriteBubble() {
    return GestureDetector(
      onTap: () => setState(() => _isFavorite = !_isFavorite),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _burgundy,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildInfoBlock(CoupleProfile p) {
    // Client mock name format: "Lucy, 32 & Ray (33)".
    final firstName = p.name1.isEmpty ? '—' : p.name1;
    final secondName = p.name2.isEmpty ? '—' : p.name2;
    final displayName = '$firstName, ${p.age1} & $secondName (${p.age2})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        if (p.location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            p.location,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
        if (p.tripDateRange.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            p.tripDateRange,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
        if (p.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            p.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
        if (p.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: p.tags.take(4).map(_tagChip).toList(),
          ),
        ],
      ],
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _burgundy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
