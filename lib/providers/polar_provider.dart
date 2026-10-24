import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/polar_service.dart';
import 'database_provider.dart';

final polarServiceProvider = Provider<PolarService>(
  (ref) => PolarService(ref.read(databaseProvider)),
);

final polarConnectedProvider = FutureProvider<bool>(
  (ref) => ref.read(polarServiceProvider).isConnected,
);

final polarEmailProvider = FutureProvider<String?>(
  (ref) => ref.read(polarServiceProvider).connectedEmail,
);
