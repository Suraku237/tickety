import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'create_ticket_page.dart';
import 'my_tickets_page.dart';
import 'settings_page.dart';

// =============================================================
// AUTH USER  (DTO)
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

  factory AuthUser.fromMap(Map<String, dynamic> d) => AuthUser(
    userId:   d['user_id']  ?? '',
    username: d['username'] ?? '',
    email:    d['email']    ?? '',
  );
}

// =============================================================
// HOME PAGE  — IndexedStack shell
// =============================================================
class HomePage extends StatefulWidget {
  final AuthUser user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  final _session = SessionService();
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  int  _tab   = 0;
  bool get _dark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    ThemeProvider().addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _session.clear();
    ApiService().clearToken();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _goToCreate() => setState(() => _tab = 1);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: _dark ? Brightness.light : Brightness.dark,
    ));
    return Scaffold(
      backgroundColor: AppTheme.surface(_dark),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(
          index: _tab,
          children: [
            DashboardPage(
              user:       widget.user,
              onCreateTicket: _goToCreate,
            ),
            CreateTicketPage(user: widget.user),
            MyTicketsPage(user: widget.user),
            SettingsPage(user: widget.user, onLogout: _logout),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap:   (i) => setState(() => _tab = i),
        dark:    _dark,
      ),
    );
  }
}

// =============================================================
// BOTTOM NAV
// =============================================================
class _BottomNav extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  final bool dark;
  const _BottomNav({required this.current, required this.onTap, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:  AppTheme.card(dark),
        border: Border(top: BorderSide(color: AppTheme.border(dark))),
        boxShadow: [
          BoxShadow(
            color:   Colors.black.withOpacity(dark ? 0.3 : 0.06),
            blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_rounded,   label: 'Home',    index: 0, current: current, onTap: onTap, dark: dark),
              _NavItem(icon: Icons.add_circle_rounded,  label: 'Create',  index: 1, current: current, onTap: onTap, dark: dark, accent: true),
              _NavItem(icon: Icons.confirmation_num_rounded, label: 'Tickets', index: 2, current: current, onTap: onTap, dark: dark),
              _NavItem(icon: Icons.person_rounded,      label: 'Profile', index: 3, current: current, onTap: onTap, dark: dark),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      index;
  final int      current;
  final void Function(int) onTap;
  final bool dark;
  final bool accent;

  const _NavItem({
    required this.icon, required this.label, required this.index,
    required this.current, required this.onTap, required this.dark,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    final color    = selected ? AppTheme.crimson : AppTheme.textMuted(dark);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.crimson.withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: accent ? 28 : 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            color:      color,
            fontSize:   10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          )),
        ]),
      ),
    );
  }
}

// =============================================================
// DASHBOARD PAGE
// =============================================================
class DashboardPage extends StatefulWidget {
  final AuthUser user;
  final VoidCallback onCreateTicket;

