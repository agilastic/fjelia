import 'package:fjelia_sync/fjelia_sync.dart' show RestoreProblem;
import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/messages_provider.dart';
import 'thread_screen.dart';

/// Messages with the coach and the coach's groups.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  List<ThreadRow> _threads = const [];
  List<MessagePerson> _coaches = const [];
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    ref.read(messagesProvider.notifier).changed();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final messages = ref.read(messagesProvider.notifier);
    final threads = await messages.threads();
    final coaches = await messages.coaches();
    if (!mounted) return;
    if (_name.text.isEmpty) {
      _name.text = ref.read(messagesProvider.notifier).name;
    }
    setState(() {
      _threads = threads;
      _coaches = coaches;
    });
  }

  Future<void> _open(String thread) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ThreadScreen(thread: thread)),
    );
    await _load();
  }

  Future<void> _write(MessagePerson coach) async {
    final id = await ref.read(messagesProvider.notifier).startDirect(coach);
    await _open(id);
  }

  Future<void> _newCode() async {
    final l10n = context.l10n;
    final code = await ref.read(messagesProvider.notifier).newRecoveryCode();
    if (!mounted) return;
    if (code == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.messagesRecoveryUnreachable)));
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.messagesRecovery),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Menlo',
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.messagesRecoveryShown),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: code)),
            child: Text(l10n.messagesCopy),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.messagesDone),
          ),
        ],
      ),
    );
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    final field = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.messagesRestore),
        content: TextField(
          controller: field,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: InputDecoration(hintText: l10n.messagesRestoreHint),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: Text(l10n.messagesDone),
          ),
        ],
      ),
    );
    field.dispose();
    if (code == null || code.trim().isEmpty) return;
    final problem = await ref.read(messagesProvider.notifier).restore(code);
    if (!mounted) return;
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            problem == RestoreProblem.unreachable
                ? l10n.messagesRecoveryUnreachable
                : l10n.messagesRestoreWrong,
          ),
        ),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(messagesProvider.select((s) => s.version), (_, _) => _load());
    final direct = {
      for (final t in _threads)
        if (t.kind == ThreadKind.direct)
          for (final m in t.members) m.person,
    };
    final day = DateFormat.MMMd();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.messagesTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(messagesProvider.notifier).relay(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (_threads.isEmpty && _coaches.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.messagesEmpty, textAlign: TextAlign.center),
              ),
            for (final t in _threads)
              ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    t.kind == ThreadKind.group ? Icons.groups : Icons.person,
                  ),
                ),
                title: Text(t.title),
                subtitle: t.lastText == null
                    ? null
                    : Text(
                        t.kind == ThreadKind.group && t.lastSender != null
                            ? '${t.lastSender}: ${t.lastText}'
                            : t.lastText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: t.unread > 0
                    ? Badge(label: Text('${t.unread}'))
                    : Text(day.format(t.lastAt)),
                onTap: () => _open(t.id),
              ),
            for (final c in _coaches)
              if (!direct.contains(c.person))
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.edit)),
                  title: Text(l10n.messagesWriteTo(c.name)),
                  onTap: () => _write(c),
                ),
            if (_coaches.isNotEmpty || _threads.isNotEmpty) ...[
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _name,
                  maxLength: 80,
                  decoration: InputDecoration(
                    labelText: l10n.messagesYourName,
                    helperText: l10n.messagesYourNameHelp,
                    counterText: '',
                  ),
                  onSubmitted: (v) =>
                      ref.read(messagesProvider.notifier).rename(v),
                ),
              ),
            ],
            const Divider(height: 32),
            if (_threads.isEmpty && _coaches.isEmpty)
              ListTile(
                leading: const Icon(Icons.restore),
                title: Text(l10n.messagesRestore),
                onTap: _restore,
              )
            else
              ListTile(
                leading: const Icon(Icons.key_outlined),
                title: Text(l10n.messagesRecoveryMake),
                subtitle: Text(l10n.messagesRecoveryHelp),
                onTap: _newCode,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.messagesPrivacy,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
