import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/fjelia_edition.dart';

/// FjeliaPro or the free edition, for the screens.
final fjeliaEditionProvider = Provider<FjeliaEdition>((ref) => fjeliaEdition);
