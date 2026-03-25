import 'package:flutter/material.dart';

/// App-wide design tokens and ThemeData.
class AppTheme {
  AppTheme._();

  // ── Color Palette ──────────────────────────────────────────────────────
  static const Color _primaryBase  = Color(0xFF6C63FF); // vibrant violet
  static const Color _secondary    = Color(0xFF03DAC6); // teal accent
  static const Color _surface      = Color(0xFF1E1E2E); // dark surface
  static const Color _surfaceHigh  = Color(0xFF282840); // elevated surface
  static const Color _error        = Color(0xFFCF6679);
  static const Color _onPrimary    = Colors.white;
  static const Color _onSurface    = Color(0xFFE0E0F0);
  // Public so widgets can reference it without extension hacks
  static const Color onSurfaceLow  = Color(0xFF9090B0);

  // ── Priority Colors ────────────────────────────────────────────────────
  static const Color priorityHigh   = Color(0xFFE53935);
  static const Color priorityMedium = Color(0xFFFFB547);
  static const Color priorityLow    = Color(0xFF4CAF82);

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9C5FF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── ThemeData ──────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: _primaryBase,
        secondary: _secondary,
        surface: _surface,
        error: _error,
        onPrimary: _onPrimary,
        onSecondary: Colors.black,
        onSurface: _onSurface,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F1E),
      cardTheme: CardThemeData(
        color: _surfaceHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _onSurface,
        ),
        iconTheme: IconThemeData(color: _onSurface),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryBase,
        foregroundColor: _onPrimary,
        elevation: 8,
        shape: CircleBorder(),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryBase;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(_onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: onSurfaceLow, width: 1.5),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E2E4E),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceHigh,
        contentTextStyle: const TextStyle(color: _onSurface, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Text Styles ────────────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, color: _onSurface, height: 1.2,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, color: _onSurface,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400, color: _onSurface,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, color: onSurfaceLow,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: onSurfaceLow,
    letterSpacing: 0.8,
  );

  // ── Spacing ────────────────────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  static const double radiusCard = 16;
  static const double radiusChip = 8;
  static const double radiusFull = 100;
}
