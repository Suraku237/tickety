import 'package:flutter/material.dart';

// =============================================================
// APP THEME
// Responsibilities:
//   - Provide color palettes for both dark and light modes
//   - Expose reusable styles and decorations that adapt to mode
//   - Keep crimson red as the dominant accent in both modes
// OOP Principle: Encapsulation, Single Source of Truth
// =============================================================
class AppTheme {
  AppTheme._();

  // --- Brand accent (same in both modes) ---
  static const Color crimson     = Color(0xFFDC0F0F);
  static const Color darkCrimson = Color(0xFF9B0000);

  // --- Dark mode palette ---
  static const Color darkSurface     = Color(0xFF0D0D0D);
  static const Color darkCard        = Color(0xFF161616);
  static const Color darkBorder      = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextMuted   = Color(0xFF808080);
  static const Color darkTextHint    = Color(0xFF444444);

  // --- Light mode palette ---
  static const Color lightSurface     = Color(0xFFF7F7F7);
  static const Color lightCard        = Color(0xFFFFFFFF);
  static const Color lightBorder      = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF0D0D0D);
  static const Color lightTextMuted   = Color(0xFF666666);
  static const Color lightTextHint    = Color(0xFFAAAAAA);

  // --- Dynamic color getters ---
  static Color surface(bool isDark)     => isDark ? darkSurface     : lightSurface;
  static Color card(bool isDark)        => isDark ? darkCard        : lightCard;
  static Color border(bool isDark)      => isDark ? darkBorder      : lightBorder;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textMuted(bool isDark)   => isDark ? darkTextMuted   : lightTextMuted;
  static Color textHint(bool isDark)    => isDark ? darkTextHint    : lightTextHint;

  // --- Border radius ---
  static const double radiusSmall  = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge  = 14.0;

  // --- Dynamic input decoration ---
  static InputDecoration inputDecoration({
    required String hint,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText:       hint,
      hintStyle:      TextStyle(color: textHint(isDark), fontSize: 14),
      prefixIcon:     Icon(prefixIcon, color: textMuted(isDark), size: 20),
      suffixIcon:     suffixIcon,
      filled:         true,
      fillColor:      card(isDark),
      errorStyle:     const TextStyle(color: crimson, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border:             _outlineBorder(border(isDark)),
      enabledBorder:      _outlineBorder(border(isDark)),
      focusedBorder:      _outlineBorder(crimson, width: 1.5),
      errorBorder:        _outlineBorder(crimson),
      focusedErrorBorder: _outlineBorder(crimson, width: 1.5),
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide:   BorderSide(color: color, width: width),
    );
  }

  // --- Button style ---
  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor:         crimson,
      disabledBackgroundColor: crimson.withOpacity(0.5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    );
  }

  // --- Text styles (static, color passed separately) ---
  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white, fontSize: 14,
    fontWeight: FontWeight.w800, letterSpacing: 2,
  );

  static TextStyle headingStyle(bool isDark) => TextStyle(
    color: textPrimary(isDark), fontSize: 42,
    fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1,
  );

  static TextStyle brandStyle(bool isDark) => TextStyle(
    color: textPrimary(isDark), fontSize: 20,
    fontWeight: FontWeight.w800, letterSpacing: 4,
  );

  static TextStyle labelStyle(bool isDark) => TextStyle(
    color: textMuted(isDark), fontSize: 11,
    fontWeight: FontWeight.w700, letterSpacing: 2,
  );

  static TextStyle mutedBodyStyle(bool isDark) => TextStyle(
    color: textMuted(isDark), fontSize: 15,
  );

  // --- MaterialApp ThemeData ---
  static ThemeData darkTheme() {
    return ThemeData(
      brightness:   Brightness.dark,
      colorScheme:  ColorScheme.fromSeed(
          seedColor: crimson, brightness: Brightness.dark),
      fontFamily:   'Helvetica Neue',
      useMaterial3: true,
      scaffoldBackgroundColor: darkSurface,
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      brightness:   Brightness.light,
      colorScheme:  ColorScheme.fromSeed(
          seedColor: crimson, brightness: Brightness.light),
      fontFamily:   'Helvetica Neue',
      useMaterial3: true,
      scaffoldBackgroundColor: lightSurface,
    );
  }
}