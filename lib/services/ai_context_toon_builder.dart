import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' hide isNull, isNotNull;

import '../db/database.dart';
import '../providers/training_load_provider.dart';
import 'bio_age_service.dart';
import 'ai_data_status.dart';
import 'post_workout_scorer.dart' show noActivityReason;
import 'race_predictor.dart';
import 'race_goal_service.dart';
import '../utils/target_time.dart';
import '../models/race_profile.dart';
import 'open_meteo_client.dart';

/// Inputs from the training monitor.
class AiContextTrainingMonitor {
  const AiContextTrainingMonitor({
    this.ctl,
    this.atl,
    this.tsb,
    this.dailyLoad,
    this.optMin,
    this.optMax,
    this.curWeekH,
    this.prevWeekH,
    this.curWeekKm,
    this.prevWeekKm,
    this.vo2maxRun,
    this.vo2maxCycle,
  });
  final double? ctl,
      atl,
      tsb,
      dailyLoad,
      optMin,
      optMax,
      curWeekH,
      prevWeekH,
      curWeekKm,
      prevWeekKm,
      vo2maxRun,
      vo2maxCycle;
}

class AiContextPlanInfo {
  const AiContextPlanInfo({this.daysToRace, this.week, this.totalWeeks});
  final int? daysToRace, week, totalWeeks;
}

