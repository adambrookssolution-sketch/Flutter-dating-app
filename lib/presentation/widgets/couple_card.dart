import 'package:flutter/material.dart';

import 'package:app/l10n/app_localizations.dart';

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

  /// Invoked when the user confirms "Block this couple" from the overflow
  /// menu. Null hides the menu item.
  final VoidCallback? onBlock;

  /// Invoked when the user picks "Report" from the overflow menu. Null
  /// hides the menu item.
  final VoidCallback? onReport;

  /// Whether the heart button shows the filled "favorited" state.
  /// Agency feature merged 2026-05-16 (`Favorite Couples` screen).
  final bool isFavorite;

  /// Invoked when the user taps the heart toggle. Null hides the toggle.
  final VoidCallback? onToggleFavorite;

  /// Invoked when the user taps anywhere on the card. Used by the
  /// favorite-couples list to push the partner-profile detail screen.
  final VoidCallback? onTap;

  const CoupleCard({
    super.key,
    required this.profile,
    this.onStartConversation,
    this.onBlock,
    this.onReport,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.onTap,
  });

  @override
  State<CoupleCard> createState() => _CoupleCardState();
}

class _CoupleCardState extends State<CoupleCard> {
  static const Color _burgundy = Color(0xFFB01030);

  bool _isFavorite = false;
  // Photo index will be mutable once we re-introduce left/right tap
  // navigation between photos; keep as non-final to avoid churn later.
  // ignore: prefer_final_fields
  int _currentPhoto = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final container = Container(
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
          // Top-right: only the overflow menu (block / report). Client
          // feedback 2026-05-17 #4: tapping the card already opens the
          // partner-profile detail, so the separate ⓘ button was
          // redundant and we removed it. The heart bubble stays centred
          // at the top via the Positioned row above.
          if (widget.onBlock != null || widget.onReport != null)
            Positioned(
              top: 12,
              right: 12,
              child: _overflowMenu(context),
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
    if (widget.onTap == null) return container;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: container,
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
    // Client feedback 2026-05-16: photos must fill the card 100%. The
    // earlier #11 patch switched to BoxFit.contain to "preserve" the
    // image but produced very large black bars on tall portrait cards,
    // which the client reported as worse than gentle side-cropping. We
    // restore BoxFit.cover here; the wider card insets (4px instead of
    // 16px) from the same #11 fix already minimise the crop, and the
    // bottom-gradient + name block sit on top of the photo so the
    // composition still matches the agency reference.
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

  /// Safety-actions menu (block + report). Rendered as a small dark
  /// pill so it reads against either black card backgrounds or photo
  /// backgrounds without needing a separate scrim.
  Widget _overflowMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
      ),
      onSelected: (choice) {
        switch (choice) {
          case 'block':
            _confirmAndBlock(context);
          case 'report':
            widget.onReport?.call();
        }
      },
      itemBuilder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return [
          if (widget.onBlock != null)
            PopupMenuItem<String>(
              value: 'block',
              child: Row(children: [
                const Icon(Icons.block, color: Color(0xFFB01030), size: 18),
                const SizedBox(width: 10),
                Text(l10n.blockThisCouple),
              ]),
            ),
          if (widget.onReport != null)
            PopupMenuItem<String>(
              value: 'report',
              child: Row(children: [
                const Icon(Icons.flag_outlined,
                    color: Color(0xFFB01030), size: 18),
                const SizedBox(width: 10),
                Text(l10n.reportAction),
              ]),
            ),
        ];
      },
    );
  }

  Future<void> _confirmAndBlock(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block this couple?'),
        content: const Text(
          'They will no longer appear in your feed, Travel Match, or '
          'conversations. You can undo this later from Profile → Security.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block',
                style: TextStyle(color: Color(0xFFB01030))),
          ),
        ],
      ),
    );
    if (ok == true) widget.onBlock?.call();
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
