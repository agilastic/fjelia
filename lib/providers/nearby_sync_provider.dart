import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fjelia_sync/fjelia_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/bonjour_peer_locator.dart';
import 'database_provider.dart';

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
  const NearbySyncing(this.sent);
  final int sent;
}

class NearbySynced extends NearbySyncStatus {
  const NearbySynced(this.sent);
  final int sent;
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

  /// Sends [peer] what it does not have yet.
  Future<void> sync(SyncPeer peer) async {
    if (state[peer.deviceId] is NearbySyncing) return;
    _set(peer.deviceId, const NearbySyncing(0));
    try {
      final sent = await (await _client()).push(
        peer,
        onPage: (sent) => _set(peer.deviceId, NearbySyncing(sent)),
      );
      _set(peer.deviceId, NearbySynced(sent));
    } on Object catch (e) {
      log('[NearbySync] sync with ${peer.name} failed: $e');
      _set(peer.deviceId, NearbySyncFailed(_problem(e)));
    }
  }

  /// Syncs every paired computer, quietly: when the app comes back.
  Future<void> syncAll() async {
    final peers = await ref.read(databaseProvider).syncPeers();
    await Future.wait(peers.map(sync));
  }

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
