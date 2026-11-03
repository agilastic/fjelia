import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/dfa_alpha1.dart';
import '../services/dfa_alpha1_service.dart';
import 'database_provider.dart';

/// DFA alpha1 of an activity, when its file carried beat-to-beat data.
final dfaAlpha1Provider = FutureProvider.autoDispose
    .family<DfaAlpha1Analysis?, String>(
      (ref, activityId) =>
          DfaAlpha1Service(ref.watch(databaseProvider)).load(activityId),
    );
