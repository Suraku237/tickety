import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import '../pages/about.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  final AuthUser user;
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.user, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isEditing = false;

  bool get isDark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.text = widget.user.username;
    _emailCtrl.text = widget.user.email;
    ThemeProvider().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ThemeProvider().removeListener(_onThemeChanged);
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => _LogoutDialog(
        isDark: isDark,
        onConfirm: () {
          Navigator.pop(context);
          widget.onLogout();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      appBar: AppBar(
        backgroundColor: AppTheme.card(isDark),
        elevation: 0,
        title: Text('Profile', style: TextStyle(color: AppTheme.textPrimary(isDark))),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: _toggleEdit,
              style: TextButton.styleFrom(
                backgroundColor: _isEditing ? AppTheme.crimson : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: TextStyle(
                  color: _isEditing ? Colors.white : AppTheme.textMuted(isDark),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.crimson.withOpacity(0.14),
                      ),
                      child: Center(
                        child: Text(
                          _initials(),
                          style: const TextStyle(
                            color: AppTheme.crimson,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.user.username,
                      style: TextStyle(
                        color: AppTheme.textPrimary(isDark),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.user.email,
                      style: TextStyle(
                        color: AppTheme.textMuted(isDark),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _sectionLabel('ACCOUNT INFO'),
              const SizedBox(height: 12),
              _inputCard(label: 'Username', controller: _usernameCtrl, enabled: _isEditing),
              const SizedBox(height: 10),
              _inputCard(label: 'Email Address', controller: _emailCtrl, enabled: false),
              const SizedBox(height: 24),
              _sectionLabel('APPEARANCE'),
              const SizedBox(height: 12),
              _menuTile(
                icon: Icons.palette_outlined,
                label: isDark ? 'Dark Mode' : 'Light Mode',
                onTap: () => ThemeProvider().toggleTheme(),
              ),
              const SizedBox(height: 24),
              _sectionLabel('SECURITY'),
              const SizedBox(height: 12),
              _menuTile(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ChangePasswordSheet(isDark: isDark),
                ),
              ),
              const SizedBox(height: 10),
              _menuTile(
                icon: Icons.alternate_email_rounded,
                label: 'Change Email',
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ChangeEmailSheet(isDark: isDark),
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('ABOUT'),
              const SizedBox(height: 12),
              _menuTile(
                icon: Icons.info_outline_rounded,
                label: 'About TICKETY',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('DANGER ZONE'),
              const SizedBox(height: 12),
              _menuTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Account',
                color: AppTheme.crimson,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _DeleteAccountDialog(isDark: isDark, onDeleted: widget.onLogout),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: _confirmLogout,
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: AppTheme.crimson,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'TICKETY v1.0.0',
                  style: TextStyle(
                    color: AppTheme.textMuted(isDark).withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials() {
    final parts = widget.user.username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.user.username.isNotEmpty ? widget.user.username[0].toUpperCase() : '?';
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.textMuted(isDark),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _inputCard({
    required String label,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(color: AppTheme.textPrimary(isDark)),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? AppTheme.textPrimary(isDark);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.card(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(isDark)),
        ),
        child: Row(
          children: [
            Icon(icon, color: tileColor),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(color: tileColor, fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded, color: tileColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  final bool isDark;
  final VoidCallback onConfirm;

  const _LogoutDialog({required this.isDark, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Log out', style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('Are you sure you want to log out?', style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary(isDark),
                      side: BorderSide(color: AppTheme.border(isDark)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                    child: const Text('Log out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final bool isDark;

  const _ChangePasswordSheet({required this.isDark});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppTheme.crimson));
      }
      return;
    }

    setState(() => _loading = true);

    final session = await SessionService().restore();
    final userId = session?['user_id'] ?? '';
    final res = await ApiService().changePassword(
      userId: userId,
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Could not change password'), backgroundColor: AppTheme.crimson));
    }
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border(isDark), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 18),
                Text('Change Password', style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                _passwordField(label: 'Current password', controller: _currentCtrl, isDark: isDark),
                const SizedBox(height: 12),
                _passwordField(label: 'New password', controller: _newCtrl, isDark: isDark),
                const SizedBox(height: 12),
                _passwordField(label: 'Confirm new password', controller: _confirmCtrl, isDark: isDark),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({required String label, required TextEditingController controller, required bool isDark}) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: AppTheme.textPrimary(isDark)),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.surface(isDark),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border(isDark))),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final bool isDark;
  final VoidCallback onDeleted;

  const _DeleteAccountDialog({required this.isDark, required this.onDeleted});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _loading = false;

  Future<void> _performDelete() async {
    setState(() => _loading = true);
    final session = await SessionService().restore();
    final userId = session?['user_id'] ?? '';
    final res = await ApiService().deleteAccount(userId: userId);

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      await SessionService().clear();
      ApiService().clearToken();
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
      widget.onDeleted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Could not delete account'), backgroundColor: AppTheme.crimson));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Dialog(
      backgroundColor: AppTheme.card(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete Account', style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              'This will permanently delete your account and all associated data.',
              style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary(isDark),
                      side: BorderSide(color: AppTheme.border(isDark)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _performDelete,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================================
// CHANGE EMAIL SHEET  (#10 — 3-step verified flow, mirrors web)
//   Step 0: enter new email -> OTP sent to CURRENT email
//   Step 1: verify CURRENT-email OTP -> OTP sent to NEW email
//   Step 2: verify NEW-email OTP -> change applied
// =============================================================
class _ChangeEmailSheet extends StatefulWidget {
  final bool isDark;
  const _ChangeEmailSheet({required this.isDark});

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  final _newEmailCtrl = TextEditingController();
  final _oldCodeCtrl  = TextEditingController();
  final _newCodeCtrl  = TextEditingController();
  int  _step = 0;
  bool _loading = false;
  String? _userId;

  Future<String> _uid() async {
    _userId ??= (await SessionService().restore())?['user_id']?.toString() ?? '';
    return _userId!;
  }

  void _toast(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green : AppTheme.crimson));
  }

  Future<void> _next() async {
    if (_step == 0) {
      final email = _newEmailCtrl.text.trim();
      if (!email.contains('@') || !email.contains('.')) { _toast('Enter a valid email'); return; }
      setState(() => _loading = true);
      final res = await ApiService().initiateEmailChange(userId: await _uid(), newEmail: email);
      if (!mounted) return; setState(() => _loading = false);
      if (res['success'] == true) { setState(() => _step = 1); _toast('Code sent to your current email', ok: true); }
      else { _toast(res['message']?.toString() ?? 'Could not start email change'); }
    } else if (_step == 1) {
      final code = _oldCodeCtrl.text.trim();
      if (code.isEmpty) { _toast('Enter the code'); return; }
      setState(() => _loading = true);
      final res = await ApiService().confirmOldEmail(userId: await _uid(), code: code);
      if (!mounted) return; setState(() => _loading = false);
      if (res['success'] == true) { setState(() => _step = 2); _toast('Code sent to the new email', ok: true); }
      else { _toast(res['message']?.toString() ?? 'Incorrect code'); }
    } else {
      final code = _newCodeCtrl.text.trim();
      if (code.isEmpty) { _toast('Enter the code'); return; }
      setState(() => _loading = true);
      final res = await ApiService().confirmNewEmail(userId: await _uid(), code: code);
      if (!mounted) return; setState(() => _loading = false);
      if (res['success'] == true) {
        Navigator.pop(context);
        _toast('Email updated. Please log in again to refresh your session.', ok: true);
      } else { _toast(res['message']?.toString() ?? 'Incorrect code'); }
    }
  }

  @override
  void dispose() {
    _newEmailCtrl.dispose();
    _oldCodeCtrl.dispose();
    _newCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    const titles = ['Change Email', 'Verify Current Email', 'Verify New Email'];
    const hints  = [
      "Enter your new email. We'll send a code to your CURRENT email to confirm it's you.",
      'Enter the 6-digit code sent to your CURRENT email.',
      'Enter the 6-digit code sent to your NEW email to finish.',
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border(isDark), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _step ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= _step ? AppTheme.crimson : AppTheme.border(isDark),
                      borderRadius: BorderRadius.circular(4)),
                  )),
                ),
                const SizedBox(height: 16),
                Text(titles[_step], style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(hints[_step], textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted(isDark), fontSize: 12.5, height: 1.4)),
                const SizedBox(height: 18),
                if (_step == 0) _field(_newEmailCtrl, 'New email address', isDark, email: true),
                if (_step == 1) _field(_oldCodeCtrl, '6-digit code', isDark, code: true),
                if (_step == 2) _field(_newCodeCtrl, '6-digit code', isDark, code: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _next,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_step == 2 ? 'Confirm Change' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, bool isDark, {bool email = false, bool code = false}) {
    return TextField(
      controller: c,
      keyboardType: email
          ? TextInputType.emailAddress
          : (code ? TextInputType.number : TextInputType.text),
      style: TextStyle(color: AppTheme.textPrimary(isDark)),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.surface(isDark),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border(isDark))),
      ),
    );
  }
}