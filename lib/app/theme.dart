import 'package:flutter/material.dart';

class AppTheme {
  // Brand tokens
  static const brandBlue  = Color(0xFF2E6CF6);
  static const brandGreen = Color(0xFF2CC36B);
  static const gold       = Color(0xFFE0A23B);

  static const bgTop    = Color(0xFF0B2A4A);
  static const bgMid    = Color(0xFF143E6E);
  static const bgBottom = Color(0xFF2F2B3F);

  static const rL = 24.0; // radius
  static const gS = 8.0, gM = 12.0, gL = 16.0, gXL = 24.0; // gaps

  static ThemeData material = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: brandBlue, brightness: Brightness.dark),
    scaffoldBackgroundColor: bgTop,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5),
      titleMedium:   TextStyle(fontWeight: FontWeight.w700),
      bodyMedium:    TextStyle(fontWeight: FontWeight.w500),
    ),
  );
}