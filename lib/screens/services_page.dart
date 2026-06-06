import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'home_page.dart';

// =============================================================
// SCHEDULE INFO  (fetched from /schedule/status per service)
// =============================================================
class ScheduleInfo {
  final bool   isOpen;
  final String openingTime;   // "HH:MM:SS"
  final String closingTime;   // "HH:MM:SS"
  final int    avgDuration;   // minutes per ticket

  const ScheduleInfo({
    required this.isOpen,
    required this.openingTime,
    required this.closingTime,
    required this.avgDuration,
  });

  factory ScheduleInfo.fromMap(Map<String, dynamic> m) => ScheduleInfo(
    isOpen:      m['is_open']      as bool?   ?? false,
    openingTime: m['opening_time'] as String? ?? '',
    closingTime: m['closing_time'] as String? ?? '',
    avgDuration: (m['avg_duration'] as num?)?.toInt() ?? 0,
  );

  /// Format "HH:MM:SS" or "HH:MM" → "H:MM AM/PM"
  static String fmt(String t) {
    if (t.isEmpty) return '—';
    try {
      final p    = t.split(':');
      int h      = int.parse(p[0]);
      final m    = p.length > 1 ? p[1].padLeft(2, '0') : '00';
      final ampm = h >= 12 ? 'PM' : 'AM';
      h = h % 12;
      if (h == 0) h = 12;
      return '$h:$m $ampm';
    } catch (_) {
      return t;
    }
  }
}

// =============================================================
// SERVICE MODEL  (built from ticket data)
// =============================================================
class ServiceEntry {
  final String  id;
  final String  name;
  final int     totalTickets;
  final int     activeTickets;
  final String? lastTicketNumber;
  final String? lastTicketStatus;
  final DateTime? lastVisited;
  final ScheduleInfo? scheduleInfo;   // null until fetched

  const ServiceEntry({
    required this.id,
    required this.name,
    required this.totalTickets,
    required this.activeTickets,
    this.lastTicketNumber,
    this.lastTicketStatus,
    this.lastVisited,
    this.scheduleInfo,
  });

  ServiceEntry copyWithSchedule(ScheduleInfo info) => ServiceEntry(
    id:               id,
    name:             name,
    totalTickets:     totalTickets,
    activeTickets:    activeTickets,
    lastTicketNumber: lastTicketNumber,
    lastTicketStatus: lastTicketStatus,
    lastVisited:      lastVisited,
    scheduleInfo:     info,
  );

  /// Build a list of ServiceEntry from raw ticket list.
  /// Only services that have at least one ticket appear.
  static List<ServiceEntry> fromTickets(List<Map<String, dynamic>> tickets) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final t in tickets) {
      // service_category = bank/org name, service_name = queue name
      final key = (t['service_category'] ?? t['service_name'] ?? 'Unknown').toString();
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return grouped.entries.map((e) {
      final list = e.value;

      // Match home page logic: anything not suspended/cancelled/served = active
      final active = list.where((t) {
        final s = t['status']?.toString() ?? '';
        return s != 'suspended' && s != 'cancelled' && s != 'served';
      }).length;

      // Ticket model uses 'issued_at', not 'created_at'
      list.sort((a, b) {
        final da = DateTime.tryParse(a['issued_at']?.toString() ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['issued_at']?.toString() ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });

      final last = list.first;

      return ServiceEntry(
        id:               last['service_id']?.toString() ?? e.key,
        name:             e.key, // service_category (bank/org name)
        totalTickets:     list.length,
        activeTickets:    active,
        lastTicketNumber: last['code']?.toString(),
        lastTicketStatus: last['status']?.toString(),
        lastVisited:      DateTime.tryParse(last['issued_at']?.toString() ?? ''),
      );
    }).toList()
      ..sort((a, b) => (b.lastVisited ?? DateTime(0))
          .compareTo(a.lastVisited ?? DateTime(0)));
  }
}

