import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// =============================================================
// AUTH PAGE  (Abstract Base Class)
// Responsibilities:
//   - Provide shared animation setup for all auth pages
//   - Enforce a common system UI overlay style
//   - Define buildBody() contract that subclasses must implement
// OOP Principle: Inheritance, Abstraction, Template Method Pattern
// =============================================================
abstract class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
}

abstract class AuthPageState<T extends AuthPage> extends State<T>
    with TickerProviderStateMixin {

  // Shared animation controllers
  late AnimationController fadeController;
  late AnimationController slideController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fadeController.forward();
    slideController.forward();
  }

  void _initAnimations() {
    fadeController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    slideController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    );
    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve:  Curves.easeOut,
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: slideController,
      curve:  Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    fadeController.dispose();
    slideController.dispose();
    super.dispose();
  }

  /// Subclasses implement this to provide their page content
  Widget buildBody(BuildContext context);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:           Colors.transparent,
      statusBarIconBrightness:  Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FadeTransition(
        opacity: fadeAnimation,
        child:   SlideTransition(
          position: slideAnimation,
          child:    buildBody(context),
        ),
      ),
    );
  }
}