  const DashboardPage({
    super.key,
    required this.user,
    required this.onCreateTicket,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _api = ApiService();

  bool _loading       = true;
  int  _totalTickets  = 0;
  int  _openTickets   = 0;
  int  _closedTickets = 0;
  int  _urgentTickets = 0;
  List<Map<String, dynamic>> _recentTickets = [];

  bool get _dark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    ThemeProvider().addListener(_rebuild);
    _loadStats();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getTickets( userId:widget.user.userId);
      if (!mounted) return; 

      final tickets = (data['tickets'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      setState(() {
        _totalTickets  = tickets.length;
        _openTickets   = tickets.where((t) =>
            (t['status'] ?? '').toString().toLowerCase() == 'open').length;
        _closedTickets = tickets.where((t) =>
            (t['status'] ?? '').toString().toLowerCase() == 'closed').length;
        _urgentTickets = tickets.where((t) =>
            (t['priority'] ?? '').toString().toLowerCase() == 'urgent').length;
        _recentTickets = tickets.take(3).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Decorative background glows
      Positioned(top: -60, right: -60,
        child: Container(width: 260, height: 260,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.crimson.withOpacity(0.12), Colors.transparent])))),
      Positioned(bottom: 80, left: -80,
        child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.darkCrimson.withOpacity(0.08), Colors.transparent])))),

      SafeArea(
        child: RefreshIndicator(
          color:    AppTheme.crimson,
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 20),

              // ── Top bar ──
              _TopBar(user: widget.user, dark: _dark),
              const SizedBox(height: 28),

              // ── Greeting ──
              _GreetingSection(user: widget.user, dark: _dark),
              const SizedBox(height: 28),

              // ── Create ticket CTA ──
              _CreateTicketBanner(onTap: widget.onCreateTicket, dark: _dark),
              const SizedBox(height: 28),

              // ── Stats row ──
              _StatsRow(
                dark:    _dark,
                loading: _loading,
                total:   _totalTickets,
                open:    _openTickets,
                closed:  _closedTickets,
                urgent:  _urgentTickets,
              ),
              const SizedBox(height: 28),

              // ── Recent tickets ──
              _SectionHeader(
                title: 'Recent Tickets',
                dark:  _dark,
                action: _totalTickets > 0 ? 'View all' : null,
                onAction: () {},
              ),
              const SizedBox(height: 14),
              _loading
                  ? _SkeletonList(dark: _dark)
                  : _recentTickets.isEmpty
                      ? _EmptyState(dark: _dark, onTap: widget.onCreateTicket)
                      : Column(
                          children: _recentTickets
                              .map((t) => _TicketCard(ticket: t, dark: _dark))
                              .toList(),
                        ),
              const SizedBox(height: 28),

              // ── Quick actions ──
              _SectionHeader(title: 'Quick Actions', dark: _dark),
              const SizedBox(height: 14),
              _QuickActionsGrid(
                dark:           _dark,
                onCreateTicket: widget.onCreateTicket,
              ),
              const SizedBox(height: 28),

              // Footer
              Center(child: Text('TICKETY v1.0  ·  Smart Queue Management',
                style: TextStyle(
                  color: AppTheme.textMuted(_dark).withOpacity(0.4),
                  fontSize: 11,
                ),
              )),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// =============================================================
// TOP BAR
// =============================================================
class _TopBar extends StatelessWidget {
  final AuthUser user;
  final bool dark;
  const _TopBar({required this.user, required this.dark});

  String _initials() {
    if (user.username.isEmpty) return '?';
    final p = user.username.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : user.username[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Brand
      Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color:        AppTheme.crimson,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.confirmation_num_rounded,
              color: Colors.white, size: 17),
        ),
        const SizedBox(width: 9),
        Text('TICKETY', style: TextStyle(
          color: AppTheme.textPrimary(dark), fontSize: 18,
          fontWeight: FontWeight.w800, letterSpacing: 4,
        )),
      ]),
      const Spacer(),

      // Theme toggle
      GestureDetector(
        onTap: () => ThemeProvider().toggleTheme(),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        AppTheme.card(dark),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border(dark)),
          ),
          child: Icon(
            dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: dark ? const Color(0xFFFFC107) : const Color(0xFF555555),
            size: 17,
          ),
        ),
      ),
      const SizedBox(width: 10),

      // Avatar
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color:        AppTheme.crimson.withOpacity(0.15),
          shape:        BoxShape.circle,
          border: Border.all(color: AppTheme.crimson.withOpacity(0.3)),
        ),
        child: Center(child: Text(_initials(), style: const TextStyle(
          color: AppTheme.crimson, fontSize: 13, fontWeight: FontWeight.w900,
        ))),
      ),
    ]);
  }
}

// =============================================================
// GREETING SECTION
// =============================================================
class _GreetingSection extends StatelessWidget {
  final AuthUser user;
  final bool dark;
  const _GreetingSection({required this.user, required this.dark});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_greeting(), style: TextStyle(
        color: AppTheme.textMuted(dark), fontSize: 15,
        fontWeight: FontWeight.w500,
      )),
      const SizedBox(height: 4),
      Text(
        user.username.isNotEmpty ? user.username : 'User',
        style: TextStyle(
          color: AppTheme.textPrimary(dark), fontSize: 32,
          fontWeight: FontWeight.w900, letterSpacing: -0.8,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 4),
      Row(children: [
        Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(
            color: Colors.green, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('Account active', style: TextStyle(
          color: AppTheme.textMuted(dark), fontSize: 13,
        )),
      ]),
    ]);
  }
}

// =============================================================
// CREATE TICKET CTA BANNER
// =============================================================
class _CreateTicketBanner extends StatefulWidget {
  final VoidCallback onTap;
  final bool dark;
  const _CreateTicketBanner({required this.onTap, required this.dark});

  @override
  State<_CreateTicketBanner> createState() => _CreateTicketBannerState();
}

class _CreateTicketBannerState extends State<_CreateTicketBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.crimson, AppTheme.darkCrimson],
              begin:  Alignment.topLeft,
              end:    Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color:   AppTheme.crimson.withOpacity(0.35),
                blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('NEW', style: TextStyle(
                    color: Colors.white, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 2,
                  )),
                ),
                const SizedBox(height: 10),
                const Text('Create a Ticket', style: TextStyle(
                  color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w900,
                )),
                const SizedBox(height: 4),
                Text('Scan a QR code or enter a service link',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ]),
            ),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 26),
            ),
          ]),
        ),
      ),
    );
  }
}

// =============================================================
// STATS ROW
// =============================================================
class _StatsRow extends StatelessWidget {
  final bool dark, loading;
  final int  total, open, closed, urgent;
  const _StatsRow({
    required this.dark, required this.loading,
    required this.total, required this.open,
    required this.closed, required this.urgent,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Row(children: List.generate(4, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
          height: 82,
          decoration: BoxDecoration(
            color:        AppTheme.card(dark),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      )));
    }
    return Row(children: [
      _StatCard(label: 'Total',  value: total,  color: AppTheme.textMuted(dark), dark: dark),
      const SizedBox(width: 10),
      _StatCard(label: 'Open',   value: open,   color: Colors.blue,   dark: dark),
      const SizedBox(width: 10),
      _StatCard(label: 'Closed', value: closed, color: Colors.green,  dark: dark),
      const SizedBox(width: 10),
      _StatCard(label: 'Urgent', value: urgent, color: AppTheme.crimson, dark: dark),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;
  final bool   dark;
  const _StatCard({required this.label, required this.value,
      required this.color, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color:        AppTheme.card(dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(dark)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value.toString(), style: TextStyle(
            color: color, fontSize: 22, fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            color: AppTheme.textMuted(dark), fontSize: 11,
            fontWeight: FontWeight.w600,
          )),
        ]),
      ),
    );
  }
}

