import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// AUTH USER  (Data Transfer Object)
// =============================================================
class AuthUser {
  final String userId;
  final String username;
  final String email;

  const AuthUser({
    required this.userId,
    required this.username,
    required this.email,
  });

  factory AuthUser.fromMap(Map<String, dynamic> data) {
    return AuthUser(
      userId:   data['user_id']  ?? '',
      username: data['username'] ?? '',
      email:    data['email']    ?? '',
    );
  }
}

// =============================================================
// HOME PAGE
// =============================================================
class HomePage extends StatefulWidget {
  final AuthUser user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  final _sessionService = SessionService();

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  bool get isDark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation  = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _onLogout() async {
    await _sessionService.clear();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getInitials() {
    final name  = widget.user.username;
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.crimson.withOpacity(0.13),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.darkCrimson.withOpacity(0.10),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // ── TOP BAR ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Brand
                        Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color:        AppTheme.crimson,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.confirmation_num_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('QLINE', style: TextStyle(
                            color: AppTheme.textPrimary(isDark),
                            fontSize: 20, fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          )),
                        ]),

                        // Theme toggle + logout
                        Row(children: [
                          _buildThemeToggle(),
                          const SizedBox(width: 10),
                          _buildLogoutButton(),
                        ]),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // ── GREETING ─────────────────────────────
                    Text(_getGreeting(), style: TextStyle(
                      color: AppTheme.textMuted(isDark),
                      fontSize: 16, fontWeight: FontWeight.w500,
                    )),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: Text(widget.user.username, style: TextStyle(
                          color: AppTheme.textPrimary(isDark),
                          fontSize: 36, fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          shape:  BoxShape.circle,
                          color:  AppTheme.crimson.withOpacity(0.15),
                          border: Border.all(
                              color: AppTheme.crimson.withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: Center(child: Text(_getInitials(),
                          style: const TextStyle(
                            color: AppTheme.crimson,
                            fontSize: 18, fontWeight: FontWeight.w900,
                          ))),
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // ── STATUS CARD ───────────────────────────
                    Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:        AppTheme.card(isDark),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border(isDark)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color:        AppTheme.crimson.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_user_rounded,
                              color: AppTheme.crimson, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account Verified', style: TextStyle(
                              color: AppTheme.textPrimary(isDark),
                              fontSize: 15, fontWeight: FontWeight.w700,
                            )),
                            const SizedBox(height: 2),
                            Text(widget.user.email, style: TextStyle(
                                color: AppTheme.textMuted(isDark),
                                fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color:        Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(
                            color: Colors.green, fontSize: 10,
                            fontWeight: FontWeight.w800, letterSpacing: 1.5,
                          )),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 32),

                    Text('QUEUE FEATURES', style: TextStyle(
                      color: AppTheme.textMuted(isDark), fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 2,
                    )),
                    const SizedBox(height: 16),

                    // ── FEATURE TILES ─────────────────────────
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12, mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildFeatureTile(
                              icon: Icons.queue_rounded, label: 'My Queue'),
                          _buildFeatureTile(
                              icon: Icons.confirmation_num_outlined,
                              label: 'My Tickets'),
                          _buildFeatureTile(
                              icon: Icons.store_rounded, label: 'Services'),
                          _buildFeatureTile(
                              icon: Icons.bar_chart_rounded, label: 'Activity'),
                        ],
                      ),
                    ),

                    Center(child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text('QLINE v1.0.0 — Smart Queue Management',
                        style: TextStyle(
                          color: AppTheme.textMuted(isDark).withOpacity(0.4),
                          fontSize: 11, letterSpacing: 0.5,
                        )),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return GestureDetector(
      onTap: () => ThemeProvider().toggleTheme(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40, height: 40,
        decoration: BoxDecoration(
          color:        AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppTheme.border(isDark)),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: isDark
              ? const Color(0xFFFFC107)
              : const Color(0xFF555555),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _onLogout,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color:        AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppTheme.border(isDark)),
        ),
        child: Row(children: [
          Icon(Icons.logout_rounded,
              color: AppTheme.textMuted(isDark), size: 16),
          const SizedBox(width: 6),
          Text('Logout', style: TextStyle(
            color: AppTheme.textMuted(isDark),
            fontSize: 13, fontWeight: FontWeight.w600,
          )),
        ]),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String   label,
  }) {
    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppTheme.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:    const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        AppTheme.crimson.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.crimson, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color:        AppTheme.border(isDark),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('SOON', style: TextStyle(
                  color: AppTheme.textMuted(isDark), fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 1,
                )),
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: TextStyle(
            color: AppTheme.textPrimary(isDark),
            fontSize: 15, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 2),
          Text('Coming soon', style: TextStyle(
              color: AppTheme.textMuted(isDark), fontSize: 12)),
        ],
      ),
    );
  }
}