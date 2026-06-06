import 'package:flutter/material.dart';
import '../services/swap_service.dart';
import '../utils/app_theme.dart';

// =============================================================
// NOTIFICATION SERVICE  (Singleton)
// Responsibilities:
//   - Central hub for all in-app notification banners
//   - Manages a global overlay key so any screen can trigger a banner
//   - Stores in-memory alert list that AlertsPage reads
//   - Polls the backend for incoming swap requests periodically
// OOP Principle: Singleton, Observer, Single Responsibility
// =============================================================

// Alert types
enum NType { ticketCreated, login, logout, ticketTerminated, swapRequest, swapResponse, general }

// Alert model
class NAlert {
  final String  id;
  final NType   type;
  final String  title;
  final String  body;
  final DateTime createdAt;
  bool isRead;
  final Map<String, String>? actionData;

  NAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    DateTime? createdAt,
    this.isRead    = false,
    this.actionData,
  }) : createdAt = createdAt ?? DateTime.now();

  String get friendlyTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class NotificationService extends ChangeNotifier {
  // ── Singleton ────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ── State ────────────────────────────────────────────────────
  final List<NAlert> _alerts = [];
  List<NAlert> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _alerts.where((a) => !a.isRead).length;

  // Used to show overlay banners
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Swap polling
  final _swapService = SwapService();
  List<String> _ticketIds = [];
  final Set<String> _seenSwapIds = {};

  // ── Public triggers ──────────────────────────────────────────

  void onTicketCreated(String ticketCode, String serviceName) {
    _add(NAlert(
      id:    'ticket-created-$ticketCode',
      type:  NType.ticketCreated,
      title: 'Ticket Created',
      body:  'Your ticket $ticketCode at $serviceName has been issued. You\'re in the queue!',
    ));
  }

  void onLogin(String username) {
    _add(NAlert(
      id:    'login-${DateTime.now().millisecondsSinceEpoch}',
      type:  NType.login,
      title: 'Welcome back, $username!',
      body:  'You are now signed in to TICKETY.',
    ));
  }

  void onLogout() {
    _add(NAlert(
      id:    'logout-${DateTime.now().millisecondsSinceEpoch}',
      type:  NType.logout,
      title: 'Signed Out',
      body:  'You have been signed out successfully.',
    ));
    _ticketIds = [];
    _seenSwapIds.clear();
  }

  void onTicketTerminated(String ticketCode, String serviceName) {
    _add(NAlert(
      id:    'terminated-$ticketCode',
      type:  NType.ticketTerminated,
      title: 'Ticket Terminated',
      body:  'Ticket $ticketCode at $serviceName has been removed from the queue.',
    ));
  }

  void onSwapResponse({
    required bool accepted,
    required String myCode,
    required String otherCode,
  }) {
    _add(NAlert(
      id:    'swap-resp-${DateTime.now().millisecondsSinceEpoch}',
      type:  NType.swapResponse,
      title: accepted ? 'Swap Accepted!' : 'Swap Declined',
      body:  accepted
          ? '$otherCode accepted your swap. Your position has changed.'
          : '$otherCode declined your swap request.',
    ));
  }

  // ── Swap polling ─────────────────────────────────────────────

  void startPolling(List<String> ticketIds) {
    _ticketIds = ticketIds;
    _pollNow();
  }

  void stopPolling() {
    _ticketIds = [];
  }

  Future<void> _pollNow() async {
    for (final tid in _ticketIds) {
      final result = await _swapService.loadIncoming(targetTicketId: tid);
      if (!result.success) continue;

      for (final sr in result.items) {
        if (_seenSwapIds.contains(sr.swapId)) continue;
        _seenSwapIds.add(sr.swapId);

        final alert = NAlert(
          id:    'swap-${sr.swapId}',
          type:  NType.swapRequest,
          title: 'Swap Request Received',
          body:  'Ticket ${sr.counterpartCode ?? '?'} '
                 '(position ${sr.counterpartPosition ?? '?'}) '
                 'wants to swap positions with your ticket.',
          actionData: {
            'swap_id':       sr.swapId,
            'from_code':     sr.counterpartCode  ?? '?',
            'your_ticket_id': tid,
          },
        );
        _add(alert);
      }
    }
  }

  // Manual refresh (called when user opens Alerts tab)
  Future<void> refresh(List<String> ticketIds) async {
    _ticketIds = ticketIds;
    await _pollNow();
  }

  // ── Alert management ─────────────────────────────────────────

  void markRead(String id) {
    final i = _alerts.indexWhere((a) => a.id == id);
    if (i != -1) { _alerts[i].isRead = true; notifyListeners(); }
  }

  void markAllRead() {
    for (final a in _alerts) { a.isRead = true; }
    notifyListeners();
  }

  void removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // ── Internal ─────────────────────────────────────────────────

  void _add(NAlert alert) {
    // Deduplicate
    if (_alerts.any((a) => a.id == alert.id)) return;
    _alerts.insert(0, alert);
    notifyListeners();
    _showBanner(alert);
  }

  void _showBanner(NAlert alert) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final color = _colorForType(alert.type);
    final icon  = _iconForType(alert.type);

    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      behavior:        SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation:       0,
      duration:        const Duration(seconds: 4),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset:     const Offset(0, 4))
          ]),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alert.title, style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(alert.body,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      ),
    ));
  }

  Color _colorForType(NType t) {
    switch (t) {
      case NType.ticketCreated:    return const Color(0xFF22C55E);
      case NType.login:            return const Color(0xFF3B82F6);
      case NType.logout:           return const Color(0xFF6B7280);
      case NType.ticketTerminated: return AppTheme.crimson;
      case NType.swapRequest:      return const Color(0xFF8B5CF6);
      case NType.swapResponse:     return const Color(0xFF2196F3);
      default:                     return const Color(0xFF6B7280);
    }
  }

  IconData _iconForType(NType t) {
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
}