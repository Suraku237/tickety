import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// SERVICE MODEL
// =============================================================
class ServiceEntry {
  final String id;
  final String name;
  final String category;
  final String location;
  final String ticketNumber;
  final String status;
  final int    position;
  final int    estimatedMinutes;
  final String lastVisited;
  final int    totalVisits;

  const ServiceEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.ticketNumber,
    required this.status,
    required this.position,
    required this.estimatedMinutes,
    required this.lastVisited,
    required this.totalVisits,
  });
}

// =============================================================
// SERVICES PAGE
// Responsibilities:
//   - Show all services where the user has acquired tickets
//   - Display current queue status per service
// OOP Principle: Single Responsibility
// =============================================================
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {

  bool get isDark => ThemeProvider().isDarkMode;

  // Placeholder services
  final List<ServiceEntry> _services = const [
    ServiceEntry(
      id:               '1',
      name:             'Main Counter',
      category:         'Banking',
      location:         'Agence Centrale, Yaoundé',
      ticketNumber:     'A047',
      status:           'waiting',
      position:         3,
      estimatedMinutes: 12,
      lastVisited:      'Today',
      totalVisits:      8,
    ),
    ServiceEntry(
      id:               '2',
      name:             'Customer Support',
      category:         'Telecom',
      location:         'MTN Centre, Rue Joss',
      ticketNumber:     'B012',
      status:           'being_served',
      position:         1,
      estimatedMinutes: 2,
      lastVisited:      'Today',
      totalVisits:      3,
    ),
    ServiceEntry(
      id:               '3',
      name:             'Document Office',
      category:         'Government',
      location:         'Hôtel de Ville, Yaoundé',
      ticketNumber:     'C088',
      status:           'suspended',
      position:         7,
      estimatedMinutes: 35,
      lastVisited:      'Yesterday',
      totalVisits:      2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'being_served': return AppTheme.crimson;
      case 'suspended':    return const Color(0xFFFFA500);
      default:             return Colors.green;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'being_served': return 'BEING SERVED';
      case 'suspended':    return 'SUSPENDED';
      default:             return 'WAITING';
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Banking':    return const Color(0xFF2196F3);
      case 'Telecom':    return const Color(0xFF9C27B0);
      case 'Government': return const Color(0xFF4CAF50);
      case 'Health':     return const Color(0xFFFF5722);
      default:           return AppTheme.crimson;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Banking':    return Icons.account_balance_rounded;
      case 'Telecom':    return Icons.cell_tower_rounded;
      case 'Government': return Icons.account_balance_wallet_rounded;
      case 'Health':     return Icons.local_hospital_rounded;
      default:           return Icons.store_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: Stack(
        children: [
          Positioned(
            top: -80, left: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.crimson.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── TOP BAR ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color:        AppTheme.card(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border(isDark)),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary(isDark), size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Services', style: TextStyle(
                          color:      AppTheme.textPrimary(isDark),
                          fontSize:   20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        )),
                        Text('${_services.length} services joined',
                          style: TextStyle(
                            color:    AppTheme.textMuted(isDark),
                            fontSize: 12,
                          )),
                      ],
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── SUMMARY STRIP ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    _buildSummaryChip(
                      label: 'Active',
                      count: _services.where((s) =>
                          s.status == 'waiting' ||
                          s.status == 'being_served').length,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryChip(
                      label: 'Suspended',
                      count: _services
                          .where((s) => s.status == 'suspended').length,
                      color: const Color(0xFFFFA500),
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryChip(
                      label: 'Serving',
                      count: _services
                          .where((s) => s.status == 'being_served').length,
                      color: AppTheme.crimson,
                    ),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── SERVICE LIST ──────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount:   _services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildServiceCard(_services[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required int    count,
    required Color  color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$count $label', style: TextStyle(
          color: color, fontSize: 12, fontWeight: FontWeight.w700,
        )),
      ]),
    );
  }

  Widget _buildServiceCard(ServiceEntry service) {
    final statusColor   = _statusColor(service.status);
    final categoryColor = _categoryColor(service.category);
    final categoryIcon  = _categoryIcon(service.category);
    final isServing     = service.status == 'being_served';

    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isServing
              ? AppTheme.crimson.withOpacity(0.4)
              : AppTheme.border(isDark),
          width: isServing ? 1.5 : 1,
        ),
        boxShadow: isServing
            ? [BoxShadow(
                color:      AppTheme.crimson.withOpacity(0.08),
                blurRadius: 16,
                spreadRadius: 1,
              )]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Top row — icon, name, status
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color:        categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.category.toUpperCase(),
                      style: TextStyle(
                        color:    categoryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      )),
                    const SizedBox(height: 2),
                    Text(service.name, style: TextStyle(
                      color:      AppTheme.textPrimary(isDark),
                      fontSize:   15,
                      fontWeight: FontWeight.w800,
                    )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: statusColor.withOpacity(0.3)),
                ),
                child: Text(_statusLabel(service.status),
                  style: TextStyle(
                    color:      statusColor,
                    fontSize:   8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  )),
              ),
            ]),

            const SizedBox(height: 12),

            // Location
            Row(children: [
              Icon(Icons.location_on_outlined,
                  color: AppTheme.textMuted(isDark), size: 13),
              const SizedBox(width: 4),
              Text(service.location, style: TextStyle(
                color:    AppTheme.textMuted(isDark),
                fontSize: 12,
              )),
            ]),

            const SizedBox(height: 16),

            // Stats row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppTheme.surface(isDark),
                borderRadius: BorderRadius.circular(14),
                border:       Border.all(color: AppTheme.border(isDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    label: 'Ticket',
                    value: service.ticketNumber,
                    color: AppTheme.crimson,
                  ),
                  _buildDivider(),
                  _buildStat(
                    label: 'Position',
                    value: '#${service.position}',
                    color: AppTheme.textPrimary(isDark),
                  ),
                  _buildDivider(),
                  _buildStat(
                    label: 'Est. Wait',
                    value: '~${service.estimatedMinutes}m',
                    color: AppTheme.textPrimary(isDark),
                  ),
                  _buildDivider(),
                  _buildStat(
                    label: 'Visits',
                    value: '${service.totalVisits}x',
                    color: AppTheme.textPrimary(isDark),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Last visited
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Last visited: ${service.lastVisited}',
                  style: TextStyle(
                    color:    AppTheme.textMuted(isDark),
                    fontSize: 11,
                  )),
                Row(children: [
                  Text('View queue', style: const TextStyle(
                    color:      AppTheme.crimson,
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      color: AppTheme.crimson, size: 13),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required String value,
    required Color  color,
  }) {
    return Column(children: [
      Text(value, style: TextStyle(
        color: color, fontSize: 14, fontWeight: FontWeight.w900,
      )),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(
        color:    AppTheme.textMuted(isDark),
        fontSize: 10,
      )),
    ]);
  }

  Widget _buildDivider() {
    return Container(
      width: 1, height: 28,
      color: AppTheme.border(isDark),
    );
  }
}