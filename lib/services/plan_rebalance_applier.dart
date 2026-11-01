import 'package:drift/drift.dart';

import '../db/database.dart';
import 'plan_rebalance.dart';
import 'plan_session_actions.dart';
import 'session_adaptation_service.dart';

/// The sessions as they were before a proposal was applied.
class RebalanceUndo {
  const RebalanceUndo(this.before);
  final List<TrainingSession> before;
}

/// Carries out a checked proposal and can take it back. Moves keep the
/// workout; adjustments go through the same code as the morning readiness
/// check, so steps are shortened or eased, never rewritten by the coach.
class PlanRebalanceApplier {
  PlanRebalanceApplier(this.db, this.actions, this.adaptation);
  final AppDatabase db;
  final PlanSessionActions actions;
  final SessionAdaptationService adaptation;

  Future<TrainingSession?> _read(String id) => (db.select(
    db.trainingSessions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<RebalanceUndo> apply(
    RebalanceProposal p, {
    String missedId = '',
    String dropReason = 'My choice',
  }) async {
    final before = <TrainingSession>[];
    for (final x in p.changes) {
      final s = await _read(x.sessionId);
      if (s != null) before.add(s);
    }
    for (final x in p.changes) {
      var s = await _read(x.sessionId);
      if (s == null) continue;
      if (x.op == RebalanceOp.drop) {
        await actions.markRest(
          s,
          reason: s.id == missedId ? dropReason : 'Rebalanced by coach',
        );
        continue;
      }
      if (x.op == RebalanceOp.move) s = await actions.moveToDate(s, x.to!);
      if (x.durationMin != null || x.intensity != RebalanceIntensity.keep) {
        s = await adaptation.adjust(
          s,
          durationMin: x.durationMin,
          intensity: x.intensity.name,
        );
      }
      if (x.indoor != null) await actions.setIndoor(s, x.indoor!);
    }
    return RebalanceUndo(before);
  }

  /// Puts every changed session back as it was. A dropped one comes back
  /// through [PlanSessionActions.restore], so its calendar entries return.
  Future<void> undo(RebalanceUndo u) async {
    for (final old in u.before) {
      final now = await _read(old.id);
      if (now == null) continue;
      if (now.status == 'skipped' && old.status != 'skipped') {
        await actions.restore(now);
      }
      await db
          .into(db.trainingSessions)
          .insertOnConflictUpdate(
            old.toCompanion(true).copyWith(dateModified: Value(DateTime.now())),
          );
    }
  }
}
