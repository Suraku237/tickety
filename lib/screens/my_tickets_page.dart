import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// TICKET MODEL
// =============================================================
class UserTicket {
  final String id;
  final String ticketNumber;
  final String serviceName;
  final String serviceCategory;
  final String status;       // active | suspended
  final String joinedAt;
  final bool   hasSwapRequest;
  final String? swapRequestFrom; // ticket number requesting swap

  const UserTicket({
    required this.id,
    required this.ticketNumber,
    required this.serviceName,
    required this.serviceCategory,
    required this.status,
    required this.joinedAt,
    this.hasSwapRequest  = false,
    this.swapRequestFrom,
  });
}

// =============================================================
// MY TICKETS PAGE
// Responsibilities:
//   - List all user tickets with status
//   - Add ticket by code or QR scan
//   - Handle swap requests (accept/reject)
// OOP Principle: Single Responsibility
// =============================================================
class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage>
    with TickerProviderStateMixin {

  bool get isDark => ThemeProvider().isDarkMode;

  final TextEditingController _codeCtrl = TextEditingController();

  // Placeholder data
  final List<UserTicket> _tickets = const [
    UserTicket(
      id:              '1',
      ticketNumber:    'A047',
      serviceName:     'Main Counter',
      serviceCategory: 'Banking',
      status:          'active',
      joinedAt:        '09:24 AM',
    ),
    UserTicket(
      id:              '2',
      ticketNumber:    'B012',
      serviceName:     'Customer Support',
      serviceCategory: 'Telecom',
      status:          'active',
      joinedAt:        '10:05 AM',
      hasSwapRequest:  true,
      swapRequestFrom: 'B015',
    ),
    UserTicket(
      id:              '3',
      ticketNumber:    'C088',
      serviceName:     'Document Office',
      serviceCategory: 'Government',
      status:          'suspended',
      joinedAt:        '08:50 AM',
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
    _codeCtrl.dispose();
    super.dispose();
  }

  void _showAddTicketSheet() {
    showModalBottomSheet(
      context:           context,
      isScrollControlled: true,
      backgroundColor:   Colors.transparent,
      builder: (_) => _AddTicketSheet(isDark: isDark, codeCtrl: _codeCtrl),
    );
  }

  void _showSwapDialog(UserTicket ticket) {
    showDialog(
      context: context,
      builder: (_) => _SwapRequestDialog(
        isDark:          isDark,
        ticket:          ticket,
        onAccept: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:         const Text('Swap accepted!'),
            backgroundColor: Colors.green,
          ));
        },
        onReject: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:         const Text('Swap rejected.'),
            backgroundColor: AppTheme.crimson,
          ));
        },
      ),
    );
  }

  Color _statusColor(String status) =>
      status == 'active' ? Colors.green : const Color(0xFFFFA500);

  String _statusLabel(String status) =>
      status == 'active' ? 'ACTIVE' : 'SUSPENDED';

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
            bottom: -60, right: -60,
            child: Container(
              width: 220, height: 220,
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

                // ── TOP BAR ────────────────────────────────
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Tickets', style: TextStyle(
                            color:      AppTheme.textPrimary(isDark),
                            fontSize:   20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          )),
                          Text('${_tickets.length} tickets',
                            style: TextStyle(
                              color:    AppTheme.textMuted(isDark),
                              fontSize: 12,
                            )),
                        ],
                      ),
                    ),

                    // Add ticket button
                    GestureDetector(
                      onTap: _showAddTicketSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color:        AppTheme.crimson,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: const [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Add', style: TextStyle(
                            color:      Colors.white,
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                          )),
                        ]),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── SWAP REQUESTS BANNER ────────────────────
                if (_tickets.any((t) => t.hasSwapRequest))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFFFA500).withOpacity(0.35)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.swap_horiz_rounded,
                            color: Color(0xFFFFA500), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You have pending swap requests',
                            style: const TextStyle(
                              color:      Color(0xFFFFA500),
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                            )),
                        ),
                      ]),
                    ),
                  ),

                // ── TICKET LIST ─────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount:   _tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildTicketCard(_tickets[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(UserTicket ticket) {
    final statusColor = _statusColor(ticket.status);

    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ticket.hasSwapRequest
              ? const Color(0xFFFFA500).withOpacity(0.4)
              : AppTheme.border(isDark),
          width: ticket.hasSwapRequest ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [

              // Ticket number badge
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color:        AppTheme.crimson.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.crimson.withOpacity(0.2)),
                ),
                child: Center(child: Text(ticket.ticketNumber,
                  style: const TextStyle(
                    color:      AppTheme.crimson,
                    fontSize:   16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ))),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.serviceCategory.toUpperCase(),
                      style: TextStyle(
                        color:    AppTheme.textMuted(isDark),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      )),
                    const SizedBox(height: 2),
                    Text(ticket.serviceName, style: TextStyle(
                      color:      AppTheme.textPrimary(isDark),
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                    )),
                    const SizedBox(height: 6),
                    Text('Joined ${ticket.joinedAt}',
                      style: TextStyle(
                        color:    AppTheme.textMuted(isDark),
                        fontSize: 12,
                      )),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: statusColor.withOpacity(0.3)),
                ),
                child: Text(_statusLabel(ticket.status),
                  style: TextStyle(
                    color:      statusColor,
                    fontSize:   9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  )),
              ),
            ]),
          ),

          // Swap request actions
          if (ticket.hasSwapRequest) ...[
            Divider(height: 1, color: AppTheme.border(isDark)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.swap_horiz_rounded,
                        color: Color(0xFFFFA500), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Swap request from ticket ${ticket.swapRequestFrom}',
                      style: const TextStyle(
                        color:      Color(0xFFFFA500),
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                      )),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showSwapDialog(ticket),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color:        Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: const Center(child: Text('Accept Swap',
                            style: TextStyle(
                              color:      Colors.green,
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                            ))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:         Text('Swap rejected.'),
                              backgroundColor: AppTheme.crimson,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color:        AppTheme.crimson.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.crimson.withOpacity(0.3)),
                          ),
                          child: const Center(child: Text('Reject',
                            style: TextStyle(
                              color:      AppTheme.crimson,
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                            ))),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// =============================================================
// ADD TICKET BOTTOM SHEET
// =============================================================
class _AddTicketSheet extends StatefulWidget {
  final bool isDark;
  final TextEditingController codeCtrl;
  const _AddTicketSheet({required this.isDark, required this.codeCtrl});

