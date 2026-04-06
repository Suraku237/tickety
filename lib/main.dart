import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'services/session_service.dart';

// =============================================================
// ENTRY POINT
// Responsibilities:
//   - Bootstrap the Flutter application
//   - Check for existing session before choosing initial screen
//   - Route to HomePage if session exists, LoginPage if not
// OOP Principle: Single Responsibility
// =============================================================
void main() async {
  // Required before any async work in main()
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QLineApp());
}

class QLineApp extends StatelessWidget {
  const QLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'QLINE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:  ColorScheme.fromSeed(seedColor: const Color(0xFFDC0F0F)),
        fontFamily:   'Helvetica Neue',
        useMaterial3: true,
      ),
      home: const SplashRouter(),
    );
  }
}


// =============================================================
// SPLASH ROUTER
// Responsibilities:
//   - Silently check session on startup
//   - Redirect to the correct initial screen
// OOP Principle: Single Responsibility, Separation of Concerns
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
      // Session found — go straight to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(user: AuthUser.fromMap(sessionData)),
        ),
      );
    } else {
      // No session — go to LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shown briefly while session check completes
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_num_rounded,
              color: Color(0xFFDC0F0F),
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'QLINE',
              style: TextStyle(
                color:       Color(0xFFF5F5F5),
                fontSize:    22,
                fontWeight:  FontWeight.w900,
                letterSpacing: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}