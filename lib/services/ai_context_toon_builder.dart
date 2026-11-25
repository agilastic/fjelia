import 'dart:math' as math;

import 'package:drift/drift.dart' hide isNull, isNotNull;

import '../db/database.dart';
import 'plan_day.dart';
import '../providers/hr_zone_trends_provider.dart';
import 'fjelia_edition.dart';
import 'hr_zone_summary_service.dart';

import 'package:fjelia_core/services/bio_age_service.dart';
import 'package:fjelia_core/services/ai_context_toon.dart';
import 'package:fjelia_core/services/hrv/hrv_snapshot.dart';
import 'package:fjelia_core/services/season/goal_set.dart';
import 'package:fjelia_core/services/training_form.dart';

import 'hrv/hrv_training_service.dart';
import 'hr_zone_history.dart';
import '../providers/day_data_provider.dart'
    show readTrainingFormSeries, scheduledWorkoutFromRecord;
import '../providers/upcoming_plan_provider.dart'
    show markDoneToday, mergeUpcomingPlan;
import 'post_workout_scorer.dart' show noActivityReason;
import 'race_predictor.dart';
import 'race_goal_service.dart';

import 'package:fjelia_core/models/training_windows.dart';

import 'open_meteo_client.dart';
import '../models/workout_nutrition.dart';
import 'nutrition_service.dart';

export 'package:fjelia_core/services/ai_context_toon.dart'
    show AiContextPlanInfo, AiContextTrainingMonitor, waistContextLine;

/// Loads what the AI Coach context is written from and writes it with
/// [AiContextToon] from fjelia_core.
class AiContextToonBuilder {
  AiContextToonBuilder(
    this._db, {
    DateTime Function()? now,
    this.bodyFrame,
    this.trainingWindows,
    this.casualGoal,
    this.openProposal,
  }) : _now = now ?? DateTime.now;
  final AppDatabase _db;
  final DateTime Function() _now;

  /// Height and the profile's waist from the athlete profile, for the waist
  /// ratios. Only the ratios leave the device, not the height.
  final Future<({double? heightCm, double? waistCm})> Function()? bodyFrame;

  /// When in the week the athlete can train (Settings → Training).
  final Future<TrainingWindows> Function()? trainingWindows;

  /// Without a race goal, what the plan is for: `fun` or `fitness`.
  final Future<String?> Function()? casualGoal;

