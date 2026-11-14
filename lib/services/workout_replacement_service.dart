import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../models/workout_profile.dart' show secondsPerMetre;
import '../providers/training_load_provider.dart' show effectiveLoad;

enum WorkoutObjective {
  recovery,
  base,
  tempo,
  threshold,
  vo2max,
  longEndurance,
}

class WorkoutReplacementPreview {
  const WorkoutReplacementPreview({
    required this.source,
    required this.targetSport,
    required this.targetLabel,
    required this.objective,
    required this.durationMin,
    required this.targetLoad,
    required this.stepsJson,
    required this.usedAthleteHistory,
    required this.warnings,
    required this.suggestRest,
  });

  final TrainingSession source;
  final String targetSport;
  final String targetLabel;
  final WorkoutObjective objective;
  final int durationMin;
  final int targetLoad;
  final String stepsJson;
  final bool usedAthleteHistory;
  final List<String> warnings;
  final bool suggestRest;
}

/// Estimates a sport-specific replacement using the athlete's recent activity
/// load rates when available, with conservative starter ratios otherwise.
class WorkoutReplacementService {
  WorkoutReplacementService(this.db);
  final AppDatabase db;

  Future<WorkoutReplacementPreview> preview(
    TrainingSession source, {
    required String targetSport,
    required String targetLabel,
  }) async {
    final objective = _objective(source);
    final activities = await db.getActivitiesInRange(180);
    final sourceFamily = _family(source.sport);
    final targetFamily = _family(targetSport);
    final targetRates = <double>[];
    final sourceRates = <double>[];
    final sourceDay = DateTime(
      source.sessionDate.year,
      source.sessionDate.month,
      source.sessionDate.day,
    );
    for (final activity in activities) {
      final minutes = activity.durationSeconds / 60;
      if (minutes < 10) continue;
      final family = _family(activity.type);
      final rate = effectiveLoad(activity) / minutes;
      if (!rate.isFinite || rate <= 0) continue;
      if (family == targetFamily) targetRates.add(rate);
      if (family == sourceFamily) sourceRates.add(rate);
    }

    final useHistory = targetRates.length >= 2;
    final fallbackScale = _fallbackDurationScale(sourceFamily, targetFamily);
    final load = source.plannedTrimp;
    final estimate = useHistory
        ? load / _median(targetRates)
        : source.plannedDurationMin * fallbackScale;
    var duration = estimate.round().clamp(15, 240);
    final warnings = <String>[];
    if (!useHistory) {
      warnings.add('noHistory');
    } else if (sourceRates.length >= 2) {
      // The activity rates are used as an athlete-specific calibration. A
      // broad clamp avoids implausible duration swings from noisy records.
      final expectedFromSource =
          source.plannedDurationMin *
          (_median(sourceRates) / _median(targetRates));
      duration = ((duration * .65) + (expectedFromSource * .35)).round().clamp(
        15,
        240,
      );
    }

    final targetIsRun = targetFamily == 'run';
    if (targetIsRun) {
      final cap = mathMin(60, (source.plannedDurationMin * .75).round());
      if (duration > cap) {
        duration = cap.clamp(15, 240);
        warnings.add('runningCap');
      }
    }
    duration = ((duration / 5).round() * 5).clamp(15, 240);
    if (objective == WorkoutObjective.longEndurance && targetIsRun) {
      warnings.add('longRun');
    }
    if ((source.goalRole == 'primary' ||
            source.phase == 'race' ||
            source.phase == 'taper') &&
        (objective == WorkoutObjective.longEndurance ||
            objective.index >= WorkoutObjective.threshold.index)) {
      warnings.add('raceSpecific');
    }
    if (sourceFamily == 'swim' && targetFamily != 'swim') {
      warnings.add('swimTechnique');
    }
    if (sourceFamily == 'strength' || targetFamily == 'strength') {
      warnings.add('strengthMismatch');
    }

    final recoveryFrom = sourceDay.subtract(const Duration(days: 3));
    final recoveryScores =
        await (db.select(db.dayScoreRecords)
              ..where(
                (s) =>
                    s.date.isBiggerOrEqualValue(recoveryFrom) &
                    s.date.isSmallerOrEqualValue(sourceDay),
              )
              ..orderBy([(s) => OrderingTerm.desc(s.date)])
              ..limit(1))
            .get();
    final recovery = recoveryScores.firstOrNull?.recoveryScore;
    if (recovery != null && recovery < 40) warnings.add('lowRecovery');

    final recentActivities = await db.getActivitiesInRange(14);
    var recentLoad = 0.0;
    var previousLoad = 0.0;
    for (final activity in recentActivities) {
      final day = DateTime(
        activity.startDate.year,
        activity.startDate.month,
        activity.startDate.day,
      );
      final daysAgo = sourceDay.difference(day).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        recentLoad += effectiveLoad(activity);
      } else if (daysAgo >= 7 && daysAgo < 14) {
        previousLoad += effectiveLoad(activity);
      }
    }
    if (previousLoad > 0 && recentLoad > previousLoad * 1.3) {
      warnings.add('highRecentVolume');
    }

