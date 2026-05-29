import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

// =============================================================
// ABOUT US PAGE
// Shows the team behind TICKETY.
// Each TeamMember can carry an optional local asset path OR
// a network URL for their photo.
// To add a real photo:
//   1. Drop the image in assets/images/ (any name).
//   2. Declare it in pubspec.yaml under flutter → assets.
//   3. Set imagePath: 'assets/images/yourfile.png' on the member.
// The initials avatar is the automatic fallback when no image
// is provided, so the page always looks polished.
// =============================================================

// ── Team member data class ────────────────────────────────────
class TeamMember {
  final String name;
  final String role;
  final String bio;
  final String? imagePath;   // local asset, e.g. 'assets/images/alice.jpg'
  final String? imageUrl;    // network URL (alternative to imagePath)
  final Color   accent;

  const TeamMember({
    required this.name,
    required this.role,
    required this.bio,
    this.imagePath,
    this.imageUrl,
    required this.accent,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ── Replace these with your real team members ────────────────
// Set imagePath to your local asset path, or imageUrl for a network image.
// Leave both null to show the coloured initials avatar instead.
const _kTeamMembers = <TeamMember>[
  TeamMember(
    name:      'Alex Nguyen',
    role:      'Project Lead & Backend',
    bio:       'Designed the API architecture and queue management logic. '
               'Passionate about distributed systems and clean code.',
    // imagePath: 'assets/images/alex.jpg',   ← uncomment & set your image
    accent:    Color(0xFFDC0F0F),
  ),
  TeamMember(
    name:      'Marie Kouam',
    role:      'Mobile Developer',
    bio:       'Built the Flutter client from scratch. '
               'Loves pixel-perfect UI and smooth animations.',
    // imagePath: 'assets/images/marie.jpg',
    accent:    Color(0xFF7B61FF),
  ),
  TeamMember(
    name:      'Jean-Paul Biya',
    role:      'UI / UX Designer',
    bio:       'Created the TICKETY design system and branding. '
               'Ensures every screen is intuitive and accessible.',
    // imagePath: 'assets/images/jeanpaul.jpg',
    accent:    Color(0xFF0EA5E9),
  ),
  TeamMember(
    name:      'Fatima Al-Hassan',
    role:      'QA & DevOps',
    bio:       'Owns deployment pipelines and quality assurance. '
               'Makes sure every release works in the real world.',
    // imagePath: 'assets/images/fatima.jpg',
    accent:    Color(0xFF10B981),
  ),
];

// =============================================================
// PAGE WIDGET
// =============================================================
class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage>
    with TickerProviderStateMixin {
  final List<AnimationController> _anim = [];
  final List<Animation<double>>   _fade = [];
  final List<Animation<Offset>>   _slide = [];

  bool get _dark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    ThemeProvider().addListener(_rebuild);

    for (var i = 0; i < _kTeamMembers.length; i++) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));
      _anim.add(ctrl);
      _fade.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
      _slide.add(Tween<Offset>(
        begin: const Offset(0, 0.12), end: Offset.zero,
      ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)));

      // Stagger each card's entrance
      Future.delayed(Duration(milliseconds: 80 * i + 100), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    for (final c in _anim) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface(_dark),
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                const SizedBox(height: 10),
                _buildHeroSection(),
                const SizedBox(height: 28),
                _buildTeamSection(),
                const SizedBox(height: 24),
                _buildAppInfo(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.card(_dark),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppTheme.border(_dark)),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: AppTheme.textMuted(_dark), size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Text('About Us', style: TextStyle(
          color: AppTheme.textPrimary(_dark),
          fontSize: 22, fontWeight: FontWeight.w900,
        )),
      ]),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.crimson, AppTheme.darkCrimson],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color:   AppTheme.crimson.withOpacity(0.30),
          blurRadius: 24, offset: const Offset(0, 10),
        )],
      ),
      child: Column(children: [
        // Logo
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Icon(Icons.confirmation_num_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 14),

        const Text('TICKETY', style: TextStyle(
          color: Colors.white, fontSize: 26,
          fontWeight: FontWeight.w900, letterSpacing: 6,
        )),
        const SizedBox(height: 6),
        Text('Smart Queue Management',
          style: TextStyle(
            color: Colors.white.withOpacity(0.75), fontSize: 13)),
        const SizedBox(height: 18),

        // Divider
        Container(height: 1,
            color: Colors.white.withOpacity(0.20)),
        const SizedBox(height: 18),

        Text(
          'TICKETY was built to eliminate long queues and make '
          'service access smarter, faster, and fairer for everyone.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13, height: 1.6),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildTeamSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Row(children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color: AppTheme.crimson,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text('Meet the Team', style: TextStyle(
          color: AppTheme.textPrimary(_dark),
          fontSize: 18, fontWeight: FontWeight.w900,
        )),
      ]),
      const SizedBox(height: 16),

      // Cards
      ...List.generate(_kTeamMembers.length, (i) {
        return FadeTransition(
          opacity: _fade[i],
          child: SlideTransition(
            position: _slide[i],
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TeamCard(
                member: _kTeamMembers[i],
                dark:   _dark,
              ),
            ),
          ),
        );
      }),
    ]);
  }

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(_dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(_dark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AppStat(label: 'Version',   value: '1.0.0', dark: _dark),
          _vDivider(),
          _AppStat(label: 'Platform',  value: 'Flutter', dark: _dark),
          _vDivider(),
          _AppStat(label: 'Released',  value: '2026', dark: _dark),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1, height: 32,
    color: AppTheme.border(_dark),
  );
}

// ── Team member card ──────────────────────────────────────────
class _TeamCard extends StatelessWidget {
  final TeamMember member;
  final bool       dark;
  const _TeamCard({required this.member, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar
        _MemberAvatar(member: member),
        const SizedBox(width: 14),

        // Text
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.name, style: TextStyle(
              color: AppTheme.textPrimary(dark),
              fontSize: 15, fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 3),
            Text(member.role, style: TextStyle(
              color: member.accent, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 0.5,
            )),
            const SizedBox(height: 8),
            Text(member.bio, style: TextStyle(
              color: AppTheme.textMuted(dark),
              fontSize: 12, height: 1.5,
            )),
          ],
        )),
      ]),
    );
  }
}

// ── Member avatar (image or initials fallback) ────────────────
class _MemberAvatar extends StatelessWidget {
  final TeamMember member;
  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    final size   = 56.0;
    final radius = 14.0;

    ImageProvider? provider;
    if (member.imagePath != null) {
      provider = AssetImage(member.imagePath!);
    } else if (member.imageUrl != null) {
      provider = NetworkImage(member.imageUrl!);
    }

    if (provider != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image(
          image: provider,
          width: size, height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(size, radius),
        ),
      );
    }

    return _initialsAvatar(size, radius);
  }

  Widget _initialsAvatar(double size, double radius) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color:        member.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: member.accent.withOpacity(0.35)),
      ),
      child: Center(
        child: Text(member.initials, style: TextStyle(
          color: member.accent, fontSize: 18,
          fontWeight: FontWeight.w900,
        )),
      ),
    );
  }
}

// ── App stat widget ───────────────────────────────────────────
class _AppStat extends StatelessWidget {
  final String label, value;
  final bool   dark;
  const _AppStat({
    required this.label, required this.value, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(
        color: AppTheme.textPrimary(dark),
        fontSize: 15, fontWeight: FontWeight.w800,
      )),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(
        color: AppTheme.textMuted(dark), fontSize: 11)),
    ]);
  }
}
