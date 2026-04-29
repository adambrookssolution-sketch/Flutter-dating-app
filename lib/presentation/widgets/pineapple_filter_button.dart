import 'package:flutter/material.dart';

/// Golden pineapple filter button used on the Couples / Community feed.
///
/// ## Rendering trick (2026-04-22 client feedback)
///
/// The reference image the client sent is a full-bleed neon-glow render
/// of a pineapple on a *transparent* background — meaning the orange halo
/// fades into white around the edges. If you draw it at icon size inside
/// a bounded circular container, the glow gets clipped and the button
/// looks like "a pineapple inside a box" instead of "a glowing pineapple".
///
/// To match the mock we do the opposite: expose the image at roughly
/// 1.6× the visible hit-target, with **no container background**. The
/// white edges of the image blend into the white AppBar behind it so only
/// the orange halo + the central pineapple silhouette register visually.
///
/// The parent decides what the hit-target size is via [size]. That's the
/// InkWell area users actually tap; the image itself overflows outside
/// that circle and is allowed to bleed over neighbouring whitespace.
///
/// ## Integration
///
/// Place in the AppBar actions slot so the pineapple sits on the white
/// header:
///
/// ```dart
/// appBarActions: [
///   Padding(
///     padding: const EdgeInsets.only(right: 12),
///     child: PineappleFilterButton(
///       size: 40,
///       onTap: _openFilters,
///     ),
///   ),
/// ],
/// ```
///
/// The optional [activeCount] badge overlays a small burgundy chip with
/// the number of filters currently applied — pass `null` or `0` to hide.
class PineappleFilterButton extends StatelessWidget {
  const PineappleFilterButton({
    super.key,
    this.onTap,
    this.activeCount,
    this.size = 40,
  });

  final VoidCallback? onTap;
  final int? activeCount;

  /// Hit-target diameter. The glow image itself renders at ~1.6× this
  /// size and is allowed to overflow outside the circle.
  final double size;

  @override
  Widget build(BuildContext context) {
    // Overflow factor: glow image is ~60% larger than the hit-target so
    // the halo fades outside the tap area. The AppBar's white background
    // absorbs that halo visually.
    final imageSize = size * 1.6;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Full-bleed glow image — no container background; white halo
          // edges are meant to blend into the white AppBar. We oversize
          // and centre it so the visual pineapple matches the reference.
          Positioned(
            left: -(imageSize - size) / 2,
            top: -(imageSize - size) / 2,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/pineapple_filter_button.jpeg',
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                // Fallback icon if the asset is missing — burnt orange
                // so it still reads as "pineapple-ish" until the asset
                // ships.
                errorBuilder: (_, __, ___) => Icon(
                  Icons.local_florist_rounded,
                  color: const Color(0xFFFF7A00),
                  size: size * 0.8,
                ),
              ),
            ),
          ),
          // Transparent tap surface over the visible pineapple area.
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(width: size, height: size),
            ),
          ),
          // Active-filter-count badge (burgundy pill with white number).
          if (activeCount != null && activeCount! > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB01030),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 20),
                child: Text(
                  '$activeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
