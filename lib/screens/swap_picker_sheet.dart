import 'package:flutter/material.dart';
import '../services/swap_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// SWAP PICKER SHEET
// Responsibilities:
//   - Load real available tickets from the backend
//   - Let the user pick one and send a swap request
//   - Show loading, error and already-sent states
// OOP Principle: Single Responsibility, Composition
// =============================================================
class SwapPickerSheet extends StatefulWidget {
  final String      sourceTicketId;
  final String      sourceTicketCode;
  final String      serviceName;
  final VoidCallback? onSwapSent;

  const SwapPickerSheet({
    super.key,
    required this.sourceTicketId,
    required this.sourceTicketCode,
    required this.serviceName,
    this.onSwapSent,
  });

  @override
  State<SwapPickerSheet> createState() => _SwapPickerSheetState();
}

class _SwapPickerSheetState extends State<SwapPickerSheet> {
  final _swapService = SwapService();

  bool    _loading  = true;
  bool    _sending  = false;
  String? _error;
  String? _selected;  // ticket id of selected target
  List<SwappableTicket> _tickets = [];

  bool get _dark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await _swapService.loadAvailable(
        requesterTicketId: widget.sourceTicketId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _tickets = result.tickets;
      } else {
        _error = result.error ?? 'Failed to load available tickets';
      }
    });
  }

  Future<void> _send() async {
    if (_selected == null) return;
    setState(() { _sending = true; });

    final result = await _swapService.sendRequest(
      requesterTicketId: widget.sourceTicketId,
      targetTicketId:    _selected!,
    );
    if (!mounted) return;
    setState(() { _sending = false; });

    if (result.success) {
      Navigator.pop(context);
      widget.onSwapSent?.call();
      _snack(result.message, Colors.green);
    } else {
      _snack(result.message, AppTheme.crimson);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.card(_dark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color:        AppTheme.border(_dark),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),

              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3))),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: Color(0xFF2196F3), size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request Swap', style: TextStyle(
                      color:      AppTheme.textPrimary(_dark),
                      fontSize:   17,
                      fontWeight: FontWeight.w900)),
                    Text(
                      'Choose who to swap with at ${widget.serviceName}',
                      style: TextStyle(
                          color: AppTheme.textMuted(_dark), fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                  ])),
              ]),
              const SizedBox(height: 12),

              // Your ticket
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:        AppTheme.surface(_dark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border(_dark))),
                child: Row(children: [
                  Text('Your ticket:', style: TextStyle(
                      color: AppTheme.textMuted(_dark), fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(widget.sourceTicketCode,
                    style: const TextStyle(
                      color:      AppTheme.crimson,
                      fontSize:   13,
                      fontWeight: FontWeight.w800)),
                  const Spacer(),
                  const Icon(Icons.swap_horiz_rounded,
                      color: AppTheme.crimson, size: 16),
                  const SizedBox(width: 6),
                  Text(_selected != null
                      ? (_tickets.firstWhere(
                            (t) => t.ticketId == _selected,
                            orElse: () => const SwappableTicket(
                              ticketId: '', code: '?', queueId: '',
                              status: '')).code)
                      : 'Select target',
                    style: TextStyle(
                        color: AppTheme.textMuted(_dark), fontSize: 12)),
                ])),
              const SizedBox(height: 12),
              Divider(color: AppTheme.border(_dark)),
              const SizedBox(height: 8),

              // Body: loading / error / list
              SizedBox(
                height: 220,
                child: _loading
                    ? Center(child: CircularProgressIndicator(
                        color: AppTheme.crimson, strokeWidth: 2.5))
                    : _error != null
                        ? _ErrorState(
                            dark:    _dark,
                            message: _error!,
                            onRetry: _load)
                        : _tickets.isEmpty
                            ? _EmptyState(dark: _dark)
                            : _TicketList(
                                dark:     _dark,
                                tickets:  _tickets,
                                selected: _selected,
                                onSelect: (id) =>
                                    setState(() => _selected = id)),
              ),

              const SizedBox(height: 16),

              // Send button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_selected == null || _sending) ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected != null
                        ? const Color(0xFF2196F3)
                        : AppTheme.border(_dark),
                    disabledBackgroundColor: AppTheme.border(_dark),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                  child: _sending
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _selected != null
                              ? 'Send Swap Request'
                              : 'Select a ticket first',
                          style: TextStyle(
                            color: _selected != null
                                ? Colors.white
                                : AppTheme.textMuted(_dark),
                            fontSize:   14,
                            fontWeight: FontWeight.w800)),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// TICKET LIST
// =============================================================
class _TicketList extends StatelessWidget {
  final bool                      dark;
  final List<SwappableTicket>     tickets;
  final String?                   selected;
  final void Function(String)     onSelect;

  const _TicketList({
    required this.dark,
    required this.tickets,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount:        tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t          = tickets[i];
        final isSelected = selected == t.ticketId;
        final hasPending = t.hasPendingRequest;

        return GestureDetector(
          onTap: hasPending ? null : () => onSelect(t.ticketId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2196F3).withOpacity(0.08)
                  : AppTheme.surface(dark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2196F3).withOpacity(0.5)
                    : hasPending
                        ? const Color(0xFFFFA500).withOpacity(0.4)
                        : AppTheme.border(dark),
                width: isSelected ? 1.5 : 1)),
            child: Row(children: [
              // Ticket badge
              Container(
                width: 50, height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2196F3).withOpacity(0.12)
                      : AppTheme.card(dark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2196F3).withOpacity(0.3)
                        : AppTheme.border(dark))),
                child: Center(child: Text(t.code,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF2196F3)
                        : AppTheme.textPrimary(dark),
                    fontSize:   11,
                    fontWeight: FontWeight.w800)))),
              const SizedBox(width: 12),
              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.position != null
                        ? 'Position ${t.position}'
                        : 'Active now',
                    style: TextStyle(
                      color:      AppTheme.textPrimary(dark),
                      fontSize:   13,
                      fontWeight: FontWeight.w700)),
                  if (hasPending)
                    Text('Request already sent',
                      style: const TextStyle(
                          color: Color(0xFFFFA500), fontSize: 11))
                  else
                    Text(t.status.toUpperCase(),
                      style: TextStyle(
                          color:    AppTheme.textMuted(dark),
                          fontSize: 11)),
                ])),
              // Trailing indicator
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2196F3), size: 20)
              else if (hasPending)
                const Icon(Icons.hourglass_top_rounded,
                    color: Color(0xFFFFA500), size: 18),
            ]),
          ),
        );
      },
    );
  }
}

// =============================================================
// ERROR STATE
// =============================================================
class _ErrorState extends StatelessWidget {
  final bool   dark;
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.dark, required this.message,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded,
            color: AppTheme.crimson.withOpacity(0.6), size: 36),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 13)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onRetry,
          child: Text('Retry',
            style: const TextStyle(
              color:      AppTheme.crimson,
              fontSize:   13,
              fontWeight: FontWeight.w700))),
      ],
    ));
  }
}

// =============================================================
// EMPTY STATE
// =============================================================
class _EmptyState extends StatelessWidget {
  final bool dark;
  const _EmptyState({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline_rounded,
            color: AppTheme.textMuted(dark).withOpacity(0.4), size: 38),
        const SizedBox(height: 12),
        Text('No other tickets in this service',
          style: TextStyle(
            color:      AppTheme.textPrimary(dark),
            fontSize:   14,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('No one else is in the queue right now',
          style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 12)),
      ],
    ));
  }
}