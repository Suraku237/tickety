import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

// =============================================================
// SECURITY SETTINGS PAGE
// =============================================================
class SecuritySettingsPage extends StatefulWidget {
  final bool dark;
  const SecuritySettingsPage({super.key, required this.dark});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _biometric      = false;
  bool _twoFactor      = false;
  bool _loginAlerts    = true;
  bool _rememberDevice = true;

  bool get dark => widget.dark;

  // ── Change Password ──────────────────────────────────────────
  Future<void> _showChangePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.card(dark),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border(dark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Change Password',
                  style: TextStyle(
                      color: AppTheme.textPrimary(dark),
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _PasswordField(
                  dark: dark,
                  ctrl: currentCtrl,
                  label: 'Current Password',
                  obscure: obscure,
                  onToggle: () => setModal(() => obscure = !obscure)),
              const SizedBox(height: 12),
              _PasswordField(
                  dark: dark,
                  ctrl: newCtrl,
                  label: 'New Password',
                  obscure: obscure,
                  onToggle: () => setModal(() => obscure = !obscure)),
              const SizedBox(height: 12),
              _PasswordField(
                  dark: dark,
                  ctrl: confirmCtrl,
                  label: 'Confirm New Password',
                  obscure: obscure,
                  onToggle: () => setModal(() => obscure = !obscure)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: validate & call API
                    Navigator.pop(ctx);
                    _snack('Password updated successfully');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.crimson,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                  ),
                  child: const Text('Update Password',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Active Sessions ───────────────────────────────────────────
  void _showSessions() {
    final sessions = [
      _Session(device: 'iPhone 15 Pro', location: 'Douala, CM', current: true,
          time: 'Now'),
      _Session(device: 'Chrome – Windows', location: 'Yaoundé, CM', current: false,
          time: '2 days ago'),
      _Session(device: 'Firefox – Mac', location: 'Paris, FR', current: false,
          time: '5 days ago'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.card(dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border(dark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Active Sessions',
              style: TextStyle(
                  color: AppTheme.textPrimary(dark),
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...sessions.map((s) => _SessionTile(session: s, dark: dark)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _snack('All other sessions signed out');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.crimson,
                side: BorderSide(color: AppTheme.crimson),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text('Sign Out All Other Sessions',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.card(dark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(dark),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Authentication ───────────────────────────────────
          _SectionLabel(label: 'AUTHENTICATION', dark: dark),
          const SizedBox(height: 10),
          _Card(dark: dark, children: [
            _SwitchRow(
              dark: dark, icon: Icons.fingerprint_rounded, color: Colors.green,
              title: 'Biometric Lock',
              sub: 'Fingerprint or Face ID to unlock',
              value: _biometric,
              onChanged: (v) => setState(() => _biometric = v),
            ),
            _Divider(dark: dark),
            _SwitchRow(
              dark: dark, icon: Icons.verified_user_rounded, color: Colors.teal,
              title: 'Two-Factor Auth',
              sub: 'Extra layer of account security',
              value: _twoFactor,
              onChanged: (v) => setState(() => _twoFactor = v),
            ),
            _Divider(dark: dark),
            _ActionRow(
              dark: dark, icon: Icons.lock_outline_rounded, color: Colors.indigo,
              title: 'Change Password',
              sub: 'Update your account password',
              onTap: _showChangePassword,
            ),
          ]),
          const SizedBox(height: 20),

          // ── Login Behaviour ──────────────────────────────────
          _SectionLabel(label: 'LOGIN BEHAVIOUR', dark: dark),
          const SizedBox(height: 10),
          _Card(dark: dark, children: [
            _SwitchRow(
              dark: dark, icon: Icons.notifications_outlined, color: Colors.orange,
              title: 'Login Alerts',
              sub: 'Notify on new sign-ins',
              value: _loginAlerts,
              onChanged: (v) => setState(() => _loginAlerts = v),
            ),
            _Divider(dark: dark),
            _SwitchRow(
              dark: dark, icon: Icons.devices_rounded, color: Colors.blue,
              title: 'Remember Device',
              sub: 'Stay signed in on this device',
              value: _rememberDevice,
              onChanged: (v) => setState(() => _rememberDevice = v),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Sessions ─────────────────────────────────────────
          _SectionLabel(label: 'SESSIONS', dark: dark),
          const SizedBox(height: 10),
          _Card(dark: dark, children: [
            _ActionRow(
              dark: dark, icon: Icons.manage_accounts_rounded, color: Colors.purple,
              title: 'Active Sessions',
              sub: '3 devices currently signed in',
              onTap: _showSessions,
            ),
          ]),
          const SizedBox(height: 32),

          _SaveButton(
            dark: dark,
            onTap: () {
              _snack('Security settings saved');
              Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: AppTheme.background(dark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary(dark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Security',
            style: TextStyle(
                color: AppTheme.textPrimary(dark),
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        centerTitle: true,
      );
}

// =============================================================
// DATA MODELS
// =============================================================
class _Session {
  final String device, location, time;
  final bool current;
  const _Session(
      {required this.device,
      required this.location,
      required this.current,
      required this.time});
}

// =============================================================
// LOCAL WIDGETS
// =============================================================

class _SessionTile extends StatelessWidget {
  final _Session session;
  final bool dark;
  const _SessionTile({required this.session, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (session.current ? Colors.green : AppTheme.textMuted(dark))
                .withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            session.device.contains('iPhone')
                ? Icons.phone_iphone_rounded
                : Icons.computer_rounded,
            color: session.current ? Colors.green : AppTheme.textMuted(dark),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(session.device,
                  style: TextStyle(
                      color: AppTheme.textPrimary(dark),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              if (session.current) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('This device',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text('${session.location} · ${session.time}',
                style: TextStyle(
                    color: AppTheme.textMuted(dark), fontSize: 11)),
          ]),
        ),
        if (!session.current)
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.crimson.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text('Revoke',
                  style: TextStyle(
                      color: AppTheme.crimson,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final bool dark, obscure;
  final TextEditingController ctrl;
  final String label;
  final VoidCallback onToggle;
  const _PasswordField(
      {required this.dark,
      required this.ctrl,
      required this.label,
      required this.obscure,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style:
          TextStyle(color: AppTheme.textPrimary(dark), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textMuted(dark)),
        filled: true,
        fillColor: AppTheme.background(dark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: AppTheme.border(dark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: AppTheme.border(dark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: AppTheme.crimson),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.textMuted(dark), size: 18),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// Shared widgets ───────────────────────────────────────────────

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

class _SwitchRow extends StatelessWidget {
  final bool dark, value;
  final IconData icon;
  final Color color;
  final String title, sub;
  final void Function(bool) onChanged;
  const _SwitchRow(
      {required this.dark, required this.icon, required this.color,
      required this.title, required this.sub, required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(title, style: TextStyle(color: AppTheme.textPrimary(dark),
              fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 12)),
        ])),
        Switch(
          value: value, onChanged: onChanged,
          activeColor: AppTheme.crimson,
          activeTrackColor: AppTheme.crimson.withOpacity(0.3),
          inactiveThumbColor: AppTheme.textMuted(dark),
          inactiveTrackColor: AppTheme.border(dark),
        ),
      ]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  const _ActionRow(
      {required this.dark, required this.icon, required this.color,
      required this.title, required this.sub, required this.onTap});

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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title, style: TextStyle(color: AppTheme.textPrimary(dark),
                fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: AppTheme.textMuted(dark), fontSize: 12)),
          ])),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted(dark), size: 20),
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

class _SaveButton extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;
  const _SaveButton({required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.crimson,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Save Settings',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w800)),
        ),
      );
}