  /// Today's readiness proposal while it waits for an answer: `shorter`,
  /// `rest` or `replan` (see [BriefingBrief.proposal]).
  final String? Function()? openProposal;

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
    final upcomingWorkouts = await _db.getUpcomingWorkouts();
    final grip = await _db.getGripStrengthRange();
    final thresholds = await _db.getAllThresholdRecords();
    final heat = await _db.getHeatStateForDate(today);
    final readiness = await _db.getTodayReadiness();
    final upcomingSessions = await _db.getUpcomingTrainingSessions();
    // The Plan counts a session as done once a synced activity matches it,
    // while its status can still say planned: the briefing must agree with
    // the Plan and not call a finished session still planned.
    final doneToday = (await markDoneToday(
      _db,
      mergeUpcomingPlan(
        [
          for (final s in upcomingSessions)
            if (_day(s.sessionDate) == today) s,
        ],
        [
          for (final w in upcomingWorkouts)
            if (_day(w.scheduledDate) == today) scheduledWorkoutFromRecord(w),
        ],
      ),
    )).where((e) => e.done && !e.skipped).toList();
    final doneSessionIds = {for (final e in doneToday) ?e.session?.id};
    final doneScheduleIds = {for (final e in doneToday) ?e.workout?.scheduleId};
    // The watch copy of a finished session is finished with it.
    final doneWatchIds = {
      for (final e in doneToday)
        for (final id in [
          e.session?.garminWorkoutId,
          e.session?.garminAlternativeId,
        ])
          ?id,
    };
    final sessions = [
      for (final s in upcomingSessions)
        if (!doneSessionIds.contains(s.id)) s,
    ];
    final workouts = [
      for (final w in upcomingWorkouts)
        if (!doneScheduleIds.contains(w.scheduleId) &&
            !(_day(w.scheduledDate) == today &&
                (doneWatchIds.contains(w.workoutId) ||
                    doneWatchIds.contains(w.scheduleId))))
          w,
    ];
    final fuel = await _fuel(sessions);
    final cancelled = await _cancelledSessions(today);
    final todayAll = await sessionsOn(_db, today);
    final restToday = await isPlannedRestDay(_db, today);
    final tomorrowDay = DateTime(today.year, today.month, today.day + 1);
    final restTomorrow = await isPlannedRestDay(_db, tomorrowDay);
    final absences = await _db.absencesBetween(
      today.subtract(const Duration(days: 7)),
      tomorrowDay,
    );
    TrainingWindows? windowsToday;
    try {
      windowsToday = await trainingWindows?.call();
    } catch (_) {
      // No profile to read: the brief goes without training times.
    }
    // HRV before and after the recent workouts. Optional context: a failure
    // here never blocks the coach.
    HrvSnapshot? hrvSnapshot;
    try {
      hrvSnapshot = await HrvTrainingService(_db, clock: _now).reconcile();
    } catch (_) {}
    // Without the profile the waist line simply has no ratios.
    ({double? heightCm, double? waistCm})? frame;
    try {
      frame = await bodyFrame?.call();
    } catch (_) {}
    final waistHistory = [
      for (final m in await _db.getWaistMeasurements())
        (at: m.measuredAt, waistCm: m.waistCm, hipCm: m.hipCm),
    ];
    GoalSet? nextGoals;
    try {
      nextGoals = await RaceGoalService(_db).resolveGoalSet(today: today);
    } catch (_) {}
    List<FormPoint>? formSeries;
    try {
      formSeries = await readTrainingFormSeries(_db);
    } catch (_) {}
    // FjeliaPro: how the time in zones changed and how it compares with the
    // plan, as observations with their evidence. A failure never blocks the
    // coach.
    var zoneTrendLines = const <String>[];
    if (fjeliaEdition.isPro && hrZoneTrends.isAvailable) {
      try {
        final summaries = HrZoneSummaryService(_db);
        final since = today.subtract(const Duration(days: 60));
        await summaries.update(since: since);
        zoneTrendLines = hrZoneTrends.coachContext(
          await summaries.workouts(since: since),
          [
            for (final s
                in await (_db.select(_db.trainingSessions)..where(
                      (t) => t.sessionDate.isBetweenValues(
                        today.subtract(const Duration(days: 7)),
                        today.add(const Duration(days: 1)),
                      ),
                    ))
                    .get())
              plannedZoneSession(s, today: today),
          ],
          today: today,
        ).toList();
      } catch (_) {}
    }
    // The heart-rate zones in force, and a change of the last two weeks:
    // workouts before it were measured with the older zones.
    String? hrZonesLine;
    try {
      final zones = await HrZoneHistory(_db).book();
      if (!zones.isEmpty) {
        final changed = [
          for (final sport in zoneSports)
            if (zones.latest(sport) case final d?
                when d.method != ZoneMethod.derived &&
                    today.difference(_day(d.effectiveFrom)).inDays <= 14 &&
                    d.effectiveFrom.millisecondsSinceEpoch > 0)
              '$sport ${AiContextToon.date(d.effectiveFrom)} ${d.method}',
        ];
        String floors(String sport) =>
            zones.current(sport)?.join('/') ?? 'none';
        hrZonesLine =
            '[HrZones:Floors:Z1-Z5,Run:${floors('running')},'
            'Bike:${floors('cycling')},Swim:${floors('swimming')}'
            '${changed.isEmpty ? '' : ',ChangedRecently:${changed.join('|')}'}]';
      }
    } catch (_) {}
    // Absences that are still on or ended in the last two weeks, and the
    // weekly training times.
    final availabilityAbsences = await _db.absencesBetween(
      today.subtract(const Duration(days: 14)),
      DateTime(today.year + 2),
    );
    TrainingWindows? windows;
    try {
      windows = await trainingWindows?.call();
    } catch (_) {
      // No profile to read: the context goes without training times.
    }
    final goalSet = await RaceGoalService(_db).resolveGoalSet(today: today);
    final rows = {for (final g in await RaceGoalService(_db).getAll()) g.id: g};
    // Every goal of the season, the plan's own first.
    final ordered = [
      if (goalSet.display != null) goalSet.display!,
      ...goalSet.active.where((g) => g.id != goalSet.display?.id),
    ];
    final estimates = <String, int?>{};
    for (final seasonGoal in ordered) {
      final goal = rows[seasonGoal.id];
      if (goal == null) continue;
      estimates[goal.id] = await RacePredictor.estimateFinish(_db, goal);
    }
    String? aim;
    if (ordered.isEmpty) {
      try {
        aim = await casualGoal?.call();
      } catch (_) {
        // No profile to read: the context goes without the aim.
      }
    }
    final plan =
        await (_db.select(_db.trainingPlans)
              ..where(
                (t) => t.athleteId.equals('self') & t.status.equals('active'),
              )
              ..limit(1))
            .getSingleOrNull();
    return AiContextToon.build(
      AiContextData(
        now: now,
        monitor: monitor,
        raceGoals: raceGoals,
        weatherSummary: weatherSummary,
        bioAge: bioAge,
        planInfo: planInfo,
        hrv: hrv,
        sleep: sleep,
        wellness: wellness,
        bp: bp,
        body: body,
        activities: activities,
        scores: scores,
        grip: grip,
        thresholds: thresholds,
        heat: heat,
        readiness: readiness,
        sessions: sessions,
        workouts: workouts,
        doneSessionIds: doneSessionIds,
        fuel: fuel,
        cancelled: cancelled,
        todayAll: todayAll,
        restToday: restToday,
        restTomorrow: restTomorrow,
        absences: absences,
        trainingWindowsToday: windowsToday,
        hrvSnapshot: hrvSnapshot,
        bodyFrame: frame,
        waistHistory: waistHistory,
        formSeries: formSeries,
        zoneTrendLines: zoneTrendLines,
        hrZonesLine: hrZonesLine,
        availabilityAbsences: availabilityAbsences,
        trainingWindows: windows,
        goalSet: goalSet,
        nextGoalSet: nextGoals,
        goalRows: rows,
        estimates: estimates,
        casualAim: aim,
        seasonJson: plan?.seasonJson,
        openProposal: openProposal?.call(),
      ),
    );
  }

  static DateTime _day(DateTime date) => AiContextToon.day(date);

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

  /// Fjelia's own fuelling plan per session, from the nutrition engine (a
  /// saved or edited strategy first): the coach explains it, it does not
  /// work out its own. Gels:no where they are no option, e.g. in the water.
  Future<Map<String, String>> _fuel(List<TrainingSession> sessions) async {
    final service = NutritionService(_db);
    final prefs = await service.preferences();
    final out = <String, String>{};
    for (final s in sessions.take(14)) {
      final workout = NutritionWorkout(
        key: 'plan:${s.id}',
        title: s.title,
        sport: s.sport,
        date: s.sessionDate,
        minutes: s.plannedDurationMin.toDouble(),
        zone: s.primaryZone,
        indoor: s.indoor,
      );
      final plan =
          await service.savedPlan(workout.key) ??
          planNutrition(
            workout,
            prefs,
            s.indoor
                ? const NutritionConditions(surface: 'Indoor')
                : swimDiscipline(workout, const NutritionConditions()) == 'pool'
                ? const NutritionConditions(surface: 'Pool')
                : const NutritionConditions(),
          );
      out[s.id] =
          ',Fuel:CarbsGh:${AiContextToon.number(plan.carbs)},FluidMlH:${AiContextToon.number(plan.fluid)},'
          'Gels:${plan.gelsPractical ? plan.gels : 'no'}'
          '${swimDiscipline(plan.workout, plan.conditions) == null ? '' : ',Swim:${swimDiscipline(plan.workout, plan.conditions)},Feeds:${plan.conditions.feeds}'}';
    }
    return out;
  }

  static String? buildWeatherSummary(
    OpenMeteoResult? weather, {
    DateTime? now,
  }) {
    if (weather == null) return null;
    final time = now ?? DateTime.now();
    final points = weather.points
        .where((p) => AiContextToon.day(p.time) == AiContextToon.day(time))
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
    return '[Weather:Today:TempNow:${AiContextToon.number(temp)}°C,TempMin:${AiContextToon.number(min)}°C,'
        'TempMax:${AiContextToon.number(max)}°C,AvgHumidity:${humidity.toStringAsFixed(0)}%,'
        'WindKmh:${AiContextToon.number(wind)},WindChill:${AiContextToon.number(chill)}°C,RainChance:$rainChance%,'
        'RainMm:${AiContextToon.number(rain)},WetBulb:${AiContextToon.number(wetBulb)}°C]';
  }
}
