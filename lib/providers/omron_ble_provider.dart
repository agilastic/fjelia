import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/omron_ble_service.dart';
import '../services/omron_reading_store.dart';
import 'database_provider.dart';
import 'day_data_provider.dart' show syncStatusListenerProvider;

final omronBleServiceProvider = Provider<OmronBleService>(
  (ref) => OmronBleService(),
);

final omronReadingStoreProvider = Provider<OmronReadingStore>(
  (ref) => OmronReadingStore(
    ref.watch(databaseProvider),
    onSaved: () => ref.read(syncStatusListenerProvider.notifier).state++,
  ),
);
