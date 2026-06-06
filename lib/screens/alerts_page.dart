import 'package:flutter/material.dart';
import '../services/swap_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// ALERT TYPE ENUM
// =============================================================
enum AlertType { called, suspended, swapRequest, swapResponse, general }

// =============================================================
// ALERT MODEL
// =============================================================
class AlertItem {
  final String    id;
  final AlertType type;
  final String    title;
  final String    message;
  final String    time;
  final bool      isRead;

  // For swapRequest: holds the swap_id + ticket codes so we can
  // call the backend directly from the alert card.
  final Map<String, String>? actionData;

  const AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead     = false,
    this.actionData,
  });

  AlertItem copyWith({bool? isRead}) => AlertItem(
    id:         id,
    type:       type,
    title:      title,
    message:    message,
    time:       time,
    isRead:     isRead ?? this.isRead,
    actionData: actionData,
  );
}

// =============================================================
// ALERTS PAGE
// Responsibilities:
//   - Show all notifications grouped by read/unread
//   - Inline accept/reject for swap requests — REAL API calls
//   - Mark all as read
//   - Filter: All / Unread
//   - loadFromApi(): merge live incoming swap requests into the list
// OOP Principle: Single Responsibility, Encapsulation
// =============================================================
class AlertsPage extends StatefulWidget {
  /// The ticket IDs the current user holds (used to poll incoming swaps).
  final List<String> userTicketIds;

  const AlertsPage({super.key, this.userTicketIds = const []});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final _swapService = SwapService();

  bool get isDark => ThemeProvider().isDarkMode;
  bool _showUnreadOnly = false;
  bool _swapLoading    = false;   // covers the responding-to-swap network call

  // Static/mock alerts (called, suspended, general) are kept here
  // alongside live swap request alerts fetched from the backend.
  List<AlertItem> _alerts = [
    const AlertItem(
      id: 'static-1', type: AlertType.called,
      title: "You're being served!",
      message: 'Ticket A047 — Main Counter is now calling your number. '
               'Please proceed to Guichet 2.',
      time: '2 min ago', isRead: false,
    ),
    const AlertItem(
      id: 'static-2', type: AlertType.swapResponse,
      title: 'Swap Request Accepted',
      message: 'Your swap request with ticket A041 at Main Counter was '
               'accepted. You are now at position 1.',
      time: '15 min ago', isRead: false,
    ),
    const AlertItem(
      id: 'static-3', type: AlertType.suspended,
      title: 'Ticket Suspended',
      message: 'Your ticket C088 at Document Office has been suspended '
               'by an agent. Contact the counter to resume.',
      time: '1 hr ago', isRead: true,
    ),
    const AlertItem(
      id: 'static-4', type: AlertType.swapResponse,
      title: 'Swap Request Declined',
      message: 'Ticket A055 declined your swap request at Main Counter. '
               'Your position remains unchanged.',
      time: '2 hr ago', isRead: true,
    ),
    const AlertItem(
      id: 'static-5', type: AlertType.general,
      title: 'Welcome to TICKETY',
      message: 'Your account is verified and ready. Scan a QR code or '
               'enter a service link to get your first ticket.',
      time: '3 days ago', isRead: true,
    ),
  ];

  List<AlertItem> get _filtered => _showUnreadOnly
      ? _alerts.where((a) => !a.isRead).toList()
      : _alerts;

  int get _unreadCount => _alerts.where((a) => !a.isRead).length;

  @override
  void initState() {
    super.initState();
    ThemeProvider().addListener(_onThemeChanged);
    _loadIncomingSwapAlerts();
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    super.dispose();
  }

