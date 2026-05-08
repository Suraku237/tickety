import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/auth_user.dart'; // adjust to your actual import

// =============================================================
// PROFILE EDIT PAGE
// =============================================================
class ProfileEditPage extends StatefulWidget {
  final AuthUser user;
  final bool dark;
  const ProfileEditPage({super.key, required this.user, required this.dark});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.user.username);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _initials() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return '?';
    final p = name.split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    // TODO: wire up to your backend / state management
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.card(widget.dark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    return Scaffold(
      backgroundColor: AppTheme.background(dark),
      appBar: _buildAppBar(dark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(children: [
          // ── Avatar ──────────────────────────────────────────
          Center(
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.crimson, AppTheme.darkCrimson],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.crimson.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _nameCtrl,
                    builder: (_, __) => Text(
                      _initials(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {}, // TODO: image picker
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.card(dark),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.border(dark), width: 2),
                    ),
                    child: Icon(Icons.camera_alt_rounded,
                        size: 14, color: AppTheme.textPrimary(dark)),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 32),

          // ── Fields ───────────────────────────────────────────
          _SectionLabel(label: 'PERSONAL INFO', dark: dark),
          const SizedBox(height: 12),
          _FieldCard(dark: dark, children: [
            _InputField(
              controller: _nameCtrl,
              dark: dark,
              icon: Icons.person_outline_rounded,
              label: 'Full Name',
              hint: 'Your display name',
            ),
            _FieldDivider(dark: dark),
            _InputField(
              controller: _emailCtrl,
              dark: dark,
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              hint: 'your@email.com',
              keyboardType: TextInputType.emailAddress,
            ),
            _FieldDivider(dark: dark),
            _InputField(
              controller: _phoneCtrl,
              dark: dark,
              icon: Icons.phone_outlined,
              label: 'Phone',
              hint: '+1 234 567 8900',
              keyboardType: TextInputType.phone,
            ),
          ]),
          const SizedBox(height: 32),

          // ── Save Button ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.crimson,
                disabledBackgroundColor: AppTheme.crimson.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  AppBar _buildAppBar(bool dark) => AppBar(
        backgroundColor: AppTheme.background(dark),
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(dark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile',
            style: TextStyle(
                color: AppTheme.textPrimary(dark),
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        centerTitle: true,
      );
}

// ── Shared sub-widgets ─────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final bool dark;
  final List<Widget> children;
  const _FieldCard({required this.dark, required this.children});

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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final bool dark;
  final IconData icon;
  final String label, hint;
  final TextInputType? keyboardType;
  const _InputField(
      {required this.controller,
      required this.dark,
      required this.icon,
      required this.label,
      required this.hint,
      this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.crimson.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppTheme.crimson, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    color: AppTheme.textMuted(dark),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4)),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(
                  color: AppTheme.textPrimary(dark),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(color: AppTheme.textMuted(dark), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool dark;
  const _SectionLabel({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(label,
            style: TextStyle(
                color: AppTheme.textMuted(dark),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
      );
}

class _FieldDivider extends StatelessWidget {
  final bool dark;
  const _FieldDivider({required this.dark});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 66, color: AppTheme.border(dark));
}