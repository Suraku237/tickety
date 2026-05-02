import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/auth_widgets.dart';
import '../utils/theme_provider.dart';
import 'home_page.dart';

// =============================================================
// CREATE TICKET PAGE
// Flow:  (1) MUST scan QR OR enter link  →  (2) fill form  →  submit
// QR / link is MANDATORY — the form is locked behind it.
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

  void _onCodeReceived(String code) {
    final name = _resolveServiceName(code);
    setState(() {
      _serviceCode = code;
      _serviceName = name;
      _step        = _Step.form;
    });
    _fadeCtrl..reset()..forward();
  }

  String _resolveServiceName(String code) {
    try {
      final uri = Uri.parse(code);
      final host = uri.host.replaceFirst('www.', '');
      final seg  = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (seg.isNotEmpty) return '$host / $seg';
      return host.isNotEmpty ? host : code;
    } catch (_) {
      return code;
    }
  }

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
          : _FormPage(
              dark:        _dark,
              user:        widget.user,
              serviceCode: _serviceCode!,
              serviceName: _serviceName!,
              onBack:      _reset,
            ),
    );
  }
}

// =============================================================
// GATE PAGE — QR scan or link entry (mandatory)
// =============================================================
class _GatePage extends StatelessWidget {
  final bool dark;
  final void Function(String) onCodeReceived;
  const _GatePage({required this.dark, required this.onCodeReceived});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Decorative glow
      Positioned(top: -40, right: -40,
        child: Container(width: 220, height: 220,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.crimson.withOpacity(0.10), Colors.transparent])))),

      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 28),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color:        AppTheme.crimson.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.crimson.withOpacity(0.25)),
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
            RichText(text: TextSpan(
              text: 'You must ',
              style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 14),
              children: const [
                TextSpan(text: 'scan a QR code or enter a link',
                  style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.w700)),
                TextSpan(text: ' to start.'),
              ],
            )),
            const SizedBox(height: 32),

            // QR SCAN  — primary CTA
            _ScanQrCard(dark: dark, onCodeReceived: onCodeReceived),
            const SizedBox(height: 14),

            // Divider
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

            // LINK ENTRY — secondary CTA
            _LinkEntryCard(dark: dark, onCodeReceived: onCodeReceived),
            const SizedBox(height: 36),

            // Info strip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppTheme.card(dark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border(dark)),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.textMuted(dark), size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'The QR code or link identifies the service '
                  'provider and pre-fills your ticket details.',
                  style: TextStyle(
                    color: AppTheme.textMuted(dark), fontSize: 12),
                )),
              ]),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    ]);
  }
}

// =============================================================
// SCAN QR  CARD  (opens full-screen scanner)
// =============================================================
class _ScanQrCard extends StatefulWidget {
  final bool dark;
  final void Function(String) onCodeReceived;
  const _ScanQrCard({required this.dark, required this.onCodeReceived});

  @override
  State<_ScanQrCard> createState() => _ScanQrCardState();
}

class _ScanQrCardState extends State<_ScanQrCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _open() {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _QrScannerSheet(
        dark: widget.dark,
        onScanned: (code) {
          Navigator.pop(context);
          widget.onCodeReceived(code);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); _open(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.crimson, AppTheme.darkCrimson],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color:   AppTheme.crimson.withOpacity(0.3),
              blurRadius: 18, offset: const Offset(0, 6))],
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
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800,
                )),
                const SizedBox(height: 3),
                Text('Point your camera at the service QR',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13)),
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

// =============================================================
// LINK ENTRY  CARD  (inline expandable)
// =============================================================
class _LinkEntryCard extends StatefulWidget {
  final bool dark;
  final void Function(String) onCodeReceived;
  const _LinkEntryCard({required this.dark, required this.onCodeReceived});

  @override
  State<_LinkEntryCard> createState() => _LinkEntryCardState();
}

