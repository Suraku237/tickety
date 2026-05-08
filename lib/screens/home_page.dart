import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'create_tickets_page.dart';

// =============================================================
// AUTH USER  (DTO — shared across all pages)
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

  factory AuthUser.fromMap(Map<String, dynamic> data) => AuthUser(
    userId:   data['user_id']  ?? '',
    username: data['username'] ?? '',
    email:    data['email']    ?? '',
  );
}

// =============================================================
// HOME PAGE  —  IndexedStack shell  (3 tabs)
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

  int  _tab  = 0;
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

  // Allow DashboardView to push the user to the Create tab
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
        child: Stack(children: [
          const _BgGlows(),
          SafeArea(
            child: IndexedStack(
              index: _tab,
              children: [
                // Tab 0 — Dashboard (live data)
                _DashboardPage(
                  user:         widget.user,
                  onCreateTap:  _goToCreate,
                ),
                // Tab 1 — Create Ticket (fully implemented)
                CreateTicketPage(user: widget.user),
                // Tab 2 — Settings (fully implemented)
                _SettingsPage(
                  user:     widget.user,
                  onLogout: _logout,
                ),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        dark:    _dark,
        onTap:   (i) => setState(() => _tab = i),
      ),
    );
  }
}

// =============================================================
// BOTTOM NAV
// =============================================================
class _BottomNav extends StatelessWidget {
  final int current;
  final bool dark;
  final void Function(int) onTap;
  const _BottomNav({required this.current, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:  AppTheme.card(dark),
        border: Border(top: BorderSide(color: AppTheme.border(dark))),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(dark ? 0.25 : 0.06),
          blurRadius: 16, offset: const Offset(0, -4),
        )],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_rounded,
                  label: 'Home',    index: 0, current: current, onTap: onTap, dark: dark),
              _NavItem(icon: Icons.add_circle_rounded,
                  label: 'Create',  index: 1, current: current, onTap: onTap, dark: dark),
              _NavItem(icon: Icons.manage_accounts_rounded,
                  label: 'Profile', index: 2, current: current, onTap: onTap, dark: dark),
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
  final bool     dark;

  const _NavItem({
    required this.icon, required this.label, required this.index,
    required this.current, required this.onTap, required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final sel   = index == current;
    final color = sel ? AppTheme.crimson : AppTheme.textMuted(dark);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color:        sel ? AppTheme.crimson.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            color:      color,
            fontSize:   10,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
          )),
        ]),
      ),
    );
  }
}

// =============================================================
// BACKGROUND GLOWS  (decorative, kept from original)
// =============================================================
class _BgGlows extends StatelessWidget {
  const _BgGlows();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 260, height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.crimson.withOpacity(0.10), Colors.transparent]),
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
              AppTheme.darkCrimson.withOpacity(0.08), Colors.transparent]),
          ),
        ),
      ),
    ]);
  }
}

// =============================================================
// ─────────────────────────────────────────────────────────────
//  DASHBOARD PAGE  (Tab 0)
//  - Loads real stats from API on mount + pull-to-refresh
//  - Recent tickets live list
//  - Create CTA banner
//  - Quick actions grid wired to real tabs / pages
// ─────────────────────────────────────────────────────────────
// =============================================================
class _DashboardPage extends StatefulWidget {
  final AuthUser   user;
  final VoidCallback onCreateTap;

  const _DashboardPage({required this.user, required this.onCreateTap});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  final _api = ApiService();

  bool   _loading       = true;
  String? _error;
  int    _total         = 0;
  int    _open          = 0;
  int    _closed        = 0;
  int    _urgent        = 0;
  List<Map<String, dynamic>> _recent = [];

