// ============ PERSON 5 ============
// AppTheme (locked after Pre-Flight, changes need agreement)
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E3A8A);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      error: const Color(0xFFDC2626), // Critical Severity
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color(0xFF3B82F6),
      primary: const Color(0xFF3B82F6),
      error: const Color(0xFFEF4444),
    ),
  );

  // Severity colors
  static const Color severityCritical = Color(0xFFDC2626);
  static const Color severityModerate = Color(0xFFF59E0B);
  static const Color severityMinor = Color(0xFF10B981);
  static const Color severityCompliant = Color(0xFF059669);
}
