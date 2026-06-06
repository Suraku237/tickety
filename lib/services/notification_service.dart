import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/swap_service.dart';
import '../utils/app_theme.dart';

// =============================================================
// NOTIFICATION SERVICE  (Singleton)
// Responsibilities:
//   - Central hub for all in-app notification banners
//   - Persists alerts to SharedPreferences (1-week TTL)
//   - Polls backend for incoming swap requests
//   - Polls backend for outgoing swap responses (accepted/rejected)
// OOP Principle: Singleton, Observer, Single Responsibility
// =============================================================

enum NType { ticketCreated, login, logout, ticketTerminated, ticketCalled, swapRequest, swapResponse, general }

// =============================================================
// NALERT MODEL
// =============================================================
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
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Serialization
  Map<String, dynamic> toJson() => {
    'id':         id,
    'type':       type.name,
    'title':      title,
    'body':       body,
    'createdAt':  createdAt.toIso8601String(),
    'isRead':     isRead,
    'actionData': actionData,
  };

  factory NAlert.fromJson(Map<String, dynamic> j) => NAlert(
    id:         j['id'] as String,
    type:       NType.values.firstWhere(
                  (t) => t.name == j['type'],
                  orElse: () => NType.general),
    title:      j['title'] as String,
    body:       j['body']  as String,
    createdAt:  DateTime.parse(j['createdAt'] as String),
    isRead:     j['isRead'] as bool? ?? false,
    actionData: (j['actionData'] as Map?)
                    ?.cast<String, String>(),
  );

  // 1-week TTL
  bool get isExpired =>
      DateTime.now().difference(createdAt).inDays >= 7;
}

