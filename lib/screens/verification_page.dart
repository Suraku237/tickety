import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../utils/auth_widgets.dart';
import 'auth_page.dart';
import 'home_page.dart';

// =============================================================
// VERIFICATION PAGE
// Responsibilities:
//   - Accept 6-digit OTP input from the user
//   - Delegate verify/resend calls to ApiService
//   - Save session via SessionService after successful verification
//   - Navigate to HomePage after success
// OOP Principle: Inheritance (extends AuthPage), Single Responsibility
// =============================================================
class VerificationPage extends AuthPage {
  final String  email;
  final String? username;
  const VerificationPage({super.key, required this.email, this.username});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends AuthPageState<VerificationPage> {

  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  final _apiService     = ApiService();
  final _sessionService = SessionService();

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  bool    _isLoading      = false;
  bool    _isResending    = false;
  String? _errorMessage;
  String? _successMessage;
  int     _resendCooldown = 60;
  Timer?  _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startCooldown(60);
  }

  void _startCooldown(int seconds) {
    setState(() => _resendCooldown = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 0) t.cancel();
      else setState(() => _resendCooldown--);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cooldownTimer?.cancel();
    for (final c in _digitControllers) c.dispose();
    for (final f in _focusNodes)       f.dispose();
    super.dispose();
  }

  String get _otpCode => _digitControllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) _focusNodes[index + 1].requestFocus();
    if (_otpCode.length == 6) {
      FocusScope.of(context).unfocus();
      _onVerify();
    }
  }

  void _onBackspace(int index) {
    if (_digitControllers[index].text.isEmpty && index > 0) {
      _digitControllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _clearDigits() {
    for (final c in _digitControllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  Future<void> _onVerify() async {
    if (_otpCode.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      return;
    }
    setState(() {
      _isLoading = true; _errorMessage = null; _successMessage = null;
    });

    final data = await _apiService.verifyEmail(
      email: widget.email,
      code:  _otpCode,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (data['success'] == true) {
      setState(() => _successMessage = 'Email verified! Redirecting...');

      final resolvedUsername =
          widget.username ?? widget.email.split('@')[0];

      // Save session so user stays logged in
      await _sessionService.save(
        userId:   '',
        username: resolvedUsername,
        email:    widget.email,
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            user: AuthUser(
              userId:   '',
              username: resolvedUsername,
              email:    widget.email,
            ),
          ),
        ),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = data['message'] ?? 'Invalid code');
      _clearDigits();
    }
  }

  Future<void> _onResend() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() {
      _isResending = true; _errorMessage = null; _successMessage = null;
    });

    final data = await _apiService.resendOtp(email: widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (data['success'] == true) {
      setState(() => _successMessage = 'A new code has been sent.');
      _startCooldown(60);
      _clearDigits();
    } else {
      setState(() => _errorMessage = data['message'] ?? 'Could not resend code');
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Stack(
      children: [
        AuthWidgets.buildGlowCircle(
            size: 300, opacity: 0.15, alignment: Alignment.topCenter),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        AppTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary, size: 20),
                  ),
                ),

                const SizedBox(height: 40),

                Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color:  AppTheme.crimson.withOpacity(0.12),
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.crimson.withOpacity(0.35),
                            width: 1.5),
                      ),
                      child: const Icon(Icons.mark_email_read_outlined,
                          color: AppTheme.crimson, size: 36),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Center(
                  child: Text('Verify Your Email',
                    style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 28,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text('We sent a 6-digit code to',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(widget.email,
                    style: const TextStyle(
                        color: AppTheme.crimson,
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 40),

                if (_errorMessage != null) ...[
                  AuthWidgets.buildErrorBanner(_errorMessage!),
                  const SizedBox(height: 20),
                ],
                if (_successMessage != null) ...[
                  AuthWidgets.buildSuccessBanner(_successMessage!),
                  const SizedBox(height: 20),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, _buildDigitBox),
                ),

                const SizedBox(height: 36),

                AuthWidgets.buildPrimaryButton(
                  label:     'VERIFY CODE',
                  isLoading: _isLoading,
                  onPressed: _onVerify,
                ),

                const SizedBox(height: 28),

                Center(
                  child: GestureDetector(
                    onTap: _resendCooldown == 0 ? _onResend : null,
                    child: _isResending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.crimson))
                        : RichText(
                            text: TextSpan(
                              text: "Didn't receive a code? ",
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: _resendCooldown > 0
                                      ? 'Resend in ${_resendCooldown}s'
                                      : 'Resend',
                                  style: TextStyle(
                                    color: _resendCooldown > 0
                                        ? AppTheme.textMuted
                                        : AppTheme.crimson,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: Text('Code expires in 10 minutes',
                    style: TextStyle(
                        color: AppTheme.textMuted.withOpacity(0.5),
                        fontSize: 12),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 48, height: 58,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            _onBackspace(index);
          }
        },
        child: TextFormField(
          controller:      _digitControllers[index],
          focusNode:       _focusNodes[index],
          maxLength:       1,
          textAlign:       TextAlign.center,
          keyboardType:    TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22, fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            counterText:    '',
            filled:         true,
            fillColor:      AppTheme.card,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:   const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:   const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:   const BorderSide(
                    color: AppTheme.crimson, width: 2)),
          ),
          onChanged: (v) => _onDigitChanged(index, v),
        ),
      ),
    );
  }
}