  // ----------------------------------------------------------
  // LOAD INCOMING SWAP REQUESTS FROM BACKEND
  // Polls all user tickets and merges results into _alerts.
  // Real implementation should use a push notification channel;
  // polling on page open is sufficient for MVP.
  // ----------------------------------------------------------
  Future<void> _loadIncomingSwapAlerts() async {
    if (widget.userTicketIds.isEmpty) return;

    // Remove any existing live swap request alerts before re-loading
    setState(() {
      _alerts.removeWhere((a) =>
          a.id.startsWith('swap-') && a.type == AlertType.swapRequest);
    });

    for (final ticketId in widget.userTicketIds) {
      final result =
          await _swapService.loadIncoming(targetTicketId: ticketId);
      if (!mounted || !result.success) continue;

      for (final sr in result.items) {
        // Don't duplicate
        final exists = _alerts.any((a) => a.id == 'swap-${sr.swapId}');
        if (exists) continue;

        final alert = AlertItem(
          id:      'swap-${sr.swapId}',
          type:    AlertType.swapRequest,
          title:   'Swap Request Received',
          message: 'Ticket ${sr.counterpartCode ?? '?'} '
                   '(position ${sr.counterpartPosition ?? '?'}) '
                   'wants to swap with your ticket.',
          time:    _friendlyTime(sr.createdAt),
          isRead:  false,
          actionData: {
            'swap_id':   sr.swapId,
            'from_code': sr.counterpartCode ?? '?',
            'your_ticket_id': ticketId,
          },
        );

        setState(() {
          // Insert at top (after any unread non-swap alerts)
          _alerts.insert(0, alert);
        });
      }
    }
  }

