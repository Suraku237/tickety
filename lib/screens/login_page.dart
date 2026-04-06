import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../utils/auth_widgets.dart';
import '../utils/theme_provider.dart';
import 'auth_page.dart';
import 'registration_page.dart';
import 'verification_page.dart';
import 'home_page.dart';

class LoginPage extends AuthPage {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends AuthPageState<LoginPage> {

  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _apiService     = ApiService();
  final _sessionService = SessionService();

  bool    _obscurePassword = true;
  bool    _isLoading       = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final data = await _apiService.login(
      email:    _emailCtrl.text.trim().toLowerCase(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (data['success'] == true) {
      await _sessionService.save(
        userId:   data['user_id']  ?? '',
        username: data['username'] ?? '',
        email:    data['email']    ?? '',
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomePage(user: AuthUser.fromMap(data)),
      ));
    } else if (data['statusCode'] == 403) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => VerificationPage(
            email: _emailCtrl.text.trim().toLowerCase()),
      ));
    } else {
      setState(() => _errorMessage = data['message'] ?? 'Login failed');
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Stack(
      children: [
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

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:        AppTheme.crimson.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                          color: AppTheme.crimson.withOpacity(0.25)),
                    ),
                    child: const Text('🎟  TICKET HOLDER ACCESS',
                      style: TextStyle(
                        color: AppTheme.crimson, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Welcome\nBack', style: TextStyle(
                    color: AppTheme.textPrimary(isDark), fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1.1, letterSpacing: -1.5,
                  )),
                  const SizedBox(height: 8),
                  Text('Sign in to manage your queue',
                      style: AppTheme.mutedBodyStyle(isDark)),
                  const SizedBox(height: 40),

                  if (_errorMessage != null) ...[
                    AuthWidgets.buildErrorBanner(_errorMessage!),
                    const SizedBox(height: 20),
                  ],

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
                    hint: 'Your password',
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
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password is required' : null,
                  ),
                  const SizedBox(height: 36),

                  AuthWidgets.buildPrimaryButton(
                    label: 'SIGN IN', isLoading: _isLoading,
                    onPressed: _onLogin,
                  ),
                  const SizedBox(height: 28),

                  Row(children: [
                    Expanded(child: Divider(
                        color: AppTheme.border(isDark), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(
                          color: AppTheme.textMuted(isDark), fontSize: 13)),
                    ),
                    Expanded(child: Divider(
                        color: AppTheme.border(isDark), thickness: 1)),
                  ]),
                  const SizedBox(height: 28),

                  AuthWidgets.buildBottomLink(
                    prefix: "Don't have an account? ",
                    linkText: 'Register', isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const RegistrationPage())),
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