/// Compact health context.
/// Only explicitly selected fields leave the database: names, coordinates,
/// activity IDs, free-form notes and raw payloads are never serialized.
class AiContextToonBuilder {
  AiContextToonBuilder(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final AppDatabase _db;
  final DateTime Function() _now;

  Future<String> build(
    AiContextTrainingMonitor? monitor,
    String raceGoals,
    String? weatherSummary, {
    BioAgeResult? bioAge,
    AiContextPlanInfo? planInfo,
  }) async {
    final now = _now();
    final today = _day(now);
    final hrv = await _db.getHrvRange(60);
    final sleep = await _db.getSleepRange(60);
    final wellness = await _db.getWellnessRange(60);
    final bp = await _db.getRecentBp(60);
    final body = await _db.getRenphoRange(60);
    final activities = await _db.getActivitiesInRange(60);
    final scores = await _db.getScoreRange();
    final workouts = await _db.getUpcomingWorkouts();
    final grip = await _db.getGripStrengthRange();
    final thresholds = await _db.getAllThresholdRecords();
    final heat = await _db.getHeatStateForDate(today);
    final readiness = await _db.getTodayReadiness();
    final sessions = await _db.getUpcomingTrainingSessions();
    final cancelled = await _cancelledSessions(today);
    hrv.sort((a, b) => b.date.compareTo(a.date));
    sleep.sort((a, b) => b.date.compareTo(a.date));
    wellness.sort((a, b) => b.date.compareTo(a.date));
    bp.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    body.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    scores.sort((a, b) => b.date.compareTo(a.date));
    grip.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    thresholds.sort((a, b) => b.date.compareTo(a.date));
    activities.sort((a, b) => b.startDate.compareTo(a.startDate));
    final lines = <String>[
      '[Context:V4][Today:${_date(today)},Weekday:${_weekday(today)},'
          'TimeNow:${_time(now)}][Range:60d,Grip:90d]'
          '[Excludes:PII,GPS,GPX,ActivityNames,PlanNames]',
      aiDataStatusLine(
        now: now,
        activityDays: [for (final a in activities) a.startDate],
        hrvDays: [
          for (final r in hrv)
            if (r.hrvLastNight != null) r.date,
        ],
        sleepDays: [
          for (final r in sleep)
            if (r.totalSleepSeconds > 0) r.date,
        ],
        dailyDays: [for (final r in wellness) r.date],
      ),
      if (raceGoals.trim().isNotEmpty) '[RaceGoals:${_clean(raceGoals)}]',
      if (weatherSummary != null && weatherSummary.trim().isNotEmpty)
        weatherSummary.trim(),
    ];
    if (hrv.isNotEmpty) {
      final r = hrv.first;
      lines.add(
        '[HRV:Latest:${_date(r.date)},Night:${_num(r.hrvLastNight)}ms,'
        'Weekly7d:${_num(r.hrvWeeklyAvg)}ms,RHR:${_num(r.restingHeartRate)}bpm,'
        'Stress:${_num(r.stressLevel)},SpO2:${_num(r.spo2)}%,'
        'Resp:${_num(r.respirationRate)}brpm,Energy:${_num(r.computedEnergie)}]',
      );
      lines.add(
        '[HRV:7dTrend:${hrv.take(7).map((r) => '${_date(r.date).substring(5)}:${_num(r.hrvLastNight)}').join(',')}]',
      );
    }
    if (sleep.isNotEmpty) {
      final r = sleep.first;
      lines.add(
        '[Sleep:Latest:${_date(r.date)},Dur:${_hours(r.totalSleepSeconds)}h,'
        'Deep:${_hours(r.deepSleepSeconds)}h,REM:${_hours(r.remSleepSeconds)}h,'
        'Score:${_num(r.sleepScore)},Need:${_hours(r.sleepNeedSeconds)}h,'
        'OvernightHRV:${_num(r.avgOvernightHrv)}ms,'
        'Start:${r.sleepStart == null ? 'na' : _time(r.sleepStart!)},'
        'End:${r.sleepEnd == null ? 'na' : _time(r.sleepEnd!)}]',
      );
      lines.add(
        '[Sleep:7dTrend:${sleep.take(7).map((r) => '${_date(r.date).substring(5)}:${_hours(r.totalSleepSeconds)}h:'
            '${_num(r.sleepScore)}').join(',')}]',
      );
    }
    if (wellness.isNotEmpty) {
      final r = wellness.first;
      lines.add(
        '[Daily:Latest:${_date(r.date)},Steps:${_num(r.steps)},'
        'ActiveCal:${_num(r.activeCalories)},TotalCal:${_num(r.totalCalories)},'
        'Floors:${_num(r.floorsAscended)},IntensityMin:${_num(r.intensityMinutes)},'
        'BBHigh:${_num(r.bodyBatteryHighest)},BBLow:${_num(r.bodyBatteryLowest)},'
        'BBCharged:${_num(r.bodyBatteryCharged)},BBDrained:${_num(r.bodyBatteryDrained)},'
        'VO2maxRun:${_num(r.vo2max)},FitnessAge:${_num(r.fitnessAge)}]',
      );
    }
    if (bp.isNotEmpty) {
      final r = bp.first;
      lines.add(
        '[BP:Latest:${_date(r.measuredAt)},Sys:${r.systolic},'
        'Dia:${r.diastolic},HR:${r.heartRate}]',
      );
      final weeks = <int, List<BpMeasurement>>{};
      for (final reading in bp) {
        final week =
            reading.measuredAt.millisecondsSinceEpoch ~/
            const Duration(days: 7).inMilliseconds;
        (weeks[week] ??= []).add(reading);
      }
      final keys = weeks.keys.toList()..sort((a, b) => b.compareTo(a));
      lines.add(
        '[BP:WeeklyAvg:${keys.map((key) {
          final values = weeks[key]!;
          final sys = values.fold(0, (s, r) => s + r.systolic) / values.length;
          final dia = values.fold(0, (s, r) => s + r.diastolic) / values.length;
          final date = DateTime.fromMillisecondsSinceEpoch(key * const Duration(days: 7).inMilliseconds);
          return 'W${_date(date).substring(0, 7)}:${sys.round()}/${dia.round()}'
              '(n=${values.length})';
        }).join(',')}]',
      );
    }
    if (body.isNotEmpty) {
      final r = body.first;
      lines.add(
        '[Body:Latest:${_date(r.measuredAt)},Weight:${_num(r.weight)}kg,'
        'BMI:${_num(r.bmi)},Fat:${_num(r.bodyFat)}%,BodyWater:${_num(r.bodyWater)}%,'
        'Muscle:${_num(r.muscleMass)}kg,VFat:${_num(r.visceralFat)},'
        'BMR:${_num(r.bmr)}kcal,BodyAge:${_num(r.bodyAge)}]',
      );
    }
    final recentGrip = grip
        .where(
          (r) =>
              !r.measuredAt.isBefore(today.subtract(const Duration(days: 90))),
        )
        .take(5);
    if (recentGrip.isNotEmpty) {
      lines.add('[GripStrength:Recent90d]');
      for (final r in recentGrip) {
        lines.add(
          '- [D:${_date(r.measuredAt)},Left:${_num(r.leftKg)}kg,'
          'Right:${_num(r.rightKg)}kg]',
        );
      }
    }
    if (scores.isNotEmpty) {
      final r = scores.first;
      lines.add(
        '[Scores:Latest:${_date(r.date)},Recovery:${_num(r.recoveryScore)},'
        'Sleep:${_num(r.sleepScore)},Strain:${_num(r.strainScore)},'
        'BP:${_num(r.bpScore)},Readiness:${_num(r.readinessScore)},'
        'Level:${_clean(r.recoveryLevel)}]',
      );
    }
    if (readiness != null) {
      final flags = [
        if (readiness.flagHrv) 'hrv',
        if (readiness.flagHr) 'hr',
        if (readiness.flagSleep) 'sleep',
        if (readiness.flagBattery) 'battery',
        if (readiness.flagSkinTemp) 'skinTemp',
        if (readiness.flagFatigue) 'fatigue',
      ];
      lines.add(
        '[DailyReadiness:Level:${_clean(readiness.level)},'
        'Flags:${flags.isEmpty ? 'none' : flags.join('+')},'
        'FlagCount:${readiness.flagCount}]',
      );
    }
    if (bioAge != null) {
      // BioAgeResult exposes lifeExpectancy, but not a base/adjusted/death-age
      // trio. Do not fabricate those missing values.
      lines.add(
        '[BioAge:FitnessAge:${_num(bioAge.fitnessAge)},'
        'VO2max:${_num(bioAge.vo2max)},VO2maxClass:${_clean(bioAge.vo2Class)},'
        'DeltaYears:${_num(bioAge.deltaYears)},BaseLifeExp:na,'
        'AdjLifeExp:${_num(bioAge.lifeExpectancy)},EstDeathAge:na,'
        'Range:${_num(bioAge.rangeLow)}-${_num(bioAge.rangeHigh)}yr]',
      );
      lines.add(
        '[BioAge:Contributions:${bioAge.contributions.entries.map((e) => '${_clean(e.key)}:${_num(e.value)}').join(',')}]',
      );
    }
    if (monitor != null) {
      lines.add(
        '[TrainingMonitor:CTL:${_num(monitor.ctl)},ATL:${_num(monitor.atl)},'
        'TSB:${_num(monitor.tsb)},DailyLoad:${_num(monitor.dailyLoad)},'
        'OptMin:${_num(monitor.optMin)},OptMax:${_num(monitor.optMax)},'
        'CurWeekH:${_num(monitor.curWeekH)},PrevWeekH:${_num(monitor.prevWeekH)},'
        'CurWeekKm:${_num(monitor.curWeekKm)},PrevWeekKm:${_num(monitor.prevWeekKm)},'
        'VO2maxRun:${_num(monitor.vo2maxRun)},VO2maxCycle:${_num(monitor.vo2maxCycle)}]',
      );
    }
    if (heat != null) {
      lines.add(
        '[HeatAcclimation:Today:Score:${_num(heat.score)},'
        'Status:${_clean(heat.status)},Recommendation:${_clean(heat.recommendation)}]',
      );
    }
    if (thresholds.isNotEmpty) {
      lines.add('[LactateThresholds:Recent]');
      for (final r in thresholds.take(3)) {
        lines.add(
          '- [D:${_date(r.date)},Src:${_clean(r.source)},'
          'LT1:${_num(r.lt1Bpm)}bpm,LT2:${_num(r.lt2Bpm)}bpm,'
          'LT2Pace:${_pace(r.lt2PaceSec)},VO2Pace:${_pace(r.vo2PaceSec)}]',
        );
      }
    }
    if (planInfo != null) {
      lines.add(
        '[TrainingPlan:DaysToRace:${_num(planInfo.daysToRace)},'
        'Week:${_num(planInfo.week)},TotalWeeks:${_num(planInfo.totalWeeks)}]',
      );
    }
    lines.add(
      '[Activities:Last60d:shown=${math.min(activities.length, 20)}'
      'of${activities.length}]',
    );
    for (final a in activities.take(20).toList().reversed) {
      lines.add(
        '- [D:${_date(a.startDate)},Type:${_clean(a.type)},'
        'Dur:${_num(a.durationSeconds / 60)}m,DistKm:${_num(_km(a.distanceMeters))},'
        'AvgHR:${_num(a.avgHeartRate)},MaxHR:${_num(a.maxHeartRate)},'
        'Load:${_num(_load(a))},Watts:${_num(a.avgWatts)},'
        'ElevM:${_num(a.totalElevation)}${_parseHrZones(a.hrZonesJson)},'
        'Src:${_clean(a.source)},PlannedDur:${_minutes(a.plannedDurationSeconds)},'
        'PlannedKm:${_num(_km(a.plannedDistanceMeters))}'
        '${_parseStepsSummary(a.plannedStepsJson)}]',
      );
    }
    final todayWorkouts = workouts
        .where((w) => _day(w.scheduledDate) == today)
        .toList();
    final todaySessions = sessions
        .where((s) => _day(s.sessionDate) == today)
        .toList();
    final cancelledToday = cancelled
        .where((c) => _day(c.session.sessionDate) == today)
        .toList();
    if (todayWorkouts.isEmpty &&
        todaySessions.isEmpty &&
        cancelledToday.isNotEmpty) {
      // Not a plain rest day: a planned session was dropped, and why matters.
      lines.add(
        '[TodayWorkout:Status:cancelled,Reason:'
        '${_clean(cancelledToday.first.reason)},'
        'By:${cancelledToday.first.by},GarminScheduled:0,PlanSessions:0]',
      );
    } else if (todayWorkouts.isEmpty && todaySessions.isEmpty) {
      lines.add(
        '[TodayWorkout:Status:rest_day,GarminScheduled:0,PlanSessions:0]',
      );
    } else {
      lines.add(
        '[TodayWorkout:Status:options_available,GarminScheduled:'
        '${todayWorkouts.length},PlanSessions:${todaySessions.length},'
        'Note:AI_recommends_best_based_on_readiness]',
      );
      for (final w in todayWorkouts) {
        lines.add(
          '- [${_workout(w).replaceFirst(',PlannedSteps:', ',Steps:')}]',
        );
      }
      for (final s in todaySessions) {
        lines.add('- [${_session(s)}]');
      }
    }
    // Sessions dropped in the last two weeks and the next two, with the reason
    // given. Illness and injury are health facts the coach has to respect.
    if (cancelled.isNotEmpty) {
      final reasons = {for (final c in cancelled) _clean(c.reason)}.join('/');
      lines.add(
        '[Cancelled:Sessions:${cancelled.length},Window:±14d,Reasons:$reasons]',
      );
      for (final c in cancelled) {
        lines.add(
          '- [D:${_date(c.session.sessionDate)},Src:plan,'
          'Sport:${_clean(c.session.sport)},Type:${_clean(c.session.sessionType)},'
          'Planned:${c.session.plannedDurationMin}m,'
          'Reason:${_clean(c.reason)},By:${c.by}]',
        );
      }
    }
    final goal = await RaceGoalService(_db).getPrimaryGoal();
    if (goal != null) {
      final profile = RaceProfile(
        sport: goal.primarySport,
        distanceM: goal.distanceM,
        elevationM: goal.elevationM,
        targetSeconds: goal.targetFinishSeconds,
      );
      final estimate = await RacePredictor.estimateFinish(_db, goal);
      final flat = profile.flatEquivalentPaceSecPerKm;
      lines.add(
        '[RaceGoal:Sport:${_clean(goal.primarySport)},'
        'DistKm:${_num(profile.distanceKm)},ElevM:${_num(goal.elevationM)},'
        'ClimbMPerKm:${_num(profile.climbPerKm)},Terrain:${profile.terrain.name},'
        'Date:${_date(goal.raceDate)},'
        'Target:${goal.targetFinishSeconds == null ? 'none' : formatTargetTime(goal.targetFinishSeconds!)},'
        'PaceSecKm:${_num(profile.goalPaceSecPerKm)},FlatPaceSecKm:${_num(flat)},'
        'Estimate:${estimate == null ? 'na' : formatTargetTime(estimate)},'
        'GoalAheadOfEstimate%:${estimate == null || profile.aheadOfPrediction(estimate) == null ? 'na' : (profile.aheadOfPrediction(estimate)! * 100).round()}]',
      );
    }
    lines.add('[GarminScheduled:Upcoming:${workouts.length}]');
    for (final w in workouts) {
      lines.add('- [D:${_date(w.scheduledDate)},${_workout(w)}]');
    }
    lines.add('[TrainingPlan:Upcoming:${sessions.length}]');
    for (final s in sessions) {
      lines.add('- [D:${_date(s.sessionDate)},${_session(s)}]');
    }
    lines.add(
      '[Schedule:Next14d:Today=${_date(today)},Weekday:${_weekday(today)}]',
    );
    for (var i = 0; i < 14; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final prefix = '- [D:${_date(day)},Weekday:${_weekday(day)}';
      final ws = workouts.where((w) => _day(w.scheduledDate) == day);
      final ss = sessions.where((s) => _day(s.sessionDate) == day);
      final dropped = cancelled.where(
        (c) => _day(c.session.sessionDate) == day,
      );
      if (ws.isEmpty && ss.isEmpty) {
        lines.add(
          dropped.isEmpty
              ? '$prefix,Status:rest]'
              : '$prefix,Status:cancelled,Reason:${_clean(dropped.first.reason)}]',
        );
      }
      for (final w in ws) {
        lines.add('$prefix,${_workout(w)}]');
      }
      for (final s in ss) {
        lines.add('$prefix,${_session(s)}]');
      }
    }
    return lines.join('\n');
  }

  /// Planned sessions the athlete or the readiness check dropped, two weeks
  /// either side of [today], each with its reason. A past session nothing was
  /// recorded for is not a decision and is left out.
  Future<List<({TrainingSession session, String reason, String by})>>
  _cancelledSessions(DateTime today) async {
    final from = DateTime(today.year, today.month, today.day - 14);
    final to = DateTime(today.year, today.month, today.day + 15);
    final skipped =
        await (_db.select(_db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.status.equals('skipped') &
                    t.sessionDate.isBiggerOrEqualValue(from) &
                    t.sessionDate.isSmallerThanValue(to),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
            .get();
    if (skipped.isEmpty) return const [];
    final actuals = await (_db.select(
      _db.sessionActuals,
    )..where((t) => t.sessionId.isIn(skipped.map((s) => s.id)))).get();
    final reasons = {
      for (final a in actuals)
        if (a.skipReason != null) a.sessionId: a.skipReason!,
    };
    return [
      for (final s in skipped)
        if (reasons[s.id] != null && reasons[s.id] != noActivityReason)
          (
            session: s,
            reason: reasons[s.id]!,
            by: reasons[s.id]!.contains('readiness') ? 'readiness' : 'athlete',
          ),
    ];
  }

  static String _workout(ScheduledWorkoutRecord w) =>
      'Src:garmin,Type:${_clean(w.sportType)},Dur:${_minutes(w.estimatedDurationSeconds)},'
      'DistKm:${_num(_km(w.estimatedDistanceMeters))}${_parseStepsSummary(w.stepsJson)}';
  static String _session(TrainingSession s) =>
      'Src:plan,Sport:${_clean(s.sport)},Type:${_clean(s.sessionType)},'
      'Phase:${_clean(s.phase)},Zone:${s.primaryZone},Dur:${s.plannedDurationMin}m,'
      'TRIMP:${s.plannedTrimp}'
      '${s.tspAdjusted ? ',Adapted:${_clean(s.adaptationTrigger)}' : ''}';

  static String _parseStepsSummary(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return '';
      final steps = <String>[];
      for (final step in decoded.whereType<Map>()) {
        final type = _clean(
          (step['intensity'] ?? step['type'] ?? 'step').toString(),
        );
        final seconds = step['durationValue'];
        final duration = seconds is num ? '${_num(seconds / 60)}m' : '';
        final from = step['targetFrom'];
        final to = step['targetTo'];
        final target = step['targetType'] == null
            ? ''
            : '${_clean(step['targetType'].toString())}:${_clean(from?.toString())}'
                  '${to == null || to == from ? '' : '-${_clean(to.toString())}'}';
        steps.add(
          [
            type,
            if (duration.isNotEmpty) duration,
            if (target.isNotEmpty) target,
          ].join('/'),
        );
      }
      return steps.isEmpty ? '' : ',PlannedSteps:${steps.join('+')}';
    } on FormatException {
      return '';
    }
  }

  static String _parseHrZones(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return '';
      final values = <String>[];
      for (var zone = 1; zone <= 5; zone++) {
        final value = decoded['zone$zone'];
        if (value is num && value.isFinite) {
          values.add('Z$zone:${_num(value)}%');
        }
      }
      return values.isEmpty ? '' : ',HRZones:${values.join('/')}';
    } on FormatException {
      return '';
    }
  }

  static double _load(ActivityRecord activity) {
    try {
      return effectiveLoad(activity);
    } on FormatException {
      return activity.trainingLoad ?? 0;
    } on TypeError {
      return activity.trainingLoad ?? 0;
    }
  }

  static double? _km(num? meters) => meters == null ? null : meters / 1000;
  static String _minutes(int? seconds) =>
      seconds == null ? 'na' : '${_num(seconds / 60)}m';
  static String _hours(int? seconds) =>
      _num(seconds == null ? null : seconds / 3600);
  static String _num(num? value) => value == null || !value.isFinite
      ? 'na'
      : value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  static String _clean(String? value) {
    if (value == null || value.trim().isEmpty) return 'na';
    return value
        .replaceAll(RegExp(r'[\[\]\n\r,:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static DateTime _day(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String _date(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  static String _time(DateTime date) {
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String _weekday(DateTime date) => const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ][date.toLocal().weekday - 1];
  static String _pace(int? seconds) => seconds == null
      ? 'na'
      : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}/km';

  static String? buildWeatherSummary(
    OpenMeteoResult? weather, {
    DateTime? now,
  }) {
    if (weather == null) return null;
    final time = now ?? DateTime.now();
    final points = weather.points
        .where((p) => _day(p.time) == _day(time))
        .toList();
    if (points.isEmpty) return null;
    final current = points.where((p) => p.time.hour == time.hour).firstOrNull;
    final min = points.map((p) => p.temperatureC).reduce(math.min);
    final max = points.map((p) => p.temperatureC).reduce(math.max);
    final humidity =
        points.fold(0.0, (s, p) => s + p.humidityPct) / points.length;
    final rainChance = points
        .map((p) => p.precipitationProbability ?? 0)
        .reduce(math.max);
    final rain = points.fold(0.0, (s, p) => s + p.precipitationMm);
    final temp = current?.temperatureC;
    final wind = current?.windSpeedKmh;
    final chill = temp != null && wind != null && temp <= 10 && wind > 5
        ? 13.12 +
              0.6215 * temp -
              11.37 * math.pow(wind, 0.16) +
              0.3965 * temp * math.pow(wind, 0.16)
        : null;
    final wetBulb = current == null
        ? null
        : OpenMeteoClient.wetBulbC(current.temperatureC, current.humidityPct);
    return '[Weather:Today:TempNow:${_num(temp)}°C,TempMin:${_num(min)}°C,'
        'TempMax:${_num(max)}°C,AvgHumidity:${humidity.toStringAsFixed(0)}%,'
        'WindKmh:${_num(wind)},WindChill:${_num(chill)}°C,RainChance:$rainChance%,'
        'RainMm:${_num(rain)},WetBulb:${_num(wetBulb)}°C]';
  }
}
