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

// import 'package:flutter/material.dart';

class AppColors {
  // Modern Primary Palette: Blue gradient for trust and professionalism
  static const Color primary = Color(0xFF2563EB);  // Modern blue (main brand color)
  static const Color primaryDark = Color(0xFF1D4ED8);  // Darker blue variant
  static const Color primaryLight = Color(0xFF60A5FA);  // Lighter blue for highlights
  static const Color secondary = Color(0xFF8B5CF6);  // Purple for gradients and accents
  
  // Action Colors
  static const Color accent = Color(0xFF06D6A0);  // Green for success actions
  static const Color success = Color(0xFF10B981);  // Success green (confirmations)
  static const Color warning = Color(0xFFF59E0B);  // Amber for warnings/alerts
  static const Color error = Color(0xFFEF4444);  // Red for errors/danger
  
  // Background & Surface Colors
  static const Color background = Color(0xFFFFFFFF);  // Pure white background
  static const Color surface = Color(0xFFF8FAFC);  // Light gray for cards/surfaces
  static const Color surfaceVariant = Color(0xFFE2E8F0);  // Border/divider color
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);  // Dark text for headings
  static const Color textSecondary = Color(0xFF475569);  // Gray for body text
  static const Color textTertiary = Color(0xFF64748B);  // Lighter gray for captions
  static const Color textInverse = Color(0xFFFFFFFF);  // White text on dark backgrounds
  
  // Social Media Colors
  static const Color facebook = Color(0xFF1877F2);
  static const Color google = Color(0xFFDB4437);
  static const Color whatsapp = Color(0xFF25D366);
  
  // Status Colors
  static const Color pending = Color(0xFFFBBF24);  // Yellow for pending status
  static const Color approved = Color(0xFF10B981);  // Green for approved
  static const Color rejected = Color(0xFFEF4444);  // Red for rejected
  static const Color completed = Color(0xFF06D6A0);  // Teal for completed
  
  // Gradient Colors for UI Elements
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06D6A0)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Semantic Colors for Specific Use Cases
  static const Color emergency = Color(0xFFDC2626);  // Red for emergency/SOS
  static const Color premium = Color(0xFFF59E0B);  // Gold for premium features
  static const Color discount = Color(0xFFEF4444);  // Red for discount tags
  
  // Neutral Colors
  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
  
  // Background Colors for Different Sections
  static const Color serviceCardBg = Color(0xFFF0F9FF);  // Light blue for service cards
  static const Color providerCardBg = Color(0xFFF0FDF4);  // Light green for provider cards
  static const Color emergencyCardBg = Color(0xFFFEF2F2);  // Light red for emergency cards
  
  // Rating Colors
  static const Color rating = Color(0xFFFFD700);  // Gold for star ratings
  static const Color ratingEmpty = Color(0xFFE2E8F0);  // Gray for empty stars
}

// Extension for easy color access
extension AppColorsExtension on AppColors {
  static Color get primary => AppColors.primary;
  static Color get secondary => AppColors.secondary;
  static Color get success => AppColors.success;
  static Color get error => AppColors.error;
  static Color get warning => AppColors.warning;
}