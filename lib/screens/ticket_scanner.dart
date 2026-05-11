import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_theme.dart';
import '../utils/auth_widgets.dart';

// =============================================================
// TICKET SCANNER  (File 1 of 3)
// Exports two bottom-sheet widgets:
//   • QrScannerSheet  — full camera scanner with animated frame
//   • LinkInputSheet  — manual URL / code entry
// Both call onResult(code) once a valid code is obtained.
// =============================================================

// =============================================================
// QR SCANNER SHEET
// Shows a live camera feed with:
//   - Animated red scanning line bouncing inside the frame
//     so the user can clearly see something is being scanned
//   - Corner crosshair overlay with dimmed surround
//   - Success overlay once a code is detected
//   - Torch toggle + camera flip controls
// Camera lifecycle:
//   autoStart: false → started in addPostFrameCallback → stopped
//   immediately in onDetect → disposed on close.
//   This prevents double-fire after Navigator.pop.
// =============================================================
class QrScannerSheet extends StatefulWidget {
  final bool isDark;
  final void Function(String code) onResult;

  const QrScannerSheet({
    super.key,
    required this.isDark,
    required this.onResult,
  });

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet>
    with SingleTickerProviderStateMixin {

  final MobileScannerController _cam = MobileScannerController(
    autoStart: false,
  );

  // Animated scan-line
  late AnimationController _lineCtrl;
  late Animation<double>   _lineAnim;

  bool _scanned = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();

    // Scan-line animation — bounces top-to-bottom inside the frame
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut);

    // Start camera after first frame so the sheet is fully laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cam.start();
    });
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _cam.stop();
    _cam.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned || !mounted) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    _scanned = true;
    _cam.stop();                   // stop immediately — no more frames
    _lineCtrl.stop();
    HapticFeedback.mediumImpact();
    setState(() {});               // show success overlay
    widget.onResult(raw);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.88;

    return Container(
      height: h,
      decoration: BoxDecoration(
        color:        AppTheme.surface(widget.isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [

        _Handle(dark: widget.isDark),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Scan QR Code', style: TextStyle(
                  color: AppTheme.textPrimary(widget.isDark),
                  fontSize: 20, fontWeight: FontWeight.w800,
                )),
                const SizedBox(height: 2),
                Text('Hold your camera over the service QR code',
                  style: TextStyle(
                    color: AppTheme.textMuted(widget.isDark), fontSize: 13)),
              ]),
              _CloseBtn(dark: widget.isDark),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Camera viewport — fills remaining space
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(children: [

                // Live camera feed
                MobileScanner(controller: _cam, onDetect: _onDetect),

                // Dim surround + corner crosshairs
                Positioned.fill(
                  child: CustomPaint(painter: _FramePainter()),
                ),

                // Animated scan line (only while scanning)
                if (!_scanned)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _lineAnim,
                      builder: (_, __) => CustomPaint(
                        painter: _ScanLinePainter(_lineAnim.value),
                      ),
                    ),
                  ),

                // Success overlay
                if (_scanned)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.60),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 64),
                          SizedBox(height: 16),
                          Text('QR Code Detected!', style: TextStyle(
                            color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w800,
                          )),
                          SizedBox(height: 6),
                          Text('Loading service…', style: TextStyle(
                            color: Colors.white70, fontSize: 14,
                          )),
                        ],
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Camera controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _CamBtn(
            icon:  _torchOn
                ? Icons.flashlight_off_rounded
                : Icons.flashlight_on_rounded,
            label: _torchOn ? 'Flash off' : 'Flash on',
            dark:  widget.isDark,
            onTap: () {
              _cam.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          const SizedBox(width: 12),
          _CamBtn(
            icon:  Icons.flip_camera_ios_rounded,
            label: 'Flip',
            dark:  widget.isDark,
            onTap: () => _cam.switchCamera(),
          ),
        ]),
        const SizedBox(height: 28),
      ]),
    );
  }
}

// =============================================================
// LINK INPUT SHEET  (StatefulWidget — manages text + paste)
// =============================================================
class LinkInputSheet extends StatefulWidget {
  final bool isDark;
  final void Function(String code) onResult;

  const LinkInputSheet({
    super.key,
    required this.isDark,
    required this.onResult,
  });

  @override
  State<LinkInputSheet> createState() => _LinkInputSheetState();
}

