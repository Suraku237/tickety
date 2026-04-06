import 'package:flutter/material.dart';

// =============================================================
// APP THEME
// Responsibilities:
//   - Centralize all color, spacing, and style constants
//   - Provide reusable ThemeData for the whole app
// OOP Principle: Encapsulation, Single Source of Truth
// =============================================================
class AppTheme {
  // Private constructor — this class is never instantiated
  AppTheme._();

  // --- Colors ---
  static const Color crimson     = Color(0xFFDC0F0F);
  static const Color darkCrimson = Color(0xFF9B0000);
  static const Color surface     = Color(0xFF0D0D0D);
  static const Color card        = Color(0xFF161616);
  static const Color border      = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textMuted   = Color(0xFF808080);
  static const Color textHint    = Color(0xFF444444);

  // --- Border Radius ---
  static const double radiusSmall  = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge  = 14.0;

  // --- Input Decoration ---
  static InputDecoration inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText:        hint,
      hintStyle:       const TextStyle(color: textHint, fontSize: 14),
      prefixIcon:      Icon(prefixIcon, color: textMuted, size: 20),
      suffixIcon:      suffixIcon,
      filled:          true,
      fillColor:       card,
      errorStyle:      const TextStyle(color: crimson, fontSize: 12),
      contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border:          _outlineBorder(textMuted),
      enabledBorder:   _outlineBorder(border),
      focusedBorder:   _outlineBorder(crimson, width: 1.5),
      errorBorder:     _outlineBorder(crimson),
      focusedErrorBorder: _outlineBorder(crimson, width: 1.5),
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide:   BorderSide(color: color, width: width),
    );
  }

  // --- Button Style ---
  static ButtonStyle primaryButtonStyle({bool disabled = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor:         disabled ? crimson.withOpacity(0.5) : crimson,
      disabledBackgroundColor: crimson.withOpacity(0.5),
      elevation:               0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    );
  }

  // --- Text Styles ---
  static const TextStyle headingStyle = TextStyle(
    color: textPrimary, fontSize: 42,
    fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1,
  );

  static const TextStyle labelStyle = TextStyle(
    color: textMuted, fontSize: 11,
    fontWeight: FontWeight.w700, letterSpacing: 2,
  );

  static const TextStyle brandStyle = TextStyle(
    color: textPrimary, fontSize: 20,
    fontWeight: FontWeight.w800, letterSpacing: 4,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white, fontSize: 14,
    fontWeight: FontWeight.w800, letterSpacing: 2,
  );

  static const TextStyle mutedBodyStyle = TextStyle(
    color: textMuted, fontSize: 15,
  );
}