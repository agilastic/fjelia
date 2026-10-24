import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/bug_report_service.dart';
import '../../services/debug_log.dart';
import '../../widgets/app_widgets.dart';

class BugReportSheet extends StatefulWidget {
  const BugReportSheet({super.key, this.service});
  final BugReportService? service;
  @override
  State<BugReportSheet> createState() => _BugReportState();
}

class _BugReportState extends State<BugReportSheet> {
  final _form = GlobalKey<FormState>();
  final email = TextEditingController();
  final subject = TextEditingController(text: 'Fjelia bug report');
  final notes = TextEditingController();
  bool _diagnostics = false;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    email.dispose();
    subject.dispose();
    notes.dispose();
    super.dispose();
  }

  String report() {
    final message = notes.text.trim();
    if (!_diagnostics) return message;
    const separator = '\n\nDiagnostics (included by the sender):\n';
    final log = DebugLog.lines.join('\n');
    final available = 10000 - message.length - separator.length;
    final excerpt = log.length > available
        ? log.substring(log.length - available)
        : log;
    return '$message$separator$excerpt';
  }

  Future<void> _send() async {
    if (_sending || !_form.currentState!.validate()) return;
    final body = report();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await (widget.service ?? BugReportService()).send(
        email: email.text,
        subject: subject.text,
        body: body,
      );
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is BugReportException
              ? error.message
              : 'Could not send the report. Your text is still here. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => SheetPage(
    title: 'Report a Bug',
    child: _sent
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: mint, size: 56),
                const SizedBox(height: 16),
                const Text('Report sent. Thank you!'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          )
        : Form(
            key: _form,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              children: [
                const Text(
                  'Tell us what happened and what you expected. Please leave out passwords, API keys and personal health readings.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: email,
                  enabled: !_sending,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  maxLength: 254,
                  decoration: const InputDecoration(labelText: 'Your email'),
                  validator: (value) =>
                      RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch((value ?? '').trim())
                      ? null
                      : 'Enter a valid email address.',
                ),
                TextFormField(
                  controller: subject,
                  enabled: !_sending,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter a subject.' : null,
                ),
                TextFormField(
                  controller: notes,
                  enabled: !_sending,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 8000,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                  ),
                  validator: (value) => (value ?? '').trim().length < 10
                      ? 'Describe the problem in at least 10 characters.'
                      : null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include diagnostics'),
                  subtitle: const Text(
                    'Optional. Logs may contain account or health details. Review them below before sending.',
                  ),
                  value: _diagnostics,
                  onChanged: _sending
                      ? null
                      : (value) => setState(() => _diagnostics = value),
                ),
                if (_diagnostics) ...[
                  const SectionLabel('Diagnostics preview'),
                  SizedBox(
                    height: 150,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        DebugLog.lines.join('\n'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: muted,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Sending shares your email, subject, message and any selected diagnostics with Fjelia support at cloud.ebeling-hoppe.de.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_sending ? 'Sending…' : 'Send report'),
                ),
                OutlinedButton(
                  onPressed: _sending
                      ? null
                      : () => runUiAction(context, () async {
                          await Clipboard.setData(
                            ClipboardData(text: report()),
                          );
                        }),
                  child: const Text('Copy report'),
                ),
                TextButton(
                  onPressed: _sending
                      ? null
                      : () => runUiAction(context, () async {
                          final box = context.findRenderObject() as RenderBox?;
                          await SharePlus.instance.share(
                            ShareParams(
                              text: report(),
                              sharePositionOrigin: box == null
                                  ? null
                                  : box.localToGlobal(Offset.zero) & box.size,
                            ),
                          );
                        }),
                  child: const Text('Share report instead'),
                ),
              ],
            ),
          ),
  );
}
