import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/coros_service.dart';
import 'database_provider.dart';

final corosServiceProvider = Provider<CorosService>(
  (ref) => CorosService(ref.read(databaseProvider)),
);

final corosConnectedProvider = FutureProvider<bool>(
  (ref) => ref.read(corosServiceProvider).isConnected,
);

final corosEmailProvider = FutureProvider<String?>(
  (ref) => ref.read(corosServiceProvider).connectedEmail,
);
