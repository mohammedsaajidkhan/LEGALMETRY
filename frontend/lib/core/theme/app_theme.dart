// ==============================================================================
// LEGALMETRY — Design System & Theme Foundation (GIGW 3.0 Standard)
// Track 5: UI / Reports (Person 5)
//
// Governing Standard: Guidelines for Indian Government Websites and Apps (GIGW 3.0)
// Core Principle: Usable, User-Centric, Universally Accessible (UUU Trilogy)
// Rule: Severity colors NEVER change meaning across screens or roles.
// ==============================================================================

import 'package:flutter/material.dart';

class AppTheme {
<<<<<<< HEAD
  AppTheme._();

  // ---------------------------------------------------------------------------
  // A2. COLOR SYSTEM (Reflects UI Design Context Document Exactly)
  // ---------------------------------------------------------------------------
  static const Color primaryNavy = Color(0xFF1A3A5C); // Headers, primary buttons, app bar, gov identity
  static const Color secondaryBlue = Color(0xFF2860A0); // Links, secondary actions, section headers
  static const Color criticalRed = Color(0xFFD0021B); // Critical violations — universal meaning
  static const Color moderateAmber = Color(0xFFF5A623); // Moderate violations — universal meaning
  static const Color minorGreen = Color(0xFF7ED321); // Minor violations / Compliant status
  static const Color compliantGreen = Color(0xFF7ED321); // Compliant status
  static const Color needsReviewGold = Color(0xFFB8860B); // Low-confidence, pending human review
  
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Main background
  static const Color surfaceLight = Color(0xFFF2F6FA); // Cards, alternating table rows
  static const Color borderGrey = Color(0xFFCCCCCC); // Dividers, table borders
  static const Color textPrimary = Color(0xFF1A1A1A); // Main body text (Contrast >= 4.5:1)
  static const Color textSecondary = Color(0xFF666666); // Captions, secondary text

  // Dark Mode Surface & Background Variants
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ---------------------------------------------------------------------------
  // SPACING TOKENS (Standardized 4px / 8px Grid System)
  // ---------------------------------------------------------------------------
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // ---------------------------------------------------------------------------
  // RADIUS TOKENS
  // ---------------------------------------------------------------------------
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusPill = 999.0;

