import 'package:flutter/material.dart';

class AppColors {
  // Vibrant, modern plant-themed palette
  static const Color primary = Color(0xFF1FAB89); // vibrant green
  static const Color primaryDark = Color(0xFF0C7B61); // darker green for contrast
  static const Color primaryLight = Color(0xFF62D2A2); // soft accent
  static const Color background = Color(0xFFF7FDF9); // very light green tinted white
  
  static const Color textMain = Color(0xFF1E2E28); // dark slate
  static const Color textSecondary = Color(0xFF7A8D86); // subtle slate
  
  static const Color healthy = Color(0xFF28A745);
  static const Color diseased = Color(0xFFDC3545);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF000000); // True Black for OLED
  static const Color darkCardBg = Color(0xFF1A1A1A); // Slightly elevated black for cards
  static const Color darkTextMain = Color(0xFFE0E0E0); // Off-white for readability
  static const Color darkTextSecondary = Color(0xFFA0A0A0); // Gray for secondary text
  
  static const Color cardBg = Colors.white;
}

class AppPadding {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}
