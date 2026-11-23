import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'database_provider.dart';

/// What the coach said on a day (briefings so far), oldest first.
final coachMessagesProvider = FutureProvider.autoDispose
    .family<List<CoachMessage>, DateTime>(
      (ref, day) => ref.watch(databaseProvider).coachMessagesOn(day),
    );
