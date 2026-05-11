import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// =============================================================
// SESSION SERVICE  (Singleton)
// Responsibilities:
//   - Persist authenticated user data AND auth token to local storage
//   - Restore session + re-inject token into ApiService on startup
//   - Clear everything on logout
// OOP Principle: Singleton, Encapsulation, Single Responsibility
//
// FIX: Added _keyToken persistence.
//      restore() now calls ApiService().setToken() so every
//      API call after a cold restart still sends Authorization headers.
// =============================================================
class SessionService {

  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  // --- Storage keys ---
  static const String _keyUserId    = 'session_user_id';
  static const String _keyUsername  = 'session_username';
  static const String _keyEmail     = 'session_email';
  static const String _keyIsLoggedIn = 'session_is_logged_in';
  static const String _keyToken     = 'session_token';       // ← NEW

  // ----------------------------------------------------------
  // SAVE SESSION
  // Called after successful login or email verification.
  // Token is optional — verification response may not return one.
  // ----------------------------------------------------------
  Future<void> save({
    required String userId,
    required String username,
    required String email,
    String? token,                                           // ← NEW
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId,    userId);
    await prefs.setString(_keyUsername,  username);
    await prefs.setString(_keyEmail,     email);
    await prefs.setBool(_keyIsLoggedIn,  true);

    // Persist token when provided; keep existing one if not
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_keyToken, token);
      ApiService().setToken(token);                         // ← NEW: inject now
    }
  }

  // ----------------------------------------------------------
  // IS LOGGED IN
  // ----------------------------------------------------------
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // ----------------------------------------------------------
  // RESTORE SESSION
  // Called on cold startup by SplashRouter.
  // Re-injects the persisted token into ApiService so protected
  // routes work without requiring a new login.
  // ----------------------------------------------------------
  Future<Map<String, String>?> restore() async {
    final prefs = await SharedPreferences.getInstance();

    final loggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!loggedIn) return null;

    // Re-inject token into ApiService singleton               ← NEW
    final token = prefs.getString(_keyToken);
    if (token != null && token.isNotEmpty) {
      ApiService().setToken(token);
    }

    return {
      'user_id':  prefs.getString(_keyUserId)   ?? '',
      'username': prefs.getString(_keyUsername) ?? '',
      'email':    prefs.getString(_keyEmail)    ?? '',
    };
  }

  // ----------------------------------------------------------
  // CLEAR SESSION  (logout)
  // ----------------------------------------------------------
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyToken);                          // ← NEW
  }
}