    final dateFrom = source.sessionDate.subtract(const Duration(hours: 72));
    final dateTo = source.sessionDate.add(const Duration(hours: 72));
    final nearby =
        (await (db.select(
          db.trainingSessions,
        )..where((s) => s.planId.equals(source.planId))).get())..removeWhere(
          (s) =>
              s.id == source.id ||
              s.status == 'skipped' ||
              s.sessionDate.isBefore(dateFrom) ||
              s.sessionDate.isAfter(dateTo),
        );
    final hardNearby = nearby.where(
      (s) =>
          _isHard(s) &&
          s.sessionDate.difference(source.sessionDate).inHours.abs() <= 72,
    );
    if (hardNearby.isNotEmpty &&
        objective.index >= WorkoutObjective.tempo.index) {
      warnings.add('nearbyHard');
    }
    final thisWeek =
        (await (db.select(
              db.trainingSessions,
            )..where((s) => s.planId.equals(source.planId))).get())
            .where(
              (s) =>
                  s.weekNumber == source.weekNumber &&
                  s.id != source.id &&
                  s.status != 'skipped',
            )
            .fold<int>(0, (sum, s) => sum + s.plannedTrimp);
    if (thisWeek > 0 && load > thisWeek * .65) {
      warnings.add('largeWeeklyShare');
    }

