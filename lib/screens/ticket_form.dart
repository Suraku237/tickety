import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/auth_widgets.dart';
import 'home_page.dart';

// =============================================================
// TICKET FORM  (File 2 of 3)
// What the USER fills in after scanning / entering a service code:
//   • Title     — short summary (required, min 5 chars)
//   • Description — full detail  (required, min 10 chars)
//   • Notes     — optional extra context
//
// Removed (admin-only decisions):
//   • Priority  — set by admin when processing the ticket
//   • Service type dropdown — already known from the QR / link
//
// The serviceCode and serviceName come from the scanner step
// and are shown in a read-only banner so the user can verify
// they scanned the correct service, with a "Change" button to go back.
// =============================================================
class TicketForm extends StatefulWidget {
  final AuthUser   user;
  final String     serviceCode;
  final String     serviceName;
  final bool       isDark;
  final VoidCallback onBack;      // go back to scanner step

  const TicketForm({
    super.key,
    required this.user,
    required this.serviceCode,
    required this.serviceName,
    required this.isDark,
    required this.onBack,
  });

  @override
  State<TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<TicketForm> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _api       = ApiService();

  bool    _loading   = false;
  String? _error;
  bool    _submitted = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.user.userId.isEmpty) {
      setState(() =>
          _error = 'Session error: please log out and sign in again.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final res = await _api.createTicket(
      userId:      widget.user.userId,
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      notes:       _notesCtrl.text.trim(),
      priority:    'medium',       // default — admin adjusts after review
      service:     widget.serviceName,
      serviceCode: widget.serviceCode,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      setState(() => _submitted = true);
    } else {
      setState(() =>
          _error = res['message'] ?? 'Failed to create ticket. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return TicketSuccessView(
          isDark: widget.isDark, onCreateAnother: widget.onBack);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),

            // ── Back + heading ──
            Row(children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color:        AppTheme.card(widget.isDark),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border(widget.isDark)),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textMuted(widget.isDark), size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Text('New Ticket', style: TextStyle(
                color: AppTheme.textPrimary(widget.isDark),
                fontSize: 22, fontWeight: FontWeight.w900,
              )),
            ]),
            const SizedBox(height: 22),

            // ── Service banner (read-only — from QR / link) ──
            ServiceBanner(
              serviceName: widget.serviceName,
              isDark:      widget.isDark,
              onChange:    widget.onBack,
            ),
            const SizedBox(height: 22),

            if (_error != null) ...[
              AuthWidgets.buildErrorBanner(_error!),
              const SizedBox(height: 18),
            ],

            // ── Title ──
            _FieldLabel(text: 'SUBJECT', isDark: widget.isDark),
            const SizedBox(height: 8),
            AuthWidgets.buildTextField(
              controller: _titleCtrl,
              isDark:     widget.isDark,
              hint:       'What is your issue about?',
              icon:       Icons.title_rounded,
              validator:  (v) => (v == null || v.trim().length < 5)
                  ? 'Please enter at least 5 characters' : null,
            ),
            const SizedBox(height: 18),

            // ── Description ──
            _FieldLabel(text: 'DESCRIPTION', isDark: widget.isDark),
            const SizedBox(height: 8),
            _MultilineField(
              controller: _descCtrl,
              isDark:     widget.isDark,
              hint:       'Describe your issue in detail…',
              maxLines:   5,
              validator:  (v) => (v == null || v.trim().length < 10)
                  ? 'Please add more detail (min 10 characters)' : null,
            ),
            const SizedBox(height: 18),

            // ── Notes (optional) ──
            _FieldLabel(
                text: 'ADDITIONAL NOTES  (optional)',
                isDark: widget.isDark),
            const SizedBox(height: 8),
            _MultilineField(
              controller: _notesCtrl,
              isDark:     widget.isDark,
              hint:       'Any extra context or helpful information…',
              maxLines:   3,
              validator:  null,
            ),
            const SizedBox(height: 30),

            // ── Submit ──
            AuthWidgets.buildPrimaryButton(
              label:     'SUBMIT TICKET',
              isLoading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// SERVICE BANNER  (StatelessWidget — pure display)
// Shows the service identified from the QR / link with a
// "Change" button that takes the user back to the scanner step.
// =============================================================
class ServiceBanner extends StatelessWidget {
  final String       serviceName;
  final bool         isDark;
  final VoidCallback onChange;

  const ServiceBanner({
    super.key,
    required this.serviceName,
    required this.isDark,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppTheme.crimson.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.crimson.withOpacity(0.22)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        AppTheme.crimson.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.qr_code_rounded,
              color: AppTheme.crimson, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SERVICE', style: TextStyle(
              color: AppTheme.crimson, fontSize: 9,
              fontWeight: FontWeight.w800, letterSpacing: 2,
            )),
            const SizedBox(height: 2),
            Text(serviceName,
              style: TextStyle(
                color: AppTheme.textPrimary(isDark),
                fontSize: 14, fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )),
        GestureDetector(
          onTap: onChange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        AppTheme.card(isDark),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppTheme.border(isDark)),
            ),
            child: Text('Change', style: TextStyle(
              color: AppTheme.textMuted(isDark),
              fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ),
        ),
      ]),
    );
  }
}

// =============================================================
// SUCCESS VIEW  (StatelessWidget — pure display)
// =============================================================
class TicketSuccessView extends StatelessWidget {
  final bool         isDark;
  final VoidCallback onCreateAnother;

  const TicketSuccessView({
    super.key,
    required this.isDark,
    required this.onCreateAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                color:        Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 42),
            ),
            const SizedBox(height: 24),
            Text('Ticket Submitted!', style: TextStyle(
              color: AppTheme.textPrimary(isDark),
              fontSize: 26, fontWeight: FontWeight.w900,
            )),
            const SizedBox(height: 10),
            Text(
              'Your request has been received. '
              'You will be notified once it is processed.',
              style: TextStyle(
                  color: AppTheme.textMuted(isDark), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: onCreateAnother,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.crimson,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLarge)),
                ),
                child: const Text('CREATE ANOTHER', style: TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w800, letterSpacing: 2,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// SMALL REUSABLE STATELESS WIDGETS
// =============================================================

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool   isDark;
  const _FieldLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTheme.labelStyle(isDark));
}

class _MultilineField extends StatelessWidget {
  final TextEditingController        controller;
  final bool                         isDark;
  final String                       hint;
  final int                          maxLines;
  final String? Function(String?)?   validator;

  const _MultilineField({
    required this.controller,
    required this.isDark,
    required this.hint,
    required this.maxLines,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines:   maxLines,
      validator:  validator,
      style: TextStyle(
          color: AppTheme.textPrimary(isDark), fontSize: 14),
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  TextStyle(
            color: AppTheme.textHint(isDark), fontSize: 13),
        filled:      true,
        fillColor:   AppTheme.card(isDark),
        errorStyle:  const TextStyle(
            color: AppTheme.crimson, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:             _border(AppTheme.border(isDark)),
        enabledBorder:      _border(AppTheme.border(isDark)),
        focusedBorder:      _border(AppTheme.crimson, w: 1.5),
        errorBorder:        _border(AppTheme.crimson),
        focusedErrorBorder: _border(AppTheme.crimson, w: 1.5),
      ),
    );
  }

  OutlineInputBorder _border(Color c, {double w = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide:   BorderSide(color: c, width: w),
      );
}