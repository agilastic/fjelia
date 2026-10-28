import '../../l10n/l10n_ext.dart';

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
  final subject = TextEditingController(text: tr.fjeliaFeedback);
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
              : context.l10n.couldNotSendTheReport,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Hides the keyboard, so a tap next to a field or a drag ends the input.
  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  InputDecoration _decoration(String label, {String? hint}) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: _fieldFill,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(Colors.transparent),
      enabledBorder: border(const Color(0x14FFFFFF)),
      focusedBorder: border(mint, 1.5),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent, 1.5),
      labelStyle: const TextStyle(color: muted),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.error)
              ? Colors.redAccent
              : states.contains(WidgetState.focused)
              ? mint
              : muted,
        ),
      ),
      hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
    );
  }

  /// Character counter that only appears when a field is nearly full, so the
  /// form is not cluttered by "0/254" under every field.
  Widget? _counter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (maxLength == null || currentLength < maxLength * .8) return null;
    return Text(
      '$currentLength/$maxLength',
      style: TextStyle(
        fontSize: 11,
        color: currentLength >= maxLength ? Colors.redAccent : muted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SheetPage(
    title: context.l10n.feedbackBugReport,
    child: _sent
        ? Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: mint, size: 64),
                const SizedBox(height: 18),
                Text(
                  context.l10n.reportSentThankYou,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.weReadEveryMessageIf,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _primaryButton,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.done),
                  ),
                ),
              ],
            ),
          )
        : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismissKeyboard,
            child: Form(
              key: _form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                children: [
                  Text(
                    context.l10n.shareAnIdeaSuggestAn,
                    style: TextStyle(fontSize: 13, color: muted, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: email,
                    enabled: !_sending,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    maxLength: 254,
                    buildCounter: _counter,
                    onTapOutside: (_) => _dismissKeyboard(),
                    decoration: _decoration(context.l10n.yourEmail),
                    validator: (value) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch((value ?? '').trim())
                        ? null
                        : context.l10n.enterAValidEmailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subject,
                    enabled: !_sending,
                    textInputAction: TextInputAction.next,
                    maxLength: 200,
                    buildCounter: _counter,
                    onTapOutside: (_) => _dismissKeyboard(),
                    decoration: _decoration(context.l10n.subject),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? context.l10n.enterASubject
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notes,
                    enabled: !_sending,
                    minLines: 5,
                    maxLines: 10,
                    maxLength: 8000,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    buildCounter: _counter,
                    onTapOutside: (_) => _dismissKeyboard(),
                    decoration: _decoration(
                      context.l10n.message,
                      hint: context.l10n.whatHappenedAndWhatDid,
                    ).copyWith(alignLabelWithHint: true),
                    validator: (value) => (value ?? '').trim().length < 10
                        ? context.l10n.enterAMessageOfAt
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.pleaseLeaveOutPasswordsApi,
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: const Color(0xFF1E1E1E),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0x14FFFFFF)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: mint,
                            title: Text(
                              context.l10n.includeDiagnostics,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                context.l10n.optionalLogsMayContainAccount,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: muted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            value: _diagnostics,
                            onChanged: _sending
                                ? null
                                : (value) {
                                    _dismissKeyboard();
                                    setState(() => _diagnostics = value);
                                  },
                          ),
                          if (_diagnostics) ...[
                            const Divider(height: 16, color: Color(0x14FFFFFF)),
                            Text(
                              context.l10n.diagnosticsPreview,
                              style: TextStyle(
                                fontSize: 10,
                                color: muted,
                                letterSpacing: .8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.lock_outline, size: 14, color: muted),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.sendingSharesYourEmailSubject,
                          style: TextStyle(
                            fontSize: 12,
                            color: muted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: .4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: _primaryButton,
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: Text(
                      _sending ? context.l10n.sending : context.l10n.sendReport,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: _secondaryButton,
                          onPressed: _sending
                              ? null
                              : () => runUiAction(context, () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: report()),
                                  );
                                }),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(context.l10n.copyReport),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: _secondaryButton,
                          onPressed: _sending
                              ? null
                              : () => runUiAction(context, () async {
                                  final box =
                                      context.findRenderObject() as RenderBox?;
                                  await SharePlus.instance.share(
                                    ShareParams(
                                      text: report(),
                                      sharePositionOrigin: box == null
                                          ? null
                                          : box.localToGlobal(Offset.zero) &
                                                box.size,
                                    ),
                                  );
                                }),
                          icon: const Icon(Icons.ios_share, size: 16),
                          label: Text(context.l10n.shareReport),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
  );
}

const _fieldFill = Color(0xFF262626);

final _primaryButton = FilledButton.styleFrom(
  backgroundColor: mint,
  foregroundColor: Colors.black,
  minimumSize: const Size.fromHeight(52),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

final _secondaryButton = OutlinedButton.styleFrom(
  foregroundColor: mint,
  minimumSize: const Size.fromHeight(46),
  side: const BorderSide(color: Color(0x3300D4A0)),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);
