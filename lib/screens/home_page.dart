import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import '../screens/swap_picker_sheet.dart';
import 'ticket_scanner.dart';

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
// DASH TICKET MODEL  (live queue info per ticket)
// =============================================================
class DashTicket {
  final String  id;
  final String  ticketNumber;
  final String  serviceName;
  final String  serviceCategory;
  final String  status;          // active | suspended | cancelled
  final int     position;
  final int     peopleAhead;
  final int     estimatedMinutes;
  final String  currentlyServing;
  final int     guichetNumber;
  final int     totalInQueue;
  final bool    hasSwapRequest;
  final String? swapRequestFrom;

  const DashTicket({
    required this.id,
    required this.ticketNumber,
    required this.serviceName,
    required this.serviceCategory,
    required this.status,
    required this.position,
    required this.peopleAhead,
    required this.estimatedMinutes,
    required this.currentlyServing,
    required this.guichetNumber,
    required this.totalInQueue,
    this.hasSwapRequest  = false,
    this.swapRequestFrom,
  });

  DashTicket copyWith({bool? hasSwapRequest}) => DashTicket(
    id:               id,
    ticketNumber:     ticketNumber,
    serviceName:      serviceName,
    serviceCategory:  serviceCategory,
    status:           status,
    position:         position,
    peopleAhead:      peopleAhead,
    estimatedMinutes: estimatedMinutes,
    currentlyServing: currentlyServing,
    guichetNumber:    guichetNumber,
    totalInQueue:     totalInQueue,
    hasSwapRequest:   hasSwapRequest ?? this.hasSwapRequest,
    swapRequestFrom:  swapRequestFrom,
  );
}

// =============================================================
// HOME PAGE  —  Dashboard tab (Tab 0 inside MainShell)
// Changes from previous version:
//   - Settings gear icon REMOVED from top bar
//   - _SettingsDrawer widget REMOVED entirely
//   - Top bar now shows: brand | theme toggle | avatar only
//   - All settings content has moved to ProfilePage
// OOP Principle: Single Responsibility, Composition
// =============================================================
class HomePage extends StatefulWidget {
  final AuthUser user;
  final void Function(int)? onNavigate;  // provided by MainShell

  const HomePage({super.key, required this.user, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  final _api     = ApiService();
  final _session = SessionService();

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

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
    _api.clearToken();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

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
            child: _DashboardPage(
              user:       widget.user,
              onNavigate: widget.onNavigate,
              onLogout:   _logout,
            ),
          ),
        ]),
      ),
    );
  }
}

// =============================================================
// BACKGROUND GLOWS
// =============================================================
class _BgGlows extends StatelessWidget {
  const _BgGlows();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Align(alignment: Alignment.topRight,
        child: Container(width: 260, height: 260,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.crimson.withOpacity(0.10),
              Colors.transparent])))),
      Align(alignment: Alignment.bottomLeft,
        child: Container(width: 180, height: 180,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.darkCrimson.withOpacity(0.08),
              Colors.transparent])))),
    ]);
  }
}

// =============================================================
// DASHBOARD PAGE
// =============================================================
class _DashboardPage extends StatefulWidget {
  final AuthUser             user;
  final void Function(int)?  onNavigate;
  final VoidCallback         onLogout;