class _LinkEntryCardState extends State<_LinkEntryCard>
    with SingleTickerProviderStateMixin {
  final _ctrl  = TextEditingController();
  String? _err;
  bool _expanded = false;

  late AnimationController _animCtrl;
  late Animation<double>   _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  void _confirm() {
    final val = _ctrl.text.trim();
    if (val.isEmpty) { setState(() => _err = 'Please enter a link or code'); return; }
    widget.onCodeReceived(val);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !_expanded ? _toggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        AppTheme.card(widget.dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? AppTheme.crimson.withOpacity(0.4)
                : AppTheme.border(widget.dark),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
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
                  color: AppTheme.textPrimary(widget.dark),
                  fontSize: 17, fontWeight: FontWeight.w800,
                )),
                const SizedBox(height: 3),
                Text('Paste or type the service URL',
                  style: TextStyle(
                    color: AppTheme.textMuted(widget.dark), fontSize: 13)),
              ],
            )),
            Icon(_expanded ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
                color: AppTheme.textMuted(widget.dark), size: 22),
          ]),

          // Expanded input
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 18),
              if (_err != null) ...[
                AuthWidgets.buildErrorBanner(_err!),
                const SizedBox(height: 12),
              ],
              Container(
                decoration: BoxDecoration(
                  color:        AppTheme.surface(widget.dark),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.border(widget.dark)),
                ),
                child: Row(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.link_rounded,
                        color: AppTheme.textMuted(widget.dark), size: 18),
                  ),
                  Expanded(
                    child: TextField(
                      controller:   _ctrl,
                      autofocus:    _expanded,
                      keyboardType: TextInputType.url,
                      style: TextStyle(
                          color: AppTheme.textPrimary(widget.dark), fontSize: 14),
                      decoration: InputDecoration(
                        hintText:  'https://service.example.com/queue/abc',
                        hintStyle: TextStyle(
                            color: AppTheme.textHint(widget.dark), fontSize: 12),
                        border:         InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onSubmitted: (_) => _confirm(),
                    ),
                  ),
                  // Paste
                  GestureDetector(
                    onTap: () async {
                      final d = await Clipboard.getData('text/plain');
                      if (d?.text != null) setState(() => _ctrl.text = d!.text!);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('PASTE', style: TextStyle(
                        color: AppTheme.crimson, fontSize: 11,
                        fontWeight: FontWeight.w800, letterSpacing: 1.5,
                      )),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.crimson,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                  child: const Text('CONTINUE', style: TextStyle(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w800, letterSpacing: 2,
                  )),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// =============================================================
// QR SCANNER  BOTTOM SHEET
// =============================================================
class _QrScannerSheet extends StatefulWidget {
  final bool dark;
  final void Function(String) onScanned;
  const _QrScannerSheet({required this.dark, required this.onScanned});

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _scanned = true;
    HapticFeedback.mediumImpact();
    widget.onScanned(raw);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.88,
      decoration: BoxDecoration(
        color:        AppTheme.surface(widget.dark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 18),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color:        AppTheme.border(widget.dark),
            borderRadius: BorderRadius.circular(2)),
        ),

        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Scan QR Code', style: TextStyle(
                color: AppTheme.textPrimary(widget.dark),
                fontSize: 20, fontWeight: FontWeight.w800,
              )),
              const SizedBox(height: 3),
              Text('Align the QR code within the frame',
                style: TextStyle(color: AppTheme.textMuted(widget.dark), fontSize: 13)),
            ])),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        AppTheme.card(widget.dark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border(widget.dark)),
                ),
                child: Icon(Icons.close_rounded,
                    color: AppTheme.textMuted(widget.dark), size: 18),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Camera
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(children: [
                MobileScanner(controller: _ctrl, onDetect: _onDetect),
                Positioned.fill(child: CustomPaint(painter: _OverlayPainter())),
                // Scanned label
                if (_scanned)
                  Positioned.fill(child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 52),
                        SizedBox(height: 12),
                        Text('Code detected!', style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
                        )),
                      ],
                    )),
                  )),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ScannerBtn(
            icon:  _torchOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
            label: _torchOn ? 'Flash off' : 'Flash on',
            dark:  widget.dark,
            onTap: () { _ctrl.toggleTorch(); setState(() => _torchOn = !_torchOn); },
          ),
          const SizedBox(width: 14),
          _ScannerBtn(
            icon:  Icons.flip_camera_ios_rounded,
            label: 'Flip camera',
            dark:  widget.dark,
            onTap: () => _ctrl.switchCamera(),
          ),
        ]),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _ScannerBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     dark;
  final VoidCallback onTap;
  const _ScannerBtn({required this.icon, required this.label,
      required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color:        AppTheme.card(dark),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.border(dark)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppTheme.textMuted(dark), size: 17),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(
            color: AppTheme.textMuted(dark),
            fontSize: 13, fontWeight: FontWeight.w600,
          )),
        ]),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dim   = Paint()..color = Colors.black.withOpacity(0.40);
    final clear = Paint()..blendMode = BlendMode.clear..style = PaintingStyle.fill;
    final line  = Paint()
      ..color       = AppTheme.crimson
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap   = StrokeCap.round;

    const cr = 30.0;
    final cx = size.width / 2, cy = size.height / 2;
    final half = size.width * 0.58 / 2;
    final l = cx - half, r = cx + half, t = cy - half, b = cy + half;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), dim);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(l, t, r, b), const Radius.circular(8)),
      clear,
    );

    for (final pts in [
      [Offset(l, t + cr), Offset(l, t), Offset(l + cr, t)],
      [Offset(r - cr, t), Offset(r, t), Offset(r, t + cr)],
      [Offset(r, b - cr), Offset(r, b), Offset(r - cr, b)],
      [Offset(l + cr, b), Offset(l, b), Offset(l, b - cr)],
    ]) {
      canvas.drawPath(
        Path()..moveTo(pts[0].dx, pts[0].dy)
              ..lineTo(pts[1].dx, pts[1].dy)
              ..lineTo(pts[2].dx, pts[2].dy),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// =============================================================
// FORM PAGE — ticket details
// =============================================================
class _FormPage extends StatefulWidget {
  final bool dark;
  final AuthUser user;
  final String serviceCode;
  final String serviceName;
  final VoidCallback onBack;

  const _FormPage({
    required this.dark, required this.user,
    required this.serviceCode, required this.serviceName,
    required this.onBack,
  });

  @override
  State<_FormPage> createState() => _FormPageState();
}

enum _Priority { low, medium, high, urgent }

extension _PX on _Priority {
  String   get label => name[0].toUpperCase() + name.substring(1);
  IconData get icon  => [
    Icons.arrow_downward_rounded, Icons.remove_rounded,
    Icons.arrow_upward_rounded,   Icons.priority_high_rounded,
  ][index];
  Color get color => [
    Colors.green, Colors.blue, Colors.orange, AppTheme.crimson,
  ][index];
}

class _FormPageState extends State<_FormPage> {
  final _key       = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _api       = ApiService();

  _Priority _prio     = _Priority.medium;
  String?   _service;
  bool      _loading  = false;
  String?   _err;
  bool      _done     = false;

  static const _categories = [
    'General Support', 'Technical Issue', 'Billing & Payments',
    'Account Access', 'Product Inquiry', 'Complaint', 'Other',
  ];

  @override
  void initState() { super.initState(); _service = _categories.first; }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() { _loading = true; _err = null; });

    final res = await _api.createTicket(
      userId:      widget.user.userId,
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      notes:       _notesCtrl.text.trim(),
      priority:    _prio.name,
      service:     _service!,
      serviceCode: widget.serviceCode,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      setState(() => _done = true);
    } else {
      setState(() => _err = res['message'] ?? 'Failed to create ticket.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _SuccessPage(dark: widget.dark, onBack: widget.onBack);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _key,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 28),

          // Back + title
          Row(children: [
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color:        AppTheme.card(widget.dark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border(widget.dark)),
                ),
                child: Icon(Icons.arrow_back_rounded,
                    color: AppTheme.textMuted(widget.dark), size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Text('Ticket Details', style: TextStyle(
              color: AppTheme.textPrimary(widget.dark),
              fontSize: 22, fontWeight: FontWeight.w900,
            )),
          ]),
          const SizedBox(height: 22),

          // Service banner (from QR/link)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppTheme.crimson.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.crimson.withOpacity(0.22)),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        AppTheme.crimson.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.qr_code_rounded,
                    color: AppTheme.crimson, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SERVICE IDENTIFIED', style: TextStyle(
                    color: AppTheme.crimson, fontSize: 9,
                    fontWeight: FontWeight.w800, letterSpacing: 2,
                  )),
                  const SizedBox(height: 2),
                  Text(widget.serviceName, style: TextStyle(
                    color: AppTheme.textPrimary(widget.dark),
                    fontSize: 13, fontWeight: FontWeight.w700,
                  ), overflow: TextOverflow.ellipsis),
                ],
              )),
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color:        AppTheme.card(widget.dark),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppTheme.border(widget.dark)),
                  ),
                  child: Text('Change', style: TextStyle(
                    color: AppTheme.textMuted(widget.dark),
                    fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 22),

          if (_err != null) ...[
            AuthWidgets.buildErrorBanner(_err!),
            const SizedBox(height: 18),
          ],

          // Service type
          _Label(text: 'SERVICE TYPE', dark: widget.dark),
          const SizedBox(height: 8),
          _Dropdown(
            dark: widget.dark, value: _service, items: _categories,
            onChanged: (v) => setState(() => _service = v),
          ),
          const SizedBox(height: 18),

          // Title
          _Label(text: 'TICKET TITLE', dark: widget.dark),
          const SizedBox(height: 8),
          AuthWidgets.buildTextField(
            controller: _titleCtrl, isDark: widget.dark,
            hint: 'Short summary of your issue',
            icon: Icons.title_rounded,
            validator: (v) => (v == null || v.trim().length < 5)
                ? 'Title must be at least 5 characters' : null,
          ),
          const SizedBox(height: 18),

          // Description
          _Label(text: 'DESCRIPTION', dark: widget.dark),
          const SizedBox(height: 8),
          _MultilineField(
            controller: _descCtrl, dark: widget.dark,
            hint: 'Describe your issue in detail…', maxLines: 5,
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Please provide more detail (min 10 chars)' : null,
          ),
          const SizedBox(height: 18),

          // Priority
          _Label(text: 'PRIORITY', dark: widget.dark),
          const SizedBox(height: 10),
          _PriorityRow(
            dark: widget.dark, selected: _prio,
            onChanged: (p) => setState(() => _prio = p),
          ),
          const SizedBox(height: 18),

          // Notes
          _Label(text: 'ADDITIONAL NOTES  (optional)', dark: widget.dark),
          const SizedBox(height: 8),
          _MultilineField(
            controller: _notesCtrl, dark: widget.dark,
            hint: 'Any extra context or information…', maxLines: 3,
            validator: null,
          ),
          const SizedBox(height: 30),

          // Submit
          AuthWidgets.buildPrimaryButton(
            label: 'CREATE TICKET', isLoading: _loading, onPressed: _submit),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

// =============================================================
// REUSABLE FORM WIDGETS
// =============================================================
class _Label extends StatelessWidget {
  final String text;
  final bool dark;
  const _Label({required this.text, required this.dark});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTheme.labelStyle(dark));
}

