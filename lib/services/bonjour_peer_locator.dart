import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:fjelia_sync/fjelia_sync.dart';

/// Finds a paired computer by Bonjour when its address changed: Fjelia on
/// the computer advertises [bonjourServiceType] with its device id.
class BonjourPeerLocator implements PeerLocator {
  const BonjourPeerLocator({this.timeout = const Duration(seconds: 5)});

  final Duration timeout;

  @override
  Future<String?> locate(String deviceId) async {
    final discovery = BonsoirDiscovery(type: bonjourServiceType);
    final found = Completer<String?>();
    StreamSubscription<BonsoirDiscoveryEvent>? events;
    try {
      await discovery.initialize();
      events = discovery.eventStream?.listen((event) {
        final service = event.service;
        if (service == null ||
            service.attributes[bonjourDeviceKey] != deviceId) {
          return;
        }
        switch (event) {
          case BonsoirDiscoveryServiceFoundEvent():
            unawaited(service.resolve(discovery.serviceResolver));
          case BonsoirDiscoveryServiceResolvedEvent():
          case BonsoirDiscoveryServiceUpdatedEvent():
            final host = service.hostAddress;
            if (host != null && !found.isCompleted) {
              found.complete(
                host.contains(':')
                    ? '[$host]:${service.port}'
                    : '$host:${service.port}',
              );
            }
          default:
        }
      });
      await discovery.start();
      return await found.future.timeout(timeout, onTimeout: () => null);
    } on Object {
      return null; // no discovery on this network or platform
    } finally {
      await events?.cancel();
      await discovery.stop();
    }
  }
}