class _LinkInputSheetState extends State<LinkInputSheet> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _confirm() {
    final val = _ctrl.text.trim();
    if (val.isEmpty) {
      setState(() => _error = 'Please enter a service link or code');
      return;
    }
    widget.onResult(val);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding:    const EdgeInsets.fromLTRB(24, 0, 24, 32),
        decoration: BoxDecoration(
          color:        AppTheme.surface(widget.isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _Handle(dark: widget.isDark),

          Text('Enter Service Link', style: TextStyle(
            color: AppTheme.textPrimary(widget.isDark),
            fontSize: 20, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 6),
          Text('Paste the URL or code from the service provider',
            style: TextStyle(
              color: AppTheme.textMuted(widget.isDark), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),

          if (_error != null) ...[
            AuthWidgets.buildErrorBanner(_error!),
            const SizedBox(height: 14),
          ],

          // URL field row
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
                    hintText:  'https://service.example.com/queue/…',
                    hintStyle: TextStyle(
                        color: AppTheme.textHint(widget.isDark),
                        fontSize: 13),
                    border:         InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (_) => _confirm(),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final d = await Clipboard.getData('text/plain');
                  if (d?.text != null) setState(() => _ctrl.text = d!.text!);
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
          const SizedBox(height: 22),

          AuthWidgets.buildPrimaryButton(
            label: 'CONTINUE', isLoading: false, onPressed: _confirm),
        ]),
      ),
    );
  }
}

// =============================================================
// PAINTERS
// =============================================================

// Dim surround + 4 red corner crosshairs
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dim   = Paint()..color = Colors.black.withOpacity(0.45);
    final clear = Paint()
      ..blendMode = BlendMode.clear
      ..style     = PaintingStyle.fill;
    final corner = Paint()
      ..color       = AppTheme.crimson
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap   = StrokeCap.round;

    const arm  = 28.0;
    final cx   = size.width / 2;
    final cy   = size.height / 2;
    final half = size.width * 0.60 / 2;
    final l = cx - half, r = cx + half, t = cy - half, b = cy + half;

    // Dim everything
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), dim);

    // Clear the scan window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(l, t, r, b), const Radius.circular(8)),
      clear,
    );

    // Four corner L-shapes
    for (final pts in [
      [Offset(l, t + arm), Offset(l, t), Offset(l + arm, t)],
      [Offset(r - arm, t), Offset(r, t), Offset(r, t + arm)],
      [Offset(r, b - arm), Offset(r, b), Offset(r - arm, b)],
      [Offset(l + arm, b), Offset(l, b), Offset(l, b - arm)],
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..lineTo(pts[1].dx, pts[1].dy)
          ..lineTo(pts[2].dx, pts[2].dy),
        corner,
      );
    }
  }

  @override
  bool shouldRepaint(_FramePainter _) => false;
}

// Animated horizontal red line inside the scan window
class _ScanLinePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 driven by animation
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width / 2;
    final cy   = size.height / 2;
    final half = size.width * 0.60 / 2;
    final l = cx - half, r = cx + half;
    final t = cy - half, b = cy + half;

    // Interpolate y inside the scan window
    final y = t + (b - t) * progress;

    // Glowing line: wide faint + thin bright
    canvas.drawLine(
      Offset(l + 4, y), Offset(r - 4, y),
      Paint()
        ..color       = AppTheme.crimson.withOpacity(0.25)
        ..strokeWidth = 6
        ..strokeCap   = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(l + 4, y), Offset(r - 4, y),
      Paint()
        ..color       = AppTheme.crimson
        ..strokeWidth = 2
        ..strokeCap   = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

// =============================================================
// SHARED SMALL STATELESS WIDGETS
// =============================================================

class _Handle extends StatelessWidget {
  final bool dark;
  const _Handle({required this.dark});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 14),
    width: 40, height: 4,
    decoration: BoxDecoration(
      color:        AppTheme.border(dark),
      borderRadius: BorderRadius.circular(2)),
  );
}

class _CloseBtn extends StatelessWidget {
  final bool dark;
  const _CloseBtn({required this.dark});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Icon(Icons.close_rounded,
          color: AppTheme.textMuted(dark), size: 18),
    ),
  );
}

class _CamBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     dark;
  final VoidCallback onTap;
  const _CamBtn({required this.icon, required this.label,
      required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
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
          fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}