    return WorkoutReplacementPreview(
      source: source,
      targetSport: targetSport,
      targetLabel: targetLabel,
      objective: objective,
      durationMin: duration,
      targetLoad: load,
      stepsJson: _adaptSteps(source, duration, targetSport),
      usedAthleteHistory: useHistory,
      warnings: warnings,
      suggestRest:
          duration < 20 ||
          (recovery != null && recovery < 30) ||
          (hardNearby.isNotEmpty &&
              const {
                WorkoutObjective.threshold,
                WorkoutObjective.vo2max,
              }.contains(objective)),
    );
  }

  static WorkoutObjective _objective(TrainingSession s) {
    final text = '${s.sessionType} ${s.subType ?? ''} ${s.title}'.toLowerCase();
    if (text.contains('recovery') || text.contains('regeneration')) {
      return WorkoutObjective.recovery;
    }
    if (text.contains('long') || text.contains('lang')) {
      return WorkoutObjective.longEndurance;
    }
    if (text.contains('vo2') || text.contains('max') || s.primaryZone >= 5) {
      return WorkoutObjective.vo2max;
    }
    if (text.contains('threshold') ||
        text.contains('schwelle') ||
        s.primaryZone == 4) {
      return WorkoutObjective.threshold;
    }
    if (text.contains('tempo') || s.primaryZone == 3) {
      return WorkoutObjective.tempo;
    }
    if (s.primaryZone <= 1) return WorkoutObjective.recovery;
    return WorkoutObjective.base;
  }

  static bool _isHard(TrainingSession s) =>
      s.primaryZone >= 3 ||
      const {
        WorkoutObjective.tempo,
        WorkoutObjective.threshold,
        WorkoutObjective.vo2max,
      }.contains(_objective(s));

  static String _family(String sport) {
    final s = sport.toLowerCase().replaceAll('_', ' ');
    if (s.contains('run') || s.contains('jog')) return 'run';
    if (s.contains('cycl') || s.contains('bike') || s.contains('bik')) {
      return 'cycle';
    }
    if (s.contains('swim')) return 'swim';
    if (s.contains('row')) return 'row';
    if (s.contains('ski')) return 'ski';
    if (s.contains('ellipt')) return 'elliptical';
    if (s.contains('hik') || s.contains('walk')) return 'hike';
    if (s.contains('strength') || s.contains('weight')) return 'strength';
    return s;
  }

  static double _fallbackDurationScale(String source, String target) {
    if (source == target) return 1;
    const scales = <String, double>{
      'run>cycle': 1.65,
      'cycle>run': .60,
      'run>elliptical': 1.10,
      'elliptical>run': .85,
      'cycle>row': .75,
      'row>ski': .90,
      'ski>row': 1.10,
      'trail>hike': .95,
      'swim>cycle': 1.20,
    };
    return scales['$source>$target'] ?? 1.15;
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static String _adaptSteps(
    TrainingSession source,
    int durationMin,
    String targetSport,
  ) {
    final input = source.stepsJson;
    if (input == null || input.isEmpty) {
      return _basicSteps(durationMin, source.primaryZone);
    }
    try {
      final decoded = jsonDecode(input);
      if (decoded is! List) return _basicSteps(durationMin, source.primaryZone);
      final targetSeconds = durationMin * 60;
      final nodes = <({Map<String, dynamic> node, double repeat})>[];
      void convertDistanceSteps(List values, [double repeatMultiplier = 1]) {
        for (var i = 0; i < values.length; i++) {
          final value = values[i];
          if (value is! Map) continue;
          final node = Map<String, dynamic>.from(value);
          final nested = node['workoutSteps'];
          if (nested is List) {
            final rawRepeats =
                node['numberOfIterations'] ?? node['endConditionValue'];
            final repeats = rawRepeats is num
                ? rawRepeats.round().clamp(1, 100)
                : 1;
            convertDistanceSteps(nested, repeatMultiplier * repeats);
          } else {
            nodes.add((node: node, repeat: repeatMultiplier));
          }
          final condition = node['endCondition'];
          final isDistance =
              condition is Map &&
              (condition['conditionTypeKey'] == 'distance' ||
                  condition['conditionTypeId'] == 3);
          final endValue = node['endConditionValue'];
          if (isDistance && endValue is num) {
            node['endCondition'] = {
              'conditionTypeId': 2,
              'conditionTypeKey': 'time',
            };
            node['endConditionValue'] =
                (endValue * secondsPerMetre(targetSport)).round();
          }
          values[i] = node;
        }
      }

      convertDistanceSteps(decoded);
      final timeNodes = nodes.where((n) {
        final condition = n.node['endCondition'];
        return condition is Map &&
            (condition['conditionTypeKey'] == 'time' ||
                condition['conditionTypeId'] == 2);
      }).toList();
      final sum = timeNodes.fold<double>(
        0,
        (v, n) =>
            v +
            ((n.node['endConditionValue'] as num?)?.toDouble() ?? 0) * n.repeat,
      );
      if (sum <= 0) return _basicSteps(durationMin, source.primaryZone);
      final factor = targetSeconds / sum;
      for (final node in timeNodes) {
        final value = node.node['endConditionValue'];
        if (value is num) {
          node.node['endConditionValue'] = (value * factor).round().clamp(
            30,
            targetSeconds,
          );
        }
        for (final key in [
          'targetType',
          'targetValueOne',
          'targetValueTwo',
          'ftpFraction',
          'ftpLow',
          'ftpHigh',
        ]) {
          node.node.remove(key);
        }
      }
      // Keep the executable source structure and HR zones; unsupported sport
      // targets are removed and rebuilt by the platform from the new sport.
      return jsonEncode(decoded);
    } catch (_) {
      return _basicSteps(durationMin, source.primaryZone);
    }
  }

  static String _basicSteps(int durationMin, int zone) {
    final total = durationMin * 60;
    final warm = total >= 2700 ? 600 : 300;
    final cool = total >= 2700 ? 300 : 0;
    final main = total - warm - cool;
    Map<String, Object> step(String type, int id, int seconds, int z) => {
      'type': 'ExecutableStepDTO',
      'stepType': {'stepTypeId': id, 'stepTypeKey': type},
      'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
      'endConditionValue': seconds,
      'zoneNumber': z,
    };
    return jsonEncode([
      step('warmup', 1, warm, 1),
      step('interval', 3, main, zone),
      if (cool > 0) step('cooldown', 2, cool, 1),
    ]);
  }
}

int mathMin(int a, int b) => a < b ? a : b;
