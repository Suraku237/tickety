import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// AUTH USER (DTO)
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
      userId: data['user_id'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
    );
  }
}

// =============================================================
// HOME PAGE (Main Controller)
// =============================================================
class HomePage extends StatefulWidget {
  final AuthUser user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _sessionService = SessionService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentIndex = 0;
  bool get isDark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            const BackgroundDecorations(),
            SafeArea(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  DashboardView(user: widget.user, isDark: isDark, onLogout: _onLogout),
                  const Center(child: Text("Create Ticket Page")),
                  const Center(child: Text("Settings Page")),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TicketyBottomNav(
        currentIndex: _currentIndex,
        isDark: isDark,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// =============================================================
// VIEW OBJECT: DASHBOARD
// =============================================================
class DashboardView extends StatelessWidget {
  final AuthUser user;
  final bool isDark;
  final VoidCallback onLogout;

  const DashboardView({
    super.key,
    required this.user,
    required this.isDark,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          HeaderBar(isDark: isDark, onLogout: onLogout),
          const SizedBox(height: 48),
          GreetingHeader(user: user, isDark: isDark),
          const SizedBox(height: 32),
          AccountStatusCard(user: user, isDark: isDark),
          const SizedBox(height: 32),
          const SectionLabel(label: 'QUEUE FEATURES'),
          const SizedBox(height: 16),
          const Expanded(child: FeatureGrid()),
          const FooterLabel(),
        ],
      ),
    );
  }
}

// =============================================================
// COMPONENT OBJECTS
// =============================================================

class BackgroundDecorations extends StatelessWidget {
  const BackgroundDecorations({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppTheme.crimson.withOpacity(0.13), Colors.transparent]),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppTheme.darkCrimson.withOpacity(0.10), Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }
}

class HeaderBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onLogout;
  const HeaderBar({super.key, required this.isDark, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.crimson, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text('TICKETY', style: TextStyle(
            color: AppTheme.textPrimary(isDark),
            fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 4,
          )),
        ]),
        Row(children: [
          const ThemeToggleButton(),
          const SizedBox(width: 10),
          LogoutButton(onTap: onLogout),
        ]),
      ],
    );
  }
}

class GreetingHeader extends StatelessWidget {
  final AuthUser user;
  final bool isDark;
  const GreetingHeader({super.key, required this.user, required this.isDark});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getInitials() {
    if (user.username.isEmpty) return '?';
    final parts = user.username.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return user.username[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_getGreeting(), style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text(user.username, style: TextStyle(
            color: AppTheme.textPrimary(isDark), fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1,
          ), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.crimson.withOpacity(0.15),
            child: Text(_getInitials(), style: const TextStyle(color: AppTheme.crimson, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ]),
      ],
    );
  }
}

class AccountStatusCard extends StatelessWidget {
  final AuthUser user;
  final bool isDark;
  const AccountStatusCard({super.key, required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(isDark)),
      ),
      child: Row(children: [
        const Icon(Icons.verified_user_rounded, color: AppTheme.crimson, size: 22),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Verified', style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 15, fontWeight: FontWeight.w700)),
            Text(user.email, style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 13), overflow: TextOverflow.ellipsis),
          ],
        )),
        const StatusBadge(label: 'ACTIVE', color: Colors.green),
      ]),
    );
  }
}

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
      ],
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const FeatureTile({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.crimson, size: 20),
          const Spacer(),
          Text(label, style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 15, fontWeight: FontWeight.w700)),
          Text('Coming soon', style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 12)),
        ],
      ),
    );
  }
}

class TicketyBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final Function(int) onTap;

  const TicketyBottomNav({super.key, required this.currentIndex, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border(isDark)))),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: AppTheme.card(isDark),
        selectedItemColor: AppTheme.crimson,
        unselectedItemColor: AppTheme.textMuted(isDark),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_rounded, size: 28), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

// =============================================================
// SMALL UI ATOMS
// =============================================================

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return GestureDetector(
      onTap: () => ThemeProvider().toggleTheme(),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppTheme.card(isDark), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border(isDark)),
        ),
        child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? const Color(0xFFFFC107) : const Color(0xFF555555), size: 18),
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const LogoutButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.card(isDark), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border(isDark)),
        ),
        child: Row(children: [
          Icon(Icons.logout_rounded, color: AppTheme.textMuted(isDark), size: 16),
          const SizedBox(width: 6),
          Text('Logout', style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return Text(label, style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2));
  }
}

class FooterLabel extends StatelessWidget {
  const FooterLabel({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text('TICKETY v1.0.0 — Smart Queue Management',
            style: TextStyle(color: AppTheme.textMuted(isDark).withOpacity(0.4), fontSize: 11)),
      ),
    );
  }
}