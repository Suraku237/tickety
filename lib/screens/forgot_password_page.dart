import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/auth_widgets.dart';
import '../utils/theme_provider.dart';
import 'auth_page.dart';
import 'login_page.dart';

// =============================================================
// FORGOT PASSWORD PAGE
// Two-step flow:
//   Step 1 — user enters their email → POST /forgot-password
//   Step 2 — user enters the 6-digit OTP  → POST /reset-password
// On success, navigates back to LoginPage with a success banner.
//
// NOTE: The backend must implement:
//   POST /api/forgot-password  { email }
//     → { success: true }  (sends OTP email)
//   POST /api/reset-password   { email, code, new_password }
//     → { success: true }
//
// Add the two ApiService calls below once the endpoints are live.
// The UI is fully functional and ready to plug in.
// =============================================================
class ForgotPasswordPage extends AuthPage {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum _FPStep { email, otp }

class _ForgotPasswordPageState extends AuthPageState<ForgotPasswordPage> {
  final _api = ApiService();

  _FPStep _step = _FPStep.email;

  // Step 1
  final _emailCtrl = TextEditingController();
  final _emailKey  = GlobalKey<FormState>();

  // Step 2
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus =
      List.generate(6, (_) => FocusNode());
  final _pwCtrl    = TextEditingController();
  final _pwConfCtrl = TextEditingController();
  bool _obscurePw  = true;
  bool _obscurePwConf = true;

