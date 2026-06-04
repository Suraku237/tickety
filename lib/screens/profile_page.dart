import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'home_page.dart';

// =============================================================
// PROFILE PAGE
// Responsibilities:
//   - Display and edit user profile (username, email)
//   - Account stats
//   - Appearance (theme toggle) — merged from old settings drawer
//   - Security (change password, notification preferences)
//   - About (About TICKETY, Privacy Policy, Terms of Service)
//     — merged from old settings drawer
//   - Danger Zone (delete account)
//   - Logout — merged from old settings drawer
//
// Changes from previous version:
//   - Appearance section added (theme toggle)
//   - About section added (About, Privacy, Terms)
//   - Logout button added at the very bottom
//   - "Edit Profile" tile removed from settings drawer (drawer gone)
//   - Settings drawer no longer exists anywhere in the app
//
// OOP Principle: Single Responsibility, Encapsulation, Composition
// =============================================================
class ProfilePage extends StatefulWidget {
  final AuthUser     user;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {

  bool get isDark => ThemeProvider().isDarkMode;
  bool _isEditing = false;

  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late AnimationController   _fadeCtrl;
  late Animation<double>     _fadeAnim;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _emailCtrl    = TextEditingController(text: widget.user.email);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _initials() {
    final name  = widget.user.username;
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    return (parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'
            : name[0])
        .toUpperCase();
  }

  void _toggleEdit() {
    if (_isEditing) {
      // TODO: call backend to save changes
      _snack('Profile updated successfully', Colors.green);
    }
    setState(() => _isEditing = !_isEditing);
  }

  void _cancelEdit() {
    _usernameCtrl.text = widget.user.username;
    _emailCtrl.text    = widget.user.email;
    setState(() => _isEditing = false);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Logout confirmation ──────────────────────────────────────
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => _LogoutDialog(
        isDark:    isDark,
        onConfirm: widget.onLogout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(children: [
          // Background glow
          Positioned(top: -60, right: -60,
            child: Container(width: 240, height: 240,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.crimson.withOpacity(0.12),
                  Colors.transparent])))),

          SafeArea(child: Column(children: [

            // ── TOP BAR ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(children: [
                Expanded(child: Text('Profile', style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontSize:   24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5))),
                GestureDetector(
                  onTap: _toggleEdit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _isEditing
                          ? AppTheme.crimson
                          : AppTheme.card(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isEditing
                            ? AppTheme.crimson
                            : AppTheme.border(isDark))),
                    child: Row(children: [
                      Icon(
                        _isEditing
                            ? Icons.check_rounded
                            : Icons.edit_outlined,
                        color: _isEditing
                            ? Colors.white
                            : AppTheme.textMuted(isDark),
                        size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _isEditing ? 'Save' : 'Edit',
                        style: TextStyle(
                          color: _isEditing
                              ? Colors.white
                              : AppTheme.textMuted(isDark),
                          fontSize:   13,
                          fontWeight: FontWeight.w700)),
                    ]))),
              ]),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── AVATAR ────────────────────────────
                    Center(
                      child: Stack(children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            shape:  BoxShape.circle,
                            color:  AppTheme.crimson.withOpacity(0.12),
                            border: Border.all(
                              color: AppTheme.crimson.withOpacity(0.4),
                              width: 2.5)),
                          child: Center(child: Text(_initials(),
                            style: const TextStyle(
                              color:      AppTheme.crimson,
                              fontSize:   30,
                              fontWeight: FontWeight.w900)))),
                        if (_isEditing)
                          Positioned(bottom: 0, right: 0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color:  AppTheme.crimson,
                                shape:  BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.surface(isDark),
                                  width: 2)),
                              child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white, size: 13))),
                      ]),
                    ),

                    const SizedBox(height: 12),

                    Center(child: Text(widget.user.username,
                      style: TextStyle(
                        color:      AppTheme.textPrimary(isDark),
                        fontSize:   18,
                        fontWeight: FontWeight.w900))),
                    const SizedBox(height: 4),
                    Center(child: Text(widget.user.email,
                      style: TextStyle(
                          color:    AppTheme.textMuted(isDark),
                          fontSize: 13))),
                    const SizedBox(height: 8),

                    // Verified badge
                    Center(child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color:        Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3))),
                      child: Row(mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_rounded,
                              color: Colors.green, size: 13),
                          SizedBox(width: 5),
                          Text('Verified Account', style: TextStyle(
                            color:      Colors.green,
                            fontSize:   11,
                            fontWeight: FontWeight.w700)),
                        ]))),

                    const SizedBox(height: 24),

                    // ── STATS ─────────────────────────────
                    Row(children: [
                      _statCard('13', 'Total Visits',
                          Icons.store_rounded),
                      const SizedBox(width: 10),
                      _statCard('2', 'Active Tickets',
                          Icons.confirmation_num_outlined),
                      const SizedBox(width: 10),
                      _statCard('Apr 2025', 'Member Since',
                          Icons.calendar_today_outlined, small: true),
                    ]),

                    const SizedBox(height: 28),

                    // ── ACCOUNT INFO ──────────────────────
                    _sLabel('ACCOUNT INFO'),
                    const SizedBox(height: 12),
                    _editField(
                      label:      'Username',
                      icon:       Icons.person_outline_rounded,
                      controller: _usernameCtrl,
                      enabled:    _isEditing),
                    const SizedBox(height: 10),
                    _editField(
                      label:        'Email Address',
                      icon:         Icons.mail_outline_rounded,
                      controller:   _emailCtrl,
                      enabled:      _isEditing,
                      keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _readOnlyField(
                      label: 'User ID',
                      icon:  Icons.fingerprint_rounded,
                      value: widget.user.userId.isEmpty
                          ? 'Not assigned'
                          : widget.user.userId),

                    if (_isEditing) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _cancelEdit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          decoration: BoxDecoration(
                            color:        AppTheme.card(isDark),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppTheme.border(isDark))),
                          child: Center(child: Text('Cancel',
                            style: TextStyle(
                              color:      AppTheme.textMuted(isDark),
                              fontSize:   14,
                              fontWeight: FontWeight.w700))))),
                    ],

                    const SizedBox(height: 28),

                    // ── APPEARANCE ────────────────────────
                    // Moved from old settings drawer
                    _sLabel('APPEARANCE'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color:        AppTheme.card(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.border(isDark))),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:        AppTheme.crimson.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(9)),
                          child: Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: AppTheme.crimson, size: 18)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDark ? 'Dark Mode' : 'Light Mode',
                              style: TextStyle(
                                color:      AppTheme.textPrimary(isDark),
                                fontSize:   14,
                                fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              isDark
                                  ? 'Switch to light theme'
                                  : 'Switch to dark theme',
                              style: TextStyle(
                                color:    AppTheme.textMuted(isDark),
                                fontSize: 12)),
                          ])),
                        // Animated toggle switch
                        GestureDetector(
                          onTap: () => ThemeProvider().toggleTheme(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 48, height: 26,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.crimson
                                  : AppTheme.border(isDark),
                              borderRadius: BorderRadius.circular(13)),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 300),
                              curve:    Curves.easeInOut,
                              alignment: isDark
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 20, height: 20,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle)))),
                )])),

                    const SizedBox(height: 28),

                    // ── SECURITY ──────────────────────────
                    _sLabel('SECURITY'),
                    const SizedBox(height: 12),
                    _actionTile(
                      icon:  Icons.lock_outline_rounded,
                      label: 'Change Password',
                      color: AppTheme.textPrimary(isDark),
                      onTap: () => showModalBottomSheet(
                        context:            context,
                        isScrollControlled: true,
                        backgroundColor:    Colors.transparent,
                        builder: (_) =>
                            _ChangePasswordSheet(isDark: isDark))),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon:  Icons.notifications_outlined,
                      label: 'Notification Preferences',
                      color: AppTheme.textPrimary(isDark),
                      onTap: () {}),

                    const SizedBox(height: 28),

                    // ── ABOUT ─────────────────────────────
                    // Moved from old settings drawer
                    _sLabel('ABOUT'),
                    const SizedBox(height: 12),
                    _actionTile(
                      icon:  Icons.info_outline_rounded,
                      label: 'About TICKETY',
                      color: AppTheme.textPrimary(isDark),
                      onTap: () => _showAboutSheet()),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon:  Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      color: AppTheme.textPrimary(isDark),
                      onTap: () {}),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon:  Icons.article_outlined,
                      label: 'Terms of Service',
                      color: AppTheme.textPrimary(isDark),
                      onTap: () {}),

                    const SizedBox(height: 28),

                    // ── DANGER ZONE ───────────────────────
                    _sLabel('DANGER ZONE'),
                    const SizedBox(height: 12),
                    _actionTile(
                      icon:  Icons.delete_outline_rounded,
                      label: 'Delete Account',
                      color: AppTheme.crimson,
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) =>
                            _DeleteAccountDialog(isDark: isDark))),

                    const SizedBox(height: 28),

                    // ── LOGOUT ────────────────────────────
                    // Moved from old settings drawer — standard placement
                    GestureDetector(
                      onTap: _confirmLogout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color:        AppTheme.crimson.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.crimson.withOpacity(0.3))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.logout_rounded,
                                color: AppTheme.crimson, size: 18),
                            SizedBox(width: 10),
                            Text('Log Out', style: TextStyle(
                              color:      AppTheme.crimson,
                              fontSize:   15,
                              fontWeight: FontWeight.w700)),
                          ]))),

                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'TICKETY v1.0.0',
                        style: TextStyle(
                          color:    AppTheme.textMuted(isDark).withOpacity(0.4),
                          fontSize: 11,
                          letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ])),
        ]),
      ),
    );
  }

  // ── About sheet ──────────────────────────────────────────────
  void _showAboutSheet() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color:        AppTheme.card(isDark),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                    color:        AppTheme.border(isDark),
                    borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color:        AppTheme.crimson,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                      color:      AppTheme.crimson.withOpacity(0.35),
                      blurRadius: 20, offset: const Offset(0, 8))]),
                  child: const Icon(Icons.confirmation_num_rounded,
                      color: Colors.white, size: 34)),
                const SizedBox(height: 18),
                Text('TICKETY', style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontSize:   24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4)),
                const SizedBox(height: 6),
                Text('Smart Queue Management System',
                  style: TextStyle(
                    color:    AppTheme.textMuted(isDark),
                    fontSize: 13)),
                const SizedBox(height: 4),
                Text('Version 1.0.0',
                  style: TextStyle(
                    color:    AppTheme.textMuted(isDark).withOpacity(0.5),
                    fontSize: 12)),
                const SizedBox(height: 20),
                Text(
                  'TICKETY helps you manage service queues and digital '
                  'tickets with a modern, intuitive interface. '
                  'Skip the physical line — queue from anywhere.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:  AppTheme.textMuted(isDark),
                    fontSize: 13,
                    height: 1.6)),
                const SizedBox(height: 24),
              ]),
          ),
        ),
      ),
    );
  }

  // ── Widget helpers ───────────────────────────────────────────

  Widget _sLabel(String t) => Text(t, style: TextStyle(
    color:      AppTheme.textMuted(isDark),
    fontSize:   11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2));

  Widget _statCard(String value, String label,
      IconData icon, {bool small = false}) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(isDark))),
      child: Column(children: [
        Icon(icon, color: AppTheme.crimson, size: 18),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
          color:      AppTheme.textPrimary(isDark),
          fontSize:   small ? 11 : 18,
          fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textMuted(isDark), fontSize: 10)),
      ])));
  }

  Widget _editField({
    required String                label,
    required IconData              icon,
    required TextEditingController controller,
    required bool                  enabled,
    TextInputType?                 keyboardType,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? AppTheme.crimson.withOpacity(0.5)
              : AppTheme.border(isDark),
          width: enabled ? 1.5 : 1)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon,
            color: enabled
                ? AppTheme.crimson
                : AppTheme.textMuted(isDark),
            size: 18),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                color:    AppTheme.textMuted(isDark),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
              const SizedBox(height: 4),
              TextField(
                controller:   controller,
                enabled:      enabled,
                keyboardType: keyboardType,
                style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontSize:   14,
                  fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  isDense:        true,
                  contentPadding: EdgeInsets.zero,
                  border:         InputBorder.none,
                  disabledBorder: InputBorder.none)),
            ])),
          if (enabled)
            Icon(Icons.edit_rounded,
                color: AppTheme.crimson.withOpacity(0.5), size: 14),
        ])));
  }

  Widget _readOnlyField({
    required String   label,
    required IconData icon,
    required String   value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(isDark))),
      child: Row(children: [
        Icon(icon, color: AppTheme.textMuted(isDark), size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(
              color:    AppTheme.textMuted(isDark),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(
              color:      AppTheme.textMuted(isDark),
              fontSize:   13,
              fontWeight: FontWeight.w500)),
          ])),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color:        AppTheme.border(isDark),
            borderRadius: BorderRadius.circular(5)),
          child: Text('READ ONLY', style: TextStyle(
            color:    AppTheme.textMuted(isDark),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1))),
      ]));
  }

  Widget _actionTile({
    required IconData     icon,
    required String       label,
    required Color        color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color:        AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(isDark))),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(
            color:      color,
            fontSize:   14,
            fontWeight: FontWeight.w600))),
          Icon(Icons.chevron_right_rounded,
              color: color.withOpacity(0.4), size: 18),
        ])));
  }
}

