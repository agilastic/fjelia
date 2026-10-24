import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'database_provider.dart';

final gripStrengthProvider = FutureProvider<List<GripStrengthRecord>>(
  (ref) => ref.watch(databaseProvider).getGripStrengthRange(),
);

final latestGripStrengthProvider = FutureProvider<GripStrengthRecord?>(
  (ref) => ref.watch(databaseProvider).getLatestGripStrength(),
);

final gripStrengthNotifierProvider =
    AsyncNotifierProvider<GripStrengthNotifier, void>(GripStrengthNotifier.new);

class GripStrengthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> add(DateTime measuredAt, double? leftKg, double? rightKg) async {
    await ref
        .read(databaseProvider)
        .insertGripStrength(
          GripStrengthRecordsCompanion(
            measuredAt: Value(measuredAt),
            leftKg: Value(leftKg),
            rightKg: Value(rightKg),
          ),
        );
    ref.invalidate(gripStrengthProvider);
    ref.invalidate(latestGripStrengthProvider);
  }

  Future<void> delete(int id) async {
    await ref.read(databaseProvider).deleteGripStrength(id);
    ref.invalidate(gripStrengthProvider);
    ref.invalidate(latestGripStrengthProvider);
  }
}
