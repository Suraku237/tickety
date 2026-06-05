import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'home_page.dart';
import 'services_page.dart';
import 'alerts_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

// =============================================================
// NAV ITEM MODEL
// OOP Principle: Encapsulation — groups icon + label together
// =============================================================
class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String   label;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}

// =============================================================
// MAIN SHELL
// Responsibilities:
//   - Host all 4 main pages in an IndexedStack (pages stay alive)
//   - Provide animated bottom navigation bar
//   - Pass onNavigate callback to HomePage for quick actions
//   - Own logout logic and pass it down to ProfilePage
//
// Changes from previous version:
//   - Settings drawer removed entirely
//   - onLogout now passed to ProfilePage (not HomePage's drawer)
//   - ProfilePage constructor updated to accept onLogout
//
// OOP Principle: Single Responsibility, Composition
// =============================================================
class MainShell extends StatefulWidget {
  final AuthUser user;
  final int      initialIndex;

  const MainShell({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {

  final _session = SessionService();
  final _api     = ApiService();

  bool get isDark => ThemeProvider().isDarkMode;
  late int _currentIndex;

  final List<_NavItem> _navItems = const [
    _NavItem(
      activeIcon:   Icons.dashboard_rounded,
      inactiveIcon: Icons.dashboard_outlined,
      label:        'Home',
    ),
    _NavItem(
      activeIcon:   Icons.store_rounded,
      inactiveIcon: Icons.store_outlined,
      label:        'Services',
    ),
    _NavItem(
      activeIcon:   Icons.notifications_rounded,
      inactiveIcon: Icons.notifications_outlined,
      label:        'Alerts',
    ),
    _NavItem(
      activeIcon:   Icons.person_rounded,
      inactiveIcon: Icons.person_outlined,
      label:        'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _switchTo(int index) => setState(() => _currentIndex = index);

  // Owned here and passed down to ProfilePage
  Future<void> _logout() async {
    await _session.clear();
    _api.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor:                    Colors.transparent,
      statusBarIconBrightness:           isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:          AppTheme.card(isDark),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0 — Home dashboard
          HomePage(user: widget.user, onNavigate: _switchTo),
          // Tab 1 — Services
          const ServicesPage(),
          // Tab 2 — Alerts
          const AlertsPage(),
          // Tab 3 — Profile (owns theme, about, logout)
          ProfilePage(user: widget.user, onLogout: _logout),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(isDark),
        border: Border(
            top: BorderSide(color: AppTheme.border(isDark), width: 1)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset:     const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
              (i) => _buildNavItem(i),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item     = _navItems[index];
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap:    () => _switchTo(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical:   8),
        decoration: BoxDecoration(
          color:        isActive
              ? AppTheme.crimson.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.inactiveIcon,
              color: isActive
                  ? AppTheme.crimson
                  : AppTheme.textMuted(isDark),
              size: 22),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve:    Curves.easeInOut,
              child: isActive
                  ? Row(children: [
                      const SizedBox(width: 6),
                      Text(item.label, style: const TextStyle(
                        color:      AppTheme.crimson,
                        fontSize:   12,
                        fontWeight: FontWeight.w700)),
                    ])
                  : const SizedBox.shrink()),
          ]),
      ),
    );
  }
}