import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// SERVICE MODEL
// =============================================================
class ServiceEntry {
  final String  id;
  final String  name;
  final String  category;
  final String  location;
  final int     totalVisits;
  final String  lastVisited;
  final int     avgWaitMinutes;
  final String  openTime;
  final String  closeTime;
  final bool    isOpenNow;
  final String? activeTicket;

  const ServiceEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.totalVisits,
    required this.lastVisited,
    required this.avgWaitMinutes,
    required this.openTime,
    required this.closeTime,
    required this.isOpenNow,
    this.activeTicket,
  });
}

// =============================================================
// SERVICES PAGE
// Responsibilities:
//   - Show all services the user has visited
//   - Display avg wait time, open/close hours, active ticket
//   - Filter by open / closed
// OOP Principle: Single Responsibility
// =============================================================
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage>
    with SingleTickerProviderStateMixin {

  bool get isDark => ThemeProvider().isDarkMode;
  late TabController _tabController;
  String _filter = 'all';

  final List<ServiceEntry> _services = const [
    ServiceEntry(
      id: '1', name: 'Main Counter', category: 'Banking',
      location: 'Agence Centrale, Yaoundé',
      totalVisits: 8, lastVisited: 'Today',
      avgWaitMinutes: 14, openTime: '08:00', closeTime: '17:00',
      isOpenNow: true, activeTicket: 'A047',
    ),
    ServiceEntry(
      id: '2', name: 'Customer Support', category: 'Telecom',
      location: 'MTN Centre, Rue Joss',
      totalVisits: 3, lastVisited: 'Today',
      avgWaitMinutes: 8, openTime: '09:00', closeTime: '18:00',
      isOpenNow: true, activeTicket: 'B012',
    ),
    ServiceEntry(
      id: '3', name: 'Document Office', category: 'Government',
      location: 'Hôtel de Ville, Yaoundé',
      totalVisits: 2, lastVisited: 'Yesterday',
      avgWaitMinutes: 32, openTime: '07:30', closeTime: '15:30',
      isOpenNow: false,
    ),
    ServiceEntry(
      id: '4', name: 'Emergency Ward', category: 'Health',
      location: 'Hôpital Central, Yaoundé',
      totalVisits: 1, lastVisited: '3 days ago',
      avgWaitMinutes: 45, openTime: '00:00', closeTime: '23:59',
      isOpenNow: true,
    ),
  ];

  List<ServiceEntry> get _filtered {
    switch (_filter) {
      case 'open':   return _services.where((s) => s.isOpenNow).toList();
      case 'closed': return _services.where((s) => !s.isOpenNow).toList();
      default:       return _services;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() =>
            _filter = ['all', 'open', 'closed'][_tabController.index]);
      }
    });
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _tabController.dispose();
    super.dispose();
  }

  Color    _cc(String c) {
    switch (c) {
      case 'Banking':    return const Color(0xFF2196F3);
      case 'Telecom':    return const Color(0xFF9C27B0);
      case 'Government': return const Color(0xFF4CAF50);
      case 'Health':     return const Color(0xFFFF5722);
      default:           return AppTheme.crimson;
    }
  }

  IconData _ci(String c) {
    switch (c) {
      case 'Banking':    return Icons.account_balance_rounded;
      case 'Telecom':    return Icons.cell_tower_rounded;
      case 'Government': return Icons.account_balance_wallet_rounded;
      case 'Health':     return Icons.local_hospital_rounded;
      default:           return Icons.store_rounded;
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
                      Text('${_services.length} services visited',
                        style: TextStyle(
                            color: AppTheme.textMuted(isDark),
                            fontSize: 12)),
                    ],
                  )),
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
                        '${_services.where((s) => s.isOpenNow).length} open',
                        style: const TextStyle(
                          color:      Colors.green,
                          fontSize:   11,
                          fontWeight: FontWeight.w700)),
                    ])),
                ]),
              ),
              const SizedBox(height: 16),
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
                      Tab(text: 'Open'),
                      Tab(text: 'Closed'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(child: Text('No services found',
                        style: TextStyle(
                          color:      AppTheme.textPrimary(isDark),
                          fontSize:   15,
                          fontWeight: FontWeight.w700)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount:        _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
                      ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCard(ServiceEntry s) {
    final cc = _cc(s.category);
    final ci = _ci(s.category);

    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: s.activeTicket != null
              ? AppTheme.crimson.withOpacity(0.35)
              : AppTheme.border(isDark),
          width: s.activeTicket != null ? 1.5 : 1)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(
                  color:        cc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14)),
                child: Icon(ci, color: cc, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.category.toUpperCase(), style: TextStyle(
                    color: cc, fontSize: 9,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(s.name, style: TextStyle(
                    color:      AppTheme.textPrimary(isDark),
                    fontSize:   15,
                    fontWeight: FontWeight.w800)),
                ])),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: s.isOpenNow
                      ? Colors.green.withOpacity(0.1)
                      : AppTheme.border(isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: s.isOpenNow
                        ? Colors.green.withOpacity(0.3)
                        : Colors.transparent)),
                child: Text(s.isOpenNow ? 'OPEN' : 'CLOSED',
                  style: TextStyle(
                    color: s.isOpenNow
                        ? Colors.green
                        : AppTheme.textMuted(isDark),
                    fontSize: 9, fontWeight: FontWeight.w800,
                    letterSpacing: 1))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.location_on_outlined,
                  color: AppTheme.textMuted(isDark), size: 13),
              const SizedBox(width: 4),
              Expanded(child: Text(s.location,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppTheme.textMuted(isDark), fontSize: 12))),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppTheme.surface(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border(isDark))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _cell(Icons.access_time_rounded,
                      '~${s.avgWaitMinutes}m', 'Avg Wait',
                      AppTheme.crimson),
                  _vDiv(),
                  _cell(Icons.login_rounded,
                      s.openTime, 'Opens', Colors.green),
                  _vDiv(),
                  _cell(Icons.logout_rounded,
                      s.closeTime, 'Closes',
                      AppTheme.textMuted(isDark)),
                  _vDiv(),
                  _cell(Icons.repeat_rounded,
                      '${s.totalVisits}x', 'Visits',
                      AppTheme.textPrimary(isDark)),
                ])),
            if (s.activeTicket != null) ...[
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
                  Text(s.activeTicket!, style: const TextStyle(
                    color:      AppTheme.crimson,
                    fontSize:   13,
                    fontWeight: FontWeight.w800)),
                  const Spacer(),
                  const Text('In queue →', style: TextStyle(
                    color:      AppTheme.crimson,
                    fontSize:   12,
                    fontWeight: FontWeight.w600)),
                ])),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.history_rounded,
                  color: AppTheme.textMuted(isDark), size: 12),
              const SizedBox(width: 4),
              Text('Last visited: ${s.lastVisited}',
                style: TextStyle(
                    color: AppTheme.textMuted(isDark), fontSize: 11)),
            ]),
          ]),
      ),
    );
  }

  Widget _cell(IconData icon, String value,
      String label, Color color) {
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