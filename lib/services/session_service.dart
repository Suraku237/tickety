import 'package:shared_preferences/shared_preferences.dart';

// =============================================================
// SESSION SERVICE  (Singleton)
// Responsibilities:
//   - Persist authenticated user data to local storage
//   - Restore session on app startup
//   - Clear session on logout
// OOP Principle: Singleton, Encapsulation, Single Responsibility
// =============================================================
class SessionService {

  // --- Singleton setup ---
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  // --- Storage keys (private constants) ---
  static const String _keyUserId   = 'session_user_id';
  static const String _keyUsername = 'session_username';
  static const String _keyEmail    = 'session_email';
  static const String _keyIsLoggedIn = 'session_is_logged_in';

  // ----------------------------------------------------------
  // SAVE SESSION
  // Called after successful login or email verification
  // ----------------------------------------------------------
  Future<void> save({
    required String userId,
    required String username,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId,     userId);
    await prefs.setString(_keyUsername,   username);
    await prefs.setString(_keyEmail,      email);
    await prefs.setBool(_keyIsLoggedIn,   true);
  }

  // ----------------------------------------------------------
  // IS LOGGED IN
  // Quick check used on app startup
  // ----------------------------------------------------------
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // ----------------------------------------------------------
  // RESTORE SESSION
  // Returns stored user data as a Map, or null if none exists
  // ----------------------------------------------------------
  Future<Map<String, String>?> restore() async {
    final prefs = await SharedPreferences.getInstance();

    final loggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!loggedIn) return null;

    return {
      'user_id':  prefs.getString(_keyUserId)   ?? '',
      'username': prefs.getString(_keyUsername) ?? '',
      'email':    prefs.getString(_keyEmail)    ?? '',
    };
  }

  // ----------------------------------------------------------
  // CLEAR SESSION
  // Called on logout
  // ----------------------------------------------------------
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyIsLoggedIn);
  }
}