  const _DashboardPage({
    required this.user,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  final _api = ApiService();

  bool    _loading      = true;
  String? _error;
  int     _total        = 0;
  int     _active       = 0;
  int     _suspended    = 0;
  int     _cancelled    = 0;

  List<DashTicket> _tickets = [];
  int              _cardIndex = 0;
  late PageController _pageCtrl;

  bool get _dark => ThemeProvider().isDarkMode;

  final List<DashTicket> _placeholder = const [
    DashTicket(
      id: '1', ticketNumber: 'A047',
      serviceName: 'Main Counter', serviceCategory: 'Banking',
      status: 'active', position: 3, peopleAhead: 2,
      estimatedMinutes: 12, currentlyServing: 'A045',
      guichetNumber: 2, totalInQueue: 18,
    ),
    DashTicket(
      id: '2', ticketNumber: 'B012',
      serviceName: 'Customer Support', serviceCategory: 'Telecom',
      status: 'active', position: 1, peopleAhead: 0,
      estimatedMinutes: 3, currentlyServing: 'B011',
      guichetNumber: 1, totalInQueue: 5,
      hasSwapRequest: true, swapRequestFrom: 'B015',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.92);
    ThemeProvider().addListener(_rebuild);
    _load();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getTickets(userId: widget.user.userId, email: widget.user.email);
      if (!mounted) return;
      final raw = (data['tickets'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _total     = raw.length;
        _active    = raw.where((t) => t['status'] == 'active').length;
        _suspended = raw.where((t) => t['status'] == 'suspended').length;
        _cancelled = raw.where((t) => t['status'] == 'cancelled').length;
        _loading   = false;
        _tickets   = raw.map((t) => DashTicket(
          id:               t['ticket_id']?.toString()         ?? '',
          ticketNumber:     t['code']?.toString()              ?? '—',
          serviceName:      t['service_category']?.toString()  ?? '—',
          serviceCategory:  t['service_category']?.toString()  ?? 'General',
          status:           t['status']?.toString()            ?? 'pending',
          position:         (t['position']          as num?)?.toInt() ?? 0,
          peopleAhead:      (t['people_ahead']      as num?)?.toInt() ?? 0,
          estimatedMinutes: (t['estimated_minutes'] as num?)?.toInt() ?? 0,
          currentlyServing: t['currently_serving']?.toString() ?? '—',
          guichetNumber:    (t['guichet_number']    as num?)?.toInt() ?? 0,
          totalInQueue:     (t['total_in_queue']    as num?)?.toInt() ?? 0,
        )).toList();
      });
    } catch (_) {
      if (mounted) setState(() {
        _loading  = false;
        _error    = 'Could not load tickets.';
        _tickets  = [];
        _total    = 0;
        _active   = 0;
      });
    }
  }

  // ── Ticket actions ───────────────────────────────────────────

  void _onLeaveQueue(DashTicket ticket) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        dark:    _dark,
        title:   'Leave Queue',
        message: 'Leave the queue at ${ticket.serviceName}? '
                 'This cannot be undone.',
        confirmLabel: 'Leave',
        onConfirm: () {
          setState(() =>
              _tickets.removeWhere((t) => t.id == ticket.id));
          _showSnack(
              'Left queue at ${ticket.serviceName}',
              AppTheme.crimson);
        },
      ),
    );
  }

  void _onRequestSwap(DashTicket ticket) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => SwapPickerSheet(
        sourceTicketId:   ticket.id,
        sourceTicketCode: ticket.ticketNumber,
        serviceName:      ticket.serviceName,
        onSwapSent: () {
          // Refresh the dashboard so the sent-request badge appears
          _load();
        },
      ),
    );
  }

  void _onAcceptSwap(DashTicket ticket) {
    setState(() {
      final i = _tickets.indexWhere((t) => t.id == ticket.id);
      if (i != -1) {
        _tickets[i] = DashTicket(
          id:               ticket.id,
          ticketNumber:     ticket.ticketNumber,
          serviceName:      ticket.serviceName,
          serviceCategory:  ticket.serviceCategory,
          status:           ticket.status,
          position:         ticket.position,
          peopleAhead:      ticket.peopleAhead,
          estimatedMinutes: ticket.estimatedMinutes,
          currentlyServing: ticket.currentlyServing,
          guichetNumber:    ticket.guichetNumber,
          totalInQueue:     ticket.totalInQueue,
          hasSwapRequest:   false,
        );
      }
    });
    _showSnack('Swap accepted!', Colors.green);
  }

  void _onRejectSwap(DashTicket ticket) {
    setState(() {
      final i = _tickets.indexWhere((t) => t.id == ticket.id);
      if (i != -1) {
        _tickets[i] = DashTicket(
          id:               ticket.id,
          ticketNumber:     ticket.ticketNumber,
          serviceName:      ticket.serviceName,
          serviceCategory:  ticket.serviceCategory,
          status:           ticket.status,
          position:         ticket.position,
          peopleAhead:      ticket.peopleAhead,
          estimatedMinutes: ticket.estimatedMinutes,
          currentlyServing: ticket.currentlyServing,
          guichetNumber:    ticket.guichetNumber,
          totalInQueue:     ticket.totalInQueue,
          hasSwapRequest:   false,
        );
      }
    });
    _showSnack('Swap rejected.', AppTheme.crimson);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Scanner helpers ──────────────────────────────────────────

  void _openScanner() {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => QrScannerSheet(
        isDark:   _dark,
        onResult: (code) {
          Navigator.pop(context);
          _onCodeReceived(code);
        },
      ),
    );
  }

  void _openLinkInput() {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => LinkInputSheet(
        isDark:   _dark,
        onResult: (code) {
          Navigator.pop(context);
          _onCodeReceived(code);
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // _onCodeReceived  — central entry point for both QR and URL
  // ----------------------------------------------------------
  Future<void> _onCodeReceived(String raw) async {
    final token = _extractJoinToken(raw);
    if (token == null) {
      _showSnack(
        'Invalid link. Only official Tickety QR codes and links are accepted.',
        AppTheme.crimson,
      );
      return;
    }

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context:   context,
      barrierDismissible: false,
      builder:   (_) => const Center(child: CircularProgressIndicator(
          color: AppTheme.crimson)),
    );

    // Preview the queue — this also validates the token on the server
    final preview = await _api.previewQueue(joinToken: token);
    if (!mounted) return;
    Navigator.pop(context); // dismiss loader

    if (preview['success'] != true) {
      _showSnack(
        preview['message'] as String? ??
            'Invalid QR code or link. Only official Tickety links are accepted.',
        AppTheme.crimson,
      );
      return;
    }

    // Show confirmation sheet — user must tap "Get Ticket" to confirm
    final confirmed = await showModalBottomSheet<bool>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _JoinConfirmSheet(
        dark:     _dark,
        queue:    preview['queue']   as Map<String, dynamic>,
        service:  preview['service'] as Map<String, dynamic>? ?? {},
      ),
    );

    if (confirmed != true || !mounted) return;

    // Issue the ticket
    showDialog(
      context:   context,
      barrierDismissible: false,
      builder:   (_) => const Center(child: CircularProgressIndicator(
          color: AppTheme.crimson)),
    );

    final result = await _api.joinQueue(
      joinToken:          token,
      customerIdentifier: widget.user.email,
    );
    if (!mounted) return;
    Navigator.pop(context); // dismiss loader

    if (result['success'] == true) {
      final carried = result['carried_over'] == true;
      _showSnack(
        carried
            ? 'Queue is full for today — your ticket is carried over to tomorrow!'
            : 'Ticket issued! You are in the queue.',
        carried ? const Color(0xFFFFA500) : Colors.green,
      );
      _load(); // refresh the dashboard
    } else {
      _showSnack(
        result['message'] as String? ?? 'Could not issue ticket.',
        AppTheme.crimson,
      );
    }
  }

  // ----------------------------------------------------------
  // _extractJoinToken
  // ----------------------------------------------------------
  String? _extractJoinToken(String raw) {
    final trimmed = raw.trim();

    // Case 1 — URL containing "/join/"
    if (trimmed.contains('/join/')) {
      try {
        final uri   = Uri.parse(trimmed);
        final segs  = uri.pathSegments;
        final idx   = segs.indexOf('join');
        if (idx != -1 && idx + 1 < segs.length) {
          final token = segs[idx + 1];
          if (_isUuid(token)) return token;
        }
      } catch (_) {}
      return null; // malformed URL with /join/ but no valid UUID
    }

    // Case 2 — bare UUID (e.g. copied directly from admin panel)
    if (_isUuid(trimmed)) return trimmed;

    // Case 3 — everything else is rejected
    return null;
  }

  static final _uuidRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  bool _isUuid(String s) => _uuidRe.hasMatch(s);

  // ── Helpers ──────────────────────────────────────────────────

  String _initials() {
    if (widget.user.username.isEmpty) return '?';
    final p = widget.user.username.trim().split(' ');
    return (p.length >= 2
            ? '${p[0][0]}${p[1][0]}'
            : widget.user.username[0])
        .toUpperCase();
  }

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color:     AppTheme.crimson,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),

            // ── Top bar (settings gear removed) ──────────
            _TopBar(
              user:     widget.user,
              dark:     _dark,
              initials: _initials(),
              onNavigate: widget.onNavigate,
            ),
            const SizedBox(height: 26),

            // ── Greeting ─────────────────────────────────
            _Greeting(
                user: widget.user, dark: _dark, greet: _greet()),
            const SizedBox(height: 26),

            // ── Create ticket banner ──────────────────────
            _CreateBanner(
              dark:        _dark,
              onScanQr:    _openScanner,
              onEnterLink: _openLinkInput,
            ),
            const SizedBox(height: 26),

            // ── Stats ─────────────────────────────────────
            if (_error != null)
              _ErrorStrip(message: _error!, dark: _dark)
            else
              _StatsRow(
                dark:      _dark,
                loading:   _loading,
                total:     _total,
                active:    _active,
                suspended: _suspended,
                cancelled: _cancelled,
              ),
            const SizedBox(height: 26),

            // ── Recent tickets ────────────────────────────
            _SectionHeader(title: 'Recent Tickets', dark: _dark),
            const SizedBox(height: 12),
            _loading
                ? _SkeletonCard(dark: _dark)
                : _buildTicketSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketSection() {
    if (_tickets.isEmpty) {
      return Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color:        AppTheme.card(_dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(_dark))),
        child: Column(children: [
          Icon(Icons.confirmation_num_outlined,
              color: AppTheme.textMuted(_dark).withOpacity(0.35),
              size: 38),
          const SizedBox(height: 12),
          Text('No tickets yet', style: TextStyle(
            color:      AppTheme.textPrimary(_dark),
            fontSize:   15,
            fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Use the banner above to get your first ticket',
            style: TextStyle(
                color: AppTheme.textMuted(_dark), fontSize: 12)),
        ]),
      );
    }

    return Column(children: [
      if (_tickets.length > 1) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_tickets.length, (i) {
            final active = i == _cardIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width:  active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.crimson
                    : AppTheme.border(_dark),
                borderRadius: BorderRadius.circular(3)));
          }),
        ),
        const SizedBox(height: 10),
      ],

      LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight.isInfinite ? 400.0
              : constraints.maxHeight.clamp(320.0, 600.0);
          return SizedBox(
            height: h,
            child: PageView.builder(
              controller:    _pageCtrl,
              itemCount:     _tickets.length,
              onPageChanged: (i) => setState(() => _cardIndex = i),
              itemBuilder:   (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DashTicketCard(
                  ticket:         _tickets[i],
                  dark:           _dark,
                  onLeave:        () => _onLeaveQueue(_tickets[i]),
                  onRequestSwap:  () => _onRequestSwap(_tickets[i]),
                  onAcceptSwap:   () => _onAcceptSwap(_tickets[i]),
                  onRejectSwap:   () => _onRejectSwap(_tickets[i]),
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }
}

// =============================================================
// TOP BAR  — Settings gear removed; just brand + theme + avatar
// OOP Principle: Single Responsibility
// =============================================================
class _TopBar extends StatelessWidget {
  final AuthUser user;
  final bool     dark;
  final String   initials;
  final void Function(int)? onNavigate;

  const _TopBar({
    required this.user,
    required this.dark,
    required this.initials,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Brand
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color:        AppTheme.crimson,
          borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.confirmation_num_rounded,
            color: Colors.white, size: 16)),
      const SizedBox(width: 9),
      Text('TICKETY', style: TextStyle(
        color:      AppTheme.textPrimary(dark),
        fontSize:   17,
        fontWeight: FontWeight.w800,
        letterSpacing: 4)),
      const Spacer(),

      // Theme toggle
      GestureDetector(
        onTap: () => ThemeProvider().toggleTheme(),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        AppTheme.card(dark),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppTheme.border(dark))),
          child: Icon(
            dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: dark
                ? const Color(0xFFFFC107)
                : const Color(0xFF555555),
            size: 16))),
      const SizedBox(width: 10),

      // Avatar — tapping navigates to Profile tab (index 3)
      GestureDetector(
        onTap: () => onNavigate?.call(3),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:  AppTheme.crimson.withOpacity(0.14),
            shape:  BoxShape.circle,
            border: Border.all(
                color: AppTheme.crimson.withOpacity(0.3))),
          child: Center(child: Text(initials, style: const TextStyle(
            color:      AppTheme.crimson,
            fontSize:   13,
            fontWeight: FontWeight.w900))))),
    ]);
  }
}

