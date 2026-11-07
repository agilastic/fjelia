import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/mywhoosh_service.dart';
import 'database_provider.dart';

final myWhooshServiceProvider = Provider<MyWhooshService>(
  (ref) => MyWhooshService(ref.read(databaseProvider)),
);

final myWhooshConnectedProvider = FutureProvider<bool>(
  (ref) => ref.read(myWhooshServiceProvider).isConnected,
);

final myWhooshEmailProvider = FutureProvider<String?>(
  (ref) => ref.read(myWhooshServiceProvider).connectedEmail,
);
