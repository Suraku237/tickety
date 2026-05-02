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
// Responsibilities:
//   - Step 1: user picks input method (QR scan or manual link)
//   - Step 2: user fills ticket details (service, title, desc,
//             priority, notes) and submits to the API
// OOP Principle: Composition — each step is its own widget tree
// =============================================================
class CreateTicketPage extends StatefulWidget {
  final AuthUser user;
  const CreateTicketPage({super.key, required this.user});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

enum _Step { method, form }

class _CreateTicketPageState extends State<CreateTicketPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  _Step   _step        = _Step.method;
  String? _serviceCode;   // raw URL / code from QR or text input
  String? _serviceName;   // human-readable label shown in the form

  bool get isDark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Called by both input methods once a code is obtained
  // ----------------------------------------------------------
  void _onCodeReceived(String code) {
    setState(() {
      _serviceCode = code;
      _serviceName = _resolveServiceName(code);
      _step        = _Step.form;
    });
    _fadeCtrl..reset()..forward();
  }

  // Derives a readable label from the URL.
  // Replace with a real API lookup once your backend supports it.
  String _resolveServiceName(String code) {
    try {
      final uri      = Uri.parse(code);
      final host     = uri.host.replaceFirst('www.', '');
      final pathSeg  = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first : '';
      if (pathSeg.isNotEmpty) return '$host / $pathSeg';
      return host.isNotEmpty ? host : code;
    } catch (_) {
      return code;
    }
  }

  // Go back to method selection and clear previous data
  void _reset() {
    setState(() {
      _step        = _Step.method;
      _serviceCode = null;
      _serviceName = null;
    });
    _fadeCtrl..reset()..forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: _step == _Step.method
          ? _MethodStep(isDark: isDark, onCodeReceived: _onCodeReceived)
          : _FormStep(
              isDark:      isDark,
              user:        widget.user,
              serviceCode: _serviceCode!,
              serviceName: _serviceName!,
              onBack:      _reset,
            ),
    );
  }
}

// =============================================================
// STEP 1 — METHOD SELECTION
// Two tappable cards: "Scan QR Code" and "Enter a Link"
// =============================================================
class _MethodStep extends StatelessWidget {
  final bool isDark;
  final void Function(String) onCodeReceived;

  const _MethodStep({required this.isDark, required this.onCodeReceived});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // ── Page badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color:        AppTheme.crimson.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.crimson.withOpacity(0.25)),
            ),
            child: const Text('NEW TICKET', style: TextStyle(
              color: AppTheme.crimson, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 2,
            )),
          ),
          const SizedBox(height: 18),

          Text('Create\nTicket', style: TextStyle(
            color: AppTheme.textPrimary(isDark), fontSize: 38,
            fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1,
          )),
          const SizedBox(height: 8),
          Text('Choose how to locate your service',
              style: AppTheme.mutedBodyStyle(isDark)),
          const SizedBox(height: 36),

          // ── QR tile ──
          _MethodTile(
            isDark:   isDark,
            icon:     Icons.qr_code_scanner_rounded,
            title:    'Scan QR Code',
            subtitle: 'Point your camera at the service QR code',
            onTap:    () => _openQrScanner(context),
          ),
          const SizedBox(height: 14),

          // ── Link tile ──
          _MethodTile(
            isDark:   isDark,
            icon:     Icons.link_rounded,
            title:    'Enter a Link',
            subtitle: 'Paste or type the service URL manually',
            onTap:    () => _openLinkSheet(context),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _openQrScanner(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _QrScannerSheet(
        isDark:    isDark,
        onScanned: (code) { Navigator.pop(context); onCodeReceived(code); },
      ),
    );
  }

  void _openLinkSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _LinkInputSheet(
        isDark:    isDark,
        onConfirm: (link) { Navigator.pop(context); onCodeReceived(link); },
      ),
    );
  }
}

