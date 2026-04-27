import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'my_queue_page.dart';
import 'my_tickets_page.dart';
import 'services_page.dart';

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
// SETTINGS PANEL
// Responsibilities:
//   - Display settings options in a right-side drawer
//   - Theme toggle lives here
//   - Logout action lives here
// OOP Principle: Single Responsibility
// =============================================================
class _SettingsPanel extends StatelessWidget {
  final bool isDark;
  final VoidCallback onLogout;

  const _SettingsPanel({
    required this.isDark,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.card(isDark),
        border: Border(
          left: BorderSide(color: AppTheme.border(isDark), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Settings', style: TextStyle(
                    color: AppTheme.textPrimary(isDark),
                    fontSize: 20, fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  )),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(isDark),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border(isDark)),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: AppTheme.textMuted(isDark), size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Divider(color: AppTheme.border(isDark), height: 1),
            const SizedBox(height: 24),

            // ── APPEARANCE SECTION ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('APPEARANCE', style: TextStyle(
                color: AppTheme.textMuted(isDark), fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 2,
              )),
            ),
            const SizedBox(height: 16),

            // Theme toggle row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.surface(isDark),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border(isDark)),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: isDark
                            ? const Color(0xFFFFC107)
                            : const Color(0xFF555555),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(isDark ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(
                        color: AppTheme.textPrimary(isDark),
                        fontSize: 15, fontWeight: FontWeight.w600,
                      )),
                  ]),

                  // Toggle switch
                  GestureDetector(
                    onTap: () => ThemeProvider().toggleTheme(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 48, height: 26,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.crimson
                            : AppTheme.border(isDark),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: isDark
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 20, height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Divider(color: AppTheme.border(isDark), height: 1),
            const SizedBox(height: 24),

            // ── ACCOUNT SECTION ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('ACCOUNT', style: TextStyle(
                color: AppTheme.textMuted(isDark), fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 2,
              )),
            ),
            const SizedBox(height: 16),

            // Profile settings tile
            _buildSettingsTile(
              isDark: isDark,
              icon:   Icons.person_outline_rounded,
              label:  'Edit Profile',
              onTap:  () {},
            ),

            const SizedBox(height: 8),

            // Notifications tile
            _buildSettingsTile(
              isDark: isDark,
              icon:   Icons.notifications_outlined,
              label:  'Notifications',
              onTap:  () {},
            ),

            const Spacer(),

            Divider(color: AppTheme.border(isDark), height: 1),
            const SizedBox(height: 16),

            // Logout
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: onLogout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.crimson.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded,
                          color: AppTheme.crimson, size: 18),
                      SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(
                        color: AppTheme.crimson,
                        fontSize: 14, fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(isDark)),
          ),
          child: Row(children: [
            Icon(icon, color: AppTheme.textMuted(isDark), size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(
              color: AppTheme.textPrimary(isDark),
              fontSize: 14, fontWeight: FontWeight.w600,
            ))),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted(isDark), size: 18),
          ]),
        ),
      ),
    );
  }
}


