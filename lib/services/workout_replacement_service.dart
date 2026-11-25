import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'package:fjelia_core/models/workout_profile.dart' show secondsPerMetre;
import '../providers/training_load_provider.dart' show effectiveLoadFromSummary;
import 'athlete_thresholds_service.dart';
import 'package:fjelia_core/services/hr_zone_model.dart'
    show zonePercentFromActiveSamples, zonePercentFromSamples, zoneOf;
import 'package:fjelia_core/services/single_session_cap.dart';

class _InternalActivityLoad {
  const _InternalActivityLoad(this.load, {required this.fromHeartRateSamples});

  final double load;
  final bool fromHeartRateSamples;
}

class _AdaptedWorkout {
  const _AdaptedWorkout({
    required this.durationMin,
    required this.stepsJson,
    this.exceededTargetForStructure = false,
  });

  final int durationMin;
  final String stepsJson;
  final bool exceededTargetForStructure;
}

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
    required this.historyActivityCount,
    required this.historySampleCount,
    required this.warnings,
    required this.suggestRest,
    this.equivalentMin = 0,
    this.longestRecentMin,
    this.remainderMin = 0,
    this.remainderSport = '',
    this.remainderLoad = 0,
    this.remainderStepsJson = '',
  });

  final TrainingSession source;
  final String targetSport;
  final String targetLabel;
  final WorkoutObjective objective;
  final int durationMin;

  /// The load this replacement carries: the original's, or the part of it the
  /// shorter replacement covers.
  final int targetLoad;
  final String stepsJson;
  final bool usedAthleteHistory;
  final int historyActivityCount;
  final int historySampleCount;
  final List<String> warnings;
  final bool suggestRest;

  /// Minutes in the target sport for a load similar to the original's, before
  /// any limit. A comparison, not a recommendation.
  final int equivalentMin;

  /// The longest session in the target sport's family in the last
  /// [singleSessionCapDays] days; null when there is none.
  final int? longestRecentMin;

  /// What the replacement leaves of the original when it only covers part of
  /// it: minutes, sport (the original's, indoors when the replacement is),
  /// load and an easy workout for them. Zero minutes when it covers it all.
  final int remainderMin;
  final String remainderSport;
  final int remainderLoad;
  final String remainderStepsJson;

  /// The replacement covers only part of the original: a split into the
  /// replacement plus the rest in the original sport can be offered.
  bool get isPartial => remainderMin > 0;
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
    final thresholdsService = AthleteThresholdsService(db);
    final thresholds = await thresholdsService.get();
    final sourceFamily = _family(source.sport);
    final targetFamily = _family(targetSport);
    final targetRates = <double>[];
    final sourceRates = <double>[];
    var targetSampleCount = 0;
    final canonicalActivityLoads = <String, double>{};
    final sourceDay = DateTime(
      source.sessionDate.year,
      source.sessionDate.month,
      source.sessionDate.day,
    );
    final recentActivities = activities.where((activity) {
      final day = DateTime(
        activity.startDate.year,
        activity.startDate.month,
        activity.startDate.day,
      );
      final daysAgo = sourceDay.difference(day).inDays;
      return daysAgo >= 0 && daysAgo < 14;
    }).toList();
    for (final activity in activities) {
      final minutes = activity.durationSeconds / 60;
      if (minutes < 10) continue;
      final family = _family(activity.type);
      final load = _internalActivityLoad(
        activity,
        thresholdsService,
        thresholds,
      );
      if (load == null) continue;
      canonicalActivityLoads[activity.activityId] = load.load;
      final rate = load.load / minutes;
      if (!rate.isFinite || rate <= 0) continue;
      if (family == targetFamily) {
        targetRates.add(rate);
        if (load.fromHeartRateSamples) targetSampleCount++;
      }
      if (family == sourceFamily) sourceRates.add(rate);
    }

    // Five recent sessions is a modest minimum for an athlete-specific median;
    // one or two unusual workouts should not dictate the conversion.
    const minimumComparableActivities = 5;
    final useHistory = targetRates.length >= minimumComparableActivities;
    final fallbackScale = _fallbackDurationScale(sourceFamily, targetFamily);
    final load = source.plannedTrimp;
    final estimate = useHistory
        ? load / _median(targetRates)
        : source.plannedDurationMin * fallbackScale;
    var duration = estimate.round().clamp(15, 240);
    final warnings = <String>[];
    if (!useHistory) {
      warnings.add(targetRates.isEmpty ? 'noHistory' : 'limitedHistory');
    } else if (sourceRates.length >= minimumComparableActivities) {
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

    // What a similar load would take, before any limit: shown for comparison
    // and the measure of how much of the original a shorter one covers.
    final equivalent = duration;

    final targetIsRun = targetFamily == 'run';
    // Every switch to running is capped, trail to road included: the spec
    // limits the running stress of a replacement, not only a new sport's.
    final switchToRun = targetIsRun && targetSport != source.sport;
    final runCap = mathMin(
      60,
      (source.plannedDurationMin * .75).round(),
    ).clamp(15, 60);
    // A sport of another family is held to the athlete's longest recent
    // session in it: the heart may be trained for three hours, the muscles
    // of a sport rarely done long are not. The same family needs no limit:
    // the plan sized the session for it.
    final longest = longestRecentSessionMin(
      activities,
      sourceDay,
      sameSport: (type) => _family(type) == targetFamily,
    );
    final historyCap = targetFamily == sourceFamily
        ? null
        : singleSessionCapMin(longest).clamp(15, 240);
    final limit = mathMin(switchToRun ? runCap : 240, historyCap ?? 240);
    var capped = false;
    if (duration > limit) {
      duration = limit;
      capped = true;
      if (switchToRun && runCap <= (historyCap ?? 240)) {
        warnings.add('runningCap');
      }
      if (historyCap != null && historyCap <= (switchToRun ? runCap : 240)) {
        warnings.add(longest == null ? 'noTargetHistory' : 'targetHistoryCap');
      }
    }
    // Five-minute steps; a capped run rounds down so it stays under the cap.
    duration = capped
        ? mathMax(15.0, (duration ~/ 5) * 5.0).round()
        : ((duration / 5).round() * 5).clamp(15, 240);
    // A long session is not fully replaceable by any other sport.
    if (objective == WorkoutObjective.longEndurance) warnings.add('longRun');
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

    var recentLoad = 0.0;
    var previousLoad = 0.0;
    var recentCount = 0;
    var recentWithHrCount = 0;
    var previousCount = 0;
    var previousWithHrCount = 0;
    for (final activity in recentActivities) {
      final day = DateTime(
        activity.startDate.year,
        activity.startDate.month,
        activity.startDate.day,
      );
      final daysAgo = sourceDay.difference(day).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        recentCount++;
        final load = canonicalActivityLoads[activity.activityId];
        if (load != null) {
          recentLoad += load;
          recentWithHrCount++;
        }
      } else if (daysAgo >= 7 && daysAgo < 14) {
        previousCount++;
        final load = canonicalActivityLoads[activity.activityId];
        if (load != null) {
          previousLoad += load;
          previousWithHrCount++;
        }
      }
    }
    final recentCoverage = recentCount == 0
        ? 0
        : recentWithHrCount / recentCount;
    final previousCoverage = previousCount == 0
        ? 0
        : previousWithHrCount / previousCount;
    if (previousLoad > 0 &&
        recentLoad > previousLoad * 1.3 &&
        recentWithHrCount >= 2 &&
        previousWithHrCount >= 2 &&
        recentCoverage >= .7 &&
        previousCoverage >= .7) {
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

    var adapted = _adaptWorkout(source, duration, targetSport);
    if (switchToRun && adapted.durationMin > runCap) {
      // Preserve the running safety cap even when the original interval set
      // cannot fit. Offer an easy run at the cap rather than overloading it.
      adapted = _AdaptedWorkout(
        durationMin: runCap,
        stepsJson: _basicSteps(runCap, source.primaryZone.clamp(1, 2).toInt()),
      );
      warnings.add('runningStructure');
    } else if (capped && adapted.durationMin > limit) {
      // The same for the limit from the target sport's history.
      adapted = _AdaptedWorkout(
        durationMin: duration,
        stepsJson: _basicSteps(
          duration,
          source.primaryZone.clamp(1, 2).toInt(),
        ),
      );
      warnings.add('targetHistoryStructure');
    } else if (adapted.exceededTargetForStructure) {
      warnings.add('structureMinimum');
    }

    // A limited replacement covers only its share of the original load. Well
    // short of it, the rest can be trained in the original sport (indoors
    // when the replacement is indoors); nothing is added on its own.
    final coverage = capped && equivalent > 0
        ? (adapted.durationMin / equivalent).clamp(0.0, 1.0)
        : 1.0;
    final replacementLoad = (load * coverage).round();
    var remainder = coverage < .85
        ? ((source.plannedDurationMin * (1 - coverage)) / 5).round() * 5
        : 0;
    if (remainder < 20) remainder = 0;
    final remainderSport = remainderSportFor(source.sport, targetSport);

    return WorkoutReplacementPreview(
      source: source,
      targetSport: targetSport,
      targetLabel: targetLabel,
      objective: objective,
      durationMin: adapted.durationMin,
      targetLoad: replacementLoad,
      equivalentMin: ((equivalent / 5).round() * 5).clamp(15, 240),
      longestRecentMin: longest,
      remainderMin: remainder,
      remainderSport: remainderSport,
      remainderLoad: remainder == 0 ? 0 : load - replacementLoad,
      remainderStepsJson: remainder == 0
          ? ''
          : _basicSteps(remainder, source.primaryZone.clamp(1, 2).toInt()),
      stepsJson: adapted.stepsJson,
      usedAthleteHistory: useHistory,
      historyActivityCount: targetRates.length,
      historySampleCount: targetSampleCount,
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

  /// Recalculates history with Fjelia's own zone weights. Vendor training-load
  /// scores and stored zone summaries are intentionally ignored because their
  /// scales and zone definitions differ between providers.
  static _InternalActivityLoad? _internalActivityLoad(
    ActivityRecord activity,
    AthleteThresholdsService thresholdsService,
    AthleteThreshold? thresholds,
  ) {
    if (activity.durationSeconds < 600) return null;
    final floors = thresholds == null
        ? null
        : thresholdsService.hrZoneFloorsFor(thresholds, activity.type);
    if (floors == null || floors.length < 5) return null;

    Map<String, double>? zones;
    final source = activity.source?.toLowerCase();
    if (source == 'ftms' || source == 'manual_recording') {
      zones = zonePercentFromActiveSamples(
        activity.metricsJson,
        floors,
        activity.durationSeconds.toDouble(),
      );
    } else {
      zones = zonePercentFromSamples(activity.metricsJson, floors);
    }
    if (zones != null) {
      final load = effectiveLoadFromSummary(
        durationSeconds: activity.durationSeconds,
        hrZonesJson: jsonEncode(zones),
      );
      if (load.isFinite && load > 0) {
        return _InternalActivityLoad(load, fromHeartRateSamples: true);
      }
    }

    // Average-HR-only records cannot show how time was distributed across
    // zones. Use a one-zone approximation and disclose the lower confidence.
    final averageHr = activity.avgHeartRate;
    if (averageHr == null || !averageHr.isFinite || averageHr <= 0) return null;
    final zone = zoneOf(averageHr, floors);
    final averageZone = jsonEncode({
      for (var i = 1; i <= 5; i++) 'zone$i': i == zone ? 100.0 : 0.0,
    });
    final load = effectiveLoadFromSummary(
      durationSeconds: activity.durationSeconds,
      hrZonesJson: averageZone,
    );
    return load.isFinite && load > 0
        ? _InternalActivityLoad(load, fromHeartRateSamples: false)
        : null;
  }

  static WorkoutObjective _objective(TrainingSession s) {
    final text = '${s.sessionType} ${s.subType ?? ''} ${s.title}'.toLowerCase();
    bool word(String pattern) => RegExp('\\b($pattern)\\b').hasMatch(text);
    if (word('recovery|regeneration')) return WorkoutObjective.recovery;
    // Whole words only: "Langlauf" is a sport, not a long session.
    if (word('long|lang|lange|langer|langes')) {
      return WorkoutObjective.longEndurance;
    }
    if (text.contains('vo2') || word('max') || s.primaryZone >= 5) {
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
    // An easy session this long is a long session, whatever its title says.
    final longFrom = _family(s.sport) == 'run' ? 90 : 150;
    if (s.plannedDurationMin >= longFrom) return WorkoutObjective.longEndurance;
    return WorkoutObjective.base;
  }

  /// The sport the rest of a partly replaced session is trained in: the
  /// original sport, indoors when the replacement is an indoor sport (the
  /// weather was likely the reason to switch).
  static String remainderSportFor(String sourceSport, String targetSport) {
    const indoor = {
      'indoor_rowing',
      'indoor_cycling',
      'treadmill_running',
      'elliptical',
      'stair_climbing',
    };
    if (!indoor.contains(targetSport)) return sourceSport;
    return switch (_family(sourceSport)) {
      'cycle' => 'indoor_cycling',
      'run' => 'treadmill_running',
      'row' => 'indoor_rowing',
      _ => sourceSport,
    };
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

  static _AdaptedWorkout _adaptWorkout(
    TrainingSession source,
    int durationMin,
    String targetSport,
  ) {
    final input = source.stepsJson;
    if (input == null || input.isEmpty) {
      return _AdaptedWorkout(
        durationMin: durationMin,
        stepsJson: _basicSteps(durationMin, source.primaryZone),
      );
    }
    try {
      final decoded = jsonDecode(input);
      if (decoded is! List) {
        return _AdaptedWorkout(
          durationMin: durationMin,
          stepsJson: _basicSteps(durationMin, source.primaryZone),
        );
      }
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
      if (sum <= 0) {
        return _AdaptedWorkout(
          durationMin: durationMin,
          stepsJson: _basicSteps(durationMin, source.primaryZone),
        );
      }

      final hasHardIntervals = nodes.any((entry) {
        final zone = entry.node['zoneNumber'];
        return zone is num && zone >= 3;
      });
      final hasRepeats = nodes.any((entry) => entry.repeat > 1);
      final simpleAerobic = !hasHardIntervals && !hasRepeats;
      var exceededTargetForStructure = false;

      if (simpleAerobic) {
        // For steady easy workouts, scale the single effort to the estimated
        // equivalent duration. No interval/recovery pattern is being changed.
        final factor = targetSeconds / sum;
        for (final entry in timeNodes) {
          final value = entry.node['endConditionValue'];
          if (value is num) {
            entry.node['endConditionValue'] = (value * factor).round().clamp(
              30,
              targetSeconds,
            );
          }
        }
      } else if (targetSeconds > sum) {
        // Keep work and recovery intervals intact. Add the extra aerobic volume
        // as a separate Z2 block immediately before the cooldown.
        final extra = (targetSeconds - sum).round();
        final cooldownIndex = decoded.lastIndexWhere((item) {
          if (item is! Map) return false;
          final type = item['stepType'];
          return type is Map && type['stepTypeKey'] == 'cooldown';
        });
        final easyStep = <String, dynamic>{
          'type': 'ExecutableStepDTO',
          'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
          'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
          'endConditionValue': extra,
          'zoneNumber': 2,
        };
        decoded.insert(
          cooldownIndex < 0 ? decoded.length : cooldownIndex,
          easyStep,
        );
        timeNodes.add((node: easyStep, repeat: 1));
      } else {
        // When shortening structured work, reduce only the non-repeated easy
        // portions. Hard intervals and their recoveries stay at their
        // prescribed durations. Warm-up and cool-down retain at least 5 min.
        final adjustable = <({Map<String, dynamic> node, int floor})>[];
        for (final entry in timeNodes) {
          if (entry.repeat > 1) continue;
          final node = entry.node;
          final value = node['endConditionValue'];
          final type = _stepType(node);
          final zone = node['zoneNumber'];
          final z = zone is num ? zone.toInt() : 1;
          if (value is! num || z > 2 || type == 'recovery' || type == 'rest') {
            continue;
          }
          // Never below five minutes for warm-up and cool-down, but a shorter
          // step is not lengthened either.
          final minimum = type == 'warmup' || type == 'cooldown' ? 300 : 30;
          adjustable.add((node: node, floor: mathMin(minimum, value.toInt())));
        }
        final fixed =
            sum -
            adjustable.fold<double>(
              0,
              (total, entry) =>
                  total +
                  ((entry.node['endConditionValue'] as num?)?.toDouble() ?? 0),
            );
        final desiredAdjustable = mathMax(0.0, targetSeconds - fixed);
        final currentAdjustable = adjustable.fold<double>(
          0,
          (total, entry) =>
              total +
              ((entry.node['endConditionValue'] as num?)?.toDouble() ?? 0),
        );
        final floorTotal = adjustable.fold<int>(
          0,
          (total, entry) => total + entry.floor,
        );
        if (adjustable.isNotEmpty && desiredAdjustable < currentAdjustable) {
          final reducible = mathMax(
            0.0,
            currentAdjustable - floorTotal.toDouble(),
          );
          final retained = mathMax(floorTotal.toDouble(), desiredAdjustable);
          final factor = reducible == 0
              ? 0.0
              : ((retained - floorTotal) / reducible).clamp(0.0, 1.0);
          for (final entry in adjustable) {
            final current = (entry.node['endConditionValue'] as num).toDouble();
            entry.node['endConditionValue'] =
                (entry.floor + (current - entry.floor) * factor).round();
          }
        }
        final adaptedSeconds = timeNodes.fold<double>(
          0,
          (total, entry) =>
              total +
              ((entry.node['endConditionValue'] as num?)?.toDouble() ?? 0) *
                  entry.repeat,
        );
        exceededTargetForStructure = adaptedSeconds > targetSeconds + 1;
      }

      for (final entry in timeNodes) {
        for (final key in [
          'targetType',
          'targetValueOne',
          'targetValueTwo',
          'ftpFraction',
          'ftpLow',
          'ftpHigh',
        ]) {
          entry.node.remove(key);
        }
      }
      // Keep the executable source structure and HR zones; unsupported sport
      // targets are removed and rebuilt by the platform from the new sport.
      final totalSeconds = timeNodes.fold<double>(
        0,
        (total, entry) =>
            total +
            ((entry.node['endConditionValue'] as num?)?.toDouble() ?? 0) *
                entry.repeat,
      );
      final adaptedDuration = (totalSeconds / 60).round().clamp(1, 240);
      return _AdaptedWorkout(
        durationMin: adaptedDuration,
        stepsJson: jsonEncode(decoded),
        exceededTargetForStructure: exceededTargetForStructure,
      );
    } catch (_) {
      return _AdaptedWorkout(
        durationMin: durationMin,
        stepsJson: _basicSteps(durationMin, source.primaryZone),
      );
    }
  }

  static String? _stepType(Map<String, dynamic> node) {
    final type = node['stepType'];
    return type is Map ? type['stepTypeKey']?.toString() : type?.toString();
  }

  static double mathMax(double a, double b) => a > b ? a : b;

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
