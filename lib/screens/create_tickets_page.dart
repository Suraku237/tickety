import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'home_page.dart';
import 'ticket_scanner.dart';
import 'ticket_form.dart';

// =============================================================
// CREATE TICKET PAGE  (File 3 of 3 — coordinator)
// Responsibilities:
//   - Own the two-step state machine: gate → form
//   - Drive the fade transition between steps
//   - Pass the resolved serviceCode + serviceName into TicketForm
//
// Step 0 (gate): user must scan a QR code OR enter a link.
//   • QrScannerSheet and LinkInputSheet live in ticket_scanner.dart
//   • Both call onResult(code) when a code is obtained
//
// Step 1 (form): TicketForm (ticket_form.dart) collects title,
//   description, and optional notes, then POSTs to the API.
//
// This file contains NO form fields, NO camera logic, and
// NO API calls — it is intentionally thin (~120 lines).
// =============================================================
class CreateTicketPage extends StatefulWidget {
  final AuthUser user;
  const CreateTicketPage({super.key, required this.user});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

enum _Step { gate, form }

class _CreateTicketPageState extends State<CreateTicketPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  _Step   _step        = _Step.gate;
  String? _serviceCode;
  String? _serviceName;

  bool get _dark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    ThemeProvider().addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Called by both QrScannerSheet and LinkInputSheet
  void _onCodeReceived(String code) {
    setState(() {
      _serviceCode = code;
      _serviceName = _parseServiceName(code);
      _step        = _Step.form;
    });
    _fadeCtrl..reset()..forward();
  }

  // Derive a readable label from the URL / raw code
  String _parseServiceName(String code) {
    try {
      final uri  = Uri.parse(code);
      final host = uri.host.replaceFirst('www.', '');
      final seg  = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first : '';
      if (host.isNotEmpty && seg.isNotEmpty) return '$host / $seg';
      if (host.isNotEmpty) return host;
    } catch (_) {}
    return code.length > 40 ? '${code.substring(0, 40)}…' : code;
  }

  // Reset back to gate — used by the "Change" button in the banner
  void _reset() {
    setState(() {
      _step        = _Step.gate;
      _serviceCode = null;
      _serviceName = null;
    });
    _fadeCtrl..reset()..forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: _step == _Step.gate
          ? _GatePage(dark: _dark, onCodeReceived: _onCodeReceived)
          : TicketForm(
              user:        widget.user,
              serviceCode: _serviceCode!,
              serviceName: _serviceName!,
              isDark:      _dark,
              onBack:      _reset,
            ),
    );
  }
}

// =============================================================
// GATE PAGE  (StatelessWidget — no mutable state)
// Presents the two input methods as tappable cards.
// The QR card is primary (gradient, more prominent).
// The link card is secondary (outlined).
// =============================================================
class _GatePage extends StatelessWidget {
  final bool                   dark;
  final void Function(String) onCodeReceived;

  const _GatePage({
    required this.dark,
    required this.onCodeReceived,
  });

  void _openQr(BuildContext ctx) {
    showModalBottomSheet(
      context:            ctx,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => QrScannerSheet(
        isDark:   dark,
        onResult: (code) {
          Navigator.pop(ctx);
          Future.microtask(() => onCodeReceived(code));
        },
      ),
    );
  }

  void _openLink(BuildContext ctx) {
    showModalBottomSheet(
      context:            ctx,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => LinkInputSheet(
        isDark:   dark,
        onResult: (code) {
          Navigator.pop(ctx);
          Future.microtask(() => onCodeReceived(code));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),

          // Page badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color:        AppTheme.crimson.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                  color: AppTheme.crimson.withOpacity(0.25)),
            ),
            child: const Text('NEW TICKET', style: TextStyle(
              color: AppTheme.crimson, fontSize: 10,
              fontWeight: FontWeight.w800, letterSpacing: 2,
            )),
          ),
          const SizedBox(height: 16),

          Text('Create\nTicket', style: TextStyle(
            color: AppTheme.textPrimary(dark), fontSize: 36,
            fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1,
          )),
          const SizedBox(height: 8),

          // Instruction — makes it clear scanning is required
          RichText(text: TextSpan(
            style: TextStyle(
                color: AppTheme.textMuted(dark), fontSize: 14),
            children: const [
              TextSpan(text: 'Scan the '),
              TextSpan(text: 'QR code',
                style: TextStyle(
                    color: AppTheme.crimson, fontWeight: FontWeight.w700)),
              TextSpan(text: ' at the service point, or enter the link manually.'),
            ],
          )),
          const SizedBox(height: 32),

          // ── Primary CTA: Scan QR ──
          _QrCard(dark: dark, onTap: () => _openQr(context)),
          const SizedBox(height: 14),

          // Divider with "or"
          Row(children: [
            Expanded(child: Divider(color: AppTheme.border(dark))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('or', style: TextStyle(
                  color: AppTheme.textMuted(dark), fontSize: 13)),
            ),
            Expanded(child: Divider(color: AppTheme.border(dark))),
          ]),
          const SizedBox(height: 14),

          // ── Secondary CTA: Enter link ──
          _LinkCard(dark: dark, onTap: () => _openLink(context)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Primary QR card (gradient background) ──
class _QrCard extends StatefulWidget {
  final bool         dark;
  final VoidCallback onTap;
  const _QrCard({required this.dark, required this.onTap});

  @override
  State<_QrCard> createState() => _QrCardState();
}

class _QrCardState extends State<_QrCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _c.forward(),
      onTapUp:     (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: ()  => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) =>
            Transform.scale(scale: _s.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.crimson, AppTheme.darkCrimson],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color:   AppTheme.crimson.withOpacity(0.28),
              blurRadius: 16, offset: const Offset(0, 6),
            )],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scan QR Code', style: TextStyle(
                  color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w800,
                )),
                const SizedBox(height: 4),
                Text('Point your camera at the service QR',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13)),
              ],
            )),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 22),
          ]),
        ),
      ),
    );
  }
}

// ── Secondary link card (outlined) ──
class _LinkCard extends StatelessWidget {
  final bool         dark;
  final VoidCallback onTap;
  const _LinkCard({required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        AppTheme.card(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(dark)),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color:        AppTheme.crimson.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.link_rounded,
                color: AppTheme.crimson, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter a Link', style: TextStyle(
                color: AppTheme.textPrimary(dark),
                fontSize: 17, fontWeight: FontWeight.w800,
              )),
              const SizedBox(height: 4),
              Text('Paste or type the service URL',
                style: TextStyle(
                    color: AppTheme.textMuted(dark), fontSize: 13)),
            ],
          )),
          Icon(Icons.chevron_right_rounded,
              color: AppTheme.textMuted(dark), size: 22),
        ]),
      ),
    );
  }
}