import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fjelia_sync/fjelia_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/bonjour_peer_locator.dart';
import 'database_provider.dart';
import 'day_data_provider.dart'
    show fullSyncListenerProvider, syncStatusListenerProvider;
import 'sync_provider.dart' show waitForSyncToSettle;

/// Settings → System → Computers: this phone pairs with Fjelia on a Mac or
/// PC by its QR code and sends it its changes over the local network.

class _SecureSecrets implements SecretStore {
  const _SecureSecrets();
  static const _storage = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final syncIdentityProvider = FutureProvider<DeviceIdentity>(
  (ref) => DeviceIdentity.loadOrCreate(const _SecureSecrets()),
);

final syncPeersProvider = FutureProvider<List<SyncPeer>>(
  (ref) => ref.watch(databaseProvider).syncPeers(),
);

/// Why a sync or pairing did not happen, for the message to show.
enum NearbySyncProblem { unreachable, codeExpired, updateBoth, pairAgain }

/// What is happening with one paired computer.
sealed class NearbySyncStatus {
  const NearbySyncStatus();
}

class NearbySyncing extends NearbySyncStatus {
  const NearbySyncing(this.sent, [this.total]);
  final int sent;

  /// All that is due, once known.
  final int? total;
}

class NearbySynced extends NearbySyncStatus {
  const NearbySynced(this.sent, this.received);
  final int sent;
  final int received;
}

class NearbySyncFailed extends NearbySyncStatus {
  const NearbySyncFailed(this.problem);
  final NearbySyncProblem problem;
}

/// The status per computer by device id.
class NearbySyncNotifier extends Notifier<Map<String, NearbySyncStatus>> {
  @override
  Map<String, NearbySyncStatus> build() => const {};

  Future<SyncClient> _client() async => SyncClient(
    db: ref.read(databaseProvider),
    identity: await ref.read(syncIdentityProvider.future),
    name: await _deviceName(),
    secrets: const _SecureSecrets(),
    locator: const BonjourPeerLocator(),
  );

  void _set(String id, NearbySyncStatus status) =>
      state = {...state, id: status};

  /// Pairs with the computer that showed [offer] and sends it everything.
  /// Returns the problem when pairing failed.
  Future<NearbySyncProblem?> pair(PairingOffer offer) async {
    try {
      final peer = await (await _client()).pair(offer);
      ref.invalidate(syncPeersProvider);
      unawaited(sync(peer));
      return null;
    } on Object catch (e) {
      log('[NearbySync] pairing failed: $e');
      return _problem(e);
    }
  }

  /// Waits before each retry of a sync the computer did not answer.
  static const retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 30),
    Duration(minutes: 2),
  ];

  /// Sends [peer] what it does not have yet and takes its changes. A sync
  /// started on its own ([retry]) tries again later while the computer is
  /// out of reach, such as asleep or on another network for a moment.
  Future<void> sync(SyncPeer peer, {bool retry = false}) async {
    if (state[peer.deviceId] is NearbySyncing) return;
    for (var attempt = 0; ; attempt++) {
      _set(peer.deviceId, const NearbySyncing(0));
      try {
        final result = await (await _client()).sync(
          peer,
          onProgress: (sent, total) =>
              _set(peer.deviceId, NearbySyncing(sent, total)),
        );
        _set(peer.deviceId, NearbySynced(result.sent, result.received));
        ref.invalidate(syncPeersProvider);
        if (result.received > 0) {
          // Edits made on the computer: the screens read again.
          ref.read(syncStatusListenerProvider.notifier).state++;
          ref.read(fullSyncListenerProvider.notifier).state++;
        }
        return;
      } on Object catch (e) {
        log('[NearbySync] sync with ${peer.name} failed: $e');
        final problem = _problem(e);
        _set(peer.deviceId, NearbySyncFailed(problem));
        if (!retry ||
            problem != NearbySyncProblem.unreachable ||
            attempt >= retryDelays.length) {
          return;
        }
        await Future<void>.delayed(retryDelays[attempt]);
        // Unpaired or synced by hand meanwhile.
        if (state[peer.deviceId] is! NearbySyncFailed) return;
      }
    }
  }

  /// Syncs every paired computer, quietly, trying again while one is out
  /// of reach.
  Future<void> syncAll() async {
    final peers = await ref.read(databaseProvider).syncPeers();
    await Future.wait(peers.map((p) => sync(p, retry: true)));
  }

  /// Before all data is deleted: each computer forgets this phone, so no
  /// pairing is left behind there. A computer out of reach keeps it until
  /// it is unpaired there.
  Future<void> unpairAll() async {
    final peers = await ref.read(databaseProvider).syncPeers();
    for (final peer in peers) {
      try {
        await unpair(peer).timeout(const Duration(seconds: 5));
      } on Object catch (e) {
        log('[NearbySync] ${peer.name} not told about the unpairing: $e');
      }
    }
  }

  Future<void>? _afterOtherSyncs;

  /// Syncs every paired computer once the watch, health and history syncs
  /// are done, so the computer gets what they brought in. Calls while one is
  /// still waiting share it.
  Future<void> syncAfterOtherSyncs() => _afterOtherSyncs ??= () async {
    try {
      await waitForSyncToSettle(ref);
    } finally {
      _afterOtherSyncs = null;
    }
    await syncAll();
  }();

  Future<void> unpair(SyncPeer peer) async {
    await (await _client()).unpair(peer);
    state = {...state}..remove(peer.deviceId);
    ref.invalidate(syncPeersProvider);
  }

  static NearbySyncProblem _problem(Object e) => switch (e) {
    SyncRefused(reason: 'token') => NearbySyncProblem.codeExpired,
    SyncRefused(reason: 'schema') => NearbySyncProblem.updateBoth,
    SyncRefused(reason: 'unknown_device') => NearbySyncProblem.pairAgain,
    _ => NearbySyncProblem.unreachable,
  };

  static Future<String> _deviceName() async {
    final info = DeviceInfoPlugin();
    try {
      if (Platform.isIOS) return (await info.iosInfo).name;
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return '${android.manufacturer} ${android.model}';
      }
    } on Object {
      // The generic name below.
    }
    return Platform.localHostname;
  }
}

final nearbySyncProvider =
    NotifierProvider<NearbySyncNotifier, Map<String, NearbySyncStatus>>(
      NearbySyncNotifier.new,
    );
