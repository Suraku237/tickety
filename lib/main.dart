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
  await ThemeProvider().loadTheme();
  runApp(const TicketyApp());               // FIX: was QLineApp
}

// =============================================================
// TICKETY APP
// FIX: renamed from QLineApp → TicketyApp
// =============================================================
class TicketyApp extends StatelessWidget {
  const TicketyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider(),
      builder: (context, _) {
        final isDark = ThemeProvider().isDarkMode;
        return MaterialApp(
          title:                      'TICKETY',
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
// FIX: animated logo with fade-in + scale instead of bare icon
// =============================================================
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter>
    with SingleTickerProviderStateMixin {

  final _session = SessionService();

  late AnimationController _ctrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.80, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();
    _resolveRoute();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _resolveRoute() async {
    // Give the splash animation time to breathe
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // FIX: restore() now also re-injects the token into ApiService
    final sessionData = await _session.restore();
    if (!mounted) return;

    if (sessionData != null) {
      Navigator.pushReplacement(context, _fadeRoute(
        HomePage(user: AuthUser.fromMap(sessionData)),
      ));
    } else {
      Navigator.pushReplacement(context, _fadeRoute(
        const LoginPage(),
      ));
    }
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder:      (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo container
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color:        AppTheme.crimson,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color:      AppTheme.crimson.withOpacity(0.4),
                        blurRadius: 28,
                        offset:     const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.confirmation_num_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),

                // Brand name
                Text('TICKETY', style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontSize:   26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                )),
                const SizedBox(height: 8),

                // Tagline
                Text('Smart Queue Management', style: TextStyle(
                  color:    AppTheme.textMuted(isDark),
                  fontSize: 13,
                  letterSpacing: 1,
                )),
                const SizedBox(height: 48),

                // Loading indicator
                SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color:       AppTheme.crimson.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}