  bool get _dark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    ThemeProvider().addListener(_rebuild);
    _load();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getTickets(userId: widget.user.userId);
      if (!mounted) return;
      final tickets = (data['tickets'] as List? ?? []).cast<Map<String,dynamic>>();
      setState(() {
        _total   = tickets.length;
        _open    = tickets.where((t) => t['status'] == 'open').length;
        _closed  = tickets.where((t) => t['status'] == 'closed').length;
        _urgent  = tickets.where((t) => t['priority'] == 'urgent').length;
        _recent  = tickets.take(3).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Could not load tickets.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color:    AppTheme.crimson,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 22),

          // ── Top bar ──
          _TopBar(user: widget.user, dark: _dark),
          const SizedBox(height: 26),

          // ── Greeting ──
          _Greeting(user: widget.user, dark: _dark),
          const SizedBox(height: 26),

          // ── Create CTA ──
          _CreateBanner(dark: _dark, onTap: widget.onCreateTap),
          const SizedBox(height: 26),

          // ── Stats ──
          if (_error != null)
            _ErrorStrip(message: _error!, dark: _dark)
          else
            _StatsRow(
              dark: _dark, loading: _loading,
              total: _total, open: _open,
              closed: _closed, urgent: _urgent,
            ),
          const SizedBox(height: 26),

          // ── Recent tickets ──
          _SectionHeader(
            title: 'Recent Tickets', dark: _dark,
            action: _total > 0 ? 'See all' : null,
            onAction: () {},
          ),
          const SizedBox(height: 12),
          _loading
              ? _SkeletonList(dark: _dark)
              : _recent.isEmpty
                  ? _EmptyTickets(dark: _dark, onTap: widget.onCreateTap)
                  : Column(children: _recent
                      .map((t) => _TicketRow(ticket: t, dark: _dark))
                      .toList()),
          const SizedBox(height: 26),

          // ── Quick actions ──
          _SectionHeader(title: 'Quick Actions', dark: _dark),
          const SizedBox(height: 12),
          _QuickGrid(dark: _dark, onCreateTap: widget.onCreateTap),

          const SizedBox(height: 28),
          Center(child: Text('TICKETY v1.0  ·  Smart Queue Management',
            style: TextStyle(
              color:    AppTheme.textMuted(_dark).withOpacity(0.35),
              fontSize: 11,
            ))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ── Top bar: brand + theme toggle + avatar ──
class _TopBar extends StatelessWidget {
  final AuthUser user;
  final bool dark;
  const _TopBar({required this.user, required this.dark});

  String _initials() {
    if (user.username.isEmpty) return '?';
    final p = user.username.trim().split(' ');
    return (p.length >= 2 ? '${p[0][0]}${p[1][0]}' : user.username[0])
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Brand
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppTheme.crimson, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.confirmation_num_rounded,
            color: Colors.white, size: 16),
      ),
      const SizedBox(width: 9),
      Text('TICKETY', style: TextStyle(
        color: AppTheme.textPrimary(dark), fontSize: 17,
        fontWeight: FontWeight.w800, letterSpacing: 4,
      )),

      const Spacer(),

      // Theme toggle
      GestureDetector(
        onTap: () => ThemeProvider().toggleTheme(),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.card(dark), borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppTheme.border(dark)),
          ),
          child: Icon(
            dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: dark ? const Color(0xFFFFC107) : const Color(0xFF555555),
            size: 16,
          ),
        ),
      ),
      const SizedBox(width: 10),

      // Avatar
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color:  AppTheme.crimson.withOpacity(0.14),
          shape:  BoxShape.circle,
          border: Border.all(color: AppTheme.crimson.withOpacity(0.3)),
        ),
        child: Center(child: Text(_initials(), style: const TextStyle(
          color: AppTheme.crimson, fontSize: 13, fontWeight: FontWeight.w900,
        ))),
      ),
    ]);
  }
}

// ── Greeting ──
class _Greeting extends StatelessWidget {
  final AuthUser user;
  final bool dark;
  const _Greeting({required this.user, required this.dark});

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_greet(), style: TextStyle(
        color: AppTheme.textMuted(dark), fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(user.username.isNotEmpty ? user.username : 'User',
        style: TextStyle(
          color: AppTheme.textPrimary(dark), fontSize: 30,
          fontWeight: FontWeight.w900, letterSpacing: -0.8),
        overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Row(children: [
        Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(
            color: Colors.green, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('Account active', style: TextStyle(
          color: AppTheme.textMuted(dark), fontSize: 12)),
      ]),
    ]);
  }
}

// ── Create CTA banner ──
class _CreateBanner extends StatefulWidget {
  final bool dark;
  final VoidCallback onTap;
  const _CreateBanner({required this.dark, required this.onTap});

  @override
  State<_CreateBanner> createState() => _CreateBannerState();
}

class _CreateBannerState extends State<_CreateBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _c.forward(),
      onTapUp:     (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: ()  => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.crimson, AppTheme.darkCrimson],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
              color:   AppTheme.crimson.withOpacity(0.30),
              blurRadius: 20, offset: const Offset(0, 8),
            )],
          ),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('NEW', style: TextStyle(
                    color: Colors.white, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 2,
                  )),
                ),
                const SizedBox(height: 10),
                const Text('Create a Ticket', style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                )),
                const SizedBox(height: 4),
                Text('Scan a QR code or enter a service link',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ],
            )),
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 24),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Stats row ──
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
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.card(dark),
            borderRadius: BorderRadius.circular(14)),
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
            color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            color: AppTheme.textMuted(dark), fontSize: 11,
            fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Section header ──
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool   dark;
  final String?    action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, required this.dark,
      this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: TextStyle(
        color: AppTheme.textPrimary(dark), fontSize: 16,
        fontWeight: FontWeight.w800)),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Text(action!, style: const TextStyle(
            color: AppTheme.crimson, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
    ]);
  }
}

