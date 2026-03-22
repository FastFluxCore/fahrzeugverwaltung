import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A5276),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A5276), width: 1.5),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF1A5276),
        selectionColor: Color(0x401A5276),
        selectionHandleColor: Color(0xFF1A5276),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A5276),
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A5276), width: 1.5),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF5DADE2),
        selectionColor: Color(0x405DADE2),
        selectionHandleColor: Color(0xFF5DADE2),
      ),
      useMaterial3: true,
    );
  }
}

/// Extension for quick access to theme-aware colors used throughout the app.
extension AppColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// Main background
  Color get bgColor => _isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);

  /// Card/container background
  Color get cardColor => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  /// Card border
  Color get borderColor => _isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8ECF0);

  /// Primary text
  Color get textPrimary => _isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A2E);

  /// Secondary text
  Color get textSecondary => _isDark ? const Color(0xFF9E9E9E) : const Color(0xFF8E8E93);

  /// Input field fill
  Color get inputFill => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  /// Subtle background (chips, icons)
  Color get subtleBg => _isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7FA);

  /// Brand color (always the same)
  Color get brand => const Color(0xFF1A5276);

  /// Brand with opacity
  Color get brandLight => _isDark
      ? const Color(0xFF1A5276).withValues(alpha: 0.2)
      : const Color(0xFF1A5276).withValues(alpha: 0.1);

  /// Section header color
  Color get sectionHeader => _isDark
      ? const Color(0xFF5DADE2).withValues(alpha: 0.8)
      : const Color(0xFF1A5276).withValues(alpha: 0.7);

  /// Bottom bar
  Color get bottomBarColor => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
}
