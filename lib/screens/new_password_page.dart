import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/auth_widgets.dart';
import '../utils/theme_provider.dart';
import 'auth_page.dart';
import 'login_page.dart';

// =============================================================
// NEW PASSWORD PAGE  (Step 3 of 3)
// Responsibilities:
//   - Accept a new password + confirmation
//   - Validate client-side (min length, match)
//   - Call /api/reset-password (hashing done server-side)
//   - Navigate back to LoginPage on success
// OOP Principle: Inheritance (extends AuthPage), Single Responsibility
// =============================================================
class NewPasswordPage extends AuthPage {
  final String email;
  final String code;     // verified OTP kept to re-authenticate the reset

  const NewPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends AuthPageState<NewPasswordPage> {

  final _formKey        = GlobalKey<FormState>();
  final _passwordCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  final _apiService     = ApiService();

  bool    _obscurePassword = true;
  bool    _obscureConfirm  = true;
  bool    _isLoading       = false;
  bool    _success         = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final data = await _apiService.resetPassword(
      email:       widget.email,
      code:        widget.code,
      newPassword: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (data['success'] == true) {
      setState(() => _success = true);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      // Pop all auth stack back to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else {
      setState(() =>
          _errorMessage = data['message'] ?? 'Could not reset password. Try again.');
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

                // Success state replaces form
                if (_success) ...[
                  const SizedBox(height: 60),
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color:  Colors.green.withOpacity(0.15),
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: Colors.green.withOpacity(0.4),
                            width: 1.5)),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.green, size: 40))),
                  const SizedBox(height: 24),
                  Center(child: Text('Password Reset!', style: TextStyle(
                    color:      AppTheme.textPrimary(isDark),
                    fontSize:   26,
                    fontWeight: FontWeight.w900))),
                  const SizedBox(height: 10),
                  Center(child: Text('Redirecting you to login…',
                    style: TextStyle(
                        color: AppTheme.textMuted(isDark),
                        fontSize: 14))),
                ] else ...[

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
                      child: const Icon(Icons.lock_open_rounded,
                          color: AppTheme.crimson, size: 34))),

                  const SizedBox(height: 28),

                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:        AppTheme.crimson.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                          color: AppTheme.crimson.withOpacity(0.25))),
                    child: const Text('🔑  NEW PASSWORD',
                      style: TextStyle(
                        color:      AppTheme.crimson,
                        fontSize:   11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                  ),
                  const SizedBox(height: 20),

                  Text('Create New\nPassword', style: TextStyle(
                    color:      AppTheme.textPrimary(isDark),
                    fontSize:   40,
                    fontWeight: FontWeight.w900,
                    height:     1.1,
                    letterSpacing: -1.5)),
                  const SizedBox(height: 8),
                  Text('Your new password must be at least 6 characters.',
                      style: AppTheme.mutedBodyStyle(isDark)),
                  const SizedBox(height: 36),

                  if (_errorMessage != null) ...[
                    AuthWidgets.buildErrorBanner(_errorMessage!),
                    const SizedBox(height: 20),
                  ],

                  AuthWidgets.buildLabel('NEW PASSWORD', isDark),
                  const SizedBox(height: 8),
                  AuthWidgets.buildTextField(
                    controller: _passwordCtrl,
                    isDark:     isDark,
                    hint:       'At least 6 characters',
                    icon:       Icons.lock_outline_rounded,
                    obscure:    _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textMuted(isDark), size: 20),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6)           return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  AuthWidgets.buildLabel('CONFIRM PASSWORD', isDark),
                  const SizedBox(height: 8),
                  AuthWidgets.buildTextField(
                    controller: _confirmCtrl,
                    isDark:     isDark,
                    hint:       'Repeat your password',
                    icon:       Icons.lock_outline_rounded,
                    obscure:    _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textMuted(isDark), size: 20),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm your password';
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  AuthWidgets.buildPrimaryButton(
                    label:     'RESET PASSWORD',
                    isLoading: _isLoading,
                    onPressed: _onReset,
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}