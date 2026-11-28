import 'dart:typed_data';

import 'package:fjelia_sync/fjelia_sync.dart'
    show RestoreProblem, maxProfilePhotoBytes;
import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/messages_provider.dart';
import '../../widgets/person_avatar.dart';
import 'coaching_screen.dart';
import 'thread_screen.dart';

/// Messages with the coach and the coach's groups.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  List<ThreadRow> _threads = const [];
  List<MessagePerson> _contacts = const [];
  Uint8List? _photo;
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
    final contacts = await messages.contacts();
    final photo = await messages.photo();
    if (!mounted) return;
    if (_name.text.isEmpty) {
      _name.text = ref.read(messagesProvider.notifier).name;
    }
    setState(() {
      _threads = threads;
      _contacts = contacts;
      _photo = photo;
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

  /// The photo coaches and athletes see: a new one, or none.
  Future<void> _changePhoto() async {
    final l10n = context.l10n;
    final remove = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.messagesChoosePhoto),
              onTap: () => Navigator.pop(sheet, false),
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.messagesRemovePhoto),
                onTap: () => Navigator.pop(sheet, true),
              ),
          ],
        ),
      ),
    );
    if (remove == null) return;
    final messages = ref.read(messagesProvider.notifier);
    if (remove) {
      await messages.setPhoto(null);
    } else {
      // Small before it travels: a profile photo is shown small anyway.
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > maxProfilePhotoBytes) return;
      await messages.setPhoto(bytes);
    }
    await _load();
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
            if (_threads.isEmpty && _contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.messagesEmpty, textAlign: TextAlign.center),
              ),
            for (final t in _threads)
              ListTile(
                leading: t.kind == ThreadKind.group
                    ? const CircleAvatar(child: Icon(Icons.groups))
                    : PersonAvatar(name: t.title, photo: t.photo),
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
            for (final c in _contacts)
              if (!direct.contains(c.person))
                ListTile(
                  leading: PersonAvatar(name: c.shownName, photo: c.photo),
                  title: Text(l10n.messagesWriteTo(c.shownName)),
                  onTap: () => _write(c),
                ),
            const Divider(height: 32),
            // What coaches and athletes see of this person.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _changePhoto,
                    child: Semantics(
                      button: true,
                      label: l10n.messagesChoosePhoto,
                      child: PersonAvatar(
                        name: _name.text,
                        photo: _photo,
                        radius: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
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
              ),
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.sports),
              title: Text(l10n.coachingTitle),
              subtitle: Text(l10n.coachingSubtitle),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CoachingScreen(),
                  ),
                );
                await _load();
              },
            ),
            if (_threads.isEmpty && _contacts.isEmpty)
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
