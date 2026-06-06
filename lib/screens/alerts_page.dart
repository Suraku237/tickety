import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/swap_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// ALERTS PAGE  — driven by NotificationService
// =============================================================
class AlertsPage extends StatefulWidget {
  final List<String> userTicketIds;
  const AlertsPage({super.key, this.userTicketIds = const []});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final _ns          = NotificationService();
  final _swapService = SwapService();

  bool get isDark => ThemeProvider().isDarkMode;
  bool _showUnreadOnly = false;
  bool _swapLoading    = false;

  @override
  void initState() {
    super.initState();
    _ns.addListener(_onAlertsChanged);
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onAlertsChanged() { if (mounted) setState(() {}); }
  void _onThemeChanged()  { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _ns.removeListener(_onAlertsChanged);
    ThemeProvider().removeListener(_onThemeChanged);
    super.dispose();
  }

  List<NAlert> get _filtered {
    final all = _ns.alerts;
    return _showUnreadOnly ? all.where((a) => !a.isRead).toList() : all;
  }

  // ── Swap actions ─────────────────────────────────────────────

  Future<void> _acceptSwap(NAlert alert) async {
    final swapId = alert.actionData?['swap_id'];
    if (swapId == null) return;
    setState(() => _swapLoading = true);
    final result = await _swapService.accept(swapId);
    if (!mounted) return;
    setState(() => _swapLoading = false);
    _ns.markRead(alert.id);
    if (result.success) _ns.removeAlert(alert.id);
    _snack(
      result.success ? result.message : 'Could not accept: ${result.message}',
      result.success ? Colors.green : AppTheme.crimson,
    );
  }

  Future<void> _rejectSwap(NAlert alert) async {
    final swapId = alert.actionData?['swap_id'];
    if (swapId == null) return;
    setState(() => _swapLoading = true);
    final result = await _swapService.reject(swapId);
    if (!mounted) return;
    setState(() => _swapLoading = false);
    _ns.markRead(alert.id);
    if (result.success) _ns.removeAlert(alert.id);
    _snack(
      result.success ? 'Swap request declined' : 'Could not reject: ${result.message}',
      result.success ? AppTheme.crimson : AppTheme.crimson,
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Styling helpers ──────────────────────────────────────────

  Color _color(NType t) {
    switch (t) {
      case NType.ticketCreated:    return const Color(0xFF22C55E);
      case NType.login:            return const Color(0xFF3B82F6);
      case NType.logout:           return const Color(0xFF6B7280);
      case NType.ticketTerminated: return AppTheme.crimson;
      case NType.swapRequest:      return const Color(0xFF8B5CF6);
      case NType.swapResponse:     return const Color(0xFF2196F3);
      default:                     return AppTheme.textMuted(isDark);
    }
  }

  IconData _icon(NType t) {
    switch (t) {
      case NType.ticketCreated:    return Icons.confirmation_num_rounded;
      case NType.login:            return Icons.login_rounded;
      case NType.logout:           return Icons.logout_rounded;
      case NType.ticketTerminated: return Icons.cancel_rounded;
      case NType.swapRequest:      return Icons.swap_horiz_rounded;
      case NType.swapResponse:     return Icons.swap_horizontal_circle_rounded;
      default:                     return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered   = _filtered;
    final unread     = _ns.unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: Stack(children: [
        Positioned(top: -60, right: -60,
          child: Container(width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.crimson.withOpacity(0.10),
                Colors.transparent])))),

        SafeArea(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── TOP BAR ───────────────────────────────────────
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
                      if (unread > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:        AppTheme.crimson,
                            borderRadius: BorderRadius.circular(10)),
                          child: Text('$unread', style: const TextStyle(
                            color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w800))),
                      ],
                    ]),
                    Text('${_ns.alerts.length} notifications',
                      style: TextStyle(
                          color: AppTheme.textMuted(isDark), fontSize: 12)),
                  ],
                )),
                // Refresh
                GestureDetector(
                  onTap: () => _ns.refresh(widget.userTicketIds),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:        AppTheme.card(isDark),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border(isDark))),
                    child: Icon(Icons.refresh_rounded,
                        color: AppTheme.textMuted(isDark), size: 18))),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _ns.markAllRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:        AppTheme.card(isDark),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border(isDark))),
                      child: const Text('Mark all read', style: TextStyle(
                        color: AppTheme.crimson, fontSize: 12,
                        fontWeight: FontWeight.w700)))),
                ],
              ]),
            ),
            const SizedBox(height: 16),

            // ── FILTER PILLS ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                _pill('All', !_showUnreadOnly,
                    () => setState(() => _showUnreadOnly = false)),
                const SizedBox(width: 8),
                _pill(
                  'Unread${unread > 0 ? ' ($unread)' : ''}',
                  _showUnreadOnly,
                  () => setState(() => _showUnreadOnly = true)),
              ]),
            ),
            const SizedBox(height: 16),

            // ── LIST ──────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount:        filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildCard(filtered[i]),
                    ),
            ),
          ],
        )),

        // Full-screen overlay while responding to swap
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
          color:      active ? Colors.white : AppTheme.textMuted(isDark),
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
          _showUnreadOnly ? 'All caught up!' : 'Notifications will appear here',
          style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 13)),
      ],
    ));
  }

  Widget _buildCard(NAlert alert) {
    final color      = _color(alert.type);
    final icon       = _icon(alert.type);
    final isSwapReq  = alert.type == NType.swapRequest;

    return GestureDetector(
      onTap: () => _ns.markRead(alert.id),
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
                          ? FontWeight.w600 : FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(alert.friendlyTime, style: TextStyle(
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
              Text(alert.body, style: TextStyle(
                color:    AppTheme.textMuted(isDark),
                fontSize: 13, height: 1.4)),

              // Swap request accept/reject buttons
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