// =============================================================
// SERVICES PAGE  — dynamic, loaded from real ticket data
// =============================================================
class ServicesPage extends StatefulWidget {
  final AuthUser user;
  const ServicesPage({super.key, required this.user});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage>
    with SingleTickerProviderStateMixin {

  final _api = ApiService();
  final _searchController = TextEditingController();

  bool get isDark => ThemeProvider().isDarkMode;
  late TabController _tabController;

  List<ServiceEntry> _services = [];
  bool  _loading = true;
  String? _error;
  String _filter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() =>
            _filter = ['all', 'active'][_tabController.index]);
      }
    });
    ThemeProvider().addListener(_onThemeChanged);
    _load();
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getTickets(userId: widget.user.userId, email: widget.user.email);
      if (!mounted) return;

      final raw = (data['tickets'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      final services = ServiceEntry.fromTickets(raw);

      setState(() {
        _services = services;
        _loading  = false;
      });

      // Fetch schedule for each service in parallel (non-blocking)
      _loadSchedules(services);
    } catch (e) {
      if (mounted) setState(() {
        _error   = 'Could not load services.';
        _loading = false;
      });
    }
  }

  Future<void> _loadSchedules(List<ServiceEntry> services) async {
    await Future.wait(services.map((s) async {
      try {
        final res = await _api.getScheduleStatus(serviceId: s.id);
        if (!mounted) return;
        if (res['success'] == true) {
          final info = ScheduleInfo.fromMap(res);
          setState(() {
            final idx = _services.indexWhere((e) => e.id == s.id);
            if (idx != -1) _services[idx] = _services[idx].copyWithSchedule(info);
          });
        }
      } catch (_) {}
    }));
  }

  List<ServiceEntry> get _filtered {
    var list = _services;
    if (_filter == 'active') {
      list = list.where((s) => s.activeTickets > 0).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) => s.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours   < 1)  return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1)  return '${diff.inHours}h ago';
    if (diff.inDays    == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'active':    return Colors.green;
      case 'suspended': return const Color(0xFFFFA500);
      default:          return AppTheme.crimson;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: Stack(children: [
        Positioned(top: -80, left: -60,
          child: Container(width: 240, height: 240,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.crimson.withOpacity(0.10),
                Colors.transparent])))),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Services', style: TextStyle(
                        color:      AppTheme.textPrimary(isDark),
                        fontSize:   24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                      Text(
                        _loading
                          ? 'Loading…'
                          : '${_services.length} service${_services.length != 1 ? "s" : ""} visited',
                        style: TextStyle(
                            color: AppTheme.textMuted(isDark),
                            fontSize: 12)),
                    ],
                  )),
                  // Active badge
                  if (!_loading && _services.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:        Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3))),
                      child: Row(children: [
                        Container(width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(
                          '${_services.where((s) => s.activeTickets > 0).length} active',
                          style: const TextStyle(
                            color:      Colors.green,
                            fontSize:   11,
                            fontWeight: FontWeight.w700)),
                      ])),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Filter tabs ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color:        AppTheme.card(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border(isDark))),
                  child: TabBar(
                    controller:       _tabController,
                    indicator:        BoxDecoration(
                      color:        AppTheme.crimson,
                      borderRadius: BorderRadius.circular(10)),
                    indicatorSize:    TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(3),
                    dividerColor:     Colors.transparent,
                    labelColor:       Colors.white,
                    unselectedLabelColor: AppTheme.textMuted(isDark),
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Active'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Search bar ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color:        AppTheme.card(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border(isDark))),
                  child: TextField(
                    controller:   _searchController,
                    onChanged:    (v) => setState(() => _searchQuery = v.trim()),
                    style: TextStyle(
                        color: AppTheme.textPrimary(isDark), fontSize: 14),
                    decoration: InputDecoration(
                      hintText:       'Search services…',
                      hintStyle: TextStyle(
                          color: AppTheme.textMuted(isDark), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppTheme.textMuted(isDark), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(Icons.close_rounded,
                                  color: AppTheme.textMuted(isDark), size: 18))
                          : null,
                      border:         InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 13, horizontal: 4)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Body ──────────────────────────────────────
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(
          color: AppTheme.crimson));
    }

    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              color: AppTheme.textMuted(isDark), size: 40),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(
              color: AppTheme.textMuted(isDark), fontSize: 14)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color:        AppTheme.crimson,
                borderRadius: BorderRadius.circular(10)),
              child: const Text('Retry', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)))),
        ],
      ));
    }

    if (_services.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store_outlined,
              color: AppTheme.textMuted(isDark).withOpacity(0.4),
              size: 48),
          const SizedBox(height: 14),
          Text('No services yet', style: TextStyle(
            color:      AppTheme.textPrimary(isDark),
            fontSize:   16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Join a queue to see services here',
            style: TextStyle(
                color: AppTheme.textMuted(isDark), fontSize: 13)),
        ],
      ));
    }

    final list = _filtered;

    if (list.isEmpty) {
      final isSearching = _searchQuery.isNotEmpty;
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.store_outlined,
            color: AppTheme.textMuted(isDark).withOpacity(0.4),
            size: 44),
          const SizedBox(height: 14),
          Text(
            isSearching ? 'No services found' : 'No active services right now',
            style: TextStyle(
              color: AppTheme.textPrimary(isDark),
              fontSize: 15, fontWeight: FontWeight.w700)),
          if (isSearching) ...[
            const SizedBox(height: 6),
            Text('Try a different search term',
              style: TextStyle(
                  color: AppTheme.textMuted(isDark), fontSize: 13)),
          ],
        ],
      ));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.crimson,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount:        list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(ServiceEntry s) {
    final hasActive = s.activeTickets > 0;

    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasActive
              ? AppTheme.crimson.withOpacity(0.35)
              : AppTheme.border(isDark),
          width: hasActive ? 1.5 : 1)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Service name + active badge
            Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color:        AppTheme.crimson.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.store_rounded,
                    color: AppTheme.crimson, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SERVICE', style: TextStyle(
                    color:      AppTheme.crimson,
                    fontSize:   9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(s.name, style: TextStyle(
                    color:      AppTheme.textPrimary(isDark),
                    fontSize:   15,
                    fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
                ])),
              if (hasActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.3))),
                  child: const Text('ACTIVE',
                    style: TextStyle(
                      color:      Colors.green,
                      fontSize:   9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1))),
            ]),

            const SizedBox(height: 14),

            // Stats row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppTheme.surface(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border(isDark))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _cell(Icons.confirmation_num_outlined,
                      '${s.totalTickets}',   'Tickets',  AppTheme.crimson),
                  _vDiv(),
                  _cell(Icons.check_circle_outline_rounded,
                      '${s.activeTickets}',  'Active',   Colors.green),
                  _vDiv(),
                  _cell(Icons.history_rounded,
                      _timeAgo(s.lastVisited), 'Last visit',
                      AppTheme.textPrimary(isDark)),
                ])),

            // Active ticket chip
            if (s.lastTicketNumber != null && hasActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:        AppTheme.crimson.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.crimson.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.confirmation_num_outlined,
                      color: AppTheme.crimson, size: 16),
                  const SizedBox(width: 8),
                  Text('Active ticket: ', style: TextStyle(
                    color: AppTheme.textMuted(isDark), fontSize: 13)),
                  Text(s.lastTicketNumber!, style: const TextStyle(
                    color:      AppTheme.crimson,
                    fontSize:   13,
                    fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(
                    (s.lastTicketStatus ?? 'active').toUpperCase(),
                    style: TextStyle(
                      color:      _statusColor(s.lastTicketStatus),
                      fontSize:   10,
                      fontWeight: FontWeight.w800)),
                ])),
            ],

            // ── Schedule info ────────────────────────────
            const SizedBox(height: 10),
            _buildScheduleRow(s),
          ]),
      ),
    );
  }

  Widget _buildScheduleRow(ServiceEntry s) {
    final sch = s.scheduleInfo;

    // Still loading schedule
    if (sch == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(isDark))),
        child: Row(children: [
          Icon(Icons.schedule_rounded,
              color: AppTheme.textMuted(isDark), size: 14),
          const SizedBox(width: 8),
          Text('Loading schedule…',
              style: TextStyle(
                  color: AppTheme.textMuted(isDark), fontSize: 12)),
        ]),
      );
    }

    final isOpen    = sch.isOpen;
    final openColor = isOpen ? Colors.green : AppTheme.crimson;
    final openLabel = isOpen ? 'OPEN' : 'CLOSED';
    final openIcon  = isOpen
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color:        openColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: openColor.withOpacity(0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Open/closed status + hours
          Row(children: [
            Icon(openIcon, color: openColor, size: 14),
            const SizedBox(width: 6),
            Text(openLabel, style: TextStyle(
              color:      openColor,
              fontSize:   11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8)),
            const Spacer(),
            Icon(Icons.access_time_rounded,
                color: AppTheme.textMuted(isDark), size: 12),
            const SizedBox(width: 4),
            Text(
              '${ScheduleInfo.fmt(sch.openingTime)} – ${ScheduleInfo.fmt(sch.closingTime)}',
              style: TextStyle(
                color:      AppTheme.textPrimary(isDark),
                fontSize:   11,
                fontWeight: FontWeight.w700)),
          ]),
          // Avg wait (only show if meaningful)
          if (sch.avgDuration > 0) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.timer_outlined,
                  color: AppTheme.textMuted(isDark), size: 12),
              const SizedBox(width: 6),
              Text('Avg. wait time: ', style: TextStyle(
                  color: AppTheme.textMuted(isDark), fontSize: 11)),
              Text('~${sch.avgDuration} min per ticket',
                style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontSize:   11,
                  fontWeight: FontWeight.w700)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _cell(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
        color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(
        color: AppTheme.textMuted(isDark), fontSize: 9)),
    ]);
  }

  Widget _vDiv() => Container(
      width: 1, height: 36, color: AppTheme.border(isDark));
}