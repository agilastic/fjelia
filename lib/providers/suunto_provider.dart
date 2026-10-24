import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/suunto_service.dart';
import 'database_provider.dart';

final suuntoServiceProvider = Provider<SuuntoService>(
  (ref) => SuuntoService(ref.read(databaseProvider)),
);

final suuntoConnectedProvider = FutureProvider<bool>(
  (ref) => ref.read(suuntoServiceProvider).isConnected,
);

final suuntoEmailProvider = FutureProvider<String?>(
  (ref) => ref.read(suuntoServiceProvider).connectedEmail,
);