// =============================================================
// LOGOUT CONFIRMATION DIALOG
// OOP Principle: Single Responsibility — one job: confirm logout
// =============================================================
class _LogoutDialog extends StatelessWidget {
  final bool         isDark;
  final VoidCallback onConfirm;

  const _LogoutDialog({
    required this.isDark,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card(isDark),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:  AppTheme.crimson.withOpacity(0.1),
              shape:  BoxShape.circle,
              border: Border.all(
                  color: AppTheme.crimson.withOpacity(0.3))),
            child: const Icon(Icons.logout_rounded,
                color: AppTheme.crimson, size: 28)),
          const SizedBox(height: 16),
          Text('Log Out', style: TextStyle(
            color:      AppTheme.textPrimary(isDark),
            fontSize:   17,
            fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to log out of your account?',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textMuted(isDark),
                fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color:        AppTheme.surface(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border(isDark))),
                child: Center(child: Text('Cancel', style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontWeight: FontWeight.w700)))))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () { Navigator.pop(context); onConfirm(); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color:        AppTheme.crimson,
                  borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Log Out',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700)))))),
          ]),
        ]),
      ),
    );
  }
}

// =============================================================
// CHANGE PASSWORD SHEET
// =============================================================
class _ChangePasswordSheet extends StatefulWidget {
  final bool isDark;
  const _ChangePasswordSheet({required this.isDark});

