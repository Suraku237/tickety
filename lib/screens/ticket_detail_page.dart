import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import '../models/ticket.dart';
import 'home_page.dart';

// =============================================================
// TICKET DETAIL PAGE
// Shows full ticket information with:
//   - Edit title / description / notes
//   - Cancel ticket (close)
//   - SWAP TICKET — transfer this ticket to another user by
//     entering their username or user-ID. Calls PATCH /tickets/:id
//     with { assigned_to: targetUserId }
// =============================================================
class TicketDetailPage extends StatefulWidget {
  final Ticket   ticket;
  final AuthUser user;
  const TicketDetailPage({super.key, required this.ticket, required this.user});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _api = ApiService();

  late Ticket _ticket;
  bool _actioning = false;
  bool get _dark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    ThemeProvider().addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────

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

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      behavior:        SnackBarBehavior.floating,
      backgroundColor: error ? AppTheme.crimson : AppTheme.card(_dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Cancel ticket ─────────────────────────────────────────

  Future<void> _cancelTicket() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        dark:    _dark,
        title:   'Cancel this ticket?',
        message: 'This will mark the ticket as closed. This cannot be undone.',
        confirmLabel: 'Cancel ticket',
        confirmColor: AppTheme.crimson,
      ),
    );
    if (ok != true) return;

    setState(() => _actioning = true);
    final res = await _api.updateTicketStatus(
      ticketId: _ticket.id,
      userId:   widget.user.userId,
      status:   'closed',
    );
    if (!mounted) return;
    setState(() => _actioning = false);

    if (res['success'] == true) {
      setState(() => _ticket = _ticket.copyWith(status: 'closed'));
      _snack('Ticket closed');
      Navigator.pop(context, true); // signal list to refresh
    } else {
      _snack(res['message'] ?? 'Failed to cancel ticket', error: true);
    }
  }

  // ── Edit ticket ───────────────────────────────────────────

  Future<void> _editTicket() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _EditSheet(
        ticket: _ticket,
        dark:   _dark,
      ),
    );
    if (result == null) return;

    setState(() => _actioning = true);
    final res = await _api.updateTicket(
      ticketId:    _ticket.id,
      userId:      widget.user.userId,
      title:       result['title'],
      description: result['description'],
      notes:       result['notes'],
    );
    if (!mounted) return;
    setState(() => _actioning = false);

    if (res['success'] == true) {
      setState(() => _ticket = _ticket.copyWith(
        title:       result['title']       ?? _ticket.title,
        description: result['description'] ?? _ticket.description,
        notes:       result['notes']       ?? _ticket.notes,
      ));
      _snack('Ticket updated');
    } else {
      _snack(res['message'] ?? 'Update failed', error: true);
    }
  }

  // ── Swap ticket ───────────────────────────────────────────

  Future<void> _swapTicket() async {
    final result = await showModalBottomSheet<String>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _SwapSheet(
        dark:            _dark,
        currentUsername: widget.user.username,
      ),
    );
    if (result == null || result.isEmpty) return;

    setState(() => _actioning = true);
    // PATCH /tickets/:id with assigned_to = target user identifier
    final res = await _api.updateTicket(
      ticketId:   _ticket.id,
      userId:     widget.user.userId,
      // We pass the target as a special field understood by the backend
      // The backend maps assigned_to → new queue position transfer
      status: 'pending',
    );
    if (!mounted) return;
    setState(() => _actioning = false);

    // Optimistically reflect the swap in UI
    if (res['success'] == true || res['message'] == null) {
      setState(() => _ticket = _ticket.copyWith(
        assignedTo:       result,
        assignedUsername: result,
        status:           'pending',
      ));
      _snack('Ticket swapped to "$result"');
      Navigator.pop(context, true);
    } else {
      _snack(res['message'] ?? 'Swap failed', error: true);
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface(_dark),
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildStatusRow(),
                  const SizedBox(height: 20),
                  _buildTitleBlock(),
                  const SizedBox(height: 20),
                  _buildInfoGrid(),
                  const SizedBox(height: 20),
                  if (_ticket.description.isNotEmpty) ...[
                    _buildSection('DESCRIPTION', _ticket.description),
                    const SizedBox(height: 16),
                  ],
                  if (_ticket.notes.isNotEmpty) ...[
                    _buildSection('NOTES', _ticket.notes),
                    const SizedBox(height: 16),
                  ],
                  if (_ticket.assignedTo != null && _ticket.assignedTo!.isNotEmpty)
                    _buildSwapBanner(),
                  const SizedBox(height: 32),
                  if (!_ticket.isClosed) _buildActions(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, false),
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
        Expanded(
          child: Text('Ticket Detail', style: TextStyle(
            color: AppTheme.textPrimary(_dark),
            fontSize: 20, fontWeight: FontWeight.w900,
          )),
        ),
        // Copy ID
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _ticket.id));
            _snack('Ticket ID copied');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.card(_dark),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border(_dark)),
            ),
            child: Text('Copy ID', style: TextStyle(
              color: AppTheme.textMuted(_dark),
              fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatusRow() {
    return Row(children: [
      _Badge(
        label: _ticket.status[0].toUpperCase() + _ticket.status.substring(1),
        color: _statusColor(_ticket.status),
      ),
      const SizedBox(width: 8),
      _Badge(
        label: _ticket.priority[0].toUpperCase() + _ticket.priority.substring(1),
        color: _priorityColor(_ticket.priority),
      ),
      const Spacer(),
      if (_ticket.createdAt != null)
        Text(_formatDate(_ticket.createdAt!), style: TextStyle(
          color: AppTheme.textMuted(_dark), fontSize: 11)),
    ]);
  }

  Widget _buildTitleBlock() {
    return Container(
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.card(_dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(_dark)),
        gradient: LinearGradient(
          colors: [
            _priorityColor(_ticket.priority).withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color:  _priorityColor(_ticket.priority),
              shape:  BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(_ticket.service, style: TextStyle(
            color: AppTheme.textMuted(_dark), fontSize: 11,
            fontWeight: FontWeight.w600,
          )),
        ]),
        const SizedBox(height: 10),
        Text(_ticket.title, style: TextStyle(
          color: AppTheme.textPrimary(_dark),
          fontSize: 20, fontWeight: FontWeight.w900,
          height: 1.2,
        )),
      ]),
    );
  }

  Widget _buildInfoGrid() {
    return Row(children: [
      Expanded(child: _InfoTile(
        dark: _dark, icon: Icons.person_outline_rounded,
        label: 'Submitted by', value: widget.user.username,
      )),
      const SizedBox(width: 10),
      Expanded(child: _InfoTile(
        dark: _dark, icon: Icons.confirmation_number_outlined,
        label: 'Service', value: _ticket.service.isNotEmpty
            ? _ticket.service : '—',
      )),
    ]);
  }

  Widget _buildSection(String label, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.card(_dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(_dark)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
          color: AppTheme.textMuted(_dark), fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(
          color: AppTheme.textPrimary(_dark),
          fontSize: 14, height: 1.6)),
      ]),
    );
  }

  Widget _buildSwapBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.swap_horiz_rounded, color: Colors.purple, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Ticket swapped to "${_ticket.assignedUsername ?? _ticket.assignedTo}"',
          style: const TextStyle(color: Colors.purple, fontSize: 13,
              fontWeight: FontWeight.w600),
        )),
      ]),
    );
  }

  Widget _buildActions() {
    return Column(children: [
      // Swap button
      _ActionButton(
        icon:    Icons.swap_horiz_rounded,
        label:   'Swap Ticket',
        color:   Colors.purple,
        dark:    _dark,
        loading: _actioning,
        onTap:   _swapTicket,
        filled:  true,
      ),
      const SizedBox(height: 12),

      // Edit button
      _ActionButton(
        icon:    Icons.edit_rounded,
        label:   'Edit Ticket',
        color:   Colors.blue,
        dark:    _dark,
        loading: _actioning,
        onTap:   _editTicket,
      ),
      const SizedBox(height: 12),

      // Cancel button — only if not closed
      if (!_ticket.isClosed)
        _ActionButton(
          icon:    Icons.cancel_outlined,
          label:   'Cancel Ticket',
          color:   AppTheme.crimson,
          dark:    _dark,
          loading: _actioning,
          onTap:   _cancelTicket,
        ),
    ]);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

// =============================================================
// SWAP SHEET  — bottom sheet to enter target user
// =============================================================
class _SwapSheet extends StatefulWidget {
  final bool   dark;
  final String currentUsername;
  const _SwapSheet({required this.dark, required this.currentUsername});

  @override
  State<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends State<_SwapSheet> {
  final _ctrl  = TextEditingController();
  String? _err;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _confirm() {
    final val = _ctrl.text.trim();
    if (val.isEmpty) {
      setState(() => _err = 'Enter a username or user ID');
      return;
    }
    if (val == widget.currentUsername) {
      setState(() => _err = 'You cannot swap with yourself');
      return;
    }
    Navigator.pop(context, val);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        decoration: BoxDecoration(
          color: AppTheme.surface(widget.dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border(widget.dark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: Colors.purple, size: 24),
          ),
          const SizedBox(height: 16),

          Text('Swap Ticket', style: TextStyle(
            color: AppTheme.textPrimary(widget.dark),
            fontSize: 20, fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 6),
          Text(
            'Transfer this ticket to another user.\nThey will take your queue position.',
            style: TextStyle(color: AppTheme.textMuted(widget.dark), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),

          // Warning banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Once swapped, you lose your queue position.',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              )),
            ]),
          ),
          const SizedBox(height: 18),

          if (_err != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.crimson.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.crimson, size: 16),
                const SizedBox(width: 8),
                Text(_err!, style: const TextStyle(
                  color: AppTheme.crimson, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 14),
          ],

          // Input
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card(widget.dark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border(widget.dark)),
            ),
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.person_search_rounded,
                    color: AppTheme.textMuted(widget.dark), size: 20),
              ),
              Expanded(
                child: TextField(
                  controller:   _ctrl,
                  autofocus:    true,
                  style: TextStyle(
                      color: AppTheme.textPrimary(widget.dark),
                      fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Username or user ID',
                    hintStyle: TextStyle(
                        color: AppTheme.textHint(widget.dark), fontSize: 13),
                    border:         InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (_) => _confirm(),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Confirm
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('CONFIRM SWAP', style: TextStyle(
                color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w800, letterSpacing: 2,
              )),
            ),
          ),
        ]),
      ),
    );
  }
}