  String _friendlyTime(String iso) {
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return '';
    }
  }

  // ----------------------------------------------------------
  // ACCEPT SWAP — real API call
  // ----------------------------------------------------------
  Future<void> _acceptSwap(AlertItem alert) async {
    final swapId = alert.actionData?['swap_id'];
    if (swapId == null) return;

    setState(() { _swapLoading = true; });
    final result = await _swapService.accept(swapId);
    if (!mounted) return;
    setState(() { _swapLoading = false; });

    _markRead(alert.id);
    _snack(
      result.success
          ? result.message
          : 'Could not accept swap: ${result.message}',
      result.success ? Colors.green : AppTheme.crimson,
    );

    if (result.success) {
      // Remove the accepted alert so the card disappears
      setState(() { _alerts.removeWhere((a) => a.id == alert.id); });
    }
  }

  // ----------------------------------------------------------
  // REJECT SWAP — real API call
  // ----------------------------------------------------------
  Future<void> _rejectSwap(AlertItem alert) async {
    final swapId = alert.actionData?['swap_id'];
    if (swapId == null) return;

    setState(() { _swapLoading = true; });
    final result = await _swapService.reject(swapId);
    if (!mounted) return;
    setState(() { _swapLoading = false; });

    _markRead(alert.id);
    _snack(
      result.success
          ? 'Swap request rejected'
          : 'Could not reject: ${result.message}',
      result.success ? AppTheme.crimson : AppTheme.crimson,
    );

    if (result.success) {
      setState(() { _alerts.removeWhere((a) => a.id == alert.id); });
    }
  }

  void _markAllRead() {
    setState(() {
      _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
    });
  }

  void _markRead(String id) {
    setState(() {
      final i = _alerts.indexWhere((a) => a.id == id);
      if (i != -1) _alerts[i] = _alerts[i].copyWith(isRead: true);
    });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // --- Alert styling helpers ---
  Color _color(AlertType t) {
    switch (t) {
      case AlertType.called:       return AppTheme.crimson;
      case AlertType.suspended:    return const Color(0xFFFFA500);
      case AlertType.swapRequest:  return const Color(0xFF2196F3);
      case AlertType.swapResponse: return const Color(0xFF9C27B0);
      default:                     return AppTheme.textMuted(isDark);
    }
  }

  IconData _icon(AlertType t) {
    switch (t) {
      case AlertType.called:       return Icons.record_voice_over_rounded;
      case AlertType.suspended:    return Icons.pause_circle_outline_rounded;
      case AlertType.swapRequest:  return Icons.swap_horiz_rounded;
      case AlertType.swapResponse: return Icons.swap_horizontal_circle_rounded;
      default:                     return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: Stack(children: [
        Positioned(top: -60, right: -60,
          child: Container(width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.crimson.withOpacity(0.10),
                Colors.transparent])))),

        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // TOP BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Alerts', style: TextStyle(
                          color:      AppTheme.textPrimary(isDark),
                          fontSize:   24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                        if (_unreadCount > 0) ...[ 
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:        AppTheme.crimson,
                              borderRadius: BorderRadius.circular(10)),
                            child: Text('$_unreadCount',
                              style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   11,
                                fontWeight: FontWeight.w800))),
                        ],
                      ]),
                      Text('${_alerts.length} notifications',
                        style: TextStyle(
                            color: AppTheme.textMuted(isDark), fontSize: 12)),
                    ],
                  )),
                  // Refresh button
                  GestureDetector(
                    onTap: _loadIncomingSwapAlerts,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:        AppTheme.card(isDark),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border(isDark))),
                      child: Icon(Icons.refresh_rounded,
                          color: AppTheme.textMuted(isDark), size: 18))),
                  if (_unreadCount > 0) ...[ 
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:        AppTheme.card(isDark),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border(isDark))),
                        child: const Text('Mark all read',
                          style: TextStyle(
                            color:      AppTheme.crimson,
                            fontSize:   12,
                            fontWeight: FontWeight.w700)))),
                  ],
                ]),
              ),
              const SizedBox(height: 16),

              // FILTER PILLS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  _pill('All',    !_showUnreadOnly,
                      () => setState(() => _showUnreadOnly = false)),
                  const SizedBox(width: 8),
                  _pill(
                    'Unread${_unreadCount > 0 ? ' ($_unreadCount)' : ''}',
                    _showUnreadOnly,
                    () => setState(() => _showUnreadOnly = true)),
                ]),
              ),
              const SizedBox(height: 16),

              // LIST
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount:        filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildCard(filtered[i]),
                      ),
              ),
            ],
          ),
        ),

        // Full-screen loading overlay while responding to a swap
        if (_swapLoading)
          Container(
            color: Colors.black.withOpacity(0.25),
            child: const Center(child: CircularProgressIndicator(
                color: AppTheme.crimson))),
      ]),
    );
  }

  Widget _pill(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.crimson : AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.crimson : AppTheme.border(isDark))),
        child: Text(label, style: TextStyle(
          color: active ? Colors.white : AppTheme.textMuted(isDark),
          fontSize:   12,
          fontWeight: FontWeight.w700))),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.notifications_off_outlined,
            color: AppTheme.textMuted(isDark).withOpacity(0.35), size: 48),
        const SizedBox(height: 14),
        Text(
          _showUnreadOnly ? 'No unread alerts' : 'No alerts yet',
          style: TextStyle(
            color:      AppTheme.textPrimary(isDark),
            fontSize:   16,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          _showUnreadOnly
              ? 'All caught up!'
              : 'Notifications will appear here',
          style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 13)),
      ],
    ));
  }

  Widget _buildCard(AlertItem alert) {
    final color     = _color(alert.type);
    final icon      = _icon(alert.type);
    final isSwapReq = alert.type == AlertType.swapRequest;

    return GestureDetector(
      onTap: () => _markRead(alert.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: alert.isRead
              ? AppTheme.card(isDark)
              : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.isRead
                ? AppTheme.border(isDark)
                : color.withOpacity(0.3),
            width: alert.isRead ? 1 : 1.5)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title, style: TextStyle(
                      color:      AppTheme.textPrimary(isDark),
                      fontSize:   14,
                      fontWeight: alert.isRead
                          ? FontWeight.w600
                          : FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(alert.time, style: TextStyle(
                      color: AppTheme.textMuted(isDark), fontSize: 11)),
                  ],
                )),
                if (!alert.isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 10),
              Text(alert.message, style: TextStyle(
                color:    AppTheme.textMuted(isDark),
                fontSize: 13,
                height:   1.4)),

              // Swap request inline accept / reject
              if (isSwapReq && !alert.isRead) ...[ 
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => _acceptSwap(alert),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:        Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3))),
                      child: const Center(child: Text('Accept',
                        style: TextStyle(
                          color:      Colors.green,
                          fontSize:   13,
                          fontWeight: FontWeight.w700)))))),
                  const SizedBox(width: 10),
                  Expanded(child: GestureDetector(
                    onTap: () => _rejectSwap(alert),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:        AppTheme.crimson.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.crimson.withOpacity(0.3))),
                      child: const Center(child: Text('Decline',
                        style: TextStyle(
                          color:      AppTheme.crimson,
                          fontSize:   13,
                          fontWeight: FontWeight.w700)))))),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}