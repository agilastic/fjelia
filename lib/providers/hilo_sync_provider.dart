import 'package:fjelia_service/fjelia_service.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_provider.dart';

/// The live Hilo service, so the sync notifier can trigger a bracelet sync
/// without holding a ref to this provider.
HiloBleService? activeHiloBleService;

final hiloBleServiceProvider = Provider<HiloBleService>((ref) {
  final service = createHiloBleService(
    onUploadComplete: () =>
        ref.read(syncProvider.notifier).refreshAktiiaAfterBleUpload(),
  );
  activeHiloBleService = service;
  ref.onDispose(() {
    service.dispose();
    activeHiloBleService = null;
  });
  return service;
});

final hiloSyncStateProvider = StreamProvider<HiloSyncState>(
  (ref) => ref.watch(hiloBleServiceProvider).stateStream,
);

final hiloBleConnectedProvider = FutureProvider<bool>(
  (ref) async => await ref.read(hiloBleServiceProvider).getPairedMac() != null,
);
