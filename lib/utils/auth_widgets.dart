import 'package:flutter/material.dart';
import 'app_theme.dart';

// =============================================================
// AUTH WIDGETS
// Responsibilities:
//   - Build reusable UI widgets shared across all auth pages
//   - Accept isDark flag to adapt colors for light/dark mode
// OOP Principle: Abstraction, Reusability, DRY
// =============================================================
class AuthWidgets {
  AuthWidgets._();

  /// App brand row with ticket icon and QLINE wordmark
  static Widget buildBrand(bool isDark) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color:        AppTheme.crimson,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.confirmation_num_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Text('QLINE', style: AppTheme.brandStyle(isDark)),
      ],
    );
  }

  /// Spaced uppercase field label
  static Widget buildLabel(String text, bool isDark) {
    return Text(text, style: AppTheme.labelStyle(isDark));
  }

  /// Styled text form field that adapts to current theme
  static Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 15),
      validator:    validator,
      decoration:   AppTheme.inputDecoration(
        hint:       hint,
        prefixIcon: icon,
        isDark:     isDark,
        suffixIcon: suffixIcon,
      ),
    );
  }

  /// Red error banner
  static Widget buildErrorBanner(String message) {
    return _buildBanner(
        message: message, color: AppTheme.crimson,
        icon: Icons.error_outline_rounded);
  }

  /// Green success banner
  static Widget buildSuccessBanner(String message) {
    return _buildBanner(
        message: message, color: Colors.green,
        icon: Icons.check_circle_outline_rounded);
  }

  static Widget _buildBanner({
    required String   message,
    required Color    color,
    required IconData icon,
  }) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }

  /// Primary action button (full width)
  static Widget buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style:     AppTheme.primaryButtonStyle(),
        child:     isLoading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(label, style: AppTheme.buttonTextStyle),
      ),
    );
  }

  /// Bottom navigation link (e.g. "Already have an account? Sign In")
  static Widget buildBottomLink({
    required String prefix,
    required String linkText,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            text:  prefix,
            style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 14),
            children: [
              TextSpan(
                text:  linkText,
                style: const TextStyle(
                    color: AppTheme.crimson, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Theme toggle button — sun/moon icon
  static Widget buildThemeToggle({
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 44, height: 44,
        decoration: BoxDecoration(
          color:        isDark
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFDDDDDD),
          ),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: isDark ? const Color(0xFFFFC107) : const Color(0xFF555555),
          size: 20,
        ),
      ),
    );
  }

  /// Radial glow background circle (decorative)
  static Widget buildGlowCircle({
    required double size,
    required double opacity,
    required AlignmentGeometry alignment,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            AppTheme.crimson.withOpacity(opacity),
            Colors.transparent,
          ]),
        ),
      ),
    );
  }
}