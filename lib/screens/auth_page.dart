import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme_provider.dart';
import '../utils/app_theme.dart';

// =============================================================
// AUTH PAGE  (Abstract Base Class)
// Responsibilities:
//   - Provide shared animation setup for all auth pages
//   - Expose isDark getter so subclasses can access theme
//   - Rebuild when ThemeProvider notifies a change
// OOP Principle: Inheritance, Abstraction, Template Method Pattern
// =============================================================
abstract class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
}

abstract class AuthPageState<T extends AuthPage> extends State<T>
    with TickerProviderStateMixin {

  late AnimationController fadeController;
  late AnimationController slideController;
  late Animation<double>   fadeAnimation;
  late Animation<Offset>   slideAnimation;

  /// Convenience getter — all subclasses use this for colors
  bool get isDark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fadeController.forward();
    slideController.forward();
    // Rebuild page when theme changes
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _initAnimations() {
    fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    fadeAnimation  = CurvedAnimation(
        parent: fadeController, curve: Curves.easeOut);
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08), end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    fadeController.dispose();
    slideController.dispose();
    super.dispose();
  }

  /// Subclasses implement this to provide their page content
  Widget buildBody(BuildContext context);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: FadeTransition(
        opacity:  fadeAnimation,
        child:    SlideTransition(
          position: slideAnimation,
          child:    buildBody(context),
        ),
      ),
    );
  }
}