class _Dropdown extends StatelessWidget {
  final bool dark;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  const _Dropdown({required this.dark, required this.value,
      required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          dropdownColor: AppTheme.card(dark),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMuted(dark)),
          style: TextStyle(color: AppTheme.textPrimary(dark), fontSize: 14),
          onChanged: onChanged,
          items: items.map((s) => DropdownMenuItem(
            value: s,
            child: Row(children: [
              Icon(Icons.support_agent_rounded, color: AppTheme.crimson, size: 17),
              const SizedBox(width: 10),
              Text(s),
            ]),
          )).toList(),
        ),
      ),
    );
  }
}

class _MultilineField extends StatelessWidget {
  final TextEditingController controller;
  final bool dark;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  const _MultilineField({required this.controller, required this.dark,
      required this.hint, required this.maxLines, required this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, maxLines: maxLines, validator: validator,
      style: TextStyle(color: AppTheme.textPrimary(dark), fontSize: 14),
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  TextStyle(color: AppTheme.textHint(dark), fontSize: 13),
        filled:      true, fillColor: AppTheme.card(dark),
        errorStyle:  const TextStyle(color: AppTheme.crimson, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:             _b(AppTheme.border(dark)),
        enabledBorder:      _b(AppTheme.border(dark)),
        focusedBorder:      _b(AppTheme.crimson, w: 1.5),
        errorBorder:        _b(AppTheme.crimson),
        focusedErrorBorder: _b(AppTheme.crimson, w: 1.5),
      ),
    );
  }