  @override
  State<_AddTicketSheet> createState() => _AddTicketSheetState();
}

class _AddTicketSheetState extends State<_AddTicketSheet>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color:        AppTheme.border(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Text('Add a Ticket', style: TextStyle(
                color:      AppTheme.textPrimary(isDark),
                fontSize:   20,
                fontWeight: FontWeight.w900,
              )),
              const SizedBox(height: 4),
              Text('Enter a ticket code or scan a QR code',
                style: TextStyle(
                  color:    AppTheme.textMuted(isDark),
                  fontSize: 13,
                )),

              const SizedBox(height: 24),

              // Tab bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color:        AppTheme.surface(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: AppTheme.border(isDark)),
                ),
                child: TabBar(
                  controller:         _tabController,
                  indicator:          BoxDecoration(
                    color:        AppTheme.crimson,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize:      TabBarIndicatorSize.tab,
                  indicatorPadding:   const EdgeInsets.all(3),
                  dividerColor:       Colors.transparent,
                  labelColor:         Colors.white,
                  unselectedLabelColor: AppTheme.textMuted(isDark),
                  labelStyle:         const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Enter Code'),
                    Tab(text: 'Scan QR'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 180,
                child: TabBarView(
                  controller: _tabController,
                  children: [

                    // ── CODE INPUT ──────────────────────────
                    Column(children: [
                      TextFormField(
                        controller:    widget.codeCtrl,
                        style:         TextStyle(
                            color: AppTheme.textPrimary(isDark),
                            fontSize: 15),
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText:  'e.g. A047',
                          hintStyle: TextStyle(
                              color: AppTheme.textHint(isDark)),
                          prefixIcon: Icon(
                              Icons.confirmation_num_outlined,
                              color: AppTheme.textMuted(isDark), size: 20),
                          filled:    true,
                          fillColor: AppTheme.surface(isDark),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: AppTheme.border(isDark)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: AppTheme.border(isDark)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppTheme.crimson, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.crimson,
                            elevation:       0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Add Ticket',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   15,
                              fontWeight: FontWeight.w800,
                            )),
                        ),
                      ),
                    ]),

                    // ── QR SCAN ─────────────────────────────
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:        AppTheme.crimson.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.crimson.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded,
                              color: AppTheme.crimson, size: 48),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity, height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: launch QR scanner
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.crimson,
                              elevation:       0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Open Camera',
                              style: TextStyle(
                                color:      Colors.white,
                                fontSize:   15,
                                fontWeight: FontWeight.w800,
                              )),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================
// SWAP REQUEST DIALOG
// =============================================================
class _SwapRequestDialog extends StatelessWidget {
  final bool        isDark;
  final UserTicket  ticket;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _SwapRequestDialog({
    required this.isDark,
    required this.ticket,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        const Color(0xFFFFA500).withOpacity(0.1),
                shape:        BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFFA500).withOpacity(0.3)),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: Color(0xFFFFA500), size: 32),
            ),
            const SizedBox(height: 16),
            Text('Swap Request', style: TextStyle(
              color:      AppTheme.textPrimary(isDark),
              fontSize:   18,
              fontWeight: FontWeight.w900,
            )),
            const SizedBox(height: 8),
            Text(
              'Ticket ${ticket.swapRequestFrom} wants to swap position with your ticket ${ticket.ticketNumber} at ${ticket.serviceName}.',
              textAlign: TextAlign.center,
              style:     TextStyle(
                color:    AppTheme.textMuted(isDark),
                fontSize: 13,
                height:   1.5,
              )),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color:        AppTheme.surface(isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border(isDark)),
                    ),
                    child: Center(child: Text('Reject', style: TextStyle(
                      color:      AppTheme.textPrimary(isDark),
                      fontWeight: FontWeight.w700,
                    ))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color:        Colors.green,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('Accept', style: TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w700,
                    ))),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}