// =============================================================
// GREETING
// =============================================================
class _Greeting extends StatelessWidget {
  final AuthUser user;
  final bool     dark;
  final String   greet;
  const _Greeting({
      required this.user, required this.dark, required this.greet});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greet, style: TextStyle(
          color:      AppTheme.textMuted(dark),
          fontSize:   14,
          fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(user.username.isNotEmpty ? user.username : 'User',
          style: TextStyle(
            color:      AppTheme.textPrimary(dark),
            fontSize:   30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8),
          overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          Container(width: 7, height: 7,
            decoration: const BoxDecoration(
              color: Colors.green, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('Account active', style: TextStyle(
            color: AppTheme.textMuted(dark), fontSize: 12)),
        ]),
      ]);
  }
}

// =============================================================
// CREATE BANNER
// =============================================================
class _CreateBanner extends StatefulWidget {
  final bool         dark;
  final VoidCallback onScanQr;
  final VoidCallback onEnterLink;
  const _CreateBanner({
      required this.dark,
      required this.onScanQr,
      required this.onEnterLink});

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
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _s,
      builder: (_, child) =>
          Transform.scale(scale: _s.value, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.crimson, AppTheme.darkCrimson],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color:      AppTheme.crimson.withOpacity(0.30),
            blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6)),
                child: const Text('GET A TICKET', style: TextStyle(
                  color:      Colors.white,
                  fontSize:   10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2))),
            ]),
            const SizedBox(height: 10),
            const Text('Join a Queue', style: TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Scan a QR code or enter a service link',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: GestureDetector(
                onTapDown:   (_) => _c.forward(),
                onTapUp:     (_) { _c.reverse(); widget.onScanQr(); },
                onTapCancel: ()  => _c.reverse(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.qr_code_scanner_rounded,
                          color: AppTheme.crimson, size: 18),
                      SizedBox(width: 8),
                      Text('Scan QR', style: TextStyle(
                        color:      AppTheme.crimson,
                        fontSize:   13,
                        fontWeight: FontWeight.w800)),
                    ])))),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: widget.onEnterLink,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.link_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Enter Link', style: TextStyle(
                        color:      Colors.white,
                        fontSize:   13,
                        fontWeight: FontWeight.w800)),
                    ])))),
            ]),
          ]),
      ),
    );
  }
}

