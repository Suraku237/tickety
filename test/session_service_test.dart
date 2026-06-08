// =============================================================
// Unit tests for lib/services/session_service.dart -> SessionService.
// Uses the SharedPreferences in-memory mock (no real device storage).
//
// >>> SET PACKAGE NAME <<<  (replace `tickety` with your pubspec name)
// =============================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tickety/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final session = SessionService(); // singleton

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('isLoggedIn is false on a fresh install', () async {
    expect(await session.isLoggedIn(), isFalse);
  });

  test('restore returns null when not logged in', () async {
    expect(await session.restore(), isNull);
  });

  test('save persists the session and flips isLoggedIn', () async {
    await session.save(
      userId: '42',
      username: 'alice',
      email: 'alice@example.com',
      token: 'jwt-token',
    );

    expect(await session.isLoggedIn(), isTrue);

    final restored = await session.restore();
    expect(restored, isNotNull);
    expect(restored!['user_id'], '42');
    expect(restored['username'], 'alice');
    expect(restored['email'], 'alice@example.com');
  });

  test('save works without a token (verification flow)', () async {
    await session.save(
      userId: '7',
      username: 'bob',
      email: 'bob@example.com',
    );
    final restored = await session.restore();
    expect(restored!['username'], 'bob');
  });

  test('clear wipes the session', () async {
    await session.save(
      userId: '42', username: 'alice', email: 'alice@example.com',
      token: 't',
    );
    await session.clear();

    expect(await session.isLoggedIn(), isFalse);
    expect(await session.restore(), isNull);
  });

  test('restore fills missing string fields with empty strings', () async {
    // Logged-in flag set but the detail keys are absent.
    SharedPreferences.setMockInitialValues({'session_is_logged_in': true});
    final restored = await session.restore();
    expect(restored, isNotNull);
    expect(restored!['user_id'], '');
    expect(restored['username'], '');
  });
}
