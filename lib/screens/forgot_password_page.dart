import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/auth_widgets.dart';
import '../utils/theme_provider.dart';
import 'auth_page.dart';
import 'reset_otp_page.dart';

// =============================================================
// FORGOT PASSWORD PAGE  (Step 1 of 3)
// Responsibilities:
//   - Collect the user's email
//   - Call /api/forgot-password
//   - Navigate to ResetOtpPage on success
// OOP Principle: Inheritance (extends AuthPage), Single Responsibility
// =============================================================
class ForgotPasswordPage extends AuthPage {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends AuthPageState<ForgotPasswordPage> {

  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _apiService = ApiService();

  bool    _isLoading    = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final data = await _apiService.forgotPassword(
      email: _emailCtrl.text.trim().toLowerCase(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (data['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResetOtpPage(
          email: _emailCtrl.text.trim().toLowerCase(),
        ),
      ));
    } else {
      setState(() =>
          _errorMessage = data['message'] ?? 'Something went wrong. Try again.');
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Stack(children: [
      AuthWidgets.buildGlowCircle(
          size: 320, opacity: 0.14, alignment: Alignment.topLeft),
      AuthWidgets.buildGlowCircle(
          size: 220, opacity: 0.10, alignment: Alignment.bottomRight),
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Back + theme toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:        AppTheme.card(isDark),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.border(isDark))),
                        child: Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary(isDark),
                            size: 20))),
                    AuthWidgets.buildThemeToggle(
                      isDark:   isDark,
                      onToggle: () => ThemeProvider().toggleTheme()),
                  ],
                ),

                const SizedBox(height: 40),

                // Icon
                Center(
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color:  AppTheme.crimson.withOpacity(0.12),
                      shape:  BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.crimson.withOpacity(0.35),
                          width: 1.5)),
                    child: const Icon(Icons.lock_reset_rounded,
                        color: AppTheme.crimson, size: 34))),

                const SizedBox(height: 28),

                // Brand + badge
                Center(child: AuthWidgets.buildBrand(isDark)),
                const SizedBox(height: 32),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:        AppTheme.crimson.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                        color: AppTheme.crimson.withOpacity(0.25))),
                  child: const Text('🔐  PASSWORD RESET',
                    style: TextStyle(
                      color:      AppTheme.crimson,
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
                ),
                const SizedBox(height: 20),

                Text('Forgot\nPassword?', style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontSize:   40,
                  fontWeight: FontWeight.w900,
                  height:     1.1,
                  letterSpacing: -1.5)),
                const SizedBox(height: 8),
                Text('Enter your email and we\'ll send you a reset code.',
                    style: AppTheme.mutedBodyStyle(isDark)),
                const SizedBox(height: 36),

                if (_errorMessage != null) ...[
                  AuthWidgets.buildErrorBanner(_errorMessage!),
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
                const SizedBox(height: 32),

                AuthWidgets.buildPrimaryButton(
                  label:     'SEND RESET CODE',
                  isLoading: _isLoading,
                  onPressed: _onSend,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}