// ── Recent ticket row ──
class _TicketRow extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool dark;
  const _TicketRow({required this.ticket, required this.dark});

  Color _pc(String p) => switch (p.toLowerCase()) {
    'urgent' => AppTheme.crimson, 'high' => Colors.orange,
    'medium' => Colors.blue,     _      => Colors.green,
  };

  Color _sc(String s) => switch (s.toLowerCase()) {
    'open'    => Colors.blue,  'pending' => Colors.orange,
    'closed'  => Colors.green, _         => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final title    = ticket['title']    ?? 'Untitled';
    final status   = ticket['status']   ?? 'open';
    final priority = ticket['priority'] ?? 'low';
    final service  = ticket['service']  ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 44,
          decoration: BoxDecoration(
            color: _pc(priority), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
              color: AppTheme.textPrimary(dark),
              fontSize: 14, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
            if (service.isNotEmpty)
              Text(service, style: TextStyle(
                color: AppTheme.textMuted(dark), fontSize: 12)),
          ],
        )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:        _sc(status).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(status[0].toUpperCase() + status.substring(1),
            style: TextStyle(color: _sc(status), fontSize: 10,
                fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

// ── Empty state ──
class _EmptyTickets extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;
  const _EmptyTickets({required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.card(dark), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Column(children: [
        Icon(Icons.confirmation_num_outlined,
            color: AppTheme.textMuted(dark).withOpacity(0.35), size: 38),
        const SizedBox(height: 12),
        Text('No tickets yet', style: TextStyle(
          color: AppTheme.textPrimary(dark),
          fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Tap the button below to create one',
          style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 12)),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.crimson,
              borderRadius: BorderRadius.circular(10)),
            child: const Text('Create ticket', style: TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ── Skeleton loader ──
class _SkeletonList extends StatelessWidget {
  final bool dark;
  const _SkeletonList({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(3, (_) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 66,
      decoration: BoxDecoration(
        color: AppTheme.card(dark), borderRadius: BorderRadius.circular(12)),
    )));
  }
}

// ── Error strip ──
class _ErrorStrip extends StatelessWidget {
  final String message;
  final bool dark;
  const _ErrorStrip({required this.message, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppTheme.crimson.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.crimson.withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: AppTheme.crimson, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(
          color: AppTheme.crimson, fontSize: 13))),
      ]),
    );
  }
}

// ── Quick actions grid ──
class _QuickGrid extends StatelessWidget {
  final bool dark;
  final VoidCallback onCreateTap;
  const _QuickGrid({required this.dark, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QA(icon: Icons.qr_code_scanner_rounded, label: 'Scan QR',
          color: AppTheme.crimson,  onTap: onCreateTap),
      _QA(icon: Icons.link_rounded, label: 'Enter Link',
          color: Colors.blue,       onTap: onCreateTap),
      _QA(icon: Icons.history_rounded, label: 'History',
          color: Colors.orange,     onTap: () {}),
      _QA(icon: Icons.notifications_rounded, label: 'Alerts',
          color: Colors.purple,     onTap: () {}),
      _QA(icon: Icons.bar_chart_rounded, label: 'Analytics',
          color: Colors.teal,       onTap: () {}),
      _QA(icon: Icons.support_agent_rounded, label: 'Support',
          color: Colors.green,      onTap: () {}),
    ];

    return GridView.count(
      crossAxisCount:   3,
      crossAxisSpacing: 10,
      mainAxisSpacing:  10,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((a) => _QATile(qa: a, dark: dark)).toList(),
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

class _QATile extends StatefulWidget {
  final _QA  qa;
  final bool dark;
  const _QATile({required this.qa, required this.dark});

  @override
  State<_QATile> createState() => _QATileState();
}

class _QATileState extends State<_QATile> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _c.forward(),
      onTapUp:     (_) { _c.reverse(); widget.qa.onTap(); },
      onTapCancel: ()  => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color:        AppTheme.card(widget.dark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(widget.dark)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:        widget.qa.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(widget.qa.icon, color: widget.qa.color, size: 17),
            ),
            const SizedBox(height: 8),
            Text(widget.qa.label, style: TextStyle(
              color: AppTheme.textPrimary(widget.dark),
              fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

// =============================================================
// ─────────────────────────────────────────────────────────────
//  SETTINGS PAGE  (Tab 2)
//  Replaces _SettingsPlaceholder entirely.
//  Features:
//    - Profile card with initials, email, verified badge
//    - Appearance: dark/light toggle (live)
//    - Notifications: push + email toggles
//    - Security: biometric stub + change password stub
//    - About: version, privacy, terms
//    - Logout with confirmation dialog
// ─────────────────────────────────────────────────────────────
// =============================================================
class _SettingsPage extends StatefulWidget {
  final AuthUser   user;
  final VoidCallback onLogout;
  const _SettingsPage({required this.user, required this.onLogout});

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  bool _notifPush    = true;
  bool _notifEmail   = true;
  bool _biometric    = false;

  bool get _dark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    ThemeProvider().addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    super.dispose();
  }

  String _initials() {
    if (widget.user.username.isEmpty) return '?';
    final p = widget.user.username.trim().split(' ');
    return (p.length >= 2 ? '${p[0][0]}${p[1][0]}' : widget.user.username[0])
        .toUpperCase();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card(_dark),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Log out?', style: TextStyle(
          color: AppTheme.textPrimary(_dark), fontWeight: FontWeight.w800)),
        content: Text(
          'You will need to sign in again to access your account.',
          style: TextStyle(color: AppTheme.textMuted(_dark))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted(_dark)))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(
              color: AppTheme.crimson, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) widget.onLogout();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior:        SnackBarBehavior.floating,
      backgroundColor: AppTheme.card(_dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),

        // Header
        Text('Settings', style: TextStyle(
          color: AppTheme.textPrimary(_dark), fontSize: 28,
          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 22),

        // ── Profile card ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.crimson, AppTheme.darkCrimson],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
              color: AppTheme.crimson.withOpacity(0.25),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color:  Colors.white.withOpacity(0.2),
                shape:  BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.4), width: 2)),
              child: Center(child: Text(_initials(), style: const TextStyle(
                color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.username.isNotEmpty
                      ? widget.user.username : 'User',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(widget.user.email, style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('Active', style: TextStyle(
                  color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 28),

        // ── APPEARANCE ──
        _SLabel(label: 'APPEARANCE', dark: _dark),
        const SizedBox(height: 10),
        _SCard(dark: _dark, children: [
          _SwitchRow(
            dark:      _dark,
            icon:      _dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: _dark ? const Color(0xFF7B61FF) : Colors.orange,
            title:     _dark ? 'Dark Mode' : 'Light Mode',
            sub:       _dark ? 'Currently using dark theme'
                              : 'Currently using light theme',
            value:     _dark,
            onChanged: (_) => ThemeProvider().toggleTheme(),
          ),
        ]),
        const SizedBox(height: 18),

        // ── NOTIFICATIONS ──
        _SLabel(label: 'NOTIFICATIONS', dark: _dark),
        const SizedBox(height: 10),
        _SCard(dark: _dark, children: [
          _SwitchRow(
            dark: _dark, icon: Icons.notifications_rounded,
            iconColor: Colors.orange,
            title: 'Push Notifications', sub: 'Ticket status updates',
            value: _notifPush,
            onChanged: (v) => setState(() => _notifPush = v),
          ),
          _SDivider(dark: _dark),
          _SwitchRow(
            dark: _dark, icon: Icons.mail_outline_rounded,
            iconColor: Colors.blue,
            title: 'Email Notifications', sub: 'Receive updates by email',
            value: _notifEmail,
            onChanged: (v) => setState(() => _notifEmail = v),
          ),
        ]),
        const SizedBox(height: 18),

        // ── SECURITY ──
        _SLabel(label: 'SECURITY', dark: _dark),
        const SizedBox(height: 10),
        _SCard(dark: _dark, children: [
          _SwitchRow(
            dark: _dark, icon: Icons.fingerprint_rounded,
            iconColor: Colors.green,
            title: 'Biometric Lock', sub: 'Fingerprint or Face ID',
            value: _biometric,
            onChanged: (v) => setState(() => _biometric = v),
          ),
          _SDivider(dark: _dark),
          _ActionRow(
            dark: _dark, icon: Icons.lock_outline_rounded,
            iconColor: Colors.teal,
            title: 'Change Password', sub: 'Update your account password',
            onTap: () => _snack('Change password — coming soon'),
          ),
        ]),
        const SizedBox(height: 18),

        // ── ABOUT ──
        _SLabel(label: 'ABOUT', dark: _dark),
        const SizedBox(height: 10),
        _SCard(dark: _dark, children: [
          _ActionRow(
            dark: _dark, icon: Icons.info_outline_rounded,
            iconColor: Colors.indigo,
            title: 'App Version', sub: 'TICKETY v1.0.0',
            trailing: Text('v1.0.0', style: TextStyle(
              color: AppTheme.textMuted(_dark), fontSize: 13)),
            onTap: () {},
          ),
          _SDivider(dark: _dark),
          _ActionRow(
            dark: _dark, icon: Icons.privacy_tip_outlined,
            iconColor: Colors.purple,
            title: 'Privacy Policy', sub: 'Read our privacy policy',
            onTap: () => _snack('Privacy Policy — coming soon'),
          ),
          _SDivider(dark: _dark),
          _ActionRow(
            dark: _dark, icon: Icons.article_outlined,
            iconColor: const Color(0xFF8D6748),
            title: 'Terms of Service', sub: 'Read terms and conditions',
            onTap: () => _snack('Terms of Service — coming soon'),
          ),
        ]),
        const SizedBox(height: 18),

        // ── ACCOUNT ──
        _SLabel(label: 'ACCOUNT', dark: _dark),
        const SizedBox(height: 10),
        _SCard(dark: _dark, children: [
          _ActionRow(
            dark: _dark, icon: Icons.logout_rounded,
            iconColor: AppTheme.crimson,
            title: 'Log Out', sub: 'Sign out of your account',
            titleColor: AppTheme.crimson,
            onTap: _confirmLogout,
          ),
        ]),
        const SizedBox(height: 32),

        Center(child: Text('TICKETY · v1.0.0',
          style: TextStyle(
            color: AppTheme.textMuted(_dark).withOpacity(0.35),
            fontSize: 11))),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ── Settings sub-widgets ──

class _SLabel extends StatelessWidget {
  final String label;
  final bool   dark;
  const _SLabel({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(
    color: AppTheme.textMuted(dark), fontSize: 11,
    fontWeight: FontWeight.w700, letterSpacing: 2));
}

class _SCard extends StatelessWidget {
  final bool   dark;
  final List<Widget> children;
  const _SCard({required this.dark, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        AppTheme.card(dark),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border(dark))),
    child: Column(children: children));
}

class _SDivider extends StatelessWidget {
  final bool dark;
  const _SDivider({required this.dark});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 64, color: AppTheme.border(dark));
}

class _SwitchRow extends StatelessWidget {
  final bool   dark;
  final IconData icon;
  final Color  iconColor;
  final String title, sub;
  final bool   value;
  final void Function(bool) onChanged;
  const _SwitchRow({required this.dark, required this.icon,
      required this.iconColor, required this.title, required this.sub,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        _IconBox(icon: icon, color: iconColor),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
              color: AppTheme.textPrimary(dark),
              fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(
              color: AppTheme.textMuted(dark), fontSize: 12)),
          ],
        )),
        Switch(
          value:            value,
          onChanged:        onChanged,
          activeColor:      AppTheme.crimson,
          activeTrackColor: AppTheme.crimson.withOpacity(0.3),
          inactiveThumbColor: AppTheme.textMuted(dark),
          inactiveTrackColor: AppTheme.border(dark),
        ),
      ]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool   dark;
  final IconData icon;
  final Color  iconColor;
  final String title, sub;
  final VoidCallback onTap;
  final Widget?  trailing;
  final Color?   titleColor;
  const _ActionRow({required this.dark, required this.icon,
      required this.iconColor, required this.title, required this.sub,
      required this.onTap, this.trailing, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                color: titleColor ?? AppTheme.textPrimary(dark),
                fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(
                color: AppTheme.textMuted(dark), fontSize: 12)),
            ],
          )),
          trailing ?? Icon(Icons.chevron_right_rounded,
              color: AppTheme.textMuted(dark), size: 20),
        ]),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color    color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
      color:        color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(9)),
    child: Icon(icon, color: color, size: 18));
}

// =============================================================
// SHARED REUSABLE WIDGETS  (kept from original for compatibility)
// =============================================================
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) { _ctrl.forward(from: 0); setState(() {}); }
  }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return GestureDetector(
      onTap: () => ThemeProvider().toggleTheme(),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color:        AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border(isDark)),
        ),
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.5).animate(_ctrl),
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

class StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 10,
        fontWeight: FontWeight.w800, letterSpacing: 1.5)));
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    return Text(label, style: TextStyle(
      color: AppTheme.textMuted(isDark), fontSize: 11,
      fontWeight: FontWeight.w700, letterSpacing: 2));
  }
}
