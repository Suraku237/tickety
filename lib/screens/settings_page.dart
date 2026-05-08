import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    ThemeProvider().addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

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
        title: Text(
          'Log out?',
          style: TextStyle(
              color: AppTheme.textPrimary(_dark),
              fontWeight: FontWeight.w800),
        ),
        content: Text(
          'You will need to sign in again to access your tickets.',
          style: TextStyle(color: AppTheme.textMuted(_dark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted(_dark))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out',
                style: TextStyle(
                    color: AppTheme.crimson, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) widget.onLogout();
  }

  void _navigate(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Decorative background accent
      Positioned(
        bottom: 0,
        right: -60,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.crimson.withOpacity(0.07),
              Colors.transparent,
            ]),
          ),
        ),
      ),

      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),

            // ── Header ──────────────────────────────────────────
            Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.textPrimary(_dark),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── Profile Card ─────────────────────────────────────
            _ProfileCard(
              user: widget.user,
              dark: _dark,
              initials: _initials(),
              onTap: () => _navigate(
                ProfileEditPage(user: widget.user, dark: _dark),
              ),
            ),
            const SizedBox(height: 28),

            // ── Appearance ───────────────────────────────────────
            _SectionLabel(label: 'APPEARANCE', dark: _dark),
            const SizedBox(height: 10),
            _SettingsCard(dark: _dark, children: [
              _SwitchTile(
                dark: _dark,
                icon: _dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: _dark ? const Color(0xFF7B61FF) : Colors.orange,
                title: 'Dark Mode',
                sub: _dark
                    ? 'Currently using dark theme'
                    : 'Currently using light theme',
                value: _dark,
                onChanged: (_) => ThemeProvider().toggleTheme(),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Notifications ────────────────────────────────────
            _SectionLabel(label: 'NOTIFICATIONS', dark: _dark),
            const SizedBox(height: 10),
            _SettingsCard(dark: _dark, children: [
              _ActionTile(
                dark: _dark,
                icon: Icons.notifications_rounded,
                color: Colors.orange,
                title: 'Notifications',
                sub: 'Manage push & email alerts',
                onTap: () => _navigate(
                  NotificationSettingsPage(dark: _dark),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Security ─────────────────────────────────────────
            _SectionLabel(label: 'SECURITY', dark: _dark),
            const SizedBox(height: 10),
            _SettingsCard(dark: _dark, children: [
              _ActionTile(
                dark: _dark,
                icon: Icons.shield_rounded,
                color: Colors.green,
                title: 'Security',
                sub: 'Password, biometrics & sessions',
                onTap: () => _navigate(
                  SecuritySettingsPage(dark: _dark),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── About ────────────────────────────────────────────
            _SectionLabel(label: 'ABOUT', dark: _dark),
            const SizedBox(height: 10),
            _SettingsCard(dark: _dark, children: [
              _ActionTile(
                dark: _dark,
                icon: Icons.info_outline_rounded,
                color: Colors.indigo,
                title: 'About TICKETY',
                sub: 'Version, privacy & terms',
                onTap: () => _navigate(AboutPage(dark: _dark)),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Account / Danger Zone ────────────────────────────
            _SectionLabel(label: 'ACCOUNT', dark: _dark),
            const SizedBox(height: 10),
            _SettingsCard(dark: _dark, children: [
              _ActionTile(
                dark: _dark,
                icon: Icons.logout_rounded,
                color: AppTheme.crimson,
                title: 'Log Out',
                sub: 'Sign out of your account',
                onTap: _confirmLogout,
                titleColor: AppTheme.crimson,
              ),
            ]),
            const SizedBox(height: 36),

            // ── Footer ───────────────────────────────────────────
            Center(
              child: Text(
                'TICKETY · Made with ❤️ · v1.0.0',
                style: TextStyle(
                  color: AppTheme.textMuted(_dark).withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    ]);
  }
}

// =============================================================
// PROFILE CARD  (tappable → opens ProfileEditPage)
// =============================================================
class _ProfileCard extends StatelessWidget {
  final AuthUser user;
  final bool dark;
  final String initials;
  final VoidCallback onTap;
  const _ProfileCard(
      {required this.user,
      required this.dark,
      required this.initials,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.crimson, AppTheme.darkCrimson],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.crimson.withOpacity(0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username.isNotEmpty ? user.username : 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style:
                      TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Edit hint
          Icon(Icons.edit_rounded, color: Colors.white.withOpacity(0.7), size: 18),
        ]),
      ),
    );
  }
}

// =============================================================
// SHARED WIDGETS  (used here and exported for sub-pages)
// =============================================================

class _SettingsCard extends StatelessWidget {
  final bool dark;
  final List<Widget> children;
  const _SettingsCard({required this.dark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(dark)),
      ),
      child: Column(children: children),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool dark;
  const _SectionLabel({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          color: AppTheme.textMuted(dark),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      );
}

class _SwitchTile extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final Color color;
  final String title, sub;
  final bool value;
  final void Function(bool) onChanged;
  const _SwitchTile(
      {required this.dark,
      required this.icon,
      required this.color,
      required this.title,
      required this.sub,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        _IconBadge(icon: icon, color: color),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    color: AppTheme.textPrimary(dark),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub,
                style:
                    TextStyle(color: AppTheme.textMuted(dark), fontSize: 12)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.crimson,
          activeTrackColor: AppTheme.crimson.withOpacity(0.3),
          inactiveThumbColor: AppTheme.textMuted(dark),
          inactiveTrackColor: AppTheme.border(dark),
        ),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;
  const _ActionTile(
      {required this.dark,
      required this.icon,
      required this.color,
      required this.title,
      required this.sub,
      required this.onTap,
      this.trailing,
      this.titleColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _IconBadge(icon: icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: titleColor ?? AppTheme.textPrimary(dark),
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(sub,
                  style: TextStyle(
                      color: AppTheme.textMuted(dark), fontSize: 12)),
            ]),
          ),
          trailing ??
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted(dark), size: 20),
        ]),
      ),
    );
  }
}

/// Reusable coloured icon container
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 18),
      );
}

class SettingsDivider extends StatelessWidget {
  final bool dark;
  const SettingsDivider({super.key, required this.dark});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 66,
        endIndent: 0,
        color: AppTheme.border(dark),
      );
}