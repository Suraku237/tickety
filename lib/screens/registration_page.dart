import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/auth_widgets.dart';
import '../utils/theme_provider.dart';
import 'auth_page.dart';
import 'verification_page.dart';

class RegistrationPage extends AuthPage {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends AuthPageState<RegistrationPage> {

  final _formKey      = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _apiService   = ApiService();

  bool    _obscurePassword = true;
  bool    _isLoading       = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final data = await _apiService.register(
      username: _usernameCtrl.text.trim(),
      email:    _emailCtrl.text.trim().toLowerCase(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (data['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => VerificationPage(
          email:    _emailCtrl.text.trim().toLowerCase(),
          username: _usernameCtrl.text.trim(),
        ),
      ));
    } else {
      setState(() => _errorMessage = data['message'] ?? 'Registration failed');
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Stack(
      children: [
        AuthWidgets.buildGlowCircle(
            size: 280, opacity: 0.18, alignment: Alignment.topRight),
        AuthWidgets.buildGlowCircle(
            size: 200, opacity: 0.12, alignment: Alignment.bottomLeft),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Brand + theme toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AuthWidgets.buildBrand(isDark),
                      AuthWidgets.buildThemeToggle(
                        isDark:   isDark,
                        onToggle: () => ThemeProvider().toggleTheme(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 52),

                  Text('Create\nAccount', style: AppTheme.headingStyle(isDark)),
                  const SizedBox(height: 8),
                  Text('Join the smart queue revolution',
                      style: AppTheme.mutedBodyStyle(isDark)),
                  const SizedBox(height: 40),

                  if (_errorMessage != null) ...[
                    AuthWidgets.buildErrorBanner(_errorMessage!),
                    const SizedBox(height: 20),
                  ],

                  AuthWidgets.buildLabel('USERNAME', isDark),
                  const SizedBox(height: 8),
                  AuthWidgets.buildTextField(
                    controller: _usernameCtrl, isDark: isDark,
                    hint: 'e.g. john_doe',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Username must be at least 3 characters' : null,
                  ),
                  const SizedBox(height: 20),

                  AuthWidgets.buildLabel('EMAIL ADDRESS', isDark),
                  const SizedBox(height: 8),
                  AuthWidgets.buildTextField(
                    controller: _emailCtrl, isDark: isDark,
                    hint: 'you@example.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email address' : null,
                  ),
                  const SizedBox(height: 20),

                  AuthWidgets.buildLabel('PASSWORD', isDark),
                  const SizedBox(height: 8),
                  AuthWidgets.buildTextField(
                    controller: _passwordCtrl, isDark: isDark,
                    hint: 'Min 6 chars with a number',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textMuted(isDark), size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6)
                        return 'Password must be at least 6 characters';
                      if (!v.contains(RegExp(r'\d')))
                        return 'Password must include at least one number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  AuthWidgets.buildPrimaryButton(
                    label: 'CREATE ACCOUNT', isLoading: _isLoading,
                    onPressed: _onRegister,
                  ),
                  const SizedBox(height: 28),

                  AuthWidgets.buildBottomLink(
                    prefix: 'Already have an account? ',
                    linkText: 'Sign In', isDark: isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}