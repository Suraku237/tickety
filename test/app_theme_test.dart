// =============================================================
// Unit tests for lib/utils/app_theme.dart -> AppTheme.
// Verifies the dynamic color getters switch correctly on isDark and
// that the brand/spacing constants are present.
//
// >>> SET PACKAGE NAME <<<  (replace `tickety` with your pubspec name)
// =============================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickety/utils/app_theme.dart';

void main() {
  group('AppTheme dynamic getters', () {
    test('surface switches between dark and light', () {
      expect(AppTheme.surface(true), AppTheme.darkSurface);
      expect(AppTheme.surface(false), AppTheme.lightSurface);
    });

    test('card switches between dark and light', () {
      expect(AppTheme.card(true), AppTheme.darkCard);
      expect(AppTheme.card(false), AppTheme.lightCard);
    });

    test('border switches between dark and light', () {
      expect(AppTheme.border(true), AppTheme.darkBorder);
      expect(AppTheme.border(false), AppTheme.lightBorder);
    });

    test('text colors switch between dark and light', () {
      expect(AppTheme.textPrimary(true), AppTheme.darkTextPrimary);
      expect(AppTheme.textPrimary(false), AppTheme.lightTextPrimary);
      expect(AppTheme.textMuted(true), AppTheme.darkTextMuted);
      expect(AppTheme.textMuted(false), AppTheme.lightTextMuted);
    });

    test('textHint getter exists and switches (regression: was missing)', () {
      expect(AppTheme.textHint(true), AppTheme.darkTextHint);
      expect(AppTheme.textHint(false), AppTheme.lightTextHint);
    });
  });

  group('AppTheme constants', () {
    test('crimson brand accent value', () {
      expect(AppTheme.crimson, const Color(0xFFDC0F0F));
    });

    test('border radii are ordered small < medium < large', () {
      expect(AppTheme.radiusSmall, lessThan(AppTheme.radiusMedium));
      expect(AppTheme.radiusMedium, lessThan(AppTheme.radiusLarge));
    });
  });
}
