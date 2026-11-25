import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'daily_readiness_service.dart';

import 'package:fjelia_core/services/session_adaptation.dart';
import 'package:fjelia_core/services/workout_semantics.dart';

class AdaptationResult {
  const AdaptationResult({
    required this.session,
    this.adapted = false,
    this.reason,
  });

  final TrainingSession session;
  final bool adapted;
  final String? reason;
}

/// What the morning check would do to a session, before it is applied.
class AdaptationPreview {
  const AdaptationPreview({
    required this.session,
    required this.title,
    required this.durationMin,
    required this.rest,
  });

  /// The session as it is now.
  final TrainingSession session;

  /// Its title and length after the change.
  final String title;
  final int durationMin;

  /// Rest is advised: the session is released, nothing replaces it.
  final bool rest;
}

/// Adjusts today's planned sessions to the morning readiness level:
/// yellow trims duration by 15 % and drops every HR zone by one, red swaps
/// the session for an easy zone-2 recovery.
class SessionAdaptationService {
  SessionAdaptationService(this._db);

  final AppDatabase _db;

  Future<List<AdaptationResult>> adaptDay(ReadinessResult readiness) async {
    if (readiness.level == ReadinessLevel.green) return const [];
    return [for (final s in await _today()) await adapt(s, readiness)];
  }

  /// What [adaptDay] would change today, without changing anything; empty
  /// when nothing would.
  Future<List<AdaptationPreview>> previewDay(
    ReadinessResult readiness, {
    DateTime? day,
  }) async {
    if (readiness.level == ReadinessLevel.green) return const [];
    return [
      for (final s in await _today(day))
        if (await _change(s, readiness) case final c?)
          AdaptationPreview(
            session: s,
            title: c.title,
            durationMin: c.rest ? 0 : c.duration,
            rest: c.rest,
          ),
    ];
  }

