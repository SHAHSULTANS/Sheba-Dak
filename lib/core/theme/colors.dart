import 'package:flutter/material.dart';

class AppColors {
  // Primary palette: Blue for trust (SmartSheba branding).
  static const Color primary = Color(0xFF2196F3);  // Main blue.
  static const Color primaryDark = Color(0xFF1976D2);  // Dark variant.
  static const Color accent = Color(0xFF4CAF50);  // Green for actions (e.g., 'Book Now').
  static const Color background = Color(0xFFFFFFFF);  // White for light mode.
  static const Color textPrimary = Color(0xFF212121);  // Dark text for readability.
  static const Color textSecondary = Color(0xFF757575);  // Gray for subtitles.
  static const Color error = Color(0xFFE57373);  // Red for errors.

  // High-contrast for accessibility (WCAG AA).
  static const Color success = Color(0xFF81C784);  // Green for confirmations.
  static const Color warning = Color(0xFFFFB74D);  // Orange for alerts.
}