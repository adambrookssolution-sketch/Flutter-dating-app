import 'package:flutter/material.dart';

/// Golden pineapple filter button used on the Couples / Community feed.
///
/// Matches the "PIÑA DORADA" reference mock the client shared on 2026-04-20:
/// a circular orange neon glow with a white pineapple silhouette in the
/// centre. Designed to sit in the top-right corner of the feed screen,
/// **pinned** so it doesn't move with scroll.
///
/// ## Integration
///
/// Drop this widget at the `top-right` of the Couples feed scaffold — the
/// easiest way is to wrap the feed body in a [Stack] and add the button as
/// a [Positioned] child:
///
/// ```dart
/// Stack(
///   children: [
///     CouplesListView(...),
///     const Positioned(
///       top: 12,
///       right: 16,
///       child: PineappleFilterButton(),
///     ),
///   ],
/// );
/// ```
///
/// [onTap] defaults to pushing [FiltersScreen]; override when wiring from
/// a parent that needs to intercept the tap (e.g. to gate behind `approved`
/// status).
///
/// The optional [activeCount] badge overlays a small burgundy chip with the
/// number of filters currently applied — pass `null` or `0` to hide it.
class PineappleFilterButton extends StatelessWidget {
  const PineappleFilterButton({
    super.key,
    this.onTap,
    this.activeCount,
    this.size = 56,
  });

  final VoidCallback? onTap;
  final int? activeCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer glow halo — layered behind the button to mimic the neon
          // look from the reference image. Two stacked shadows make the
          // orange feel luminous without relying on an SVG filter.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A00).withValues(alpha: 0.55),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFFB347).withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
          // Tappable pineapple badge itself.
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Ink(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFFFB347),
                      Color(0xFFFF7A00),
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(size * 0.18),
                  child: Image.asset(
                    'assets/images/pineapple_filter_button.jpeg',
                    fit: BoxFit.contain,
                    // Fallback icon if the asset hasn't been added yet.
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_florist_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
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
                  color: const Color(0xFFB31637),
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
