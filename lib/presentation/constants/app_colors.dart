import 'package:flutter/material.dart';

/// Affinity brand palette — sampled directly from the Figma master file
/// Alejandra shared on 2026-04-25. Use these tokens instead of inlining
/// hex literals so the next palette tweak (or Phase 2 dark-mode work) is
/// a one-file change.
class AppColors {
  AppColors._();

  /// Primary burgundy — used for CTAs, the heart logo, the active nav
  /// indicator, sender chat bubbles. Exactly the hex Figma used for the
  /// "Start Conversation" button across every mockup.
  static const Color primary = Color(0xFFB01030);

  /// Gradient end — the deep burgundy/aubergine at the bottom-left of the
  /// splash and travel-card gradients in Figma.
  static const Color primaryDark = Color(0xFF580818);

  /// On-burgundy text colour. Figma uses pure white for legibility.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Backwards-compatible aliases ──────────────────────────────────
  // The original palette named tokens after their first use site
  // (splash gradient, switch buttons, etc.). Keep those aliases live so
  // existing call sites don't break, but point them at the new
  // Figma-correct values.

  static const Color splashGradientStart = primary;
  static const Color splashGradientEnd = primaryDark;
  static const Color buttonTextColor = primaryDark;

  // Switch button colors
  static const Color switchButtonBackground = Colors.white;
  static const Color switchButtonSelected = primaryDark;
  static const Color switchButtonTextSelected = Colors.white;
  static const Color switchButtonTextUnselected = primaryDark;

  /// Splash gradient — top-right primary fading to bottom-left primaryDark.
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [splashGradientStart, splashGradientEnd],
  );
}
