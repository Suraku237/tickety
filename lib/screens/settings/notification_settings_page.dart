import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

// =============================================================
// NOTIFICATION SETTINGS PAGE
// =============================================================
class NotificationSettingsPage extends StatefulWidget {
  final bool dark;
  const NotificationSettingsPage({super.key, required this.dark});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Push
  bool _pushEnabled     = true;
  bool _ticketUpdates   = true;
  bool _newAssignments  = true;
  bool _mentions        = true;
  bool _deadlineRemind  = true;

  // Email
  bool _emailEnabled    = true;
  bool _emailDigest     = false;
  bool _emailMarketing  = false;

  // Quiet hours
  bool _quietHours      = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd   = const TimeOfDay(hour: 7, minute: 0);

  bool get dark => widget.dark;

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietStart : _quietEnd,
    );
    if (picked == null) return;
    setState(() => isStart ? _quietStart = picked : _quietEnd = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(dark),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Push ────────────────────────────────────────────
          _SectionLabel(label: 'PUSH NOTIFICATIONS', dark: dark),
          const SizedBox(height: 10),
          _Card(dark: dark, children: [
            _MasterSwitch(
              dark: dark,
              icon: Icons.notifications_active_rounded,
              color: Colors.orange,
              title: 'Push Notifications',
              sub: 'All push alerts on this device',
              value: _pushEnabled,
              onChanged: (v) => setState(() => _pushEnabled = v),
            ),
            if (_pushEnabled) ...[
              _Divider(dark: dark),
              _SubSwitch(dark: dark, title: 'Ticket Updates',
                  sub: 'Status changes on your tickets',
                  value: _ticketUpdates,
                  onChanged: (v) => setState(() => _ticketUpdates = v)),
              _Divider(dark: dark),
              _SubSwitch(dark: dark, title: 'New Assignments',
                  sub: 'When a ticket is assigned to you',
                  value: _newAssignments,
                  onChanged: (v) => setState(() => _newAssignments = v)),
              _Divider(dark: dark),
              _SubSwitch(dark: dark, title: 'Mentions',
                  sub: 'When someone @mentions you',
                  value: _mentions,
                  onChanged: (v) => setState(() => _mentions = v)),
              _Divider(dark: dark),
              _SubSwitch(dark: dark, title: 'Deadline Reminders',
                  sub: '24 h before due dates',
                  value: _deadlineRemind,
                  onChanged: (v) => setState(() => _deadlineRemind = v)),
            ],
          ]),
          const SizedBox(height: 20),

          // ── Email ────────────────────────────────────────────
          _SectionLabel(label: 'EMAIL NOTIFICATIONS', dark: dark),
          const SizedBox(height: 10),
          _Card(dark: dark, children: [
            _MasterSwitch(
              dark: dark,
              icon: Icons.mail_outline_rounded,
              color: Colors.blue,
              title: 'Email Notifications',
              sub: 'Receive updates via email',
              value: _emailEnabled,
              onChanged: (v) => setState(() => _emailEnabled = v),
            ),
            if (_emailEnabled) ...[
              _Divider(dark: dark),
              _SubSwitch(dark: dark, title: 'Weekly Digest',
                  sub: 'Summary of activity each Monday',
                  value: _emailDigest,
                  onChanged: (v) => setState(() => _emailDigest = v)),
              _Divider(dark: dark),
              _SubSwitch(dark: dark, title: 'Product Updates',
                  sub: 'News & feature announcements',
                  value: _emailMarketing,
                  onChanged: (v) => setState(() => _emailMarketing = v)),
            ],
          ]),
          const SizedBox(height: 20),

          // ── Quiet Hours ─────────────────────────────────────
          _SectionLabel(label: 'QUIET HOURS', dark: dark),
          const SizedBox(height: 10),
          _Card(dark: dark, children: [
            _MasterSwitch(
              dark: dark,
              icon: Icons.bedtime_rounded,
              color: const Color(0xFF7B61FF),
              title: 'Quiet Hours',
              sub: 'Silence notifications during set times',
              value: _quietHours,
              onChanged: (v) => setState(() => _quietHours = v),
            ),
            if (_quietHours) ...[
              _Divider(dark: dark),
              _TimeTile(
                dark: dark,
                label: 'Start',
                time: _quietStart,
                onTap: () => _pickTime(true),
              ),
              _Divider(dark: dark),
              _TimeTile(
                dark: dark,
                label: 'End',
                time: _quietEnd,
                onTap: () => _pickTime(false),
              ),
            ],
          ]),
          const SizedBox(height: 32),

          // ── Save ─────────────────────────────────────────────
          _SaveButton(dark: dark, onTap: () => Navigator.pop(context)),
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
        title: Text('Notifications',
            style: TextStyle(
                color: AppTheme.textPrimary(dark),
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        centerTitle: true,
      );
}

// =============================================================
// LOCAL WIDGETS
// =============================================================

class _TimeTile extends StatelessWidget {
  final bool dark;
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile(
      {required this.dark,
      required this.label,
      required this.time,
      required this.onTap});

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          const SizedBox(width: 50), // indent to align with sub-switches
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: AppTheme.textPrimary(dark),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Text(_fmt(time),
              style: TextStyle(
                  color: AppTheme.crimson,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              color: AppTheme.textMuted(dark), size: 18),
        ]),
      ),
    );
  }
}

// ── Shared helpers (also used in other sub-pages) ──────────────

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

class _MasterSwitch extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final Color color;
  final String title, sub;
  final bool value;
  final void Function(bool) onChanged;
  const _MasterSwitch(
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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

class _SubSwitch extends StatelessWidget {
  final bool dark, value;
  final String title, sub;
  final void Function(bool) onChanged;
  const _SubSwitch(
      {required this.dark,
      required this.title,
      required this.sub,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50, right: 16, top: 12, bottom: 12),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    color: AppTheme.textPrimary(dark),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub,
                style:
                    TextStyle(color: AppTheme.textMuted(dark), fontSize: 11)),
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.crimson,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: const Text('Save Preferences',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}