import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

// =============================================================
// ABOUT PAGE
// =============================================================
class AboutPage extends StatelessWidget {
  final bool dark;
  const AboutPage({super.key, required this.dark});

  static const _version    = '1.0.0';
  static const _buildNum   = '42';
  static const _releaseDate = '08 May 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(dark),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Logo / Brand block ───────────────────────────────
          Center(
            child: Column(children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.crimson, AppTheme.darkCrimson],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.crimson.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Center(
                  child: Text('T',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 16),
              Text('TICKETY',
                  style: TextStyle(
                    color: AppTheme.textPrimary(dark),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  )),
              const SizedBox(height: 6),
              Text('Smart Ticket Management',
                  style: TextStyle(
                      color: AppTheme.textMuted(dark), fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('v$_version (build $_buildNum)',
                    style: TextStyle(
                        color: AppTheme.crimson,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 32),

          // ── Version Info ─────────────────────────────────────
          _SectionLabel(label: 'VERSION INFO', dark: dark),
          const SizedBox(height: 10),
          _Card(dark: dark, children: [
            _InfoRow(dark: dark, label: 'Version',     value: _version),
            _Divider(dark: dark),
            _InfoRow(dark: dark, label: 'Build Number',value: _buildNum),
            _Divider(dark: dark),
            _InfoRow(dark: dark, label: 'Released',    value: _releaseDate),
            _Divider(dark: dark),
            _InfoRow(dark: dark, label: 'Platform',    value: 'Flutter 3.x'),
          ]),
          const SizedBox(height: 20),

          // ── Legal ────────────────────────────────────────────
          _SectionLabel(label: 'LEGAL', dark: dark),
          const SizedBox(height: 10),
          _Card(dark: dark, children: [
            _LinkRow(
              dark: dark,
              icon: Icons.privacy_tip_outlined,
              color: Colors.purple,
              title: 'Privacy Policy',
              onTap: () => _openWebview(context, 'Privacy Policy',
                  'https://tickety.app/privacy'),
            ),
            _Divider(dark: dark),
            _LinkRow(
              dark: dark,
              icon: Icons.article_outlined,
              color: Colors.brown,
              title: 'Terms of Service',
              onTap: () => _openWebview(context, 'Terms of Service',
                  'https://tickety.app/terms'),
            ),
            _Divider(dark: dark),
            _LinkRow(
              dark: dark,
              icon: Icons.gavel_rounded,
              color: Colors.teal,
              title: 'Open Source Licences',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'TICKETY',
                applicationVersion: _version,
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Support ──────────────────────────────────────────
          _SectionLabel(label: 'SUPPORT', dark: dark),
          const SizedBox(height: 10),
          _Card(dark: dark, children: [
            _LinkRow(
              dark: dark,
              icon: Icons.help_outline_rounded,
              color: Colors.blue,
              title: 'Help Center',
              onTap: () => _openWebview(
                  context, 'Help Center', 'https://help.tickety.app'),
            ),
            _Divider(dark: dark),
            _LinkRow(
              dark: dark,
              icon: Icons.bug_report_outlined,
              color: Colors.orange,
              title: 'Report a Bug',
              onTap: () => _reportBug(context),
            ),
            _Divider(dark: dark),
            _LinkRow(
              dark: dark,
              icon: Icons.star_outline_rounded,
              color: Colors.amber,
              title: 'Rate TICKETY',
              onTap: () {
                // TODO: launch store review
              },
            ),
          ]),
          const SizedBox(height: 36),

          // ── Footer ───────────────────────────────────────────
          Center(
            child: Text(
              'Made with ❤️ · TICKETY v$_version',
              style: TextStyle(
                color: AppTheme.textMuted(dark).withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: AppTheme.background(dark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary(dark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('About',
            style: TextStyle(
                color: AppTheme.textPrimary(dark),
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        centerTitle: true,
      );

  void _openWebview(BuildContext context, String title, String url) {
    // TODO: launch url_launcher or in-app webview
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Opening $title…'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.card(dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _reportBug(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Opening bug report form…'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.card(dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// =============================================================
// LOCAL WIDGETS
// =============================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool dark;
  const _SectionLabel({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(
          color: AppTheme.textMuted(dark),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2));
}

class _Card extends StatelessWidget {
  final bool dark;
  final List<Widget> children;
  const _Card({required this.dark, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.card(dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(dark)),
        ),
        child: Column(children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final bool dark;
  final String label, value;
  const _InfoRow({required this.dark, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                color: AppTheme.textMuted(dark),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: AppTheme.textPrimary(dark),
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  const _LinkRow(
      {required this.dark,
      required this.icon,
      required this.color,
      required this.title,
      required this.onTap});

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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: AppTheme.textPrimary(dark),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppTheme.textMuted(dark), size: 20),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool dark;
  const _Divider({required this.dark});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 66, color: AppTheme.border(dark));
}