  Future<List<TrainingSession>> _today([DateTime? day]) async {
    final now = day ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final sessions =
        await (_db.select(_db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    // Up to midnight, not including it: tomorrow's
                    // sessions are stored at 00:00.
                    t.sessionDate.isBiggerOrEqualValue(start) &
                    t.sessionDate.isSmallerThanValue(end) &
                    t.status.isIn(const ['planned', 'adapted']),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.sessionNumber)]))
            .get();
    return sessions;
  }

  /// The change readiness asks of [session]; null when it asks none.
  Future<SessionChange?> _change(
    TrainingSession session,
    ReadinessResult readiness,
  ) async {
    String? lastLevel;
    if (readiness.level != ReadinessLevel.green &&
        session.status == 'adapted') {
      // An earlier adjustment stands unless today's finding is stronger: the
      // same evidence read twice must not cut a session twice.
      final last =
          await (_db.select(_db.sessionAdaptations)
                ..where((t) => t.adaptedSessionId.equals(session.id))
                ..orderBy([(t) => OrderingTerm.desc(t.adaptedAt)])
                ..limit(1))
              .getSingleOrNull();
      lastLevel = last?.readinessLevel;
    }
    return ReadinessAdaptation.change(
      session,
      readiness,
      lastAdaptedLevel: lastLevel,
    );
  }

  Future<AdaptationResult> adapt(
    TrainingSession session,
    ReadinessResult readiness,
  ) async {
    final c = await _change(session, readiness);
    if (c == null) return AdaptationResult(session: session);
    final rest = c.rest;
    final newLevel = c.level;
    final newDuration = c.duration;
    final newZone = c.zone;
    final newTitle = c.title;
    final newSteps = c.steps;
    final newTrimp = c.trimp;
    final notes = c.notes;
    final shift = c.shift;
    await _db.transaction(() async {
      await (_db.update(
        _db.trainingSessions,
      )..where((t) => t.id.equals(session.id))).write(
        TrainingSessionsCompanion(
          sessionLevel: Value(newLevel),
          originalSessionLevel: Value(
            session.originalSessionLevel ?? session.sessionLevel,
          ),
          plannedDurationMin: rest ? const Value.absent() : Value(newDuration),
          plannedTrimp: newTrimp == null
              ? const Value.absent()
              : Value(newTrimp),
          primaryZone: Value(newZone),
          title: Value(newTitle),
          stepsJson: Value(newSteps),
          adaptationTrigger: const Value('readiness'),
          sessionNotes: Value(notes),
          tspAdjusted: const Value(true),
          status: Value(rest ? 'skipped' : 'adapted'),
          // New content is new for every watch platform: each one compares
          // what it holds with the session and sends the new content.
          dateModified: Value(DateTime.now()),
        ),
      );
      if (rest) {
        await _db
            .into(_db.sessionActuals)
            .insertOnConflictUpdate(
              SessionActualsCompanion.insert(
                sessionId: session.id,
                skipReason: const Value('Rest advised by readiness'),
              ),
            );
      }
      await _db
          .into(_db.sessionAdaptations)
          .insert(
            SessionAdaptationsCompanion.insert(
              id: const Uuid().v4(),
              originalSessionId: session.id,
              adaptedSessionId: session.id,
              adaptedAt: DateTime.now(),
              readinessLevel: readiness.level.name,
              flagCount: readiness.flagCount,
              flagsFiredJson: ReadinessAdaptation.flagsJson(readiness),
              originalSessionLevel: session.sessionLevel,
              adaptedSessionLevel: newLevel,
              originalDurationMin: session.plannedDurationMin,
              adaptedDurationMin: newDuration,
              zoneShiftJson: Value(
                '{"from": ${session.primaryZone}, "to": $newZone, "shift": $shift}',
              ),
            ),
          );
    });
    final updated = await (_db.select(
      _db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).getSingle();
    return AdaptationResult(
      session: updated,
      adapted: true,
      reason: rest
          ? 'Rest advised: ${readiness.adaptationReason}'
          : readiness.adaptationReason,
    );
  }

  /// A change outside the morning check, e.g. when a missed workout is
  /// fitted into the next days. `easier` lowers every zone by one,
  /// `recovery` turns the session into the easy 30-minute one, `keep` leaves
  /// the zones. [durationMin] shortens the steps to that length; a session is
  /// never made longer or harder here.
  Future<TrainingSession> adjust(
    TrainingSession session, {
    int? durationMin,
    String intensity = 'keep',
    String trigger = 'rebalance',
  }) async {
    if (!const {'planned', 'adapted'}.contains(session.status)) return session;
    final recovery = intensity == 'recovery';
    final shift = intensity == 'easier' ? -1 : 0;
    final target = math.min(
      durationMin ?? session.plannedDurationMin,
      session.plannedDurationMin,
    );
    var title = session.title;
    String? steps;
    int duration;
    int? trimp;
    if (recovery) {
      steps = ReadinessAdaptation.recoveryStepsJson();
      duration = math.min(30, session.plannedDurationMin);
      title = 'Easy Recovery ${ReadinessAdaptation.sportLabel(session.sport)}';
    } else if (session.stepsJson == null) {
      duration = target;
    } else {
      final shifted = shift == 0
          ? session.stepsJson!
          : ReadinessAdaptation.shiftZonesInSteps(session.stepsJson!, shift);
      final base = WorkoutSemantics.of(shifted, sport: session.sport);
      steps = shifted;
      if (!base.isEmpty && target * 60 < base.totalSeconds - 30) {
        final fitted = fitSteadyWorkout(shifted, target * 60.0);
        if (fitted.scaled) {
          steps = fitted.stepsJson;
        } else {
          // Intervals: drop repetitions until it fits, at most a few.
          for (var i = 0; i < 6; i++) {
            final now = WorkoutSemantics.of(steps!, sport: session.sport);
            if (now.totalSeconds <= target * 60 + 30) break;
            final fewer = ReadinessAdaptation.dropOneRepeat(steps);
            if (fewer == steps) break;
            steps = fewer;
          }
        }
      }
      final result = WorkoutSemantics.of(steps!, sport: session.sport);
      duration = result.isEmpty ? target : result.totalMinutes;
      trimp = result.isEmpty ? null : result.legacyLoad.round();
      if (duration != session.plannedDurationMin) {
        title = retimeTitle(session.title, duration);
      }
    }
    final level = recovery
        ? 1
        : shift < 0
        ? dropSessionIntensity(session.sessionLevel)
        : session.sessionLevel;
    final zone = recovery ? 1 : (session.primaryZone + shift).clamp(1, 5);
    await _db.transaction(() async {
      await (_db.update(
        _db.trainingSessions,
      )..where((t) => t.id.equals(session.id))).write(
        TrainingSessionsCompanion(
          sessionLevel: Value(level),
          originalSessionLevel: Value(
            session.originalSessionLevel ?? session.sessionLevel,
          ),
          plannedDurationMin: Value(duration),
          plannedTrimp: trimp == null ? const Value.absent() : Value(trimp),
          primaryZone: Value(zone),
          title: Value(title),
          stepsJson: Value(steps ?? session.stepsJson),
          adaptationTrigger: Value(trigger),
          tspAdjusted: const Value(true),
          status: const Value('adapted'),
          dateModified: Value(DateTime.now()),
          modifiedBy: const Value('athlete'),
        ),
      );
      await _db
          .into(_db.sessionAdaptations)
          .insert(
            SessionAdaptationsCompanion.insert(
              id: const Uuid().v4(),
              originalSessionId: session.id,
              adaptedSessionId: session.id,
              adaptedAt: DateTime.now(),
              readinessLevel: trigger,
              flagCount: 0,
              flagsFiredJson: '{}',
              originalSessionLevel: session.sessionLevel,
              adaptedSessionLevel: level,
              originalDurationMin: session.plannedDurationMin,
              adaptedDurationMin: duration,
              zoneShiftJson: Value(
                '{"from": ${session.primaryZone}, "to": $zone, "shift": $shift}',
              ),
            ),
          );
    });
    return (_db.select(
      _db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).getSingle();
  }
}