// =============================================================
// NOTIFICATION SERVICE
// =============================================================
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _prefKey = 'tickety_notifications';

  final List<NAlert>  _alerts      = [];
  final Set<String>   _seenSwapIds = {};
  final Set<String>   _seenRespIds = {};
  List<String>        _ticketIds   = [];

  final _swapService = SwapService();

  // Tracks which ticket IDs have already triggered the "called" alarm
  final Set<String> _calledTicketIds = {};

  void onTicketCalled({
    required String ticketCode,
    required String counter,
    required String ticketId,
  }) {
    if (_calledTicketIds.contains(ticketId)) return;
    _calledTicketIds.add(ticketId);
    _add(NAlert(
      id:    'called-$ticketId-${DateTime.now().millisecondsSinceEpoch}',
      type:  NType.ticketCalled,
      title: '🔔 Your Turn! — $ticketCode',
      body:  'Please proceed to $counter immediately.',
    ));
    _showAlarmBanner(ticketCode: ticketCode, counter: counter);
  }
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  List<NAlert> get alerts       => List.unmodifiable(_alerts);
  int get unreadCount           => _alerts.where((a) => !a.isRead).length;

  // ── Initialise — load persisted alerts ───────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_prefKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final j in list) {
        final a = NAlert.fromJson(j);
        if (!a.isExpired) _alerts.add(a);
      }
      // Rebuild seen-set so we don't re-fire on next poll
      for (final a in _alerts) {
        if (a.type == NType.swapRequest)  _seenSwapIds.add(a.id.replaceFirst('swap-', ''));
        if (a.type == NType.swapResponse) _seenRespIds.add(a.id.replaceFirst('swap-resp-', ''));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = jsonEncode(_alerts.map((a) => a.toJson()).toList());
    await prefs.setString(_prefKey, json);
  }

  // ── Public triggers ──────────────────────────────────────────

  void onTicketCreated(String ticketCode, String serviceName) {
    _add(NAlert(
      id:    'ticket-created-$ticketCode-${DateTime.now().millisecondsSinceEpoch}',
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
    _seenRespIds.clear();
    _calledTicketIds.clear();
  }

  void onTicketTerminated(String ticketCode, String serviceName) {
    _add(NAlert(
      id:    'terminated-$ticketCode-${DateTime.now().millisecondsSinceEpoch}',
      type:  NType.ticketTerminated,
      title: 'Left Queue',
      body:  'Ticket $ticketCode has been removed from the $serviceName queue and deleted.',
    ));
  }

  void onSwapResponse({
    required bool   accepted,
    required String myCode,
    required String otherCode,
    required String swapId,
  }) {
    _add(NAlert(
      id:    'swap-resp-$swapId',
      type:  NType.swapResponse,
      title: accepted ? '✅ Swap Accepted!' : '❌ Swap Declined',
      body:  accepted
          ? '$otherCode accepted your swap request. Your position has been updated!'
          : '$otherCode declined your swap request. Your position remains unchanged.',
    ));
  }

  // ── Swap polling ─────────────────────────────────────────────

  void startPolling(List<String> ticketIds) {
    _ticketIds = ticketIds;
    _pollNow();
  }

  void stopPolling() => _ticketIds = [];

  Future<void> refresh(List<String> ticketIds) async {
    _ticketIds = ticketIds;
    await _pollNow();
  }

  Future<void> _pollNow() async {
    await Future.wait([
      _pollIncoming(),
      _pollOutgoing(),
    ]);
  }

  // Poll incoming swap requests (someone wants to swap WITH me)
  Future<void> _pollIncoming() async {
    for (final tid in _ticketIds) {
      final result = await _swapService.loadIncoming(targetTicketId: tid);
      if (!result.success) continue;

      for (final sr in result.items) {
        if (_seenSwapIds.contains(sr.swapId)) continue;
        _seenSwapIds.add(sr.swapId);

        _add(NAlert(
          id:    'swap-${sr.swapId}',
          type:  NType.swapRequest,
          title: '🔄 Swap Request Received',
          body:  'Ticket ${sr.counterpartCode ?? '?'} '
                 '(position ${sr.counterpartPosition ?? '?'}) '
                 'wants to swap positions with your ticket.',
          actionData: {
            'swap_id':        sr.swapId,
            'from_code':      sr.counterpartCode  ?? '?',
            'your_ticket_id': tid,
          },
        ));
      }
    }
  }

  // Poll outgoing swap requests (did someone accept/reject MY request?)
  Future<void> _pollOutgoing() async {
    for (final tid in _ticketIds) {
      final result = await _swapService.loadOutgoing(requesterTicketId: tid);
      if (!result.success) continue;

      for (final sr in result.items) {
        // Only notify on resolved (non-pending) requests we haven't seen yet
        if (sr.isPending) continue;
        final respKey = '${sr.swapId}-${sr.status}';
        if (_seenRespIds.contains(respKey)) continue;
        _seenRespIds.add(respKey);

        onSwapResponse(
          accepted:  sr.isAccepted,
          myCode:    '(your ticket)',
          otherCode: sr.counterpartCode ?? '?',
          swapId:    '${sr.swapId}-${sr.status}',
        );
      }
    }
  }

  // ── Alert management ─────────────────────────────────────────

  void markRead(String id) {
    final i = _alerts.indexWhere((a) => a.id == id);
    if (i != -1) {
      _alerts[i].isRead = true;
      notifyListeners();
      _persist();
    }
  }

  void markAllRead() {
    for (final a in _alerts) { a.isRead = true; }
    notifyListeners();
    _persist();
  }

  void removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
    _persist();
  }

  // ── Internal ─────────────────────────────────────────────────

  void _add(NAlert alert) {
    if (_alerts.any((a) => a.id == alert.id)) return;
    _alerts.insert(0, alert);
    notifyListeners();
    _persist();
    _showBanner(alert);
  }

  // ── 10-second pulsing alarm banner for "called" notifications ─
  void _showAlarmBanner({required String ticketCode, required String counter}) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // Show the alarm for 10 seconds, pulsing 5 times
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => _AlarmOverlay(
        ticketCode: ticketCode,
        counter:    counter,
      ),
    );
  }

  void _showBanner(NAlert alert) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // "Called" alerts use the full alarm overlay instead of a snackbar
    if (alert.type == NType.ticketCalled) return;

    final color = _colorForType(alert.type);
    final icon  = _iconForType(alert.type);

    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      behavior:        SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation:       0,
      duration:        const Duration(seconds: 5),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.96),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color:      Colors.black.withOpacity(0.2),
            blurRadius: 14,
            offset:     const Offset(0, 4))]),
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
      case NType.ticketCalled:     return const Color(0xFFFF6B00);
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
      case NType.ticketCalled:     return Icons.campaign_rounded;
      case NType.swapRequest:      return Icons.swap_horiz_rounded;
      case NType.swapResponse:     return Icons.swap_horizontal_circle_rounded;
      default:                     return Icons.notifications_rounded;
    }
  }
}
// =============================================================
// ALARM OVERLAY  — shown for 15 seconds when ticket is called
// Pulses with a glowing ring to grab the user's attention.
// =============================================================
class _AlarmOverlay extends StatefulWidget {
  final String ticketCode;
  final String counter;
  const _AlarmOverlay({required this.ticketCode, required this.counter});

  @override
  State<_AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends State<_AlarmOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late Timer               _closeTimer;
  int _secondsLeft = 15;

  @override
  void initState() {
    super.initState();

    // Pulsing animation — repeating beats throughout the 15 seconds
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Countdown timer — close after 15 seconds
    _closeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _closeTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnim.value,
          child: child,
        ),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width:   320,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color:        const Color(0xFFFF6B00),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color:      const Color(0xFFFF6B00).withOpacity(0.6),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bell icon
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:  Colors.white.withOpacity(0.2),
                    shape:  BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size:  48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('YOUR TURN!',
                  style: TextStyle(
                    color:       Colors.white,
                    fontSize:    13,
                    fontWeight:  FontWeight.w900,
                    letterSpacing: 3,
                  )),
                const SizedBox(height: 8),
                Text(widget.ticketCode,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  )),
                const SizedBox(height: 8),
                Text(
                  'Please proceed to\n${widget.counter}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:      Colors.white.withOpacity(0.9),
                    fontSize:   16,
                    height:     1.4,
                  )),
                const SizedBox(height: 24),
                // Countdown ring
                Text(
                  'Closing in $_secondsLeft s',
                  style: TextStyle(
                    color:      Colors.white.withOpacity(0.7),
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  )),
                const SizedBox(height: 16),
                // Dismiss button
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Text('OK, Got it',
                      style: TextStyle(
                        color:      Colors.white,
                        fontSize:   14,
                        fontWeight: FontWeight.w800,
                      )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}