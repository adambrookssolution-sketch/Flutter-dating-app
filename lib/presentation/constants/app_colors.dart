import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Splash screen gradient colors
  static const Color splashGradientStart = Color(0xFFB31637);
  static const Color splashGradientEnd = Color(0xFF331837);
  static const Color buttonTextColor = Color(0xFF511737);
  
  // Switch button colors
  static const Color switchButtonBackground = Colors.white;
  static const Color switchButtonSelected = Color(0xFF331837);
  static const Color switchButtonTextSelected = Colors.white;
  static const Color switchButtonTextUnselected = Color(0xFF331837);

  // Gradient definition
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      splashGradientStart,
      splashGradientEnd,
    ],
  );
}