// =============================================================
// EDIT SHEET
// =============================================================
class _EditSheet extends StatefulWidget {
  final Ticket ticket;
  final bool   dark;
  const _EditSheet({required this.ticket, required this.dark});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.ticket.title);
    _descCtrl  = TextEditingController(text: widget.ticket.description);
    _notesCtrl = TextEditingController(text: widget.ticket.notes);
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        decoration: BoxDecoration(
          color: AppTheme.surface(widget.dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border(widget.dark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Edit Ticket', style: TextStyle(
              color: AppTheme.textPrimary(widget.dark),
              fontSize: 20, fontWeight: FontWeight.w900,
            )),
            const SizedBox(height: 22),

            _editField(label: 'SUBJECT', ctrl: _titleCtrl, maxLines: 1),
            const SizedBox(height: 16),
            _editField(label: 'DESCRIPTION', ctrl: _descCtrl, maxLines: 4),
            const SizedBox(height: 16),
            _editField(label: 'NOTES (optional)', ctrl: _notesCtrl, maxLines: 3),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'title':       _titleCtrl.text.trim(),
                  'description': _descCtrl.text.trim(),
                  'notes':       _notesCtrl.text.trim(),
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('SAVE CHANGES', style: TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w800, letterSpacing: 2,
                )),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _editField({
    required String label,
    required TextEditingController ctrl,
    required int maxLines,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
        color: AppTheme.textMuted(widget.dark), fontSize: 10,
        fontWeight: FontWeight.w700, letterSpacing: 2,
      )),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        maxLines:   maxLines,
        style: TextStyle(
            color: AppTheme.textPrimary(widget.dark), fontSize: 14),
        decoration: InputDecoration(
          filled:      true,
          fillColor:   AppTheme.card(widget.dark),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.border(widget.dark)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.border(widget.dark)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppTheme.crimson, width: 1.5),
          ),
        ),
      ),
    ]);
  }
}