// =============================================================
// SECTION HEADER
// =============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool   dark;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, required this.dark,
      this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: TextStyle(
        color: AppTheme.textPrimary(dark), fontSize: 17,
        fontWeight: FontWeight.w800,
      )),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Text(action!, style: const TextStyle(
            color: AppTheme.crimson, fontSize: 13, fontWeight: FontWeight.w700,
          )),
        ),
    ]);
  }
}

// =============================================================
// RECENT TICKET CARD
// =============================================================
class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool dark;
  const _TicketCard({required this.ticket, required this.dark});

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'urgent': return AppTheme.crimson;
      case 'high':   return Colors.orange;
      case 'medium': return Colors.blue;
      default:       return Colors.green;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'open':    return Colors.blue;
      case 'closed':  return Colors.green;
      case 'pending': return Colors.orange;
      default:        return AppTheme.textMuted(dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title    = ticket['title']    ?? 'Untitled';
    final status   = ticket['status']   ?? 'open';
    final priority = ticket['priority'] ?? 'low';
    final service  = ticket['service']  ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Row(children: [
        // Priority dot
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color:  _priorityColor(priority),
            shape:  BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: TextStyle(
                color: AppTheme.textPrimary(dark),
                fontSize: 14, fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (service.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(service, style: TextStyle(
                color: AppTheme.textMuted(dark), fontSize: 12,
              )),
            ],
          ],
        )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color:        _statusColor(status).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: _statusColor(status), fontSize: 10,
              fontWeight: FontWeight.w800, letterSpacing: 0.5,
            )),
        ),
      ]),
    );
  }
}

// =============================================================
// EMPTY STATE
// =============================================================
class _EmptyState extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;
  const _EmptyState({required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Column(children: [
        Icon(Icons.confirmation_num_outlined,
            color: AppTheme.textMuted(dark).withOpacity(0.4), size: 40),
        const SizedBox(height: 12),
        Text('No tickets yet', style: TextStyle(
          color: AppTheme.textPrimary(dark),
          fontSize: 15, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 6),
        Text('Create your first ticket to get started',
            style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 13)),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color:        AppTheme.crimson,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Create ticket', style: TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
            )),
          ),
        ),
      ]),
    );
  }
}

// =============================================================
// SKELETON LOADER
// =============================================================
class _SkeletonList extends StatelessWidget {
  final bool dark;
  const _SkeletonList({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 68,
        decoration: BoxDecoration(
          color:        AppTheme.card(dark),
          borderRadius: BorderRadius.circular(14),
        ),
      )),
    );
  }
}

// =============================================================
// QUICK ACTIONS GRID
// =============================================================
class _QuickActionsGrid extends StatelessWidget {
  final bool dark;
  final VoidCallback onCreateTicket;
  const _QuickActionsGrid({required this.dark, required this.onCreateTicket});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(icon: Icons.qr_code_scanner_rounded, label: 'Scan QR',   color: AppTheme.crimson,  onTap: onCreateTicket),
      _QA(icon: Icons.link_rounded,            label: 'Enter Link', color: Colors.blue,       onTap: onCreateTicket),
      _QA(icon: Icons.history_rounded,         label: 'History',    color: Colors.orange,     onTap: () {}),
      _QA(icon: Icons.notifications_rounded,   label: 'Alerts',     color: Colors.purple,     onTap: () {}),
      _QA(icon: Icons.bar_chart_rounded,       label: 'Analytics',  color: Colors.teal,       onTap: () {}),
      _QA(icon: Icons.support_agent_rounded,   label: 'Support',    color: Colors.green,      onTap: () {}),
    ];

    return GridView.count(
      crossAxisCount:   3,
      crossAxisSpacing: 10,
      mainAxisSpacing:  10,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.map((a) => _QuickActionTile(qa: a, dark: dark)).toList(),
    );
  }
}

class _QA {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _QA({required this.icon, required this.label,
      required this.color, required this.onTap});
}

class _QuickActionTile extends StatefulWidget {
  final _QA  qa;
  final bool dark;
  const _QuickActionTile({required this.qa, required this.dark});

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.qa.onTap(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color:        AppTheme.card(widget.dark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(widget.dark)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color:        widget.qa.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.qa.icon, color: widget.qa.color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(widget.qa.label, style: TextStyle(
              color: AppTheme.textPrimary(widget.dark),
              fontSize: 12, fontWeight: FontWeight.w700,
            )),
          ]),
        ),
      ),
    );
  }
}