// =============================================================
// STATS ROW
// =============================================================
class _StatsRow extends StatelessWidget {
  final bool dark, loading;
  final int  total, active, suspended, cancelled;
  const _StatsRow({
    required this.dark,    required this.loading,
    required this.total,   required this.active,
    required this.suspended, required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Row(children: List.generate(4, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
          height: 80,
          decoration: BoxDecoration(
            color:        AppTheme.card(dark),
            borderRadius: BorderRadius.circular(14))))));
    }
    return Row(children: [
      _StatCard(label: 'Total',     value: total,
          color: AppTheme.textMuted(dark), dark: dark),
      const SizedBox(width: 10),
      _StatCard(label: 'Active',    value: active,
          color: Colors.green,           dark: dark),
      const SizedBox(width: 10),
      _StatCard(label: 'Suspended', value: suspended,
          color: const Color(0xFFFFA500), dark: dark),
      const SizedBox(width: 10),
      _StatCard(label: 'Cancelled', value: cancelled,
          color: AppTheme.crimson,        dark: dark),
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
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(dark))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value.toString(), style: TextStyle(
            color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            color:      AppTheme.textMuted(dark),
            fontSize:   11,
            fontWeight: FontWeight.w600)),
        ])));
  }
}

// =============================================================
// DASHBOARD TICKET CARD
// =============================================================
class _DashTicketCard extends StatelessWidget {
  final DashTicket   ticket;
  final bool         dark;
  final VoidCallback onLeave;
  final VoidCallback onRequestSwap;
  final VoidCallback onAcceptSwap;
  final VoidCallback onRejectSwap;

