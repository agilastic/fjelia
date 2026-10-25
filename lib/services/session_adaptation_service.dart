import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'daily_readiness_service.dart';
import 'workout_semantics.dart';

/// Session intensity tiers, easiest first.
const _levels = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

int _dropIntensity(int level) {
  final i = _levels.indexOf(level);
  if (i < 0) return level;
  return _levels[(i - 1).clamp(0, _levels.length - 1)];
}

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

/// Adjusts today's planned sessions to the morning readiness level:
/// yellow trims duration by 15 % and drops every HR zone by one, red swaps
/// the session for an easy zone-2 recovery.
class SessionAdaptationService {
  SessionAdaptationService(this._db);

  final AppDatabase _db;

  Future<List<AdaptationResult>> adaptDay(ReadinessResult readiness) async {
    if (readiness.level == ReadinessLevel.green) return const [];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final sessions =
        await (_db.select(_db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.sessionDate.isBetweenValues(start, end) &
                    t.status.isIn(const ['planned', 'adapted']),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.sessionNumber)]))
            .get();
    return [for (final s in sessions) await adapt(s, readiness)];
  }

  Future<AdaptationResult> adapt(
    TrainingSession session,
    ReadinessResult readiness,
  ) async {
    if (readiness.level == ReadinessLevel.green) {
      return AdaptationResult(session: session);
    }
    if (session.status == 'adapted') {
      // An earlier adjustment stands unless today's finding is stronger: the
      // same evidence read twice must not cut a session twice.
      final last =
          await (_db.select(_db.sessionAdaptations)
                ..where((t) => t.adaptedSessionId.equals(session.id))
                ..orderBy([(t) => OrderingTerm.desc(t.adaptedAt)])
                ..limit(1))
              .getSingleOrNull();
      final stronger =
          readiness.level == ReadinessLevel.red &&
          last?.readinessLevel != 'red';
      if (!stronger) return AdaptationResult(session: session);
    } else if (session.status != 'planned') {
      return AdaptationResult(session: session);
    }

    final red = readiness.level == ReadinessLevel.red;
    // The readiness says rest: that is not a reason to add an easy session.
    final rest = red && readiness.severity == TrainingSeverity.rest;
    final int newLevel;
    final int newDuration;
    final int newZone;
    var newTitle = session.title;
    final String? newSteps;
    final int? newTrimp;
    final String notes;
    var shift = 0;

    if (rest) {
      newLevel = session.sessionLevel;
      newDuration = 0;
      newZone = session.primaryZone;
      newSteps = session.stepsJson;
      newTrimp = null;
      notes =
          'Your readiness says rest today. No replacement session was added; '
          'restore the session if you want to train anyway.';
    } else if (red) {
      newLevel = 1;
      newDuration = math.min(30, session.plannedDurationMin);
      newZone = 1;
      newTitle = 'Easy Recovery ${_sportLabel(session.sport)}';
      newSteps = _recoveryStepsJson();
      newTrimp = null;
      notes =
          'Your body is signalling it needs more rest today. This easy '
          'session keeps momentum without adding fatigue.';
    } else {
      shift = -1;
      newLevel = _dropIntensity(session.sessionLevel);
      newZone = (session.primaryZone - 1).clamp(1, 5);
      notes =
          'Today\'s effort adjusted to match your recovery. Same session, '
          'slightly easier pace.';
      if (session.stepsJson == null) {
        newSteps = null;
        newTrimp = null;
        newDuration = (session.plannedDurationMin * 0.85).round();
      } else {
        // The steps change, not just the number shown: an easy main step is
        // shortened, else one repetition of the first repeat group dropped.
        final shifted = _shiftZonesInSteps(session.stepsJson!, shift);
        final base = WorkoutSemantics.of(shifted, sport: session.sport);
        var steps = shifted;
        if (!base.isEmpty) {
          final fitted = fitSteadyWorkout(shifted, base.totalSeconds * 0.85);
          steps = fitted.scaled ? fitted.stepsJson : _dropOneRepeat(shifted);
        }
        final result = WorkoutSemantics.of(steps, sport: session.sport);
        newSteps = steps;
        newDuration = result.isEmpty
            ? (session.plannedDurationMin * 0.85).round()
            : result.totalMinutes;
        newTrimp = result.isEmpty ? null : result.legacyLoad.round();
        if (steps != shifted && newDuration != session.plannedDurationMin) {
          newTitle = retimeTitle(session.title, newDuration);
        }
      }
    }

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
              flagsFiredJson: _flagsJson(readiness),
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

  /// Drops one repetition of the first repeat group of three or more.
  String _dropOneRepeat(String stepsJson) {
    final decoded = jsonDecode(stepsJson);
    if (decoded is! List) return stepsJson;
    for (var i = 0; i < decoded.length; i++) {
      final step = decoded[i];
      if (step is! Map || step['workoutSteps'] is! List) continue;
      final n = (step['numberOfIterations'] as num?)?.toInt() ?? 1;
      if (n < 3) continue;
      final out = [...decoded];
      out[i] = {
        ...Map<String, dynamic>.from(step),
        'numberOfIterations': n - 1,
        'endConditionValue': n - 1,
      };
      return jsonEncode(out);
    }
    return stepsJson;
  }

  String _flagsJson(ReadinessResult r) => jsonEncode(<String, bool>{
    'hrv': r.hrvLow,
    'hr': r.restingHrHigh,
    'sleep': r.sleepShort || r.remLow || r.deepLow || r.spo2Low,
    'battery': r.batteryLow,
    'skinTemp': r.skinTempShift,
    'fatigue': r.fatigue,
  });

  /// 5 min warm-up, 20 min steady, 5 min cool-down — all in HR zone 1.
  String _recoveryStepsJson() {
    Map<String, Object> step(int typeId, String key, int seconds) => {
      'type': 'ExecutableStepDTO',
      'stepType': {'stepTypeId': typeId, 'stepTypeKey': key},
      'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
      'endConditionValue': seconds,
      'targetType': {
        'workoutTargetTypeId': 4,
        'workoutTargetTypeKey': 'heart.rate.zone',
      },
      'zoneNumber': 1,
    };
    return jsonEncode(<Map<String, Object>>[
      step(1, 'warmup', 300),
      step(3, 'interval', 1200),
      step(2, 'cooldown', 300),
    ]);
  }

  String _sportLabel(String sport) {
    switch (sport) {
      case 'running' || 'trail_running':
        return 'Run';
      case 'cycling_road' || 'cycling_gravel' || 'cycling_mtb':
        return 'Ride';
      case 'swimming':
        return 'Swim';
      case 'strength':
        return 'Strength';
      case 'indoor_rowing':
        return 'Row';
      default:
        return 'Session';
    }
  }

  String _shiftZonesInSteps(String stepsJson, int shift) =>
      jsonEncode(_shiftList(jsonDecode(stepsJson) as List, shift));

  List _shiftList(List steps, int shift) => steps.map((step) {
    if (step is! Map) return step;
    final m = Map<String, dynamic>.from(step);
    if (m.containsKey('zoneNumber') && m['zoneNumber'] is int) {
      m['zoneNumber'] = ((m['zoneNumber'] as int) + shift).clamp(1, 5);
    }
    if (m['workoutSteps'] is List) {
      m['workoutSteps'] = _shiftList(m['workoutSteps'] as List, shift);
    }
    return m;
  }).toList();
}
