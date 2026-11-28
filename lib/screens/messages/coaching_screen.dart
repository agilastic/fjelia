import 'package:fjelia_core/services/sync/sync_tables.dart';
import 'package:fjelia_sync/fjelia_sync.dart' show CoachLink, LinkInvite;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/messages_provider.dart';
import '../../widgets/person_avatar.dart';

/// The categories an athlete can share, in the order the switches show.
const _scopeOrder = [
  SyncCategory.plan,
  SyncCategory.activities,
  SyncCategory.health,
  SyncCategory.ecg,
  SyncCategory.nutrition,
  SyncCategory.aiCoach,
  SyncCategory.media,
];

String scopeName(AppLocalizations l10n, SyncCategory c) => switch (c) {
  SyncCategory.plan => l10n.coachingScopePlan,
  SyncCategory.activities => l10n.coachingScopeActivities,
  SyncCategory.health => l10n.coachingScopeHealth,
  SyncCategory.ecg => l10n.coachingScopeEcg,
  SyncCategory.nutrition => l10n.coachingScopeNutrition,
  SyncCategory.aiCoach => l10n.coachingScopeAiCoach,
  SyncCategory.media => l10n.coachingScopeMedia,
  SyncCategory.coach => l10n.coachingTitle,
};

/// "123456" → "123 456", as the coach's screen shows it.
String spacedCode(String code) =>
    '${code.substring(0, 3)} ${code.substring(3)}';

/// Coaching: this athlete's coaches, what each sees, ending it, and joining
/// a coach by the invitation they sent.
class CoachingScreen extends ConsumerStatefulWidget {
  const CoachingScreen({super.key, this.invite});

  /// An invitation opened in Fjelia, to answer right away.
  final String? invite;

  @override
  ConsumerState<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends ConsumerState<CoachingScreen> {
  List<CoachRow>? _rows;

  MessagesNotifier get _messages => ref.read(messagesProvider.notifier);

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.invite case final invite?) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _answer(invite));
    }
  }

  Future<void> _load() async {
    final rows = await _messages.coachRows();
    if (mounted) setState(() => _rows = rows);
  }

  Future<void> _join() async {
    final pasted = (await Clipboard.getData('text/plain'))?.text ?? '';
    if (!mounted) return;
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _JoinDialog(
        initial: LinkInvite.parse(pasted) != null ? pasted.trim() : '',
      ),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    await _answer(text);
  }

  /// The consent screen for the invitation in [text], or why not.
  Future<void> _answer(String text) async {
    final l10n = context.l10n;
    final (answer, problem) = await _messages.readInvite(text);
    if (!mounted) return;
    if (answer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (problem) {
            InviteProblem.ownInvite => l10n.coachingOwnInvite,
            InviteProblem.coachUnknown => l10n.coachingCoachUnknown,
            InviteProblem.unreachable => l10n.coachingUnreachable,
            _ => l10n.coachingNotInvite,
          }),
        ),
      );
      return;
    }
    final sent = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => _ConsentScreen(answer)));
    if (sent == true) await _load();
  }

  Future<void> _end(CoachRow row) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.coachingEndConfirm(row.coach.name)),
        content: Text(l10n.coachingEndBody(row.coach.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.coachingCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.coachingEndAction),
          ),
        ],
      ),
    );
    if (sure != true) return;
    await _messages.endCoaching(row.link!);
    await _load();
  }

  Future<void> _toggle(CoachLink link, SyncCategory c, bool on) async {
    final next = {...link.scopes};
    on ? next.add(c) : next.remove(c);
    await _messages.share(link, next);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(messagesProvider.select((s) => s.version), (_, _) => _load());
    final rows = _rows;
    final day = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.coachingTitle)),
      body: rows == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _messages.relay();
                await _load();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.coachingNone,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final row in rows) ...[
                    ListTile(
                      leading: PersonAvatar(
                        name: row.coach.shownName,
                        photo: row.coach.photo,
                      ),
                      title: Text(row.coach.shownName),
                      subtitle: Text(switch (row.link) {
                        null => l10n.coachingWaiting(row.coach.name),
                        final l when !l.active => l10n.coachingEnded(
                          day.format(DateTime.parse(l.ended!).toLocal()),
                        ),
                        final l => l10n.coachingSince(
                          day.format(DateTime.parse(l.since).toLocal()),
                        ),
                      }),
                    ),
                    if (row.link case final link? when link.active) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          l10n.coachingShares(row.coach.name),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      for (final c in _scopeOrder)
                        SwitchListTile(
                          title: Text(scopeName(l10n, c)),
                          value: link.scopes.contains(c),
                          onChanged: (on) => _toggle(link, c, on),
                        ),
                      ListTile(
                        leading: const Icon(Icons.link_off),
                        title: Text(l10n.coachingEnd),
                        onTap: () => _end(row),
                      ),
                    ],
                    const Divider(height: 24),
                  ],
                  ListTile(
                    leading: const Icon(Icons.add_link),
                    title: Text(l10n.coachingJoin),
                    subtitle: Text(l10n.coachingJoinHelp),
                    onTap: _join,
                  ),
                ],
              ),
            ),
    );
  }
}

/// The invitation pasted, or typed.
class _JoinDialog extends StatefulWidget {
  const _JoinDialog({required this.initial});
  final String initial;

  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<_JoinDialog> {
  late final _field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.coachingJoin),
      content: TextField(
        controller: _field,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(helperText: l10n.coachingJoinHelp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.coachingCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _field.text),
          child: Text(l10n.coachingContinue),
        ),
      ],
    );
  }
}

/// Before anything is shared: who invites, what they would see, and the
/// code both screens show (remote coaching D7).
class _ConsentScreen extends ConsumerStatefulWidget {
  const _ConsentScreen(this.answer);
  final InviteToAnswer answer;

  @override
  ConsumerState<_ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<_ConsentScreen> {
  final _scopes = {SyncCategory.plan, SyncCategory.activities};
  bool _sending = false;

  Future<void> _send() async {
    final l10n = context.l10n;
    final name = widget.answer.invite.name;
    setState(() => _sending = true);
    final ok = await ref
        .read(messagesProvider.notifier)
        .answerInvite(widget.answer, _scopes);
    if (!mounted) return;
    if (!ok) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.coachingNotInvite)));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(
          l10n.coachingReadCode(name, spacedCode(widget.answer.code)),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(l10n.messagesDone),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = widget.answer.invite.name;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.coachingConsentTitle(name))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.coachingConsentIntro(name)),
          ),
          for (final c in _scopeOrder)
            SwitchListTile(
              title: Text(scopeName(l10n, c)),
              value: _scopes.contains(c),
              onChanged: (on) =>
                  setState(() => on ? _scopes.add(c) : _scopes.remove(c)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.coachingConsentHealth(name),
              style: theme.textTheme.bodySmall,
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.coachingConsentCode(name)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              spacedCode(widget.answer.code),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.coachingConsentPrivacy(name),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _sending ? null : _send,
              child: Text(l10n.coachingConsentShare),
            ),
          ),
        ],
      ),
    );
  }
}