  bool    _loading         = false;
  String? _error;
  String? _success;
  String  _email           = '';
  int     _resendCooldown  = 60;
  Timer?  _cooldownTimer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus)  f.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int secs) {
    setState(() => _resendCooldown = secs);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 0) { t.cancel(); return; }
      setState(() => _resendCooldown--);
    });
  }

  String get _otpCode => _otpCtrls.map((c) => c.text).join();

  // ── Step 1: request OTP ───────────────────────────────────

  Future<void> _requestReset() async {
    if (!_emailKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim().toLowerCase();
    setState(() { _loading = true; _error = null; });

    // TODO: replace with real endpoint once backend is ready
    // final data = await _api.forgotPassword(email: email);
    await Future.delayed(const Duration(milliseconds: 800)); // ← remove when wired
    final data = {'success': true};                          // ← remove when wired

    if (!mounted) return;
    setState(() => _loading = false);

    if (data['success'] == true) {
      setState(() {
        _email = email;
        _step  = _FPStep.otp;
        _error = null;
      });
      _startCooldown(60);
    } else {
      setState(() =>
          _error = (data['message'] as String?) ??
              'No account found with that email.');
    }
  }

  // ── Step 2: submit new password with OTP ─────────────────

  Future<void> _resetPassword() async {
    if (_otpCode.length < 6) {
      setState(() => _error = 'Enter the complete 6-digit code');
      return;
    }
    if (_pwCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (_pwCtrl.text != _pwConfCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = null; });

    // TODO: replace with real endpoint
    // final data = await _api.resetPassword(
    //   email: _email, code: _otpCode,
    //   newPassword: _pwCtrl.text,
    // );
    await Future.delayed(const Duration(milliseconds: 800));
    final data = {'success': true};

    if (!mounted) return;
    setState(() => _loading = false);

    if (data['success'] == true) {
      _cooldownTimer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (r) => false,
      );
    } else {
      setState(() =>
          _error = (data['message'] as String?) ?? 'Invalid code. Try again.');
      _clearOtp();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    setState(() { _loading = true; _error = null; });

    // TODO: await _api.resendOtp(email: _email);
    await Future.delayed(const Duration(milliseconds: 600));
    final data = {'success': true};

    if (!mounted) return;
    setState(() => _loading = false);
    if (data['success'] == true) {
      setState(() => _success = 'A new code was sent.');
      _clearOtp();
      _startCooldown(60);
    } else {
      setState(() => _error = 'Could not resend code.');
    }
  }

  void _clearOtp() {
    for (final c in _otpCtrls) c.clear();
    _otpFocus[0].requestFocus();
  }

  void _onOtpDigit(int idx, String val) {
    if (val.length == 1 && idx < 5) {
      _otpFocus[idx + 1].requestFocus();
    }
    if (_otpCode.length == 6) {
      FocusScope.of(context).unfocus();
    }
  }

  void _onOtpKeyEvent(int idx, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpCtrls[idx].text.isEmpty && idx > 0) {
        _otpCtrls[idx - 1].clear();
        _otpFocus[idx - 1].requestFocus();
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget buildBody(BuildContext context) {
    return Stack(children: [
      AuthWidgets.buildGlowCircle(
          size: 300, opacity: 0.12, alignment: Alignment.topRight),
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _step == _FPStep.email
              ? _buildEmailStep()
              : _buildOtpStep(),
        ),
      ),
    ]);
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),

        // Top bar
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.card(isDark),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border(isDark)),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary(isDark), size: 20),
            ),
          ),
          AuthWidgets.buildThemeToggle(
            isDark:   isDark,
            onToggle: () => ThemeProvider().toggleTheme(),
          ),
        ]),

        const SizedBox(height: 40),

        // Icon
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color:  AppTheme.crimson.withOpacity(0.12),
              shape:  BoxShape.circle,
              border: Border.all(
                  color: AppTheme.crimson.withOpacity(0.35), width: 1.5),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: AppTheme.crimson, size: 36),
          ),
        ),
        const SizedBox(height: 28),

        Center(child: Text('Forgot Password?', style: TextStyle(
          color: AppTheme.textPrimary(isDark), fontSize: 28,
          fontWeight: FontWeight.w900, letterSpacing: -0.5,
        ))),
        const SizedBox(height: 10),
        Center(child: Text(
          'Enter your email address and we will\nsend you a reset code.',
          style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 14),
          textAlign: TextAlign.center,
        )),

        const SizedBox(height: 36),

        if (_error != null) ...[
          AuthWidgets.buildErrorBanner(_error!),
          const SizedBox(height: 20),
        ],

        AuthWidgets.buildLabel('EMAIL ADDRESS', isDark),
        const SizedBox(height: 8),
        AuthWidgets.buildTextField(
          controller:   _emailCtrl,
          isDark:       isDark,
          hint:         'you@example.com',
          icon:         Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => (v == null || !v.contains('@'))
              ? 'Enter a valid email address' : null,
        ),
        const SizedBox(height: 28),

        AuthWidgets.buildPrimaryButton(
          label:     'SEND RESET CODE',
          isLoading: _loading,
          onPressed: _requestReset,
        ),
        const SizedBox(height: 28),

        AuthWidgets.buildBottomLink(
          prefix:   'Remember your password? ',
          linkText: 'Sign In',
          isDark:   isDark,
          onTap:    () => Navigator.pop(context),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildOtpStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),

      // Top bar
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(
          onTap: () => setState(() {
            _step  = _FPStep.email;
            _error = null;
            _clearOtp();
          }),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.card(isDark),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border(isDark)),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: AppTheme.textPrimary(isDark), size: 20),
          ),
        ),
        AuthWidgets.buildThemeToggle(
          isDark:   isDark,
          onToggle: () => ThemeProvider().toggleTheme(),
        ),
      ]),

      const SizedBox(height: 40),

      // Icon
      Center(
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color:  AppTheme.crimson.withOpacity(0.12),
            shape:  BoxShape.circle,
            border: Border.all(
                color: AppTheme.crimson.withOpacity(0.35), width: 1.5),
          ),
          child: const Icon(Icons.key_rounded,
              color: AppTheme.crimson, size: 34),
        ),
      ),
      const SizedBox(height: 28),

      Center(child: Text('Enter Reset Code', style: TextStyle(
        color: AppTheme.textPrimary(isDark), fontSize: 28,
        fontWeight: FontWeight.w900, letterSpacing: -0.5,
      ))),
      const SizedBox(height: 10),
      Center(child: Text('Code sent to', style: TextStyle(
          color: AppTheme.textMuted(isDark), fontSize: 14))),
      const SizedBox(height: 4),
      Center(child: Text(_email, style: const TextStyle(
          color: AppTheme.crimson,
          fontSize: 14, fontWeight: FontWeight.w600))),

      const SizedBox(height: 36),

      if (_error != null) ...[
        AuthWidgets.buildErrorBanner(_error!),
        const SizedBox(height: 16),
      ],
      if (_success != null) ...[
        AuthWidgets.buildSuccessBanner(_success!),
        const SizedBox(height: 16),
      ],

      // OTP boxes
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) => SizedBox(
          width: 48, height: 58,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (e) => _onOtpKeyEvent(i, e),
            child: TextFormField(
              controller:      _otpCtrls[i],
              focusNode:       _otpFocus[i],
              maxLength:       1,
              textAlign:       TextAlign.center,
              keyboardType:    TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                color: AppTheme.textPrimary(isDark),
                fontSize: 22, fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled:      true,
                fillColor:   AppTheme.card(isDark),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppTheme.border(isDark))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppTheme.border(isDark))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: const BorderSide(
                        color: AppTheme.crimson, width: 2)),
              ),
              onChanged: (v) => _onOtpDigit(i, v),
            ),
          ),
        )),
      ),

      const SizedBox(height: 28),

      // New password
      AuthWidgets.buildLabel('NEW PASSWORD', isDark),
      const SizedBox(height: 8),
      AuthWidgets.buildTextField(
        controller: _pwCtrl,
        isDark:     isDark,
        hint:       'At least 6 characters',
        icon:       Icons.lock_outline_rounded,
        obscure:    _obscurePw,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePw ? Icons.visibility_off_outlined
                       : Icons.visibility_outlined,
            color: AppTheme.textMuted(isDark), size: 20,
          ),
          onPressed: () => setState(() => _obscurePw = !_obscurePw),
        ),
      ),
      const SizedBox(height: 16),

      AuthWidgets.buildLabel('CONFIRM NEW PASSWORD', isDark),
      const SizedBox(height: 8),
      AuthWidgets.buildTextField(
        controller: _pwConfCtrl,
        isDark:     isDark,
        hint:       'Repeat your new password',
        icon:       Icons.lock_outline_rounded,
        obscure:    _obscurePwConf,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePwConf ? Icons.visibility_off_outlined
                           : Icons.visibility_outlined,
            color: AppTheme.textMuted(isDark), size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePwConf = !_obscurePwConf),
        ),
      ),
      const SizedBox(height: 28),

      AuthWidgets.buildPrimaryButton(
        label:     'RESET PASSWORD',
        isLoading: _loading,
        onPressed: _resetPassword,
      ),
      const SizedBox(height: 24),

      // Resend link
      Center(
        child: GestureDetector(
          onTap: _resendCooldown == 0 ? _resendOtp : null,
          child: RichText(text: TextSpan(
            text:  "Didn't get a code? ",
            style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 14),
            children: [TextSpan(
              text: _resendCooldown > 0
                  ? 'Resend in ${_resendCooldown}s'
                  : 'Resend',
              style: TextStyle(
                color: _resendCooldown > 0
                    ? AppTheme.textMuted(isDark)
                    : AppTheme.crimson,
                fontWeight: FontWeight.w700,
              ),
            )],
          )),
        ),
      ),
      const SizedBox(height: 40),
    ]);
  }
}
