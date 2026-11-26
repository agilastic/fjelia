import 'dart:developer' show log;

import 'package:fjelia_data/sync.dart';

import '../db/database.dart';
import 'training_plan_service.dart';
import 'workout_providers/workout_providers.dart';

/// Sessions a computer changed reach the phone by sync, past the planner
/// that would update the watch calendars. This does it afterwards: a
/// skipped session comes off, a moved or edited one goes up again, and new
/// sessions of the active plan go out as after any other change.
class SyncedPlanFollowUp {
  SyncedPlanFollowUp(this._db, this._plans, this._providers);

  final AppDatabase _db;
  final TrainingPlanService _plans;
  final WorkoutProviders _providers;

  /// Follows up on the sessions [fromDevice] changed after log position
  /// [afterSeq]. Best effort: a platform out of reach is tried again with
  /// the next change.
  Future<void> run(String fromDevice, {required int afterSeq}) async {
    final keys = await _db.syncKeysFrom(
      'training_sessions',
      fromDevice,
      afterSeq: afterSeq,
    );
    if (keys.isEmpty) return;
    for (final key in keys) {
      final s = await (_db.select(
        _db.trainingSessions,
      )..where((t) => t.id.equals('${key.first}'))).getSingleOrNull();
      // Deleted on the computer: what was sent for it stays until the
      // platform's own cleanup, as the ids went with the row.
      if (s == null) continue;
      if (s.status == 'skipped') {
        await _providers.releaseEverywhere(s);
        continue;
      }
      if (!['planned', 'adapted'].contains(s.status)) continue;
      for (final p in await _providers.deliveredTo(s)) {
        try {
          // Puts it on its new day, or sends the new content.
          await _plans.deliver(s.id, p);
        } catch (e) {
          log('[NearbySync] ${p.label} update failed for ${s.id}: $e');
        }
      }
    }
    try {
      await _plans.deliverPlan('self');
    } catch (e) {
      log('[NearbySync] new sessions not sent: $e');
    }
  }
}
