import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/short_session_provider.dart';
import '../../services/control/execution.dart' show shortReasons;
import '../../services/short_session_reminder.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';

/// Opened from the "shorter than planned" push: the reason and an optional
/// note for the coach, kept with the activity.
class ShortSessionSheet extends ConsumerStatefulWidget {
  const ShortSessionSheet({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<ShortSessionSheet> createState() => _ShortSessionSheetState();
}

class _ShortSessionSheetState extends ConsumerState<ShortSessionSheet> {
  final _note = TextEditingController();
  String? _reason;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() => _busy = true);
    await runUiAction(
      context,
      () => ref.read(answerShortSessionProvider)(
        widget.sessionId,
        reason,
        text: _note.text,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SheetPage(
      title: l.shortSessionTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Builder(
            builder: (context) {
              final s = ref
                  .watch(shortSessionProvider(widget.sessionId))
                  .valueOrNull;
              return SectionCard(
                title: l.shortSessionTitle,
                accent: const [Color(0xFFFFB13D), Color(0xFFFFE066)],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s != null)
                      Text(
                        s.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: fjInk,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final r in shortReasons)
                          ChoiceChip(
                            label: Text(shortReasonText(l, r)),
                            showCheckmark: false,
                            selected: _reason == r,
                            onSelected: (_) => setState(() => _reason = r),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _note,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: InputDecoration(labelText: l.noteForCoach),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('short-session-save'),
            onPressed: _reason == null || _busy ? null : _save,
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}
