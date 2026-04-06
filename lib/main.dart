import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'services/session_service.dart';
import 'utils/theme_provider.dart';
import 'utils/app_theme.dart';

// =============================================================
// ENTRY POINT
// =============================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted theme before app renders
  await ThemeProvider().loadTheme();

  runApp(const QLineApp());
}

// =============================================================
// QLINE APP
// Responsibilities:
//   - Listen to ThemeProvider and rebuild when theme changes
//   - Supply correct ThemeData to MaterialApp
// OOP Principle: Observer Pattern (AnimatedBuilder on ChangeNotifier)
// =============================================================
class QLineApp extends StatelessWidget {
  const QLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider(),
      builder: (context, _) {
        final isDark = ThemeProvider().isDarkMode;
        return MaterialApp(
          title:                      'QLINE',
          debugShowCheckedModeBanner: false,
          theme:      AppTheme.lightTheme(),
          darkTheme:  AppTheme.darkTheme(),
          themeMode:  isDark ? ThemeMode.dark : ThemeMode.light,
          home:       const SplashRouter(),
        );
      },
    );
  }
}

// =============================================================
// SPLASH ROUTER
// Responsibilities:
//   - Check session on startup and route accordingly
// =============================================================
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {

  final _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    final sessionData = await _sessionService.restore();
    if (!mounted) return;

    if (sessionData != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomePage(user: AuthUser.fromMap(sessionData)),
      ));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color:        AppTheme.crimson,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.confirmation_num_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            Text('QLINE', style: AppTheme.brandStyle(isDark)),
          ],
        ),
      ),
    );
  }
}