  const _DashTicketCard({
    required this.ticket,
    required this.dark,
    required this.onLeave,
    required this.onRequestSwap,
    required this.onAcceptSwap,
    required this.onRejectSwap,
  });

  Color  _sc() => ticket.status == 'suspended'
      ? const Color(0xFFFFA500)
      : ticket.status == 'cancelled'
          ? AppTheme.crimson : Colors.green;

  String _sl() => ticket.status == 'suspended'
      ? 'SUSPENDED'
      : ticket.status == 'cancelled' ? 'CANCELLED' : 'ACTIVE';

  @override
  Widget build(BuildContext context) {
    final sc = _sc();

    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ticket.hasSwapRequest
              ? const Color(0xFFFFA500).withOpacity(0.5)
              : AppTheme.border(dark),
          width: ticket.hasSwapRequest ? 1.5 : 1)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.serviceCategory.toUpperCase(),
                    style: TextStyle(
                      color:      AppTheme.textMuted(dark),
                      fontSize:   9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(ticket.serviceName, style: TextStyle(
                    color:      AppTheme.textPrimary(dark),
                    fontSize:   14,
                    fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
                ])),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sc.withOpacity(0.3))),
                child: Text(_sl(), style: TextStyle(
                  color: sc, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 1))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:        sc.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sc.withOpacity(0.2))),
                child: Text(ticket.ticketNumber, style: TextStyle(
                  color:      sc,
                  fontSize:   22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2))),
              const SizedBox(width: 14),
              Expanded(child: Column(children: [
                _row(dark, Icons.people_outline_rounded,
                    'Ahead',    '${ticket.peopleAhead}'),
                const SizedBox(height: 5),
                _row(dark, Icons.group_outlined,
                    'In Queue', '${ticket.totalInQueue}'),
                const SizedBox(height: 5),
                _row(dark, Icons.record_voice_over_rounded,
                    'Serving',  ticket.currentlyServing),
                const SizedBox(height: 5),
                _row(dark, Icons.door_front_door_outlined,
                    'Guichet',  '${ticket.guichetNumber}'),
                const SizedBox(height: 5),
                _row(dark, Icons.timer_outlined,
                    'Est. wait', '~${ticket.estimatedMinutes} min',
                    highlight: true),
              ])),
            ]),
            const SizedBox(height: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Queue progress', style: TextStyle(
                      color:    AppTheme.textMuted(dark),
                      fontSize: 11)),
                    Text(
                      '${ticket.totalInQueue - ticket.peopleAhead} / ${ticket.totalInQueue} served',
                      style: TextStyle(
                        color:    AppTheme.textMuted(dark),
                        fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ticket.totalInQueue > 0
                        ? (ticket.totalInQueue - ticket.peopleAhead) /
                          ticket.totalInQueue
                        : 0,
                    minHeight:       6,
                    backgroundColor: AppTheme.border(dark),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.crimson))),
              ]),
            const SizedBox(height: 12),
            if (ticket.hasSwapRequest) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        const Color(0xFFFFA500).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFFA500).withOpacity(0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.swap_horiz_rounded,
                          color: Color(0xFFFFA500), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Swap request from ${ticket.swapRequestFrom}',
                        style: const TextStyle(
                          color:      Color(0xFFFFA500),
                          fontSize:   12,
                          fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _actionBtn(
                        label: 'Accept',
                        color: Colors.green,
                        onTap: onAcceptSwap)),
                      const SizedBox(width: 8),
                      Expanded(child: _actionBtn(
                        label: 'Reject',
                        color: AppTheme.crimson,
                        onTap: onRejectSwap)),
                    ]),
                  ])),
            ] else ...[
              Row(children: [
                Expanded(child: _actionBtn(
                  label: 'Request Swap',
                  color: const Color(0xFF2196F3),
                  onTap: onRequestSwap)),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn(
                  label: 'Leave Queue',
                  color: AppTheme.crimson,
                  onTap: onLeave)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(bool dark, IconData icon, String label, String value,
      {bool highlight = false}) {
    return Row(children: [
      Icon(icon,
          color: highlight
              ? AppTheme.crimson : AppTheme.textMuted(dark),
          size: 12),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
          color: AppTheme.textMuted(dark), fontSize: 11)),
      const Spacer(),
      Text(value, style: TextStyle(
        color: highlight
            ? AppTheme.crimson : AppTheme.textPrimary(dark),
        fontSize: 11, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _actionBtn({
    required String       label,
    required Color        color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.3))),
        child: Center(child: Text(label, style: TextStyle(
          color:      color,
          fontSize:   12,
          fontWeight: FontWeight.w700)))));
  }
}

// =============================================================
// SECTION HEADER
// =============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool   dark;
  const _SectionHeader({required this.title, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(
      color:      AppTheme.textPrimary(dark),
      fontSize:   16,
      fontWeight: FontWeight.w800));
  }
}