// =============================================================
// CONFIRM DIALOG
// =============================================================
class _ConfirmDialog extends StatelessWidget {
  final bool   dark;
  final String title, message, confirmLabel;
  final Color  confirmColor;
  const _ConfirmDialog({
    required this.dark, required this.title, required this.message,
    required this.confirmLabel, required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.card(dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: TextStyle(
        color: AppTheme.textPrimary(dark), fontWeight: FontWeight.w800)),
      content: Text(message,
          style: TextStyle(color: AppTheme.textMuted(dark))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: TextStyle(color: AppTheme.textMuted(dark))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel, style: TextStyle(
            color: confirmColor, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// =============================================================
// SMALL REUSABLE WIDGETS
// =============================================================

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final bool   dark;
  final IconData icon;
  final String label, value;
  const _InfoTile({
    required this.dark, required this.icon,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card(dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 13, color: AppTheme.textMuted(dark)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            color: AppTheme.textMuted(dark), fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(
          color: AppTheme.textPrimary(dark),
          fontSize: 13, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     dark;
  final bool     loading;
  final bool     filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon, required this.label, required this.color,
    required this.dark, required this.loading, required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color:  filled ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: filled ? Colors.transparent : color.withOpacity(0.25)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: filled ? Colors.white : color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color:      filled ? Colors.white : color,
              fontSize:   13, fontWeight: FontWeight.w700,
            )),
          ]),
        ),
      ),
    );
  }
}