// =============================================================
// HOME PAGE
// Responsibilities:
//   - Display authenticated user's dashboard
//   - Show live queue info in the My Queue card
//   - Open settings drawer on settings button tap
// OOP Principle: Single Responsibility, Composition
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

  // Placeholder queue data — will come from backend later
  final Map<String, dynamic> _queueInfo = {
    'hasActiveTicket': true,
    'ticketNumber':    'A047',
    'serviceName':     'Main Counter',
    'position':        3,
    'peopleAhead':     2,
    'currentlyServing': 'A045',
    'estimatedMinutes': 12,
    'status':          'waiting', // waiting | being_served | suspended
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(
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

  void _openSettings() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: _SettingsPanel(
            isDark:   isDark,
            onLogout: _onLogout,
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end:   Offset.zero,
          ).animate(CurvedAnimation(
              parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
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
            // Background glows
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── TOP BAR ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color:        AppTheme.crimson,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                                Icons.confirmation_num_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('QLINE', style: TextStyle(
                            color: AppTheme.textPrimary(isDark),
                            fontSize: 20, fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          )),
                        ]),

                        // Settings button
                        GestureDetector(
                          onTap: _openSettings,
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.card(isDark),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.border(isDark)),
                            ),
                            child: Icon(Icons.settings_rounded,
                                color: AppTheme.textMuted(isDark), size: 20),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── GREETING ─────────────────────────────
                    Text(_getGreeting(), style: TextStyle(
                      color: AppTheme.textMuted(isDark),
                      fontSize: 14, fontWeight: FontWeight.w500,
                    )),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(
                        child: Text(widget.user.username, style: TextStyle(
                          color: AppTheme.textPrimary(isDark),
                          fontSize: 30, fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.crimson.withOpacity(0.15),
                          border: Border.all(
                              color: AppTheme.crimson.withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: Center(child: Text(_getInitials(),
                          style: const TextStyle(
                            color: AppTheme.crimson,
                            fontSize: 16, fontWeight: FontWeight.w900,
                          ))),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ── SECTION LABEL ─────────────────────────
                    Text('MY SPACE', style: TextStyle(
                      color: AppTheme.textMuted(isDark), fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 2,
                    )),
                    const SizedBox(height: 12),

                    // ── MAIN LAYOUT ───────────────────────────
                    // Left: tall My Queue card | Right: My Tickets + Services
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── MY QUEUE (tall card, full height) ──
                          Expanded(
                            flex: 5,
                            child: _buildMyQueueCard(),
                          ),

                          const SizedBox(width: 12),

                          // ── RIGHT COLUMN: My Tickets + Services ──
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildSmallCard(
                                    icon:  Icons.confirmation_num_outlined,
                                    label: 'My Tickets',
                                    sub:   'View history',
                                    route: const MyTicketsPage(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _buildSmallCard(
                                    icon:  Icons.store_rounded,
                                    label: 'Services',
                                    sub:   'Browse & join',
                                    route: const ServicesPage(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Footer
                    Center(child: Text(
                      'QLINE v1.0.0 — Smart Queue Management',
                      style: TextStyle(
                        color: AppTheme.textMuted(isDark).withOpacity(0.35),
                        fontSize: 10, letterSpacing: 0.5,
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // MY QUEUE CARD — tall, shows live queue info
  // =============================================================
  Widget _buildMyQueueCard() {
    final bool hasTicket = _queueInfo['hasActiveTicket'] as bool;
    final bool isBeingServed = _queueInfo['status'] == 'being_served';

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const MyQueuePage())),
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
            color: hasTicket && isBeingServed
                ? AppTheme.crimson.withOpacity(0.5)
                : AppTheme.border(isDark),
            width: hasTicket && isBeingServed ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Card header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:        AppTheme.crimson.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.queue_rounded,
                      color: AppTheme.crimson, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasTicket
                        ? (isBeingServed
                            ? AppTheme.crimson.withOpacity(0.12)
                            : Colors.green.withOpacity(0.1))
                        : AppTheme.border(isDark),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hasTicket
                          ? (isBeingServed
                              ? AppTheme.crimson.withOpacity(0.4)
                              : Colors.green.withOpacity(0.3))
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    hasTicket
                        ? (isBeingServed ? 'SERVING' : 'WAITING')
                        : 'NO TICKET',
                    style: TextStyle(
                      color: hasTicket
                          ? (isBeingServed
                              ? AppTheme.crimson
                              : Colors.green)
                          : AppTheme.textMuted(isDark),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text('My Queue', style: TextStyle(
              color: AppTheme.textPrimary(isDark),
              fontSize: 15, fontWeight: FontWeight.w800,
            )),

            const SizedBox(height: 16),

            if (hasTicket) ...[

              // Ticket number — big display
              Center(
                child: Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.crimson.withOpacity(0.2)),
                  ),
                  child: Column(children: [
                    Text(_queueInfo['ticketNumber'],
                      style: const TextStyle(
                        color:       AppTheme.crimson,
                        fontSize:    32,
                        fontWeight:  FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(_queueInfo['serviceName'],
                      style: TextStyle(
                        color:    AppTheme.textMuted(isDark),
                        fontSize: 11,
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Queue stats
              _buildQueueStat(
                icon:  Icons.people_outline_rounded,
                label: 'Ahead of you',
                value: '${_queueInfo['peopleAhead']} people',
              ),
              const SizedBox(height: 10),
              _buildQueueStat(
                icon:  Icons.confirmation_num_outlined,
                label: 'Now serving',
                value: _queueInfo['currentlyServing'],
              ),
              const SizedBox(height: 10),
              _buildQueueStat(
                icon:  Icons.timer_outlined,
                label: 'Est. wait',
                value: '~${_queueInfo['estimatedMinutes']} min',
                highlight: true,
              ),

              const Spacer(),

              // Tap to view more hint
              Center(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tap for details', style: TextStyle(
                    color:    AppTheme.textMuted(isDark),
                    fontSize: 11,
                  )),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      color: AppTheme.textMuted(isDark), size: 12),
                ],
              )),

            ] else ...[

              const Spacer(),

              // No active ticket state
              Center(child: Column(children: [
                Icon(Icons.inbox_outlined,
                    color: AppTheme.textMuted(isDark), size: 36),
                const SizedBox(height: 12),
                Text('No active ticket',
                  style: TextStyle(
                    color:      AppTheme.textMuted(isDark),
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                  )),
                const SizedBox(height: 4),
                Text('Join a service to\nget your ticket',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:    AppTheme.textMuted(isDark).withOpacity(0.6),
                    fontSize: 11,
                  )),
              ])),

              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStat({
    required IconData icon,
    required String   label,
    required String   value,
    bool highlight = false,
  }) {
    return Row(children: [
      Icon(icon,
          color: highlight
              ? AppTheme.crimson
              : AppTheme.textMuted(isDark),
          size: 14),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(
        color: AppTheme.textMuted(isDark), fontSize: 12,
      )),
      const Spacer(),
      Text(value, style: TextStyle(
        color: highlight
            ? AppTheme.crimson
            : AppTheme.textPrimary(isDark),
        fontSize: 12, fontWeight: FontWeight.w700,
      )),
    ]);
  }

  // =============================================================
  // SMALL CARD — My Tickets and Services
  // =============================================================
  Widget _buildSmallCard({
    required IconData icon,
    required String   label,
    required String   sub,
    required Widget   route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => route)),
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: AppTheme.border(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
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
                  child: Icon(icon, color: AppTheme.crimson, size: 18),
                ),
                Icon(Icons.arrow_forward_rounded,
                    color: AppTheme.textMuted(isDark), size: 16),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontSize:   14,
                  fontWeight: FontWeight.w800,
                )),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(
                  color:    AppTheme.textMuted(isDark),
                  fontSize: 11,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}