// =============================================================
// SKELETON CARD
// =============================================================
class _SkeletonCard extends StatelessWidget {
  final bool dark;
  const _SkeletonCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(20)));
  }
}

// =============================================================
// ERROR STRIP
// =============================================================
class _ErrorStrip extends StatelessWidget {
  final String message;
  final bool   dark;
  const _ErrorStrip({required this.message, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppTheme.crimson.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.crimson.withOpacity(0.25))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: AppTheme.crimson, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(
          color: AppTheme.crimson, fontSize: 13))),
      ]));
  }
}

// =============================================================
// CONFIRM DIALOG
// =============================================================
class _ConfirmDialog extends StatelessWidget {
  final bool         dark;
  final String       title;
  final String       message;
  final String       confirmLabel;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.dark,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card(dark),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:  AppTheme.crimson.withOpacity(0.1),
              shape:  BoxShape.circle,
              border: Border.all(
                  color: AppTheme.crimson.withOpacity(0.3))),
            child: const Icon(Icons.exit_to_app_rounded,
                color: AppTheme.crimson, size: 28)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(
            color:      AppTheme.textPrimary(dark),
            fontSize:   17,
            fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textMuted(dark),
                fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color:        AppTheme.surface(dark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.border(dark))),
                child: Center(child: Text('Cancel',
                  style: TextStyle(
                    color:      AppTheme.textPrimary(dark),
                    fontWeight: FontWeight.w700)))))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () { Navigator.pop(context); onConfirm(); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color:        AppTheme.crimson,
                  borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(confirmLabel,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700)))))),
          ]),
        ]),
      ),
    );
  }
}