  OutlineInputBorder _b(Color c, {double w = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
    borderSide: BorderSide(color: c, width: w),
  );
}

class _PriorityRow extends StatelessWidget {
  final bool dark;
  final _Priority selected;
  final void Function(_Priority) onChanged;
  const _PriorityRow({required this.dark, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _Priority.values.map((p) {
        final on = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin:  const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: on ? p.color.withOpacity(0.14) : AppTheme.card(dark),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: on ? p.color : AppTheme.border(dark),
                  width: on ? 1.6 : 1,
                ),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(p.icon, color: on ? p.color : AppTheme.textMuted(dark), size: 15),
                const SizedBox(height: 4),
                Text(p.label, style: TextStyle(
                  color: on ? p.color : AppTheme.textMuted(dark),
                  fontSize: 10, fontWeight: FontWeight.w700,
                )),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================
// SUCCESS PAGE
// =============================================================
class _SuccessPage extends StatelessWidget {
  final bool dark;
  final VoidCallback onBack;
  const _SuccessPage({required this.dark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              color:        Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 42),
          ),
          const SizedBox(height: 24),
          Text('Ticket Created!', style: TextStyle(
            color: AppTheme.textPrimary(dark),
            fontSize: 26, fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 10),
          Text(
            'Your ticket has been submitted. '
            'You will be notified when it is processed.',
            style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.crimson, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
              ),
              child: const Text('CREATE ANOTHER', style: TextStyle(
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