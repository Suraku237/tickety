import 'dart:async';
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
// SERVICE MODEL  (built from /services/browse)
// =============================================================
class ServiceEntry {
  final String id;
  final String name;
  final int    peopleWaiting;
  final int    avgWaitMinutes;
  final int    numQueues;
  final bool   visited;
  final ScheduleInfo? scheduleInfo;   // null until fetched

  const ServiceEntry({
    required this.id,
    required this.name,
    required this.peopleWaiting,
    required this.avgWaitMinutes,
    required this.numQueues,
    required this.visited,
    this.scheduleInfo,
  });

  factory ServiceEntry.fromMap(Map<String, dynamic> m) => ServiceEntry(
    id:             (m['service_id'] ?? m['id'] ?? '').toString(),
    name:           (m['service_name'] ?? m['name'] ?? 'Service').toString(),
    peopleWaiting:  (m['people_waiting']   as num?)?.toInt() ?? 0,
    avgWaitMinutes: (m['avg_wait_minutes'] as num?)?.toInt() ?? 0,
    numQueues:      (m['num_queues']       as num?)?.toInt() ?? 0,
    visited:        m['visited'] as bool? ?? false,
  );

  ServiceEntry copyWithSchedule(ScheduleInfo info) => ServiceEntry(
    id: id, name: name, peopleWaiting: peopleWaiting,
    avgWaitMinutes: avgWaitMinutes, numQueues: numQueues,
    visited: visited, scheduleInfo: info,
  );
}

// =============================================================
// SERVICES PAGE — browse all services (visited + non-visited),
// compare by wait time, search by name.
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
  bool   _loading = true;
  String? _error;
  String _filter = 'all';          // 'all' | 'visited'
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _filter = ['all', 'visited'][_tabController.index]);
      }
    });
    ThemeProvider().addListener(_onThemeChanged);
    _load();
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Server-side search is debounced so we don't fire a request per keystroke.
  void _onSearchChanged(String v) {
    setState(() => _searchQuery = v.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.browseServices(
        query:     _searchQuery,
        userEmail: widget.user.email,
      );
      if (!mounted) return;

      if (data['success'] != true) {
        setState(() { _error = data['message']?.toString() ?? 'Could not load services.'; _loading = false; });
        return;
      }

      final raw = (data['services'] as List? ?? []).cast<Map<String, dynamic>>();
      final services = raw.map(ServiceEntry.fromMap).toList();

      setState(() { _services = services; _loading = false; });
      _loadSchedules(services);
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not load services.'; _loading = false; });
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
    if (_filter == 'visited') list = list.where((s) => s.visited).toList();
    return list;
  }

  String _waitLabel(ServiceEntry s) {
    if (s.peopleWaiting == 0) return 'No wait';
    if (s.avgWaitMinutes <= 0) return 'Open queue';
    return '~${s.avgWaitMinutes} min';
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
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Services', style: TextStyle(
                        color: AppTheme.textPrimary(isDark),
                        fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      Text(
                        _loading
                          ? 'Loading…'
                          : '${_services.length} service${_services.length != 1 ? "s" : ""} available',
                        style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 12)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Filter tabs ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.card(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border(isDark))),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.crimson, borderRadius: BorderRadius.circular(10)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(3),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textMuted(isDark),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    tabs: const [Tab(text: 'All'), Tab(text: 'Visited')],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Search bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.card(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border(isDark))),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search services by name…',
                      hintStyle: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted(isDark), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () { _searchController.clear(); _onSearchChanged(''); },
                              child: Icon(Icons.close_rounded, color: AppTheme.textMuted(isDark), size: 18))
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.crimson));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded, color: AppTheme.textMuted(isDark), size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 14)),
        const SizedBox(height: 16),
        GestureDetector(onTap: _load, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: AppTheme.crimson, borderRadius: BorderRadius.circular(10)),
          child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
      ]));
    }

    final list = _filtered;
    if (list.isEmpty) {
      final isSearching = _searchQuery.isNotEmpty;
      final visitedTab  = _filter == 'visited';
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(isSearching ? Icons.search_off_rounded : Icons.store_outlined,
          color: AppTheme.textMuted(isDark).withOpacity(0.4), size: 44),
        const SizedBox(height: 14),
        Text(
          isSearching ? 'No services found'
                      : (visitedTab ? "You haven't visited any service yet" : 'No services available'),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 15, fontWeight: FontWeight.w700)),
        if (isSearching) ...[
          const SizedBox(height: 6),
          Text('Try a different search term', style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 13)),
        ],
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.crimson,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(ServiceEntry s) {
    final busy      = s.peopleWaiting > 0;
    final waitColor = s.peopleWaiting == 0
        ? Colors.green
        : (s.avgWaitMinutes >= 30 ? AppTheme.crimson : const Color(0xFFFFA500));

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: busy ? AppTheme.crimson.withOpacity(0.30) : AppTheme.border(isDark),
          width: busy ? 1.4 : 1)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Name + visited/new badge
          Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppTheme.crimson.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.store_rounded, color: AppTheme.crimson, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SERVICE', style: TextStyle(
                color: AppTheme.crimson, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(s.name, style: TextStyle(
                color: AppTheme.textPrimary(isDark), fontSize: 15, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis),
            ])),
            _badge(
              s.visited ? 'VISITED' : 'NEW',
              s.visited ? Colors.green : AppTheme.crimson,
            ),
          ]),

          const SizedBox(height: 14),

          // Stats row: wait time · people waiting · queues
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border(isDark))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _cell(Icons.timer_outlined, _waitLabel(s), 'Est. wait', waitColor),
              _vDiv(),
              _cell(Icons.people_alt_outlined, '${s.peopleWaiting}', 'Waiting', AppTheme.textPrimary(isDark)),
              _vDiv(),
              _cell(Icons.layers_outlined, '${s.numQueues}', 'Queues', AppTheme.crimson),
            ])),

          const SizedBox(height: 10),
          _buildScheduleRow(s),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Text(text, style: TextStyle(
      color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)));

  Widget _buildScheduleRow(ServiceEntry s) {
    final sch = s.scheduleInfo;
    if (sch == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(isDark))),
        child: Row(children: [
          Icon(Icons.schedule_rounded, color: AppTheme.textMuted(isDark), size: 14),
          const SizedBox(width: 8),
          Text('Loading schedule…', style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 12)),
        ]),
      );
    }
    final isOpen    = sch.isOpen;
    final openColor = isOpen ? Colors.green : AppTheme.crimson;
    final openLabel = isOpen ? 'OPEN' : 'CLOSED';
    final openIcon  = isOpen ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: openColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: openColor.withOpacity(0.25))),
      child: Row(children: [
        Icon(openIcon, color: openColor, size: 14),
        const SizedBox(width: 6),
        Text(openLabel, style: TextStyle(
          color: openColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        const Spacer(),
        Icon(Icons.access_time_rounded, color: AppTheme.textMuted(isDark), size: 12),
        const SizedBox(width: 4),
        Text('${ScheduleInfo.fmt(sch.openingTime)} – ${ScheduleInfo.fmt(sch.closingTime)}',
          style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _cell(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 9)),
    ]);
  }

  Widget _vDiv() => Container(width: 1, height: 36, color: AppTheme.border(isDark));
}