// =============================================================
// JOIN CONFIRM SHEET
// Shown after a successful token preview. The user can see the
// service + queue details and then tap "Get Ticket" to confirm,
// or dismiss the sheet to cancel. Returns true on confirm.
// =============================================================
class _JoinConfirmSheet extends StatelessWidget {
  final bool                    dark;
  final Map<String, dynamic>    queue;
  final Map<String, dynamic>    service;

  const _JoinConfirmSheet({
    required this.dark,
    required this.queue,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final queueName   = queue['name']    as String? ?? 'Queue';
    final serviceNm   = service['service_name'] as String? ?? '';
    final active      = queue['active']  as int? ?? 0;
    final pending     = queue['pending'] as int? ?? 0;
    final total       = active + pending;
    final queueCode   = queue['code']    as String? ?? '';
    final color       = queue['color']   as String? ?? '#DC0F0F';

    // Parse hex colour to Flutter Color (fallback: crimson)
    Color qColor = AppTheme.crimson;
    try {
      qColor = Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(width: 40, height: 4,
              decoration: BoxDecoration(
                color:        AppTheme.border(dark),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            // Icon + header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        qColor.withOpacity(0.1),
                shape:        BoxShape.circle,
                border: Border.all(color: qColor.withOpacity(0.3))),
              child: Icon(Icons.confirmation_num_rounded,
                  color: qColor, size: 32)),
            const SizedBox(height: 14),
            Text('Join Queue', style: TextStyle(
              color:      AppTheme.textPrimary(dark),
              fontSize:   20,
              fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Confirm your spot in the queue below',
              style: TextStyle(
                  color: AppTheme.textMuted(dark), fontSize: 13),
              textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:        AppTheme.surface(dark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border(dark))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (serviceNm.isNotEmpty) ...[ 
                    Text(serviceNm.toUpperCase(), style: TextStyle(
                      color:      AppTheme.textMuted(dark),
                      fontSize:   9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                  ],
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:        qColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: qColor.withOpacity(0.25))),
                      child: Text(queueCode, style: TextStyle(
                        color:      qColor,
                        fontSize:   13,
                        fontWeight: FontWeight.w900))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(queueName, style: TextStyle(
                      color:      AppTheme.textPrimary(dark),
                      fontSize:   16,
                      fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoCell(Icons.people_outline_rounded,
                          '$total', 'In Queue', dark),
                      _infoCell(Icons.play_arrow_rounded,
                          '$active', 'Active', dark),
                      _infoCell(Icons.hourglass_top_rounded,
                          '$pending', 'Waiting', dark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Action buttons
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color:        AppTheme.surface(dark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border(dark))),
                  child: Center(child: Text('Cancel', style: TextStyle(
                    color:      AppTheme.textPrimary(dark),
                    fontWeight: FontWeight.w700)))))),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color:        AppTheme.crimson,
                    borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('Get Ticket',
                    style: TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize:   15)))))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _infoCell(IconData icon, String value, String label, bool dark) {
    return Column(children: [
      Icon(icon, color: AppTheme.textMuted(dark), size: 16),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
        color:      AppTheme.textPrimary(dark),
        fontSize:   16,
        fontWeight: FontWeight.w900)),
      Text(label, style: TextStyle(
          color: AppTheme.textMuted(dark), fontSize: 10)),
    ]);
  }
}