  @override
  State<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {

  final _currentCtrl  = TextEditingController();
  final _newCtrl      = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Passwords do not match'),
        backgroundColor: AppTheme.crimson));
      return;
    }
    setState(() => _isLoading = true);
    // TODO: call backend
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Password changed successfully'),
        backgroundColor: Colors.green));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color:        AppTheme.card(isDark),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color:        AppTheme.border(isDark),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        AppTheme.crimson.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: AppTheme.crimson, size: 20)),
                const SizedBox(width: 14),
                Text('Change Password', style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontSize:   18,
                  fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 20),
              _pwField(isDark, _currentCtrl, 'Current password',
                  _obscureCurrent,
                  () => setState(() =>
                      _obscureCurrent = !_obscureCurrent)),
              const SizedBox(height: 12),
              _pwField(isDark, _newCtrl, 'New password',
                  _obscureNew,
                  () => setState(
                      () => _obscureNew = !_obscureNew)),
              const SizedBox(height: 12),
              _pwField(isDark, _confirmCtrl,
                  'Confirm new password', _obscureConfirm,
                  () => setState(() =>
                      _obscureConfirm = !_obscureConfirm)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:         AppTheme.crimson,
                    disabledBackgroundColor:
                        AppTheme.crimson.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Update Password',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   15,
                            fontWeight: FontWeight.w800)))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _pwField(bool isDark, TextEditingController ctrl,
      String hint, bool obscure, VoidCallback onToggle) {
    return TextField(
      controller:  ctrl,
      obscureText: obscure,
      style: TextStyle(
          color: AppTheme.textPrimary(isDark), fontSize: 14),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: TextStyle(color: AppTheme.textHint(isDark)),
        prefixIcon: Icon(Icons.lock_outline_rounded,
            color: AppTheme.textMuted(isDark), size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.textMuted(isDark), size: 18),
          onPressed: onToggle),
        filled:    true,
        fillColor: AppTheme.surface(isDark),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.border(isDark))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.border(isDark))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppTheme.crimson, width: 1.5))));
  }
}

// =============================================================
// DELETE ACCOUNT DIALOG
// =============================================================
class _DeleteAccountDialog extends StatelessWidget {
  final bool isDark;
  const _DeleteAccountDialog({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card(isDark),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:  AppTheme.crimson.withOpacity(0.1),
              shape:  BoxShape.circle,
              border: Border.all(
                  color: AppTheme.crimson.withOpacity(0.3))),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.crimson, size: 30)),
          const SizedBox(height: 16),
          Text('Delete Account', style: TextStyle(
            color:      AppTheme.textPrimary(isDark),
            fontSize:   18,
            fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'This will permanently delete your account and all '
            'associated data. This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color:    AppTheme.textMuted(isDark),
                fontSize: 13,
                height:   1.5)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color:        AppTheme.surface(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.border(isDark))),
                child: Center(child: Text('Cancel', style: TextStyle(
                  color:      AppTheme.textPrimary(isDark),
                  fontWeight: FontWeight.w700)))))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                // TODO: call backend delete endpoint
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color:        AppTheme.crimson,
                  borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('Delete',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700)))))),
          ]),
        ]),
      ),
    );
  }
}