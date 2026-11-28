import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:typed_data';

import 'package:fjelia_core/services/sync/sync_tables.dart';
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

  /// Whether there is anyone to write to yet: a coach, athletes, a group.
  final bool hasCoach;
  final String? relayProblem;

  /// Grows with every change, for screens to read again.
  final int version;
}

/// Why an invitation cannot be answered.
enum InviteProblem { notInvite, ownInvite, coachUnknown, unreachable }

/// An invitation read and its coach found: what the consent screen shows.
class InviteToAnswer {
  const InviteToAnswer(this.invite, this.coachList, this.code);
  final LinkInvite invite;
  final Map<String, dynamic> coachList;

  /// The six-digit code the coach's screen shows too.
  final String code;
}

/// A coach of this athlete, with the link when one holds or held.
class CoachRow {
  const CoachRow(this.coach, this.link);
  final MessagePerson coach;

  /// Null while the coach has not accepted yet.
  final CoachLink? link;
}

class MessagesNotifier extends Notifier<MessagesState>
    with WidgetsBindingObserver {
  PersonIdentity? _me;
  String _name = '';
  Timer? _timer;
  bool _running = false;

  /// The relay; tests point it at a closed port, or answer for it.
  @visibleForTesting
  static Uri relayBase = RelayClient.defaultBase;
  @visibleForTesting
  static RelayTransport? relayTransport;
  final _relay = RelayClient(relayBase, transport: relayTransport);

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
    // Signed, so the coach and this person's other devices take it.
    final self = await ref.read(databaseProvider).self();
    await _book.publishProfile(name: n, photo: self?.photo);
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

  LinkBook get _book => LinkBook(ref.read(databaseProvider), () => _me);

  /// This athlete's coaches, with what each link shares.
  Future<List<CoachRow>> coachRows() async {
    await _open();
    final links = await _book.links();
    return [
      for (final c
          in await ref.read(databaseProvider).people(role: PersonRole.coach))
        CoachRow(c, links.where((l) => l.coach == c.person).firstOrNull),
    ];
  }

  /// The invitation in [text], with the coach's devices from the relay.
  Future<(InviteToAnswer?, InviteProblem?)> readInvite(String text) async {
    final invite = LinkInvite.parse(text);
    if (invite == null) return (null, InviteProblem.notInvite);
    final me = await _open();
    if (invite.coach == me.personId) return (null, InviteProblem.ownInvite);
    try {
      final list = await _relay.list(invite.coach);
      if (list == null) return (null, InviteProblem.coachUnknown);
      return (InviteToAnswer(invite, list, invite.code(me.personId)), null);
    } on Object catch (e) {
      log('[Messages] invitation: $e');
      return (null, InviteProblem.unreachable);
    }
  }

  /// Answers [answer] sharing [scopes]; it goes to the coach now. False
  /// when the coach's list does not fit the invitation.
  Future<bool> answerInvite(
    InviteToAnswer answer,
    Set<SyncCategory> scopes,
  ) async {
    await _open();
    final code = await _book.answer(
      answer.invite,
      answer.coachList,
      name: _name,
      scopes: scopes,
    );
    changed();
    return code != null;
  }

  /// From now on [link] shares [scopes].
  Future<void> share(CoachLink link, Set<SyncCategory> scopes) async {
    await _open();
    await _book.changeSharing(link.id, scopes);
    changed();
  }

  Future<void> endCoaching(CoachLink link) async {
    await _open();
    await _book.endLink(link.id);
    changed();
  }

  // What the screens read and do; they never touch the database.

  /// A new recovery code, to show once; the previous one stops working.
  /// Null when Fjelia's server cannot be reached.
  Future<String?> newRecoveryCode() async {
    try {
      return await makeRecoveryCode(await _open(), _relay, secureSecrets);
    } on Object catch (e) {
      log('[Messages] recovery code: $e');
      return null;
    }
  }

  /// This phone continues as the person of [code]. Null when it worked.
  Future<RestoreProblem?> restore(String code) async {
    final db = ref.read(databaseProvider);
    try {
      final r = await restoreWithCode(
        code,
        relay: _relay,
        store: secureSecrets,
        deviceName: await NearbySyncNotifier.deviceName(),
        platform: Platform.operatingSystem,
      );
      final me = r.identity;
      if (me == null) return r.problem;
      final old = await db.self();
      if (old != null && old.person != me.personId) {
        await db.forgetPerson(old.person);
      }
      await db.savePerson(
        MessagePerson(person: me.personId, name: _name, role: PersonRole.self),
      );
      _me = me;
      _opening = Future.value(me);
      changed();
      return null;
    } on Object catch (e) {
      log('[Messages] restore: $e');
      return RestoreProblem.unreachable;
    }
  }

  Future<List<views.ThreadRow>> threads() async {
    await _open();
    return views.loadThreads(ref.read(databaseProvider));
  }

  Future<List<MessagePerson>> coaches() async {
    await _open();
    return ref.read(databaseProvider).people(role: PersonRole.coach);
  }

  /// Everyone this person can write to directly: their coaches and, when
  /// they coach, their athletes.
  Future<List<MessagePerson>> contacts() async {
    await _open();
    return [
      for (final p in await ref.read(databaseProvider).people())
        if (p.role == PersonRole.coach || p.role == PersonRole.athlete) p,
    ];
  }

  /// Everyone known here by person id, this person too: names as this
  /// person knows them, photos.
  Future<Map<String, MessagePerson>> people() async {
    await _open();
    return {
      for (final p in await ref.read(databaseProvider).people()) p.person: p,
    };
  }

  /// This person's photo, as coaches and athletes see it; null for none.
  Future<Uint8List?> photo() async {
    await _open();
    return (await ref.read(databaseProvider).self())?.photo;
  }

  /// [photo] (small already, see [maxProfilePhotoBytes]) or none from now
  /// on; it goes to the coach signed, with the name.
  Future<void> setPhoto(Uint8List? photo) async {
    await _open();
    await _book.publishProfile(name: _name, photo: photo);
    changed();
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
      // A coach, or athletes for someone who coaches from the phone.
      hasCoach:
          threads.isNotEmpty ||
          people.any(
            (p) => p.role == PersonRole.coach || p.role == PersonRole.athlete,
          ),
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
      final db = ref.read(databaseProvider);
      await MessageRelay(
        db,
        me,
        _relay,
        secureSecrets,
        links: _book,
        // This athlete's training to their coaches, plan changes back.
        changes: ChangeRelay(
          me: me,
          book: _book,
          databaseOf: (athlete) => athlete == me.personId ? db : null,
        ),
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