  // ---------------------------------------------------------------------------
  // A3. TYPOGRAPHY (GIGW Compliant, Scales with Accessibility Settings)
  // ---------------------------------------------------------------------------
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.bold,
    color: primaryNavy,
    letterSpacing: -0.1,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    color: secondaryBlue,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.3,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonOutlinedLabel = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: primaryNavy,
    letterSpacing: 0.2,
  );

  // ---------------------------------------------------------------------------
  // PART C — SHARED COMPONENT STYLES & DECORATIONS
  // ---------------------------------------------------------------------------

  /// Standard Primary Button Style (Navy fill, White text, 48px min height for GIGW touch targets)
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryNavy,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing12),
    minimumSize: const Size(88, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    textStyle: buttonLabel,
  );

  /// Standard Secondary Button Style (Outlined, Navy border and text, 48px min height)
  static final ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryNavy,
    side: const BorderSide(color: primaryNavy, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing12),
    minimumSize: const Size(88, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    textStyle: buttonOutlinedLabel,
  );

  /// Danger Button Style (For explicit violations / critical escalations)
  static final ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: criticalRed,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing12),
    minimumSize: const Size(88, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    textStyle: buttonLabel,
  );

  /// Standard Card Decoration with GIGW Subtle Surface & Border
  static BoxDecoration cardDecoration({bool isDark = false}) => BoxDecoration(
    color: isDark ? darkSurface : surfaceLight,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(
      color: isDark ? darkBorder : borderGrey,
      width: 1.0,
=======
  static const Color primary = Color(0xFF1E3A8A);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      error: const Color(0xFFDC2626), // Critical Severity
>>>>>>> capture-cv
    ),
  );

  /// Field Result Card Decoration with Severity Left Border Accent
  static BoxDecoration cardDecorationWithSeverity(String? severity, {bool isDark = false}) {
    final Color borderAccent = severityColor(severity);
    return BoxDecoration(
      color: isDark ? darkSurface : surfaceLight,
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border(
        left: BorderSide(color: borderAccent, width: 4.0),
        top: BorderSide(color: isDark ? darkBorder : borderGrey, width: 1.0),
        right: BorderSide(color: isDark ? darkBorder : borderGrey, width: 1.0),
        bottom: BorderSide(color: isDark ? darkBorder : borderGrey, width: 1.0),
      ),
    );
  }

  /// Status Chip Decoration (Pill shape with subtle tint background)
  static BoxDecoration statusChipDecoration(String? status, {bool isDark = false}) {
    final Color color = severityColor(status);
    return BoxDecoration(
      color: color.withOpacity(isDark ? 0.25 : 0.12),
      borderRadius: BorderRadius.circular(radiusPill),
      border: Border.all(color: color, width: 1.0),
    );
  }

  // ---------------------------------------------------------------------------
  // SEVERITY COLOR MAPPING & HELPER FUNCTIONS
  // ---------------------------------------------------------------------------

  /// Returns the exact hex-mapped color according to GIGW & Part A2 specifications.
  /// Rule: Severity colors NEVER change meaning across screens or roles.
  static Color severityColor(String? status) {
    if (status == null) return borderGrey;
    final normalized = status.toUpperCase().trim();
    switch (normalized) {
      case 'CRITICAL':
      case 'SECOND_OFFENCE_CONFIRMED':
      case 'ESCALATED':
      case 'FAIL':
        return criticalRed;

      case 'MODERATE':
      case 'NOTICE_ISSUED':
      case 'DISPUTED':
      case 'WARNING':
        return moderateAmber;

      case 'NEEDS_REVIEW':
      case 'NEEDS REVIEW':
      case 'PENDING_SUPERVISOR_VERIFICATION':
      case 'ESCALATED_PENDING_VERIFICATION':
      case 'LOW_CONFIDENCE':
        return needsReviewGold;

      case 'MINOR':
      case 'COMPLIANT':
      case 'PASS':
      case 'CLOSED':
      case 'RESOLVED':
        return minorGreen;

      default:
        return secondaryBlue;
    }
  }

  /// Returns a background tint for severity chips / indicators
  static Color severityBgColor(String? status, {bool isDark = false}) {
    return severityColor(status).withOpacity(isDark ? 0.25 : 0.12);
  }

  /// Returns human-readable label for status/severity
  static String severityLabel(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    final normalized = status.toUpperCase().trim();
    switch (normalized) {
      case 'CRITICAL':
        return 'Critical';
      case 'MODERATE':
        return 'Moderate';
      case 'MINOR':
        return 'Minor';
      case 'COMPLIANT':
        return 'Compliant';
      case 'NEEDS_REVIEW':
        return 'Needs Review';
      case 'NOTICE_ISSUED':
        return 'Notice Issued';
      case 'PENDING_SUPERVISOR_VERIFICATION':
        return 'Pending Verification';
      case 'DISPUTED':
        return 'Disputed';
      case 'CLOSED':
        return 'Closed (Resolved)';
      case 'SECOND_OFFENCE_CONFIRMED':
        return '2nd Offence Confirmed';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  // ---------------------------------------------------------------------------
  // FLUTTER THEMEDATA DEFINITIONS (Light & Dark Themes)
  // ---------------------------------------------------------------------------

  /// GIGW 3.0 Standard Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryNavy,
      scaffoldBackgroundColor: backgroundWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        secondary: secondaryBlue,
        surface: surfaceLight,
        error: criticalRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      dividerColor: borderGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
      cardTheme: CardTheme(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderGrey, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderGrey, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderGrey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryNavy, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: criticalRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceLight),
        headingTextStyle: headingMedium.copyWith(fontSize: 14),
        dataTextStyle: body,
        dividerThickness: 1.0,
        horizontalMargin: spacing16,
        columnSpacing: spacing24,
      ),
    );
  }

  /// GIGW 3.0 Accessible Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondaryBlue,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: secondaryBlue,
        secondary: primaryNavy,
        surface: darkSurface,
        error: criticalRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onError: Colors.white,
      ),
      dividerColor: darkBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing12),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: darkBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing12),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: secondaryBlue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: criticalRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(darkSurface),
        headingTextStyle: headingMedium.copyWith(fontSize: 14, color: Colors.white),
        dataTextStyle: body.copyWith(color: darkTextPrimary),
        dividerThickness: 1.0,
        horizontalMargin: spacing16,
        columnSpacing: spacing24,
      ),
    );
  }
}
