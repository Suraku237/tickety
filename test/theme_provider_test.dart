// =============================================================
// Unit tests for lib/utils/theme_provider.dart -> ThemeProvider.
// Covers the default, persisted load, toggle + persistence, and that
// listeners are notified (Observer pattern via ChangeNotifier).
//
// Note: ThemeProvider is a singleton, so each test calls loadTheme()
// first to establish deterministic state regardless of run order.
//
// >>> SET PACKAGE NAME <<<  (replace `tickety` with your pubspec name)
// =============================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tickety/utils/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final theme = ThemeProvider(); // singleton

  test('defaults to dark mode when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    await theme.loadTheme();
    expect(theme.isDarkMode, isTrue);
  });

  test('loadTheme restores a persisted light preference', () async {
    SharedPreferences.setMockInitialValues({'is_dark_mode': false});
    await theme.loadTheme();
    expect(theme.isDarkMode, isFalse);
  });

  test('toggleTheme flips the current mode', () async {
    SharedPreferences.setMockInitialValues({'is_dark_mode': true});
    await theme.loadTheme();
    final before = theme.isDarkMode;

    await theme.toggleTheme();
    expect(theme.isDarkMode, !before);
  });

  test('toggleTheme persists the new value to SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({'is_dark_mode': true});
    await theme.loadTheme();

    await theme.toggleTheme();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('is_dark_mode'), theme.isDarkMode);
  });

  test('notifies listeners when toggled', () async {
    SharedPreferences.setMockInitialValues({'is_dark_mode': true});
    await theme.loadTheme();

    var notified = 0;
    void listener() => notified++;
    theme.addListener(listener);

    await theme.toggleTheme();
    expect(notified, greaterThan(0));

    theme.removeListener(listener);
  });
}
