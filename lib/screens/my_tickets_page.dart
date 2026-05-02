import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'home_page.dart';

// =============================================================
// MY TICKETS PAGE
// =============================================================
class MyTicketsPage extends StatefulWidget {
  final AuthUser user;
  const MyTicketsPage({super.key, required this.user});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage>
    with SingleTickerProviderStateMixin {

  final _api = ApiService();

  late TabController _tabCtrl;
  bool   _loading = true;
  String _search  = '';
  List<Map<String, dynamic>> _all = [];

  bool get _dark => ThemeProvider().isDarkMode;

  final List<String> _tabs = ['All', 'Open', 'Pending', 'Closed', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    ThemeProvider().addListener(_rebuild);
    _load(); 
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {   final data = await _api.getTickets( userId: widget.user.userId);
      if (!mounted) return;
      setState(() {
        _all     = (data['tickets'] as List? ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final tab    = _tabs[_tabCtrl.index];
    final search = _search.toLowerCase();

    return _all.where((t) {
      final title    = (t['title']    ?? '').toLowerCase();
      final status   = (t['status']   ?? '').toLowerCase();
      final priority = (t['priority'] ?? '').toLowerCase();
      final service  = (t['service']  ?? '').toLowerCase();

      final matchSearch = search.isEmpty ||
          title.contains(search) || service.contains(search);

      bool matchTab;
      switch (tab) {
        case 'Open':    matchTab = status   == 'open';   break;
        case 'Pending': matchTab = status   == 'pending'; break;
        case 'Closed':  matchTab = status   == 'closed'; break;
        case 'Urgent':  matchTab = priority == 'urgent'; break;
        default:        matchTab = true;
      }
      return matchSearch && matchTab;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Glow
      Positioned(top: -50, right: -50,
        child: Container(width: 180, height: 180,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.crimson.withOpacity(0.08), Colors.transparent])))),

      SafeArea(child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('My Tickets', style: TextStyle(
                color: AppTheme.textPrimary(_dark), fontSize: 28,
                fontWeight: FontWeight.w900, letterSpacing: -0.5,
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color:        AppTheme.crimson.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.crimson.withOpacity(0.25)),
                ),
                child: Text('${_all.length} tickets', style: const TextStyle(
                  color: AppTheme.crimson, fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
              ),
            ]),
            const SizedBox(height: 16),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color:        AppTheme.card(_dark),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.border(_dark)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(color: AppTheme.textPrimary(_dark), fontSize: 14),
                decoration: InputDecoration(
                  hintText:  'Search tickets…',
                  hintStyle: TextStyle(color: AppTheme.textHint(_dark)),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppTheme.textMuted(_dark), size: 20),
                  border:         InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tabs
            TabBar(
              controller:          _tabCtrl,
              isScrollable:        true,
              labelColor:          AppTheme.crimson,
              unselectedLabelColor: AppTheme.textMuted(_dark),
              labelStyle:          const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              indicatorColor:      AppTheme.crimson,
              indicatorSize:       TabBarIndicatorSize.label,
              dividerColor:        Colors.transparent,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ]),
        ),

        // Divider
        Divider(height: 1, color: AppTheme.border(_dark)),

        // List
        Expanded(
          child: _loading
              ? _Skeleton(dark: _dark)
              : RefreshIndicator(
                  color:    AppTheme.crimson,
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? _Empty(dark: _dark, search: _search)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                          itemCount:   _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder:  (_, i) => _TicketTile(
                            ticket: _filtered[i],
                            dark:   _dark,
                            onTap: () => _openDetail(_filtered[i]),
                          ),
                        ),
                ),
        ),
      ])),
    ]);
  }

  void _openDetail(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _TicketDetailSheet(
          ticket: ticket, dark: _dark, onRefresh: _load),
    );
  }
}

