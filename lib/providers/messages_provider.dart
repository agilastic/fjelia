import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';

import 'package:fjelia_data/messages.dart';
import 'package:fjelia_sync/fjelia_sync.dart';
import 'package:fjelia_views/fjelia_views.dart' as views;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'nearby_sync_provider.dart' show NearbySyncNotifier, secureSecrets;

/// Messages with the coach (and the coach's groups): this phone's person,
/// introduced to the computer at each nearby sync, and the messages that go
/// through the relay, encrypted for each device in the thread.
class MessagesState {
  const MessagesState({
    this.unread = 0,
    this.hasCoach = false,
    this.relayProblem,
    this.version = 0,
  });

  final int unread;

  /// Whether this athlete has met a coach (or a group) yet.
  final bool hasCoach;
  final String? relayProblem;

  /// Grows with every change, for screens to read again.
  final int version;
}

class MessagesNotifier extends Notifier<MessagesState>
    with WidgetsBindingObserver {
  PersonIdentity? _me;
  String _name = '';
  Timer? _timer;
  bool _running = false;

  /// The relay; tests point it at a closed port.
  @visibleForTesting
  static Uri relayBase = RelayClient.defaultBase;
  final _relay = RelayClient(relayBase);

  @override
  MessagesState build() {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => relay());
    ref.onDispose(() {
      _timer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });
    unawaited(_open().then((_) => relay()));
    return const MessagesState();
  }

  @override
  // `state` here is the app's, not this notifier's.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(relay());
  }

  Future<PersonIdentity>? _opening;

  /// This phone's person, made once: callers at the same moment wait for
  /// the same one.
  Future<PersonIdentity> _open() => _opening ??= _make().whenComplete(() {
    if (_me == null) _opening = null; // failed: try again next time
  });

  Future<PersonIdentity> _make() async {
    final db = ref.read(databaseProvider);
    await db.installMessages();
    final me =
        await PersonIdentity.load(secureSecrets) ??
        (await PersonIdentity.create(
          secureSecrets,
          deviceName: await NearbySyncNotifier.deviceName(),
          platform: Platform.operatingSystem,
        )).identity;
    _me = me;
    final self = await db.self();
    _name = self?.name ?? _defaultName(await NearbySyncNotifier.deviceName());
    if (self?.person != me.personId) {
      await db.savePerson(
        MessagePerson(person: me.personId, name: _name, role: PersonRole.self),
      );
    }
    return me;
  }

  /// "Alex's iPhone" → "Alex".
  static String _defaultName(String device) {
    final m = RegExp(r"^(.+?)(’|')s\s").firstMatch(device);
    return m?.group(1) ?? device;
  }

  String get name => _name;

  /// Once this phone's person exists (made at the first start).
  Future<void> ready() => _open();

  Future<void> rename(String name) async {
    final n = name.trim();
    final me = _me;
    if (n.isEmpty || n.length > 80 || me == null) return;
    _name = n;
    await ref
        .read(databaseProvider)
        .savePerson(
          MessagePerson(person: me.personId, name: n, role: PersonRole.self),
        );
    changed();
  }

  /// For the nearby sync client.
  Future<PersonSide> side() async {
    await _open();
    return PersonSide(
      db: ref.read(databaseProvider),
      store: secureSecrets,
      identity: () => _me,
      name: () => _name,
      onChanged: (i) => _me = i,
    );
  }

  String? get personId => _me?.personId;

  // What the screens read and do; they never touch the database.

  Future<List<views.ThreadRow>> threads() async {
    await _open();
    return views.loadThreads(ref.read(databaseProvider));
  }

  Future<List<MessagePerson>> coaches() async {
    await _open();
    return ref.read(databaseProvider).people(role: PersonRole.coach);
  }

  /// The thread's events; opening it marks it read.
  Future<List<StoredEvent>> openThread(String thread) async {
    await _open();
    final events = await views.openThread(ref.read(databaseProvider), thread);
    // Read now: the badge changes, the screens need not load again.
    unawaited(_refresh(bump: false));
    return events;
  }

  Future<String> startDirect(MessagePerson coach) async {
    await _open();
    return views.startDirect(ref.read(databaseProvider), coach);
  }

  Future<void> send(String thread, String text) async {
    await _open();
    await views.sendText(ref.read(databaseProvider), thread, text);
    changed();
  }

  Future<void> leave(String thread) async {
    await _open();
    await views.leaveGroup(ref.read(databaseProvider), thread);
    changed();
  }

  /// Something changed (a sync, a message written): show it, and send.
  void changed() {
    unawaited(_refresh());
    unawaited(relay());
  }

  Future<void> _refresh({bool bump = true}) async {
    final db = ref.read(databaseProvider);
    await db.installMessages();
    final threads = await db.threads();
    final people = await db.people();
    state = MessagesState(
      unread: threads.fold(0, (n, t) => n + t.unread),
      hasCoach:
          threads.isNotEmpty || people.any((p) => p.role == PersonRole.coach),
      relayProblem: state.relayProblem,
      version: bump ? state.version + 1 : state.version,
    );
  }

  /// Sends what waits and takes what arrived.
  Future<void> relay() async {
    if (_running) return;
    _running = true;
    String? problem;
    try {
      final me = await _open();
      await MessageRelay(
        ref.read(databaseProvider),
        me,
        _relay,
        secureSecrets,
      ).run();
    } on Object catch (e) {
      problem = '$e';
      log('[Messages] relay: $e');
    } finally {
      _running = false;
    }
    await _refresh();
    if (state.relayProblem != problem) {
      state = MessagesState(
        unread: state.unread,
        hasCoach: state.hasCoach,
        relayProblem: problem,
        version: state.version + 1,
      );
    }
  }
}

final messagesProvider = NotifierProvider<MessagesNotifier, MessagesState>(
  MessagesNotifier.new,
);
