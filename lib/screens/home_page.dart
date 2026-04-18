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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
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
                  DashboardView(
                    user: widget.user,
                    isDark: isDark,
                    onLogout: _onLogout,
                  ),
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
// STATEFUL: BACKGROUND DECORATIONS
// Stateful to support future animated entrance or theme-reactive
// gradient transitions without rebuilding the whole tree.
// =============================================================
class BackgroundDecorations extends StatefulWidget {
  const BackgroundDecorations({super.key});

  @override
  State<BackgroundDecorations> createState() => _BackgroundDecorationsState();
}

class _BackgroundDecorationsState extends State<BackgroundDecorations> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppTheme.crimson.withOpacity(0.13), Colors.transparent],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppTheme.darkCrimson.withOpacity(0.10), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// STATELESS: HEADER BAR
// =============================================================
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.crimson,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'TICKETY',
            style: TextStyle(
              color: AppTheme.textPrimary(isDark),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
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

// =============================================================
// STATELESS: GREETING HEADER
// =============================================================
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
        Text(
          _getGreeting(),
          style: TextStyle(
            color: AppTheme.textMuted(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: Text(
              user.username,
              style: TextStyle(
                color: AppTheme.textPrimary(isDark),
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.crimson.withOpacity(0.15),
            child: Text(
              _getInitials(),
              style: const TextStyle(
                color: AppTheme.crimson,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

// =============================================================
// STATEFUL: ACCOUNT STATUS CARD
// Stateful to allow future real-time status updates (e.g. polling
// verification status, showing a loading state, or refreshing
// account info) without lifting state to the parent.
// =============================================================
class AccountStatusCard extends StatefulWidget {
  final AuthUser user;
  final bool isDark;

  const AccountStatusCard({
    super.key,
    required this.user,
    required this.isDark,
  });

  @override
  State<AccountStatusCard> createState() => _AccountStatusCardState();
}

class _AccountStatusCardState extends State<AccountStatusCard> {
  bool _isVerified = true; // Can be fetched from a remote source in the future

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(widget.isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(widget.isDark)),
      ),
      child: Row(children: [
        Icon(
          _isVerified ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
          color: AppTheme.crimson,
          size: 22,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isVerified ? 'Account Verified' : 'Not Verified',
                style: TextStyle(
                  color: AppTheme.textPrimary(widget.isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.user.email,
                style: TextStyle(color: AppTheme.textMuted(widget.isDark), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        StatusBadge(
          label: _isVerified ? 'ACTIVE' : 'PENDING',
          color: _isVerified ? Colors.green : Colors.orange,
        ),
      ]),
    );
  }
}

// =============================================================
// STATEFUL: FEATURE GRID
// Stateful to support future dynamic loading of feature tiles
// from an API or local config (e.g. feature flags, permissions).
// =============================================================
class FeatureGrid extends StatefulWidget {
  const FeatureGrid({super.key});

  @override
  State<FeatureGrid> createState() => _FeatureGridState();
}

class _FeatureGridState extends State<FeatureGrid> {
  // Feature tiles definition — easily extendable or fetched remotely
  final List<Map<String, dynamic>> _features = const [
    {'icon': Icons.queue_rounded,        'label': 'My Queue'},
    {'icon': Icons.bar_chart_rounded,    'label': 'Analytics'},
    {'icon': Icons.people_alt_rounded,   'label': 'Agents'},
    {'icon': Icons.history_rounded,      'label': 'History'},
    {'icon': Icons.notifications_rounded,'label': 'Alerts'},
    {'icon': Icons.settings_rounded,     'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      physics: const NeverScrollableScrollPhysics(),
      children: _features
          .map((f) => FeatureTile(
                icon: f['icon'] as IconData,
                label: f['label'] as String,
              ))
          .toList(),
    );
  }
}

// =============================================================
// STATEFUL: FEATURE TILE
// Stateful to handle press/tap animation (scale + color feedback),
// and future navigation or locked-state toggling per tile.
// =============================================================
class FeatureTile extends StatefulWidget {
  final IconData icon;
  final String label;

  const FeatureTile({super.key, required this.icon, required this.label});

  @override
  State<FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<FeatureTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  void _onTap() {
    // TODO: Navigate to the respective feature page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.label} — Coming soon!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.card(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, color: AppTheme.crimson, size: 20),
              const Spacer(),
              Text(
                widget.label,
                style: TextStyle(
                  color: AppTheme.textPrimary(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Coming soon',
                style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// STATELESS: BOTTOM NAV
// =============================================================
class TicketyBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final Function(int) onTap;

  const TicketyBottomNav({
    super.key,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(isDark))),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: AppTheme.card(isDark),
        selectedItemColor: AppTheme.crimson,
        unselectedItemColor: AppTheme.textMuted(isDark),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded, size: 28),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// =============================================================
// STATEFUL: THEME TOGGLE BUTTON
// Stateful to animate the icon swap on theme change.
// =============================================================
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) {
      _rotateController.forward(from: 0);
      setState(() {});
    }
  }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return GestureDetector(
      onTap: () => ThemeProvider().toggleTheme(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border(isDark)),
        ),
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.5).animate(_rotateController),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? const Color(0xFFFFC107) : const Color(0xFF555555),
            size: 18,
          ),
        ),
      ),
    );
  }
}

// =============================================================
// STATELESS: LOGOUT BUTTON
// =============================================================
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
          color: AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border(isDark)),
        ),
        child: Row(children: [
          Icon(Icons.logout_rounded, color: AppTheme.textMuted(isDark), size: 16),
          const SizedBox(width: 6),
          Text(
            'Logout',
            style: TextStyle(
              color: AppTheme.textMuted(isDark),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ),
    );
  }
}

// =============================================================
// STATELESS: STATUS BADGE
// =============================================================
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// =============================================================
// STATELESS: SECTION LABEL
// =============================================================
class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.textMuted(isDark),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

// =============================================================
// STATELESS: FOOTER LABEL
// =============================================================
class FooterLabel extends StatelessWidget {
  const FooterLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          'TICKETY v1.0.0 — Smart Queue Management',
          style: TextStyle(
            color: AppTheme.textMuted(isDark).withOpacity(0.4),
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