// =============================================================
// METHOD TILE  — animated pressable card
// =============================================================
class _MethodTile extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodTile({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_MethodTile> createState() => _MethodTileState();
}

class _MethodTileState extends State<_MethodTile>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:        AppTheme.card(widget.isDark),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.border(widget.isDark)),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color:        AppTheme.crimson.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: AppTheme.crimson, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: TextStyle(
                  color: AppTheme.textPrimary(widget.isDark),
                  fontSize: 16, fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 3),
                Text(widget.subtitle, style: TextStyle(
                  color: AppTheme.textMuted(widget.isDark), fontSize: 13,
                )),
              ],
            )),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted(widget.isDark), size: 22),
          ]),
        ),
      ),
    );
  }
}

// =============================================================
// QR SCANNER  BOTTOM SHEET
// Requires:  mobile_scanner: ^5.2.3  in pubspec.yaml
// Permission: android camera / ios NSCameraUsageDescription
// =============================================================
class _QrScannerSheet extends StatefulWidget {
  final bool isDark;
  final void Function(String) onScanned;

  const _QrScannerSheet({required this.isDark, required this.onScanned});

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {

  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;

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
    final sheetH = MediaQuery.of(context).size.height * 0.82;

    return Container(
      height:     sheetH,
      decoration: BoxDecoration(
        color:        AppTheme.surface(widget.isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [

        // ── Handle ──
        _sheetHandle(widget.isDark),
        const SizedBox(height: 16),

        // ── Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Scan QR Code', style: TextStyle(
                color: AppTheme.textPrimary(widget.isDark),
                fontSize: 20, fontWeight: FontWeight.w800,
              )),
              _closeButton(context, widget.isDark),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Point your camera at the service QR code to auto-fill the form',
            style: AppTheme.mutedBodyStyle(widget.isDark),
          ),
        ),
        const SizedBox(height: 20),

        // ── Camera viewport ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(children: [
                MobileScanner(controller: _ctrl, onDetect: _onDetect),
                Positioned.fill(
                  child: CustomPaint(painter: _ScanOverlayPainter()),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Torch toggle ──
        GestureDetector(
          onTap: () => _ctrl.toggleTorch(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color:        AppTheme.card(widget.isDark),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.border(widget.isDark)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.flashlight_on_rounded,
                  color: AppTheme.textMuted(widget.isDark), size: 18),
              const SizedBox(width: 8),
              Text('Toggle flashlight', style: TextStyle(
                color: AppTheme.textMuted(widget.isDark),
                fontSize: 14, fontWeight: FontWeight.w600,
              )),
            ]),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Scan-frame overlay (corners + dim) ──
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint  = Paint()..color = Colors.black.withOpacity(0.38);
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style     = PaintingStyle.fill;
    final cornerPaint = Paint()
      ..color       = AppTheme.crimson
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap   = StrokeCap.round;

    const corner = 28.0;
    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final half   = (size.width * 0.60) / 2;
    final l = cx - half;
    final r = cx + half;
    final t = cy - half;
    final b = cy + half;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), dimPaint);
    canvas.drawRect(Rect.fromLTRB(l, t, r, b), clearPaint);

    for (final pts in [
      [Offset(l, t + corner), Offset(l, t),     Offset(l + corner, t)],
      [Offset(r - corner, t), Offset(r, t),     Offset(r, t + corner)],
      [Offset(r, b - corner), Offset(r, b),     Offset(r - corner, b)],
      [Offset(l + corner, b), Offset(l, b),     Offset(l, b - corner)],
    ]) {
      canvas.drawPath(
        Path()..moveTo(pts[0].dx, pts[0].dy)
              ..lineTo(pts[1].dx, pts[1].dy)
              ..lineTo(pts[2].dx, pts[2].dy),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// =============================================================
// LINK INPUT  BOTTOM SHEET
// =============================================================
class _LinkInputSheet extends StatefulWidget {
  final bool isDark;
  final void Function(String) onConfirm;
  const _LinkInputSheet({required this.isDark, required this.onConfirm});

  @override
  State<_LinkInputSheet> createState() => _LinkInputSheetState();
}

class _LinkInputSheetState extends State<_LinkInputSheet> {

  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onConfirm() {
    final val = _ctrl.text.trim();
    if (val.isEmpty) {
      setState(() => _error = 'Please enter a service link or code');
      return;
    }
    widget.onConfirm(val);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding:    const EdgeInsets.fromLTRB(24, 0, 24, 32),
        decoration: BoxDecoration(
          color:        AppTheme.surface(widget.isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHandle(widget.isDark),
          const SizedBox(height: 4),

          Text('Enter Service Link', style: TextStyle(
            color: AppTheme.textPrimary(widget.isDark),
            fontSize: 20, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 6),
          Text('Paste the URL or code provided by the service',
              style: AppTheme.mutedBodyStyle(widget.isDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),

          if (_error != null) ...[
            AuthWidgets.buildErrorBanner(_error!),
            const SizedBox(height: 16),
          ],

          // ── URL input row ──
          Container(
            decoration: BoxDecoration(
              color:        AppTheme.card(widget.isDark),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.border(widget.isDark)),
            ),
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.link_rounded,
                    color: AppTheme.textMuted(widget.isDark), size: 20),
              ),
              Expanded(
                child: TextField(
                  controller:   _ctrl,
                  autofocus:    true,
                  keyboardType: TextInputType.url,
                  style: TextStyle(
                      color: AppTheme.textPrimary(widget.isDark),
                      fontSize: 14),
                  decoration: InputDecoration(
                    hintText:  'https://service.example.com/queue/abc',
                    hintStyle: TextStyle(
                        color: AppTheme.textHint(widget.isDark),
                        fontSize: 13),
                    border:         InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (_) => _onConfirm(),
                ),
              ),
              // ── Paste shortcut ──
              GestureDetector(
                onTap: () async {
                  final clip = await Clipboard.getData('text/plain');
                  if (clip?.text != null) setState(() => _ctrl.text = clip!.text!);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('PASTE', style: TextStyle(
                    color: AppTheme.crimson, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5,
                  )),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          AuthWidgets.buildPrimaryButton(
              label: 'CONTINUE', isLoading: false, onPressed: _onConfirm),
        ]),
      ),
    );
  }
}

// =============================================================
// STEP 2 — TICKET FORM
// =============================================================
class _FormStep extends StatefulWidget {
  final bool isDark;
  final AuthUser user;
  final String serviceCode;
  final String serviceName;
  final VoidCallback onBack;

  const _FormStep({
    required this.isDark,
    required this.user,
    required this.serviceCode,
    required this.serviceName,
    required this.onBack,
  });

  @override
  State<_FormStep> createState() => _FormStepState();
}

// ── Priority options ──
enum _Priority { low, medium, high, urgent }

extension _PriorityX on _Priority {
  String   get label   => name[0].toUpperCase() + name.substring(1);
  IconData get icon    => const [
    Icons.arrow_downward_rounded,
    Icons.remove_rounded,
    Icons.arrow_upward_rounded,
    Icons.priority_high_rounded,
  ][index];
  Color get color => const [
    Colors.green,
    Colors.blue,
    Colors.orange,
    AppTheme.crimson,
  ][index];
}

class _FormStepState extends State<_FormStep> {

  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _api       = ApiService();

  _Priority _priority        = _Priority.medium;
  String?   _selectedService;
  bool      _isLoading       = false;
  String?   _errorMessage;
  bool      _submitted       = false;

  // Service categories — replace with API fetch when ready
  static const List<String> _categories = [
    'General Support',
    'Technical Issue',
    'Billing & Payments',
    'Account Access',
    'Product Inquiry',
    'Complaint',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = _categories.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final data = await _api.createTicket(
      userId:      widget.user.userId,
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      notes:       _notesCtrl.text.trim(),
      priority:    _priority.name,
      service:     _selectedService!,
      serviceCode: widget.serviceCode,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (data['success'] == true) {
      setState(() => _submitted = true);
    } else {
      setState(() =>
          _errorMessage = data['message'] ?? 'Failed to create ticket. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _SuccessView(isDark: widget.isDark, onBack: widget.onBack);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            // ── Back + heading ──
            Row(children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color:        AppTheme.card(widget.isDark),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border(widget.isDark)),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textMuted(widget.isDark), size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Text('Ticket Details', style: TextStyle(
                color: AppTheme.textPrimary(widget.isDark),
                fontSize: 22, fontWeight: FontWeight.w900,
              )),
            ]),
            const SizedBox(height: 24),

            // ── Detected service banner ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppTheme.crimson.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.crimson.withOpacity(0.22)),
              ),
              child: Row(children: [
                const Icon(Icons.verified_rounded,
                    color: AppTheme.crimson, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SERVICE DETECTED', style: TextStyle(
                      color: AppTheme.crimson, fontSize: 10,
                      fontWeight: FontWeight.w800, letterSpacing: 1.8,
                    )),
                    const SizedBox(height: 2),
                    Text(widget.serviceName,
                      style: TextStyle(
                        color: AppTheme.textPrimary(widget.isDark),
                        fontSize: 14, fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Error ──
            if (_errorMessage != null) ...[
              AuthWidgets.buildErrorBanner(_errorMessage!),
              const SizedBox(height: 20),
            ],

            // ── Service type ──
            _label('SERVICE TYPE', widget.isDark),
            const SizedBox(height: 8),
            _ServiceDropdown(
              isDark:    widget.isDark,
              value:     _selectedService,
              items:     _categories,
              onChanged: (v) => setState(() => _selectedService = v),
            ),
            const SizedBox(height: 20),

            // ── Ticket title ──
            _label('TICKET TITLE', widget.isDark),
            const SizedBox(height: 8),
            AuthWidgets.buildTextField(
              controller: _titleCtrl,
              isDark:     widget.isDark,
              hint:       'Short summary of your issue',
              icon:       Icons.title_rounded,
              validator:  (v) => (v == null || v.trim().length < 5)
                  ? 'Title must be at least 5 characters' : null,
            ),
            const SizedBox(height: 20),

            // ── Description ──
            _label('DESCRIPTION', widget.isDark),
            const SizedBox(height: 8),
            _MultilineField(
              controller: _descCtrl,
              isDark:     widget.isDark,
              hint:       'Describe your issue in detail…',
              maxLines:   5,
              validator:  (v) => (v == null || v.trim().length < 10)
                  ? 'Please provide more detail (min 10 chars)' : null,
            ),
            const SizedBox(height: 20),

            // ── Priority ──
            _label('PRIORITY', widget.isDark),
            const SizedBox(height: 10),
            _PrioritySelector(
              isDark:    widget.isDark,
              selected:  _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 20),

            // ── Notes (optional) ──
            _label('ADDITIONAL NOTES  (optional)', widget.isDark),
            const SizedBox(height: 8),
            _MultilineField(
              controller: _notesCtrl,
              isDark:     widget.isDark,
              hint:       'Any extra context or information…',
              maxLines:   3,
              validator:  null,
            ),
            const SizedBox(height: 32),

            // ── Submit ──
            AuthWidgets.buildPrimaryButton(
              label:     'CREATE TICKET',
              isLoading: _isLoading,
              onPressed: _onSubmit,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String t, bool dark) =>
      Text(t, style: AppTheme.labelStyle(dark));
}

// =============================================================
// SERVICE DROPDOWN
// =============================================================
class _ServiceDropdown extends StatelessWidget {
  final bool isDark;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _ServiceDropdown({
    required this.isDark,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border(isDark)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:         value,
          isExpanded:    true,
          dropdownColor: AppTheme.card(isDark),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMuted(isDark), size: 22),
          style: TextStyle(
              color: AppTheme.textPrimary(isDark), fontSize: 15),
          onChanged: onChanged,
          items: items.map((s) => DropdownMenuItem(
            value: s,
            child: Row(children: [
              Icon(Icons.support_agent_rounded,
                  color: AppTheme.crimson, size: 18),
              const SizedBox(width: 10),
              Text(s),
            ]),
          )).toList(),
        ),
      ),
    );
  }
}

// =============================================================
// MULTI-LINE TEXT FIELD
// =============================================================
class _MultilineField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _MultilineField({
    required this.controller,
    required this.isDark,
    required this.hint,
    required this.maxLines,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines:   maxLines,
      validator:  validator,
      style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 14),
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  TextStyle(color: AppTheme.textHint(isDark), fontSize: 13),
        filled:      true,
        fillColor:   AppTheme.card(isDark),
        errorStyle:  const TextStyle(color: AppTheme.crimson, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:             _ob(AppTheme.border(isDark)),
        enabledBorder:      _ob(AppTheme.border(isDark)),
        focusedBorder:      _ob(AppTheme.crimson, w: 1.5),
        errorBorder:        _ob(AppTheme.crimson),
        focusedErrorBorder: _ob(AppTheme.crimson, w: 1.5),
      ),
    );
  }

  OutlineInputBorder _ob(Color c, {double w = 1.0}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
    borderSide:   BorderSide(color: c, width: w),
  );
}

// =============================================================
// PRIORITY SELECTOR  — row of 4 animated chips
// =============================================================
class _PrioritySelector extends StatelessWidget {
  final bool isDark;
  final _Priority selected;
  final void Function(_Priority) onChanged;

  const _PrioritySelector({
    required this.isDark,
    required this.selected,
    required this.onChanged,
  });

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
                color: on ? p.color.withOpacity(0.15) : AppTheme.card(isDark),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: on ? p.color : AppTheme.border(isDark),
                  width: on ? 1.5 : 1.0,
                ),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(p.icon,
                    color: on ? p.color : AppTheme.textMuted(isDark), size: 16),
                const SizedBox(height: 4),
                Text(p.label, style: TextStyle(
                  color: on ? p.color : AppTheme.textMuted(isDark),
                  fontSize: 11, fontWeight: FontWeight.w700,
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
// SUCCESS VIEW  — shown after ticket is submitted
// =============================================================
class _SuccessView extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBack;
  const _SuccessView({required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color:        Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 40),
            ),
            const SizedBox(height: 24),
            Text('Ticket Created!', style: TextStyle(
              color: AppTheme.textPrimary(isDark),
              fontSize: 26, fontWeight: FontWeight.w900,
            )),
            const SizedBox(height: 10),
            Text(
              'Your ticket has been submitted successfully. '
              'You will be notified once it is processed.',
              style: AppTheme.mutedBodyStyle(isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            AuthWidgets.buildPrimaryButton(
              label:     'CREATE ANOTHER',
              isLoading: false,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// SHARED HELPERS  (sheet handle + close button)
// =============================================================
Widget _sheetHandle(bool isDark) => Container(
  margin: const EdgeInsets.only(top: 12, bottom: 16),
  width: 40, height: 4,
  decoration: BoxDecoration(
    color:        AppTheme.border(isDark),
    borderRadius: BorderRadius.circular(2),
  ),
);

Widget _closeButton(BuildContext context, bool isDark) => GestureDetector(
  onTap: () => Navigator.pop(context),
  child: Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
      color:        AppTheme.card(isDark),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: AppTheme.border(isDark)),
    ),
    child: Icon(Icons.close_rounded,
        color: AppTheme.textMuted(isDark), size: 18),
  ),
);
