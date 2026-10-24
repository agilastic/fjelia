import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'daily_readiness_service.dart';

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
    final sessions = await (_db.select(_db.trainingSessions)
          ..where((t) =>
              t.athleteId.equals('self') &
              t.sessionDate.isBetweenValues(start, end) &
              t.status.isIn(const ['planned', 'adapted']))
          ..orderBy([(t) => OrderingTerm(expression: t.sessionNumber)]))
        .get();
    return [for (final s in sessions) await adapt(s, readiness)];
  }

  Future<AdaptationResult> adapt(
      TrainingSession session, ReadinessResult readiness) async {
    if (readiness.level == ReadinessLevel.green ||
        session.status == 'adapted') {
      return AdaptationResult(session: session);
    }

    final red = readiness.level == ReadinessLevel.red;
    final int newLevel;
    final int newDuration;
    final int newZone;
    final String newTitle;
    final String? newSteps;
    final String notes;
    var shift = 0;

    if (red) {
      newLevel = 1;
      newDuration = 30;
      newZone = 1;
      newTitle = 'Easy Recovery ${_sportLabel(session.sport)}';
      newSteps = _recoveryStepsJson();
      notes = 'Your body is signalling it needs more rest today. This easy '
          'session keeps momentum without adding fatigue.';
    } else {
      shift = -1;
      newLevel = _dropIntensity(session.sessionLevel);
      newDuration = (session.plannedDurationMin * 0.85).round();
      newZone = (session.primaryZone - 1).clamp(1, 5);
      newTitle = session.title;
      newSteps = session.stepsJson == null
          ? null
          : _shiftZonesInSteps(session.stepsJson!, shift);
      notes = 'Today\'s effort adjusted to match your recovery. Same session, '
          'slightly easier pace.';
    }

    await (_db.update(_db.trainingSessions)
          ..where((t) => t.id.equals(session.id)))
        .write(TrainingSessionsCompanion(
      sessionLevel: Value(newLevel),
      originalSessionLevel: Value(session.sessionLevel),
      plannedDurationMin: Value(newDuration),
      primaryZone: Value(newZone),
      title: Value(newTitle),
      stepsJson: Value(newSteps),
      adaptationTrigger: const Value('readiness'),
      sessionNotes: Value(notes),
      tspAdjusted: const Value(true),
      status: const Value('adapted'),
      dateModified: Value(DateTime.now()),
    ));
    final updated = await (_db.select(_db.trainingSessions)
          ..where((t) => t.id.equals(session.id)))
        .getSingle();

    await _db.into(_db.sessionAdaptations).insert(
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
                '{"from": ${session.primaryZone}, "to": $newZone, "shift": $shift}'),
          ),
        );

    return AdaptationResult(
      session: updated,
      adapted: true,
      reason: readiness.adaptationReason,
    );
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
