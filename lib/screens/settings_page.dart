import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'home_page.dart';

// =============================================================
// SETTINGS PAGE
// =============================================================
class SettingsPage extends StatefulWidget {
  final AuthUser user;
  final VoidCallback onLogout;
  const SettingsPage({super.key, required this.user, required this.onLogout});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool get _dark => ThemeProvider().isDarkMode;

  bool _notifEnabled  = true;
  bool _emailNotif    = true;
  bool _biometricLock = false;

  @override
  void initState() {
    super.initState();
    ThemeProvider().addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    ThemeProvider().removeListener(_rebuild);
    super.dispose();
  }

  String _initials() {
    if (widget.user.username.isEmpty) return '?';
    final p = widget.user.username.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : widget.user.username[0].toUpperCase();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card(_dark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log out?', style: TextStyle(
          color: AppTheme.textPrimary(_dark), fontWeight: FontWeight.w800)),
        content: Text('You will need to sign in again to access your tickets.',
          style: TextStyle(color: AppTheme.textMuted(_dark))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted(_dark))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out',
                style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(bottom: 0, right: -60,
        child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.crimson.withOpacity(0.07), Colors.transparent])))),

      SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),

          // Header
          Text('Settings', style: TextStyle(
            color: AppTheme.textPrimary(_dark), fontSize: 28,
            fontWeight: FontWeight.w900, letterSpacing: -0.5,
          )),
          const SizedBox(height: 24),

          // Profile card
          _ProfileCard(
            user: widget.user, dark: _dark, initials: _initials()),
          const SizedBox(height: 28),

          // Appearance
          _SectionLabel(label: 'APPEARANCE', dark: _dark),
          const SizedBox(height: 10),
          _SettingsCard(dark: _dark, children: [
            _SwitchTile(
              dark:   _dark,
              icon:   _dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color:  _dark ? const Color(0xFF7B61FF) : Colors.orange,
              title:  'Dark Mode',
              sub:    _dark ? 'Currently using dark theme' : 'Currently using light theme',
              value:  _dark,
              onChanged: (_) => ThemeProvider().toggleTheme(),
            ),
          ]),
          const SizedBox(height: 20),

          // Notifications
          _SectionLabel(label: 'NOTIFICATIONS', dark: _dark),
          const SizedBox(height: 10),
          _SettingsCard(dark: _dark, children: [
            _SwitchTile(
              dark: _dark, icon: Icons.notifications_rounded, color: Colors.orange,
              title: 'Push Notifications',
              sub:   'Alerts for ticket status changes',
              value: _notifEnabled,
              onChanged: (v) => setState(() => _notifEnabled = v),
            ),
            _Divider(dark: _dark),
            _SwitchTile(
              dark: _dark, icon: Icons.mail_outline_rounded, color: Colors.blue,
              title: 'Email Notifications',
              sub:   'Receive updates via email',
              value: _emailNotif,
              onChanged: (v) => setState(() => _emailNotif = v),
            ),
          ]),
          const SizedBox(height: 20),

          // Security
          _SectionLabel(label: 'SECURITY', dark: _dark),
          const SizedBox(height: 10),
          _SettingsCard(dark: _dark, children: [
            _SwitchTile(
              dark: _dark, icon: Icons.fingerprint_rounded, color: Colors.green,
              title: 'Biometric Lock',
              sub:   'Use fingerprint or face ID',
              value: _biometricLock,
              onChanged: (v) => setState(() => _biometricLock = v),
            ),
            _Divider(dark: _dark),
            _ActionTile(
              dark:  _dark,
              icon:  Icons.lock_outline_rounded,
              color: Colors.teal,
              title: 'Change Password',
              sub:   'Update your account password',
              onTap: () => _showComingSoon('Change Password'),
            ),
          ]),
          const SizedBox(height: 20),

          // About
          _SectionLabel(label: 'ABOUT', dark: _dark),
          const SizedBox(height: 10),
          _SettingsCard(dark: _dark, children: [
            _ActionTile(
              dark:  _dark, icon: Icons.info_outline_rounded, color: Colors.indigo,
              title: 'App Version', sub: 'TICKETY v1.0.0', onTap: () {},
              trailing: Text('v1.0.0', style: TextStyle(
                color: AppTheme.textMuted(_dark), fontSize: 13)),
            ),
            _Divider(dark: _dark),
            _ActionTile(
              dark:  _dark, icon: Icons.privacy_tip_outlined, color: Colors.purple,
              title: 'Privacy Policy', sub: 'Read our privacy policy',
              onTap: () => _showComingSoon('Privacy Policy'),
            ),
            _Divider(dark: _dark),
            _ActionTile(
              dark:  _dark, icon: Icons.article_outlined, color: Colors.brown,
              title: 'Terms of Service', sub: 'Read terms of service',
              onTap: () => _showComingSoon('Terms of Service'),
            ),
          ]),
          const SizedBox(height: 20),

          // Danger zone
          _SectionLabel(label: 'ACCOUNT', dark: _dark),
          const SizedBox(height: 10),
          _SettingsCard(dark: _dark, children: [
            _ActionTile(
              dark:  _dark,
              icon:  Icons.logout_rounded,
              color: AppTheme.crimson,
              title: 'Log Out',
              sub:   'Sign out of your account',
              onTap: _confirmLogout,
              titleColor: AppTheme.crimson,
            ),
          ]),
          const SizedBox(height: 36),

          // Footer
          Center(child: Text(
            'TICKETY · Made with ❤️ · v1.0.0',
            style: TextStyle(
              color: AppTheme.textMuted(_dark).withOpacity(0.4),
              fontSize: 11,
            ),
          )),
          const SizedBox(height: 24),
        ]),
      )),
    ]);
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — coming soon'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.card(_dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// =============================================================
// PROFILE CARD
// =============================================================
class _ProfileCard extends StatelessWidget {
  final AuthUser user;
  final bool dark;
  final String initials;
  const _ProfileCard({required this.user, required this.dark, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.crimson, AppTheme.darkCrimson],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color: AppTheme.crimson.withOpacity(0.28),
          blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color:  Colors.white.withOpacity(0.2),
            shape:  BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          ),
          child: Center(child: Text(initials, style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900,
          ))),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.username.isNotEmpty ? user.username : 'User',
              style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(user.email, style: TextStyle(
              color: Colors.white.withOpacity(0.75), fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.verified_rounded, color: Colors.white, size: 13),
            SizedBox(width: 4),
            Text('Active', style: TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

// =============================================================
// SETTINGS CARD
// =============================================================
class _SettingsCard extends StatelessWidget {
  final bool dark;
  final List<Widget> children;
  const _SettingsCard({required this.dark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.card(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Column(children: children),
    );
  }
}

// =============================================================
// SECTION LABEL
// =============================================================
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool dark;
  const _SectionLabel({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(
    color: AppTheme.textMuted(dark), fontSize: 11,
    fontWeight: FontWeight.w700, letterSpacing: 2,
  ));
}

// =============================================================
// SWITCH TILE
// =============================================================
class _SwitchTile extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final Color color;
  final String title, sub;
  final bool value;
  final void Function(bool) onChanged;
  const _SwitchTile({required this.dark, required this.icon,
      required this.color, required this.title, required this.sub,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
              color: AppTheme.textPrimary(dark),
              fontSize: 14, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(
              color: AppTheme.textMuted(dark), fontSize: 12)),
          ],
        )),
        Switch(
          value:           value,
          onChanged:       onChanged,
          activeColor:     AppTheme.crimson,
          activeTrackColor: AppTheme.crimson.withOpacity(0.3),
          inactiveThumbColor: AppTheme.textMuted(dark),
          inactiveTrackColor: AppTheme.border(dark),
        ),
      ]),
    );
  }
}

// =============================================================
// ACTION TILE
// =============================================================
class _ActionTile extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;
  const _ActionTile({required this.dark, required this.icon, required this.color,
      required this.title, required this.sub, required this.onTap,
      this.trailing, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                color: titleColor ?? AppTheme.textPrimary(dark),
                fontSize: 14, fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(
                color: AppTheme.textMuted(dark), fontSize: 12)),
            ],
          )),
          trailing ??
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted(dark), size: 20),
        ]),
      ),
    );
  }
}

// =============================================================
// DIVIDER
// =============================================================
class _Divider extends StatelessWidget {
  final bool dark;
  const _Divider({required this.dark});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1, indent: 66, endIndent: 0,
    color: AppTheme.border(dark),
  );
}
