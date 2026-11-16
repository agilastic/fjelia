import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/bp_monitor_registry.dart';
import 'hilo_sync_provider.dart';

export '../services/bp_monitor_registry.dart' show BpMonitor;

final bpMonitorStoreProvider = Provider((ref) => const BpMonitorStore());

/// Every saved Bluetooth blood-pressure monitor: the paired Hilo cuff first,
/// then the Omron and standard ones in the order they were added.
final bpMonitorsProvider = FutureProvider<List<BpMonitor>>((ref) async {
  String? cuff;
  try {
    cuff = await ref.read(hiloBleServiceProvider).getCuffName();
  } catch (_) {
    // Without the Hilo service the cuff is simply not there.
  }
  return [
    if (cuff != null) BpMonitor(kind: 'hilo', id: 'hilo', name: cuff),
    ...await ref.read(bpMonitorStoreProvider).list(),
  ];
});

final bpMonitorActionsProvider = Provider(BpMonitorActions.new);

class BpMonitorActions {
  BpMonitorActions(this.ref);
  final Ref ref;

  Future<void> save(BpMonitor monitor) async {
    await ref.read(bpMonitorStoreProvider).save(monitor);
    ref.invalidate(bpMonitorsProvider);
  }

  Future<void> remove(BpMonitor monitor) async {
    if (monitor.live) {
      await ref.read(hiloBleServiceProvider).unpairCuff();
    } else {
      await ref.read(bpMonitorStoreProvider).remove(monitor.id);
    }
    ref.invalidate(bpMonitorsProvider);
  }

  /// After the Hilo cuff was paired elsewhere.
  void refresh() => ref.invalidate(bpMonitorsProvider);
}
