import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  // Light theme (default) with Material 3 for modern UX.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,  // Enables modern Material Design (rounded corners, elevation).
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        background: AppColors.background,
      ),
      textTheme: GoogleFonts.notoSansBengaliTextTheme(  // Bangla font support.
        ThemeData.light().textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textSecondary,
        ),
      ).apply(
        fontSizeFactor: 1.0,  // Responsive scaling for different devices.
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,  // Green buttons for positive actions.
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),  // Rounded for touch-friendly UX.
        ),
      ),
      // Add more customizations as needed (e.g., inputDecorationTheme for forms).
    );
  }

  // Dark theme placeholder (for future accessibility enhancements).
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.accent,
        error: AppColors.error,
        background: Colors.grey[900]!,
      ),
      textTheme: GoogleFonts.notoSansBengaliTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.grey[300]!,
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';

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