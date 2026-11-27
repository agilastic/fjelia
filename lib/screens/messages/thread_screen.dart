import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/messages_provider.dart';

/// One conversation: with the coach, or a coach's group.
class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.thread});
  final String thread;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  ThreadRow? _row;
  List<StoredEvent> _events = const [];
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final messages = ref.read(messagesProvider.notifier);
    final row = (await messages.threads())
        .where((t) => t.id == widget.thread)
        .firstOrNull;
    final events = await messages.openThread(widget.thread);
    if (!mounted) return;
    setState(() {
      _row = row;
      _events = events;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    if (_text.text.trim().isEmpty) return;
    final text = _text.text;
    _text.clear();
    await ref.read(messagesProvider.notifier).send(widget.thread, text);
    await _load();
  }

  Future<void> _leave() async {
    await ref.read(messagesProvider.notifier).leave(widget.thread);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(messagesProvider.select((s) => s.version), (_, _) => _load());
    final row = _row;
    final me = ref.read(messagesProvider.notifier).personId;
    final member = row?.members.any((m) => m.person == me) ?? false;
    String nameOf(String person) => person == me
        ? l10n.messagesYou
        : row?.members.where((m) => m.person == person).firstOrNull?.name ??
              '?';
    String? change(ThreadEvent e) {
      final who = nameOf(e.sender);
      final names = e.members.map((m) => m.name).join(', ');
      return switch (e.type) {
        EventType.created when e.kind == ThreadKind.group =>
          l10n.messagesStarted(who, e.title ?? ''),
        EventType.added => l10n.messagesAdded(who, names),
        EventType.removed => l10n.messagesRemoved(who, names),
        EventType.left => l10n.messagesLeft(who),
        EventType.renamed => l10n.messagesRenamed(who, e.title ?? ''),
        _ => null,
      };
    }

    final time = DateFormat.MMMd().add_Hm();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(row?.title ?? ''),
        actions: [
          if (row != null &&
              row.kind == ThreadKind.group &&
              member &&
              !row.mine)
            PopupMenuButton<void>(
              itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: _leave,
                  child: Text(l10n.messagesLeaveGroup),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              children: [
                for (final s in _events)
                  if (s.event.type == EventType.text)
                    Align(
                      alignment: s.event.sender == me
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .78,
                        ),
                        child: Card(
                          color: s.event.sender == me
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (row?.kind == ThreadKind.group &&
                                    s.event.sender != me)
                                  Text(
                                    nameOf(s.event.sender),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                Text(s.event.text!),
                                Text(
                                  s.outgoing && !s.relayed
                                      ? '${time.format(s.event.sent.toLocal())} · ${l10n.messagesWaiting}'
                                      : time.format(s.event.sent.toLocal()),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (change(s.event) case final line?)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        line,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: member
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            minLines: 1,
                            maxLines: 5,
                            maxLength: maxTextLength,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: l10n.messagesHint,
                              counterText: '',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.messagesSend,
                          icon: const Icon(Icons.send),
                          onPressed: _send,
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.messagesGone),
                  ),
          ),
        ],
      ),
    );
  }
}