// =============================================================
// TICKET TILE
// =============================================================
class _TicketTile extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool dark;
  final VoidCallback onTap;
  const _TicketTile({required this.ticket, required this.dark, required this.onTap});

  Color _pColor(String p) => switch (p.toLowerCase()) {
    'urgent' => AppTheme.crimson, 'high' => Colors.orange,
    'medium' => Colors.blue,     _      => Colors.green,
  };

  Color _sColor(String s, bool d) => switch (s.toLowerCase()) {
    'open'    => Colors.blue,  'pending' => Colors.orange,
    'closed'  => Colors.green, _         => AppTheme.textMuted(d),
  };

  IconData _sIcon(String s) => switch (s.toLowerCase()) {
    'open'    => Icons.radio_button_unchecked,
    'pending' => Icons.hourglass_empty_rounded,
    'closed'  => Icons.check_circle_outline_rounded,
    _         => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final title    = ticket['title']    ?? 'Untitled';
    final status   = ticket['status']   ?? 'open';
    final priority = ticket['priority'] ?? 'low';
    final service  = ticket['service']  ?? '';
    final desc     = ticket['description'] ?? '';

    final pc = _pColor(priority);
    final sc = _sColor(status, dark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppTheme.card(dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(dark)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Priority strip
            Container(
              width: 4, height: 40,
              decoration: BoxDecoration(
                color:        pc,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  color: AppTheme.textPrimary(dark),
                  fontSize: 15, fontWeight: FontWeight.w700,
                ), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(service.isNotEmpty ? service : 'No service',
                  style: TextStyle(
                    color: AppTheme.textMuted(dark), fontSize: 12)),
              ],
            )),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        sc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_sIcon(status), color: sc, size: 10),
                  const SizedBox(width: 4),
                  Text(status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(color: sc, fontSize: 10,
                        fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        pc.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(priority[0].toUpperCase() + priority.substring(1),
                  style: TextStyle(color: pc, fontSize: 10,
                      fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(desc,
              style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }
}

// =============================================================
// TICKET DETAIL SHEET
// =============================================================
class _TicketDetailSheet extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool dark;
  final VoidCallback onRefresh;
  const _TicketDetailSheet({required this.ticket, required this.dark, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final title    = ticket['title']       ?? 'Untitled';
    final status   = ticket['status']      ?? 'open';
    final priority = ticket['priority']    ?? 'low';
    final service  = ticket['service']     ?? '';
    final desc     = ticket['description'] ?? '';
    final notes    = ticket['notes']       ?? '';
    final code     = ticket['service_code'] ?? '';

    Color sc(String s) => switch (s.toLowerCase()) {
      'open' => Colors.blue, 'pending' => Colors.orange,
      'closed' => Colors.green, _ => AppTheme.textMuted(dark),
    };
    Color pc(String p) => switch (p.toLowerCase()) {
      'urgent' => AppTheme.crimson, 'high' => Colors.orange,
      'medium' => Colors.blue, _ => Colors.green,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      decoration: BoxDecoration(
        color:        AppTheme.surface(dark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 20),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppTheme.border(dark), borderRadius: BorderRadius.circular(2)),
        ),

        Row(children: [
          Expanded(child: Text(title, style: TextStyle(
            color: AppTheme.textPrimary(dark),
            fontSize: 18, fontWeight: FontWeight.w900,
          ))),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close_rounded,
                color: AppTheme.textMuted(dark), size: 22),
          ),
        ]),
        const SizedBox(height: 16),

        // Badges
        Row(children: [
          _Badge(label: status, color: sc(status)),
          const SizedBox(width: 8),
          _Badge(label: priority, color: pc(priority)),
          if (service.isNotEmpty) ...[
            const SizedBox(width: 8),
            _Badge(label: service, color: AppTheme.textMuted(dark)),
          ],
        ]),
        const SizedBox(height: 20),

        if (desc.isNotEmpty) ...[
          _DetailRow(icon: Icons.description_outlined, label: 'Description', value: desc, dark: dark),
          const SizedBox(height: 14),
        ],
        if (notes.isNotEmpty) ...[
          _DetailRow(icon: Icons.notes_rounded, label: 'Notes', value: notes, dark: dark),
          const SizedBox(height: 14),
        ],
        if (code.isNotEmpty)
          _DetailRow(icon: Icons.link_rounded, label: 'Service Link', value: code, dark: dark),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
    child: Text(label[0].toUpperCase() + label.substring(1),
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool dark;
  const _DetailRow({required this.icon, required this.label,
      required this.value, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppTheme.crimson, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(
              color: AppTheme.textMuted(dark),
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5,
            )),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(
              color: AppTheme.textPrimary(dark), fontSize: 13)),
          ],
        )),
      ]),
    );
  }
}

// =============================================================
// SKELETON & EMPTY
// =============================================================
class _Skeleton extends StatelessWidget {
  final bool dark;
  const _Skeleton({required this.dark});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
    itemCount: 5,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, __) => Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.card(dark), borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _Empty extends StatelessWidget {
  final bool dark;
  final String search;
  const _Empty({required this.dark, required this.search});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(search.isNotEmpty
          ? Icons.search_off_rounded
          : Icons.confirmation_num_outlined,
        color: AppTheme.textMuted(dark).withOpacity(0.4), size: 48),
      const SizedBox(height: 14),
      Text(
        search.isNotEmpty ? 'No results for "$search"' : 'No tickets here',
        style: TextStyle(color: AppTheme.textPrimary(dark),
            fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Text('Pull down to refresh',
        style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 13)),
    ]));
  }
}
