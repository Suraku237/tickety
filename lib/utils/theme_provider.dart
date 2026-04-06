import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================
// THEME PROVIDER
// Responsibilities:
//   - Store and toggle the current theme mode
//   - Persist the user's theme preference across app restarts
//   - Notify all listeners when theme changes
// OOP Principle: Encapsulation, Single Responsibility,
//               Observer Pattern (via ChangeNotifier)
// =============================================================
class ThemeProvider extends ChangeNotifier {

  // --- Singleton setup ---
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;
  ThemeProvider._internal();

  static const String _themeKey = 'is_dark_mode';

  bool _isDarkMode = true; // default to dark

  bool get isDarkMode => _isDarkMode;

  /// Load persisted theme preference on app startup
  Future<void> loadTheme() async {
    final prefs  = await SharedPreferences.getInstance();
    _isDarkMode  = prefs.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  /// Toggle between dark and light mode and persist the choice
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
}