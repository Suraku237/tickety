import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// TICKET MODEL (lightweight placeholder)
// =============================================================
class QueueTicket {
  final String ticketNumber;
  final String serviceName;
  final String serviceCategory;
  final int    position;
  final int    peopleAhead;
  final int    totalInQueue;
  final String currentlyServing;
  final int    estimatedMinutes;
  final int    guichetNumber;
  final String status; // waiting | being_served | suspended
  final String joinedAt;

  const QueueTicket({
    required this.ticketNumber,
    required this.serviceName,
    required this.serviceCategory,
    required this.position,
    required this.peopleAhead,
    required this.totalInQueue,
    required this.currentlyServing,
    required this.estimatedMinutes,
    required this.guichetNumber,
    required this.status,
    required this.joinedAt,
  });
}

// =============================================================
// MY QUEUE PAGE
// Responsibilities:
//   - Display full queue info for each active ticket
//   - Allow navigation between multiple tickets
//   - Show guichet assignment dynamically
// OOP Principle: Single Responsibility
// =============================================================
class MyQueuePage extends StatefulWidget {
  const MyQueuePage({super.key});

  @override
  State<MyQueuePage> createState() => _MyQueuePageState();
}

class _MyQueuePageState extends State<MyQueuePage>
    with TickerProviderStateMixin {

  bool get isDark => ThemeProvider().isDarkMode;

  int _currentIndex = 0;

  late PageController _pageController;
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  // Placeholder tickets — replaced by backend data later
  final List<QueueTicket> _tickets = const [
    QueueTicket(
      ticketNumber:    'A047',
      serviceName:     'Main Counter',
      serviceCategory: 'Banking',
      position:        3,
      peopleAhead:     2,
      totalInQueue:    18,
      currentlyServing: 'A045',
      estimatedMinutes: 12,
      guichetNumber:   2,
      status:          'waiting',
      joinedAt:        '09:24 AM',
    ),
    QueueTicket(
      ticketNumber:    'B012',
      serviceName:     'Customer Support',
      serviceCategory: 'Telecom',
      position:        1,
      peopleAhead:     0,
      totalInQueue:    5,
      currentlyServing: 'B011',
      estimatedMinutes: 3,
      guichetNumber:   1,
      status:          'being_served',
      joinedAt:        '10:05 AM',
    ),
    QueueTicket(
      ticketNumber:    'C088',
      serviceName:     'Document Office',
      serviceCategory: 'Government',
      position:        7,
      peopleAhead:     6,
      totalInQueue:    30,
      currentlyServing: 'C082',
      estimatedMinutes: 35,
      guichetNumber:   4,
      status:          'suspended',
      joinedAt:        '08:50 AM',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pulseController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToTicket(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve:    Curves.easeInOutCubic,
    );
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'being_served': return Icons.play_circle_outline_rounded;
      case 'suspended':    return Icons.pause_circle_outline_rounded;
      default:             return Icons.hourglass_top_rounded;
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
          // Background glow
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.crimson.withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── TOP BAR ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Queue', style: TextStyle(
                              color:      AppTheme.textPrimary(isDark),
                              fontSize:   20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            )),
                            Text('${_tickets.length} active tickets',
                              style: TextStyle(
                                color:    AppTheme.textMuted(isDark),
                                fontSize: 12,
                              )),
                          ],
                        ),
                      ),
                      // Ticket counter badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:        AppTheme.crimson.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.crimson.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${_tickets.length}',
                          style: const TextStyle(
                            color:      AppTheme.crimson,
                            fontSize:   13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── TICKET SELECTOR DOTS ─────────────────────
                if (_tickets.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(_tickets.length, (i) {
                        final isActive = i == _currentIndex;
                        final ticket   = _tickets[i];
                        return GestureDetector(
                          onTap: () => _goToTicket(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.crimson
                                  : AppTheme.card(isDark),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.crimson
                                    : AppTheme.border(isDark),
                              ),
                            ),
                            child: Row(children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? Colors.white
                                      : _statusColor(ticket.status),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(ticket.ticketNumber,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : AppTheme.textPrimary(isDark),
                                  fontSize:   12,
                                  fontWeight: FontWeight.w700,
                                )),
                            ]),
                          ),
                        );
                      }),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── PAGE VIEW ────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller:    _pageController,
                    itemCount:     _tickets.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder:   (_, i) => _buildTicketView(_tickets[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketView(QueueTicket ticket) {
    final statusColor = _statusColor(ticket.status);
    final isServing   = ticket.status == 'being_served';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [

          // ── MAIN TICKET CARD ─────────────────────────────
          ScaleTransition(
            scale: isServing ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:        AppTheme.card(isDark),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isServing
                      ? statusColor.withOpacity(0.6)
                      : AppTheme.border(isDark),
                  width: isServing ? 1.5 : 1,
                ),
                boxShadow: isServing
                    ? [BoxShadow(
                        color:       AppTheme.crimson.withOpacity(0.15),
                        blurRadius:  20,
                        spreadRadius: 2,
                      )]
                    : [],
              ),
              child: Column(
                children: [
                  // Service info + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ticket.serviceCategory.toUpperCase(),
                            style: TextStyle(
                              color:    AppTheme.textMuted(isDark),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            )),
                          const SizedBox(height: 2),
                          Text(ticket.serviceName, style: TextStyle(
                            color:      AppTheme.textPrimary(isDark),
                            fontSize:   16,
                            fontWeight: FontWeight.w800,
                          )),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:        statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.35)),
                        ),
                        child: Row(children: [
                          Icon(_statusIcon(ticket.status),
                              color: statusColor, size: 13),
                          const SizedBox(width: 5),
                          Text(_statusLabel(ticket.status),
                            style: TextStyle(
                              color:      statusColor,
                              fontSize:   10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            )),
                        ]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Big ticket number
                  Container(
                    width:   double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: statusColor.withOpacity(0.2)),
                    ),
                    child: Column(children: [
                      Text('YOUR TICKET', style: TextStyle(
                        color:    AppTheme.textMuted(isDark),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      )),
                      const SizedBox(height: 8),
                      Text(ticket.ticketNumber, style: TextStyle(
                        color:       statusColor,
                        fontSize:    52,
                        fontWeight:  FontWeight.w900,
                        letterSpacing: 6,
                      )),
                      const SizedBox(height: 4),
                      Text('Joined at ${ticket.joinedAt}',
                        style: TextStyle(
                          color:    AppTheme.textMuted(isDark),
                          fontSize: 12,
                        )),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // Stats row
                  Row(children: [
                    _buildStatBox(
                      label: 'Position',
                      value: '#${ticket.position}',
                      icon:  Icons.format_list_numbered_rounded,
                      color: statusColor,
                    ),
                    const SizedBox(width: 10),
                    _buildStatBox(
                      label: 'Ahead',
                      value: '${ticket.peopleAhead}',
                      icon:  Icons.people_outline_rounded,
                      color: AppTheme.textMuted(isDark),
                    ),
                    const SizedBox(width: 10),
                    _buildStatBox(
                      label: 'In Queue',
                      value: '${ticket.totalInQueue}',
                      icon:  Icons.group_outlined,
                      color: AppTheme.textMuted(isDark),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── NOW SERVING CARD ─────────────────────────────
          _buildInfoCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NOW SERVING', style: TextStyle(
                    color:    AppTheme.textMuted(isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  )),
                  const SizedBox(height: 6),
                  Text(ticket.currentlyServing, style: TextStyle(
                    color:      AppTheme.textPrimary(isDark),
                    fontSize:   28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  )),
                ]),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        AppTheme.crimson.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.record_voice_over_rounded,
                      color: AppTheme.crimson, size: 26),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── GUICHET + TIME ROW ────────────────────────────
          Row(children: [
            Expanded(
              child: _buildInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GUICHET', style: TextStyle(
                      color:    AppTheme.textMuted(isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${ticket.guichetNumber}', style: TextStyle(
                        color:      AppTheme.textPrimary(isDark),
                        fontSize:   32,
                        fontWeight: FontWeight.w900,
                      )),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('counter', style: TextStyle(
                          color:    AppTheme.textMuted(isDark),
                          fontSize: 12,
                        )),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('Auto-assigned when free',
                      style: TextStyle(
                        color:    AppTheme.textMuted(isDark).withOpacity(0.6),
                        fontSize: 10,
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EST. WAIT', style: TextStyle(
                      color:    AppTheme.textMuted(isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${ticket.estimatedMinutes}', style: const TextStyle(
                        color:      AppTheme.crimson,
                        fontSize:   32,
                        fontWeight: FontWeight.w900,
                      )),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('min', style: const TextStyle(
                          color:    AppTheme.crimson,
                          fontSize: 12,
                        )),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('Average wait time',
                      style: TextStyle(
                        color:    AppTheme.textMuted(isDark).withOpacity(0.6),
                        fontSize: 10,
                      )),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // ── QUEUE PROGRESS BAR ────────────────────────────
          _buildInfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('QUEUE PROGRESS', style: TextStyle(
                      color:    AppTheme.textMuted(isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
                    Text(
                      '${ticket.totalInQueue - ticket.peopleAhead} / ${ticket.totalInQueue} served',
                      style: TextStyle(
                        color:    AppTheme.textMuted(isDark),
                        fontSize: 11,
                      )),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (ticket.totalInQueue - ticket.peopleAhead) /
                           ticket.totalInQueue,
                    minHeight:       8,
                    backgroundColor: AppTheme.border(isDark),
                    valueColor:      AlwaysStoppedAnimation<Color>(
                        AppTheme.crimson),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String   label,
    required String   value,
    required IconData icon,
    required Color    color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppTheme.border(isDark)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
            color: color, fontSize: 18, fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            color: AppTheme.textMuted(isDark), fontSize: 10,
          )),
        ]),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppTheme.border(isDark)),
      ),
      child: child,
    );
  }
}