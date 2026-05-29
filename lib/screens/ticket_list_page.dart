import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import '../models/ticket.dart';
import 'home_page.dart';
import 'ticket_detail_page.dart';

// =============================================================
// TICKET LIST PAGE
// Full paginated ticket list with:
//   - Status filter tabs (All / Open / Pending / Closed)
//   - Priority filter chip row
//   - Pull-to-refresh
//   - Tap → TicketDetailPage
//   - Empty and error states
// =============================================================
class TicketListPage extends StatefulWidget {
  final AuthUser user;
  const TicketListPage({super.key, required this.user});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();

  late TabController _tabCtrl;

  List<Ticket> _all      = [];
  bool         _loading  = true;
  String?      _error;
  String?      _priorityFilter; // null = all priorities

  static const _statuses = ['all', 'open', 'pending', 'closed'];
  static const _priorities = ['urgent', 'high', 'medium', 'low'];

  bool get _dark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(_rebuild);
    ThemeProvider().addListener(_rebuild);
    _load();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _tabCtrl.removeListener(_rebuild);
    ThemeProvider().removeListener(_rebuild);
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getTickets(userId: widget.user.userId);
      if (!mounted) return;
      final raw = (data['tickets'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() {
        _all     = raw.map(Ticket.fromMap).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Could not load tickets.'; });
    }
  }

  List<Ticket> get _filtered {
    final statusFilter = _statuses[_tabCtrl.index];
    return _all.where((t) {
      final statusOk   = statusFilter == 'all' || t.status == statusFilter;
      final priorityOk = _priorityFilter == null || t.priority == _priorityFilter;
      return statusOk && priorityOk;
    }).toList();
  }

  Color _priorityColor(String p) => switch (p) {
    'urgent' => AppTheme.crimson,
    'high'   => Colors.orange,
    'medium' => Colors.blue,
    _        => Colors.green,
  };

  Color _statusColor(String s) => switch (s) {
    'open'    => Colors.blue,
    'pending' => Colors.orange,
    'closed'  => Colors.green,
    _         => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface(_dark),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildTabBar(),
          _buildPriorityFilters(),
          Expanded(child: _buildBody()),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.card(_dark),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppTheme.border(_dark)),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: AppTheme.textMuted(_dark), size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Text('My Tickets', style: TextStyle(
          color: AppTheme.textPrimary(_dark),
          fontSize: 22, fontWeight: FontWeight.w900,
        )),
        const Spacer(),
        // Total badge
        if (!_loading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.crimson.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.crimson.withOpacity(0.25)),
            ),
            child: Text('${_all.length}', style: const TextStyle(
              color: AppTheme.crimson, fontSize: 12,
              fontWeight: FontWeight.w800,
            )),
          ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card(_dark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(_dark)),
        ),
        child: TabBar(
          controller: _tabCtrl,
          labelColor:         AppTheme.crimson,
          unselectedLabelColor: AppTheme.textMuted(_dark),
          labelStyle:   const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppTheme.crimson.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          dividerColor: Colors.transparent,
          tabs: _statuses.map((s) => Tab(
            text: s[0].toUpperCase() + s.substring(1),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildPriorityFilters() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _PriorityChip(
            label: 'All',
            color: AppTheme.textMuted(_dark),
            selected: _priorityFilter == null,
            dark: _dark,
            onTap: () => setState(() => _priorityFilter = null),
          ),
          ..._priorities.map((p) => _PriorityChip(
            label: p[0].toUpperCase() + p.substring(1),
            color: _priorityColor(p),
            selected: _priorityFilter == p,
            dark: _dark,
            onTap: () => setState(() =>
                _priorityFilter = _priorityFilter == p ? null : p),
          )),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeletons();
    if (_error != null) return _buildError();
    final items = _filtered;
    if (items.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: AppTheme.crimson,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        itemCount: items.length,
        itemBuilder: (_, i) => _TicketCard(
          ticket: items[i],
          dark: _dark,
          priorityColor: _priorityColor(items[i].priority),
          statusColor:   _statusColor(items[i].status),
          onTap: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => TicketDetailPage(
                ticket: items[i],
                user:   widget.user,
              )),
            );
            if (changed == true) _load();
          },
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 88,
        decoration: BoxDecoration(
          color: AppTheme.card(_dark),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off_rounded,
            color: AppTheme.textMuted(_dark).withOpacity(0.4), size: 48),
        const SizedBox(height: 16),
        Text(_error!, style: TextStyle(color: AppTheme.textMuted(_dark))),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _load,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.crimson,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Retry', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_rounded,
            color: AppTheme.textMuted(_dark).withOpacity(0.3), size: 56),
        const SizedBox(height: 16),
        Text('No tickets found', style: TextStyle(
          color: AppTheme.textPrimary(_dark),
          fontSize: 16, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 6),
        Text('Try a different filter', style: TextStyle(
          color: AppTheme.textMuted(_dark), fontSize: 13)),
      ]),
    );
  }
}

// ── Priority filter chip ──
class _PriorityChip extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   selected;
  final bool   dark;
  final VoidCallback onTap;
  const _PriorityChip({
    required this.label, required this.color, required this.selected,
    required this.dark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color:  selected ? color.withOpacity(0.15) : AppTheme.card(dark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : AppTheme.border(dark),
          ),
        ),
        child: Text(label, style: TextStyle(
          color:      selected ? color : AppTheme.textMuted(dark),
          fontSize:   12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        )),
      ),
    );
  }
}

// ── Ticket card ──
class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool   dark;
  final Color  priorityColor;
  final Color  statusColor;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket, required this.dark,
    required this.priorityColor, required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppTheme.card(dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(dark)),
        ),
        child: Row(children: [
          // Priority bar
          Container(
            width: 4, height: 54,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ticket.title, style: TextStyle(
                color: AppTheme.textPrimary(dark),
                fontSize: 14, fontWeight: FontWeight.w700,
              ), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (ticket.service.isNotEmpty) ...[
                  Icon(Icons.store_rounded,
                      size: 12, color: AppTheme.textMuted(dark)),
                  const SizedBox(width: 4),
                  Text(ticket.service, style: TextStyle(
                    color: AppTheme.textMuted(dark), fontSize: 11)),
                  const SizedBox(width: 10),
                ],
                // Assigned badge
                if (ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty) ...[
                  Icon(Icons.swap_horiz_rounded,
                      size: 12, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text('Swapped', style: const TextStyle(
                    color: Colors.purple, fontSize: 11,
                    fontWeight: FontWeight.w600)),
                ],
              ]),
              const SizedBox(height: 6),
              Row(children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    ticket.status[0].toUpperCase() + ticket.status.substring(1),
                    style: TextStyle(
                      color: statusColor, fontSize: 10,
                      fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    ticket.priority[0].toUpperCase() + ticket.priority.substring(1),
                    style: TextStyle(
                      color: priorityColor, fontSize: 10,
                      fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ],
          )),

          // Chevron
          Icon(Icons.chevron_right_rounded,
              color: AppTheme.textMuted(dark), size: 20),
        ]),
      ),
    );
  }
}
