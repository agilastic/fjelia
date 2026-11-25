import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

import '../db/database.dart';

import 'package:fjelia_core/services/hr_zone_model.dart';
import 'package:fjelia_core/services/plan_rules.dart';
import 'package:fjelia_core/services/plan_week_generator.dart';
import 'package:fjelia_core/services/plan_workout_builder.dart';
import 'package:fjelia_core/models/prepared_workout.dart';

import '../models/strength_workout.dart';

import 'package:fjelia_core/services/strength/garmin_strength.dart';

import 'workout_template_library.dart';
import 'strength/strength_plan_edits.dart';
import 'strength/strength_repository.dart';

import 'package:fjelia_core/models/race_profile.dart';
import 'package:fjelia_core/services/workout_semantics.dart';

import '../providers/training_load_provider.dart';

import 'package:fjelia_core/utils/log.dart';
import 'package:fjelia_core/utils/week.dart';

import 'dfa_alpha1_service.dart';
import 'hr_zone_history.dart' show zoneSport;
import 'race_goal_service.dart';

import 'package:fjelia_core/services/ramp_test.dart';
import 'package:fjelia_core/services/season/goal_set.dart';
import 'package:fjelia_core/services/season/season_goal.dart';
import 'package:fjelia_core/services/season/season_timeline.dart';

import 'workout_providers/workout_providers.dart';

export 'package:fjelia_core/services/plan_rules.dart'
    show
        allowedPlanSports,
        casualHorizonDays,
        firstCasualMinutes,
        maxLongRunMinutes,
        zoneForFtpFraction,
        PlanAthleteProfile,
        volumeRampRate,
        rampedWeeklyMinutes;

class TrainingPlanService {
  /// [usesPower] says whether a workout of a sport, indoors or not, carries
  /// power targets. By default none do: heart rate is the target, because a
  /// power meter is not something every athlete has on every bike, and running
  /// power is not available to everyone either. A smart trainer is the usual
  /// exception, so the answer can depend on [indoor].
  TrainingPlanService(
    this._db,
    this._providers, {
    bool Function(String sport, bool indoor)? usesPower,
    DateTime Function()? clock,
  }) : _usesPower = usesPower ?? ((_, _) => false),
       _build = PlanWorkoutBuilder(),
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final WorkoutProviders _providers;

  /// The watch platforms workouts go to.
  WorkoutProviders get providers => _providers;
  final bool Function(String sport, bool indoor) _usesPower;
  final PlanWorkoutBuilder _build;

  /// The clock; tests set it so a season can be planned on a fixed day.
  final DateTime Function() _now;

  /// One plan writer at a time. Two builds at once would each delete and
  /// recreate the same future sessions; the second waits for the first.
  static Future<void> _writer = Future.value();

  static Future<T> _exclusive<T>(Future<T> Function() body) {
    final done = Completer<T>();
    final previous = _writer;
    _writer = done.future.then<void>((_) {}, onError: (_) {});
    previous.then((_) async {
      try {
        done.complete(await body());
      } catch (e, st) {
        done.completeError(e, st);
      }
    });
    return done.future;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// A session the athlete moved to another day.
  static Expression<bool> _isPinned($TrainingSessionsTable t) =>
      t.modifiedBy.equals('athlete') & t.sessionDateOriginal.isNotNull();
  static DateTime _addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  // ---------------------------------------------------------------------------
  // Fitness snapshot
  // ---------------------------------------------------------------------------

  Future<PlanAthleteFitnessSnapshot> _readFitnessSnapshot(
    String athleteId,
    String sport,
  ) async {
    final thresholds = await (_db.select(
      _db.athleteThresholds,
    )..where((t) => t.athleteId.equals(athleteId))).getSingleOrNull();
    final cycling = sport.contains('cycl');
    final swim = sport.contains('swim');

    // HR zones: explicit JSON, else derived from the sport's threshold HR.
    var hrZones = <int>[];
    var hrFloors = <int>[];
    final zonesJson = cycling
        ? thresholds?.bikeHrZonesJson
        : swim
        ? thresholds?.swimHrZonesJson
        : thresholds?.runHrZonesJson;
    if (zonesJson != null) {
      try {
        // Stored as five zone floors; targets need the upper bounds.
        final stored = (jsonDecode(zonesJson) as List)
            .map((e) => (e as num).round())
            .toList();
        hrZones = zoneUpperBounds(stored);
        if (stored.length >= 5) hrFloors = stored;
      } catch (_) {}
    }
    final thrHr = cycling
        ? thresholds?.thresholdHrCyclingBpm ?? thresholds?.thresholdHrBpm
        : swim
        ? thresholds?.thresholdHrSwimBpm ?? thresholds?.thresholdHrBpm
        : thresholds?.thresholdHrBpm;
    if (hrZones.length < 4 && thrHr != null) {
      hrZones = [
        (thrHr * 0.76).round(),
        (thrHr * 0.82).round(),
        (thrHr * 0.88).round(),
        (thrHr * 0.92).round(),
      ];
    }

    final lastThreshold =
        await (_db.select(_db.thresholdRecords)
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(1))
            .getSingleOrNull();

    double? vo2max;
    if (cycling) {
      final rides =
          await (_db.select(_db.activityRecords)
                ..where(
                  (t) => t.type.like('%cycl%') & t.metricsJson.isNotNull(),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.startDate)])
                ..limit(5))
              .get();
      for (final r in rides) {
        try {
          final m = jsonDecode(r.metricsJson!);
          if (m is Map<String, dynamic>) {
            final v = m['vo2MaxCycling'] ?? m['maxMetValue'];
            if (v is num) {
              vo2max = v.toDouble();
              break;
            }
          }
        } catch (_) {}
      }
      vo2max ??=
          (await (_db.select(_db.wellnessRecords)
                    ..where((t) => t.vo2maxCycling.isNotNull())
                    ..orderBy([(t) => OrderingTerm.desc(t.date)])
                    ..limit(1))
                  .getSingleOrNull())
              ?.vo2maxCycling;
    }
    vo2max ??=
        (await (_db.select(_db.wellnessRecords)
                  ..where((t) => t.vo2max.isNotNull())
                  ..orderBy([(t) => OrderingTerm.desc(t.date)])
                  ..limit(1))
                .getSingleOrNull())
            ?.vo2max;

    // CTL/ATL (42/7-day EWMA) over a year of daily strain, every calendar
    // day: a day without training decays both, as on the Form screen and in
    // the daily readiness (finding 1 of docs/training-plan-rethink.md).
    // Counting only days with a score made athletes fitter than they are.
    final today = _day(_now());
    final since = today.subtract(const Duration(days: 365));
    final scores =
        await (_db.select(_db.dayScoreRecords)
              ..where((t) => t.date.isBiggerOrEqualValue(since))
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();
    final strainOn = <DateTime, double>{
      for (final s in scores) _day(s.date): s.strainScore ?? 0.0,
    };
    var ctl = 0.0, atl = 0.0;
    if (scores.isNotEmpty) {
      for (
        var d = _day(scores.first.date);
        !d.isAfter(today);
        d = _addDays(d, 1)
      ) {
        final load = strainOn[d] ?? 0.0;
        ctl += (load - ctl) * (2 / 43);
        atl += (load - atl) * 0.25;
      }
    }
    final tsb = ctl - atl;

    // Average weekly load over the last 6 weeks.
    final sixWeeks = _now().subtract(const Duration(days: 42));
    final recent =
        await (_db.select(_db.activityRecords)
              ..where((t) => t.startDate.isBiggerOrEqualValue(sixWeeks))
              ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
            .get();
    final perWeek = <int, double>{};
    for (final a in recent) {
      final week = a.startDate.millisecondsSinceEpoch ~/ 604800000;
      perWeek[week] = (perWeek[week] ?? 0) + effectiveLoad(a);
    }
    final weeklyTss = perWeek.isEmpty
        ? ctl * 7
        : perWeek.values.fold<double>(0, (a, b) => a + b) / perWeek.length;

    final now = _now();
    final readiness =
        await (_db.select(_db.dailyReadinessRecords)
              ..where(
                (t) => t.date.equals(DateTime(now.year, now.month, now.day)),
              )
              ..limit(1))
            .getSingleOrNull();
    final hrvRatio =
        readiness?.hrvToday != null && (readiness?.hrv7dBaseline ?? 0) > 0
        ? (readiness!.hrvToday! / readiness.hrv7dBaseline!).clamp(0.7, 1.2)
        : 1.0;

    final tier = planTierFor(ctl);
    final snapshot = PlanAthleteFitnessSnapshot(
      ctl: ctl,
      tsb: tsb,
      vo2max: vo2max,
      lt2Bpm: lastThreshold?.lt2Bpm ?? thrHr,
      lt1Bpm: lastThreshold?.lt1Bpm,
      hrZones: hrZones,
      hrFloors: hrFloors,
      maxHr: thresholds?.maxHrBpm,
      tier: tier,
      hrvRatio: hrvRatio,
      sleepScore: readiness?.sleepScore,
      weeklyTss: weeklyTss,
      easyRunZ2: sport == 'running' || sport == 'trail_running',
    );
    log(
      '[Plan] fitness snapshot: CTL=${ctl.toStringAsFixed(1)} '
      'TSB=${tsb.toStringAsFixed(1)} vo2max=$vo2max '
      'lt2=${snapshot.lt2Bpm} lt1=${snapshot.lt1Bpm} hrZones=$hrZones '
      'tier=$tier hrvRatio=${hrvRatio.toStringAsFixed(2)} '
      'sleep=${readiness?.sleepScore}',
    );
    return snapshot;
  }

  // ---------------------------------------------------------------------------
  // Templates & steps
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Plan generation
  // ---------------------------------------------------------------------------

  /// Builds (or rebuilds) a periodised plan up to [raceDate] and stores the
  /// sessions and week summaries. Returns the plan id.
  Future<String> generatePlan({
    required String athleteId,
    String? raceGoalId,
    required DateTime raceDate,
    required String sport,
    double? raceDistanceM,
    double? raceElevationM,
    int? targetFinishSeconds,
    int daysPerWeek = 5,
    List<int> restDays = const [7],
    Map<int, int> dayCapMinutes = const {},
    bool rampTests = true,
    String? casualGoal,
    List<int> strengthDays = const [3],
    double hoursPerWeek = 8.0,
    int maxSessionsPerDay = 1,
    List<String> gadSports = const [],
    String? coachId,
    String? existingPlanId,
    bool weekStartsOnMonday = true,
    PlanAthleteProfile athlete = const PlanAthleteProfile(),
    GoalSet? goals,
  }) => _exclusive(
    () => _generatePlan(
      athleteId: athleteId,
      raceGoalId: raceGoalId,
      raceDate: raceDate,
      sport: sport,
      raceDistanceM: raceDistanceM,
      raceElevationM: raceElevationM,
      targetFinishSeconds: targetFinishSeconds,
      daysPerWeek: daysPerWeek,
      restDays: restDays,
      dayCapMinutes: dayCapMinutes,
      rampTests: rampTests,
      casualGoal: casualGoal,
      strengthDays: strengthDays,
      hoursPerWeek: hoursPerWeek,
      maxSessionsPerDay: maxSessionsPerDay,
      gadSports: gadSports,
      coachId: coachId,
      existingPlanId: existingPlanId,
      weekStartsOnMonday: weekStartsOnMonday,
      athlete: athlete,
      goals: goals,
    ),
  );

  Future<String> _generatePlan({
    required String athleteId,
    String? raceGoalId,
    required DateTime raceDate,
    required String sport,
    double? raceDistanceM,
    double? raceElevationM,
    int? targetFinishSeconds,
    int daysPerWeek = 5,
    List<int> restDays = const [7],
    Map<int, int> dayCapMinutes = const {},
    bool rampTests = true,
    String? casualGoal,
    List<int> strengthDays = const [3],
    double hoursPerWeek = 8.0,
    int maxSessionsPerDay = 1,
    List<String> gadSports = const [],
    String? coachId,
    String? existingPlanId,
    bool weekStartsOnMonday = true,
    PlanAthleteProfile athlete = const PlanAthleteProfile(),
    GoalSet? goals,
  }) async {
    final today = _day(_now());
    // Every goal the season carries. Callers that know only one goal get a
    // set of one, which plans exactly as before.
    final goalSet =
        goals ??
        GoalSet.single(
          SeasonGoal(
            id: raceGoalId ?? 'race',
            name: 'Race',
            sport: sport,
            date: raceDate,
            distanceM: raceDistanceM ?? 0,
            elevationM: raceElevationM,
            targetSeconds: targetFinishSeconds,
          ),
          today: today,
        );
    // More than one goal on the calendar, or one just behind us whose
    // recovery still counts: the season planner takes over from the weekly
    // template.
    // No race goal: a plan for the athlete's own aim (`fun` or `fitness`),
    // built four weeks ahead and again as it runs out.
    final casual =
        casualGoal != null && raceGoalId == null && (goals?.isEmpty ?? true);
    final multi =
        !casual &&
        SeasonPolicy.multiGoalPlanning &&
        (goalSet.active.length > 1 || goalSet.recent.isNotEmpty);
    final display = goalSet.display;
    if (goals != null && display != null) {
      // The plan shows its most important goal; the rest are planned too.
      raceGoalId = display.id;
      raceDate = display.date;
      sport = display.sport;
      raceDistanceM = display.distanceM;
      raceElevationM = display.elevationM;
      targetFinishSeconds = display.targetSeconds;
    }
    final rotation = planGadSportRotation(
      gadSports.isEmpty ? [sport] : gadSports,
    );
    final mainSport = planSupportedSports.contains(sport)
        ? sport
        : rotation.first;
    final allowedSports = {
      ...allowedPlanSports(mainSport: mainSport, chosen: gadSports),
      if (multi)
        for (final g in goalSet.active) ...SeasonTimeline.sportsOf(g).keys,
    };
    var fitness = await _readFitnessSnapshot(athleteId, mainSport);
    // No measured zones: estimate them from age (and sex).
    if (fitness.hrZones.length < 4 && athlete.estimatedHrZones.isNotEmpty) {
      fitness = fitness.withHrZones(athlete.estimatedHrZones);
    }
    final history = PlanTrainingHistory.fromActivities(
      await (_db.select(_db.activityRecords)..where(
            (t) => t.startDate.isBiggerOrEqualValue(
              today.subtract(const Duration(days: 365)),
            ),
          ))
          .get(),
      _now(),
    );
    // The data decides once there is enough of it; the questionnaire answer
    // is only the fallback for new athletes and thin histories.
    final selfReported = athlete.experienceLevel;
    athlete = athlete.withDataLevel(
      tier: fitness.tier,
      enoughData: history.enoughForLevel,
      activeWeeks: history.activeWeeks52,
      mostlyEasy: history.mostlyEasy,
    );
    log(
      '[Plan] athlete: level=${athlete.experienceLevel} '
      '(${athlete.levelFromData ? 'from data, self-reported $selfReported' : 'self-reported'}) '
      'age=${athlete.age} '
      'sex=${athlete.sex} maxHr=${athlete.maxHrEstimate} '
      'cycle=${athlete.recoveryCycle} | history: '
      '${history.weeklyMinutes.round()} min/week '
      '(peak ${history.peakWeeklyMinutes.round()}), '
      'hard=${history.hardShare?.toStringAsFixed(2)} '
      '(${history.hardMinutesPerWeek?.round()} min/week'
      '${history.mostlyEasy ? ', mostly easy' : ''}), sports='
      '${history.sports.map((k, v) => MapEntry(k, '${v.sessions}x med${v.medianMin.round()} max${v.longestMin.round()} year${v.yearLongestMin.round()}'))}',
    );
    final thresholds = await (_db.select(
      _db.athleteThresholds,
    )..where((t) => t.athleteId.equals(athleteId))).getSingleOrNull();
    final ftp = thresholds?.ftpWatts ?? thresholds?.estimatedFtp?.round();

    final prependRecovery = fitness.isFatigued;
    if (prependRecovery) {
      log(
        '[Plan] TSB=${fitness.tsb.toStringAsFixed(1)} < -20 → '
        'prepending recovery week',
      );
    }

    final end = multi
        ? goalSet.horizonEnd!
        : raceDate.isAfter(today)
        ? _day(raceDate)
        : _addDays(today, 28);

    // Only a plan that is still the active one is built on; an ended or
    // replaced plan stays as it is and a new one is made.
    String? buildOn;
    if (existingPlanId != null) {
      final current = await (_db.select(
        _db.trainingPlans,
      )..where((t) => t.id.equals(existingPlanId))).getSingleOrNull();
      if (current != null && current.status == 'active') buildOn = current.id;
    }

    // The season anchor: where the plan began. Phases and the recovery cycle
    // are counted from it, so a replan carries on in the same block instead of
    // starting over at the day it ran. A different race starts a new season.
    var anchor = today;
    if (buildOn != null) {
      final existing = await (_db.select(
        _db.trainingPlans,
      )..where((t) => t.id.equals(buildOn!))).getSingleOrNull();
      if (existing != null && existing.startDate.isBefore(today)) {
        // The season is the same while any goal of the old plan is still a
        // goal; which one is shown does not matter. After the A race the next
        // goal is shown, and the block carries on.
        final linked = {
          for (final l in await (_db.select(
            _db.planGoals,
          )..where((t) => t.planId.equals(existing.id))).get())
            l.goalId,
          if (existing.raceGoalId != null) existing.raceGoalId!,
        };
        final sameSeason =
            existing.raceGoalId == raceGoalId ||
            goalSet.all.any((g) => linked.contains(g.id));
        if (sameSeason) anchor = _day(existing.startDate);
      }
    }
    // Weeks follow the calendar week the athlete chose, counted from the
    // anchor's week; the week index is the plan's block position.
    final anchorWeek = weekStartOf(anchor, mondayFirst: weekStartsOnMonday);
    final currentWeek = weekStartOf(today, mondayFirst: weekStartsOnMonday);
    final lastWeek = weekStartOf(end, mondayFirst: weekStartsOnMonday);
    int weeksBetween(DateTime a, DateTime b) =>
        DateTime.utc(
          b.year,
          b.month,
          b.day,
        ).difference(DateTime.utc(a.year, a.month, a.day)).inDays ~/
        7;
    final firstIndex = weeksBetween(anchorWeek, currentWeek);
    final weeks = (weeksBetween(anchorWeek, lastWeek) + 1).clamp(1, 156);

    // Plan row.
    String planId;
    // What stays of the old plan: sessions the athlete moved (on their day and
    // on the watch), finished ones and skipped ones. The week is planned
    // around them, and nothing is made up for a skipped session.
    var kept = <TrainingSession>[];
    if (buildOn != null) {
      planId = buildOn;
      await _removeDelivered(athleteId, planId);
      await (_db.delete(_db.trainingSessions)..where(
            (t) =>
                t.planId.equals(planId) &
                t.sessionDate.isBiggerOrEqualValue(today) &
                (t.status.equals('planned') | t.status.equals('adapted')) &
                _isPinned(t).not(),
          ))
          .go();
      kept =
          await (_db.select(_db.trainingSessions)..where(
                (t) =>
                    t.planId.equals(planId) &
                    t.sessionDate.isBiggerOrEqualValue(today),
              ))
              .get();
      await (_db.update(
        _db.trainingPlans,
      )..where((t) => t.id.equals(planId))).write(
        TrainingPlansCompanion(
          startDate: Value(anchor),
          endDate: Value(end),
          raceGoalId: Value(raceGoalId),
          lastReplannedAt: Value(DateTime.now()),
          daysPerWeek: Value(daysPerWeek),
          restDaysJson: Value(jsonEncode(restDays)),
          strengthDaysJson: Value(jsonEncode(strengthDays)),
          hoursPerWeek: Value(hoursPerWeek),
        ),
      );
      // Any other active plan for the athlete is superseded.
      await (_db.update(_db.trainingPlans)..where(
            (t) =>
                t.athleteId.equals(athleteId) &
                t.id.equals(planId).not() &
                t.status.equals('active'),
          ))
          .write(const TrainingPlansCompanion(status: Value('superseded')));
    } else {
      planId = const Uuid().v4();
      await (_db.update(_db.trainingPlans)..where(
            (t) => t.athleteId.equals(athleteId) & t.status.equals('active'),
          ))
          .write(const TrainingPlansCompanion(status: Value('superseded')));
      await _db
          .into(_db.trainingPlans)
          .insert(
            TrainingPlansCompanion.insert(
              id: planId,
              athleteId: athleteId,
              coachId: Value(coachId),
              raceGoalId: Value(raceGoalId),
              startDate: today,
              endDate: end,
              status: 'active',
              generatedAt: DateTime.now(),
              daysPerWeek: Value(daysPerWeek),
              restDaysJson: Value(jsonEncode(restDays)),
              strengthDaysJson: Value(jsonEncode(strengthDays)),
              hoursPerWeek: Value(hoursPerWeek),
            ),
          );
    }

    // Every plan and replan works from the current library: templates added
    // by an app update are there even when no historic sync ran since.
    await WorkoutTemplateLibrary(_db).seedIfEmpty();
    final templates = await _db.select(_db.workoutTemplates).get();
    final category = planDistanceCategory(raceDistanceM);
    final raceProfile = raceDistanceM != null && raceDistanceM > 0
        ? RaceProfile(
            sport: mainSport,
            distanceM: raceDistanceM,
            elevationM: raceElevationM,
            targetSeconds: targetFinishSeconds,
          )
        : null;
    final terrain = raceProfile?.terrain ?? Terrain.flat;
    final longRunCap = maxLongRunMinutes(
      category,
      targetMin: targetFinishSeconds == null
          ? null
          : (targetFinishSeconds / 60).round(),
    );
    final baseSlots =
        planWeekTemplates[mainSport] ?? planWeekTemplates['running']!;
    final targetWeeklyMin = hoursPerWeek * 60;
    final baseWeeklyTss = math.max(fitness.weeklyTss, 50.0);
    final readiness = _build.readinessFactor(fitness);
    final raceDay = _day(raceDate);

    var sessionNumber = 0;
    var gadIndex = 0;

    // Why sessions were skipped. Illness and injury are health restrictions:
    // that day takes nothing new, and nothing replaces what was dropped.
    final skipReasons = <String, String>{};
    final skippedIds = [
      for (final k in kept)
        if (k.status == 'skipped') k.id,
    ];
    if (skippedIds.isNotEmpty) {
      for (final a in await (_db.select(
        _db.sessionActuals,
      )..where((t) => t.sessionId.isIn(skippedIds))).get()) {
        if (a.skipReason != null) skipReasons[a.sessionId] = a.skipReason!;
      }
    }
    bool isHealth(String? reason) =>
        reason != null &&
        RegExp(
          r'illness|injur|pain|sick',
          caseSensitive: false,
        ).hasMatch(reason);
    final healthDays = {
      for (final k in kept)
        if (k.status == 'skipped' && isHealth(skipReasons[k.id]))
          _day(k.sessionDate),
    };
    // Absences the athlete entered: no session on their days. The first
    // week back from an illness or injury is easy and short.
    final easeInDays = <DateTime>{};
    for (final a in await _db.absencesBetween(
      _addDays(today, -7),
      DateTime(today.year + 3),
    )) {
      final last = _day(a.endDay);
      for (var d = _day(a.startDay); !d.isAfter(last); d = _addDays(d, 1)) {
        healthDays.add(d);
      }
      if (a.kind == 'illness' || a.kind == 'injury') {
        for (var i = 1; i <= 7; i++) {
          easeInDays.add(_addDays(last, i));
        }
      }
    }
    easeInDays.removeAll(healthDays);
    // The longest session a day has room for: its training window, and at
    // most 45 minutes in a first week back.
    // An ordinary training day of this plan, for the volume held back after
    // an event (GoalSet.volumeFactorOn): 20 % of it the first days, then 40,
    // 60 and 80 %.
    final ordinaryDayMin = hoursPerWeek * 60 / math.max(1, daysPerWeek);
    int? capOn(DateTime date) {
      var window = dayCapMinutes[date.weekday];
      final factor = goalSet.volumeFactorOn(date);
      if (factor != null) {
        final cap = math.max(20, (ordinaryDayMin * factor).round());
        window = window == null ? cap : math.min(window, cap);
      }
      if (!easeInDays.contains(date)) return window;
      return math.min(window ?? 45, 45);
    }

    // No race and no training at all yet: one easy 25-minute session to
    // start with. Once it is done, the history it leaves plans the rest.
    if (casual && history.sessions12w == 0) {
      final waiting = kept.any(
        (k) =>
            (k.status == 'planned' || k.status == 'adapted') &&
            !k.sessionDate.isBefore(today),
      );
      if (!waiting) {
        await _firstCasualSession(
          planId: planId,
          athleteId: athleteId,
          coachId: coachId,
          sports: gadSports.isEmpty ? [sport] : gadSports,
          restDays: restDays,
          blocked: healthDays,
          fitness: fitness,
          ftp: ftp,
          capOn: capOn,
        );
      }
      await (_db.update(_db.trainingPlans)..where((t) => t.id.equals(planId)))
          .write(const TrainingPlansCompanion(seasonJson: Value(null)));
      log('[Plan] casual ($casualGoal): first easy session, no history yet');
      return planId;
    }

    // The DFA alpha1 ramp test: in running or cycling (a triathlon takes
    // both, in turn), once a chest strap has recorded beat-to-beat data in
    // that sport, about every four weeks. A progression the athlete ran on
    // their own counts as a test.
    String? rampFamilyOf(String sport) =>
        sport == 'running' || sport == 'trail_running'
        ? 'running'
        : sport.startsWith('cycling')
        ? 'cycling'
        : null;
    final lastRamp = <String, DateTime?>{};
    if (rampTests) {
      for (final family
          in mainSport == 'triathlon'
              ? const ['running', 'cycling']
              : [?rampFamilyOf(mainSport)]) {
        final state = await DfaAlpha1Service(_db)
            .rampState(cycling: family == 'cycling', now: _now());
        if (!state.strap) continue;
        var last = state.lastProgression == null
            ? null
            : _day(state.lastProgression!);
        for (final k in kept) {
          if (k.subType != rampTestSubType ||
              rampFamilyOf(k.sport) != family ||
              k.status == 'skipped' ||
              k.status == 'missed') {
            continue;
          }
          final d = _day(k.sessionDate);
          if (last == null || d.isAfter(last)) last = d;
        }
        lastRamp[family] = last;
      }
    }
    // One test at a time, whatever the sport.
    DateTime? nextRamp;
    if (lastRamp.isNotEmpty) {
      final dates = lastRamp.values.nonNulls.toList()..sort();
      nextRamp = dates.isEmpty
          ? today
          : _addDays(dates.last, rampTestEvery.inDays);
    }

    // Training already done today that no session accounts for: it is real
    // load, so it takes its day and its minutes out of the plan.
    final doneToday = <({DateTime day, int minutes})>[];
    {
      final dayEnd = _addDays(today, 1);
      final rows =
          await (_db.select(_db.activityRecords)..where(
                (t) =>
                    t.startDate.isBiggerOrEqualValue(today) &
                    t.startDate.isSmallerThanValue(dayEnd),
              ))
              .get();
      if (rows.isNotEmpty) {
        final linked = {
          for (final a
              in await (_db.select(_db.sessionActuals)..where(
                    (t) =>
                        t.activityId.isIn([for (final r in rows) r.activityId]),
                  ))
                  .get())
            a.activityId,
        };
        for (final r in rows) {
          if (linked.contains(r.activityId)) continue;
          doneToday.add((
            day: today,
            minutes: (r.durationSeconds / 60).round(),
          ));
        }
      }
    }

    final generation = await PlanWeekGenerator(_build, usesPower: _usesPower)
        .generate(
          allowedSports: allowedSports,
          anchorWeek: anchorWeek,
          athlete: athlete,
          baseSlots: baseSlots,
          baseWeeklyTss: baseWeeklyTss,
          capOn: capOn,
          casual: casual,
          casualGoal: casualGoal,
          daysPerWeek: daysPerWeek,
          doneToday: doneToday,
          easeInDays: easeInDays,
          end: end,
          firstIndex: firstIndex,
          fitness: fitness,
          ftp: ftp,
          gadIndex: gadIndex,
          gadSports: gadSports,
          goalSet: goalSet,
          healthDays: healthDays,
          history: history,
          kept: kept,
          lastRamp: lastRamp,
          longRunCap: longRunCap,
          mainSport: mainSport,
          maxSessionsPerDay: maxSessionsPerDay,
          multi: multi,
          nextRamp: nextRamp,
          prependRecovery: prependRecovery,
          raceDay: raceDay,
          raceGoalId: raceGoalId,
          raceProfile: raceProfile,
          rampFamilyOf: rampFamilyOf,
          readiness: readiness,
          restDays: restDays,
          rotation: rotation,
          sessionNumber: sessionNumber,
          sport: sport,
          strengthDays: strengthDays,
          targetWeeklyMin: targetWeeklyMin,
          templates: templates,
          terrain: terrain,
          thresholdPaceMps: thresholds?.thresholdPaceMps,
          today: today,
          weekStartsOnMonday: weekStartsOnMonday,
          weeks: weeks,
          readFitness: (sport) => _readFitnessSnapshot(athleteId, sport),
        );
    sessionNumber = generation.sessionNumber;
    final report = generation.report;
    for (final write in generation.writes) {
      switch (write) {
        case GeneratedPlanSession s:
          await _db
              .into(_db.trainingSessions)
              .insert(
                TrainingSessionsCompanion.insert(
                  id: const Uuid().v4(),
                  planId: planId,
                  athleteId: athleteId,
                  coachId: Value(coachId),
                  sessionDate: s.sessionDate,
                  sessionNumber: s.sessionNumber,
                  weekNumber: s.weekNumber,
                  sport: s.sport,
                  sessionType: s.sessionType,
                  subType: Value(s.subType),
                  phase: s.phase,
                  primaryZone: s.primaryZone,
                  title: s.title,
                  sessionNotes: Value(s.sessionNotes),
                  mainSet: Value(s.mainSet),
                  warmUp: Value(s.warmUp),
                  warmUpDurationMin: Value(s.warmUpDurationMin),
                  stepsJson: Value(s.stepsJson),
                  hrRangesJson: Value(s.hrRangesJson),
                  paceRangesJson: Value(s.paceRangesJson),
                  powerRangesJson: Value(s.powerRangesJson),
                  plannedDurationMin: s.plannedDurationMin,
                  plannedTrimp: s.plannedTrimp,
                  sessionLevel: s.sessionLevel,
                  goalId: Value(s.goalId),
                  goalRole: Value(s.goalRole),
                  goalObjective: Value(s.goalObjective),
                  status: const Value('planned'),
                ),
              );
        case GeneratedWeekSummary w:
          await _db
              .into(_db.weekSummaries)
              .insert(
                WeekSummariesCompanion.insert(
                  athleteId: athleteId,
                  weekStart: w.weekStart,
                  weekNumber: w.weekNumber,
                  phase: w.phase,
                  isRecoveryWeek: Value(w.phase == 'recovery'),
                  plannedTrimp: Value(w.plannedTrimp),
                  sessionsPlanned: Value(w.sessionsPlanned),
                  ctl: Value(w.ctl),
                  tsb: Value(w.tsb),
                ),
                onConflict: DoUpdate(
                  (old) => WeekSummariesCompanion(
                    weekNumber: Value(w.weekNumberOnUpdate),
                    phase: Value(w.phase),
                    isRecoveryWeek: Value(w.phase == 'recovery'),
                    plannedTrimp: Value(w.plannedTrimp),
                    sessionsPlanned: Value(w.sessionsPlanned),
                  ),
                ),
              );
      }
    }

    await (_db.update(
      _db.trainingPlans,
    )..where((t) => t.id.equals(planId))).write(
      TrainingPlansCompanion(
        goalSetRevision: Value(goalSet.revision),
        // Without a race there is no season to explain.
        seasonJson: Value(casual ? null : report.encode()),
      ),
    );
    await (_db.delete(
      _db.planGoals,
    )..where((t) => t.planId.equals(planId))).go();
    if (goals != null || raceGoalId != null) {
      for (final goal in goalSet.active) {
        await _db
            .into(_db.planGoals)
            .insert(
              PlanGoalsCompanion.insert(
                planId: planId,
                goalId: goal.id,
                priority: goal.priority.name,
                goalRevision: goal.revision,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    }
    log(
      '[Plan] generatePlan done — planId=$planId sessions=$sessionNumber '
      'weeks=$weeks days=$daysPerWeek maxPerDay=$maxSessionsPerDay '
      'GAD rotation=$rotation race=$category sport=$mainSport '
      'goals=${goalSet.active.length} outcome=${report.outcome.name}',
    );
    return planId;
  }

  /// The very first session of a plan without a race or any history: 25
  /// minutes easy, running or cycling when the athlete chose one, else
  /// their first sport, on the next day free for it.
  Future<void> _firstCasualSession({
    required String planId,
    required String athleteId,
    required String? coachId,
    required List<String> sports,
    required List<int> restDays,
    required Set<DateTime> blocked,
    required PlanAthleteFitnessSnapshot fitness,
    required int? ftp,
    required int? Function(DateTime) capOn,
  }) async {
    const preferred = [
      'running',
      'cycling_road',
      'cycling_gravel',
      'cycling_mtb',
      'trail_running',
    ];
    final sport =
        preferred.where(sports.contains).firstOrNull ??
        planGadSportRotation(sports).first;
    final now = _now();
    var day = _day(now);
    // Too late today for a first session: tomorrow.
    if (now.hour >= 18) day = _addDays(day, 1);
    for (var i = 0; i < 7; i++) {
      final cap = capOn(day);
      if (!restDays.contains(day.weekday) &&
          !blocked.contains(day) &&
          (cap == null || cap >= 25)) {
        break;
      }
      day = _addDays(day, 1);
    }
    final stepsJson = _build.resolveStepsJson(
      PlanWorkoutBuilder.steadySteps(firstCasualMinutes, 2),
      ftp,
      fitness,
      power: _usesPower(sport, false),
    );
    final semantics = WorkoutSemantics.of(stepsJson, sport: sport);
    final hr = fitness.hrRangeForZone(2);
    await _db
        .into(_db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: const Uuid().v4(),
            planId: planId,
            athleteId: athleteId,
            coachId: Value(coachId),
            sessionDate: day,
            sessionNumber: 1,
            weekNumber: 1,
            sport: sport,
            sessionType: 'recovery',
            phase: 'base',
            primaryZone: 2,
            title: PlanWorkoutBuilder.steadyTitle(
              sport,
              firstCasualMinutes,
              lead: 'Easy',
            ),
            sessionNotes: const Value(
              'A first easy session: relaxed, you could talk the whole time. '
              'Once it is done, Fjelia plans the weeks after it from it.',
            ),
            stepsJson: Value(stepsJson),
            hrRangesJson: Value(
              jsonEncode({'low': hr.low, 'high': hr.high, 'zone': 2}),
            ),
            plannedDurationMin: firstCasualMinutes,
            plannedTrimp: semantics.legacyLoad.round(),
            sessionLevel: PlanWorkoutBuilder.sessionLevel(
              'recovery',
              2,
              'base',
            ),
            goalRole: const Value('primary'),
            status: const Value('planned'),
          ),
        );
    await (_db.update(_db.trainingPlans)..where((t) => t.id.equals(planId)))
        .write(TrainingPlansCompanion(endDate: Value(day)));
  }

  /// Rebuilds the remaining weeks of [planId] (e.g. after a readiness
  /// trigger or a settings change), bumping the plan version.
  Future<void> replan({
    required String planId,
    required String reason,
    int daysPerWeek = 5,
    List<int> restDays = const [7],
    Map<int, int> dayCapMinutes = const {},
    bool rampTests = true,
    String? casualGoal,
    List<int> strengthDays = const [3],
    double hoursPerWeek = 8.0,
    int maxSessionsPerDay = 1,
    List<String> preferredSports = const [],
    bool weekStartsOnMonday = true,
    PlanAthleteProfile athlete = const PlanAthleteProfile(),
  }) => _exclusive(
    () => _replan(
      planId: planId,
      reason: reason,
      daysPerWeek: daysPerWeek,
      restDays: restDays,
      dayCapMinutes: dayCapMinutes,
      rampTests: rampTests,
      casualGoal: casualGoal,
      strengthDays: strengthDays,
      hoursPerWeek: hoursPerWeek,
      maxSessionsPerDay: maxSessionsPerDay,
      preferredSports: preferredSports,
      weekStartsOnMonday: weekStartsOnMonday,
      athlete: athlete,
    ),
  );

  Future<void> _replan({
    required String planId,
    required String reason,
    int daysPerWeek = 5,
    List<int> restDays = const [7],
    Map<int, int> dayCapMinutes = const {},
    bool rampTests = true,
    String? casualGoal,
    List<int> strengthDays = const [3],
    double hoursPerWeek = 8.0,
    int maxSessionsPerDay = 1,
    List<String> preferredSports = const [],
    bool weekStartsOnMonday = true,
    PlanAthleteProfile athlete = const PlanAthleteProfile(),
  }) async {
    final plan = await (_db.select(
      _db.trainingPlans,
    )..where((t) => t.id.equals(planId))).getSingleOrNull();
    if (plan == null || plan.status != 'active') return;
    final today = _day(_now());
    log(
      '[Plan] replan: deleting Garmin workouts for athlete='
      '${plan.athleteId} from=$today',
    );

    await (_db.update(
      _db.trainingPlans,
    )..where((t) => t.id.equals(planId))).write(
      TrainingPlansCompanion(
        version: Value(plan.version + 1),
        lastReplannedAt: Value(DateTime.now()),
        replannedReason: Value(reason),
      ),
    );

    // The whole season: every goal that is still on, not only the next A.
    final goalSet = await RaceGoalService(_db)
        .resolveGoalSet(athleteId: plan.athleteId, today: today);
    final goal = goalSet.display;
    final rotation = planGadSportRotation(preferredSports);
    // No race to prepare for: the athlete's own aim, four weeks at a time.
    final casual = goal == null && casualGoal != null;

    await _generatePlan(
      athleteId: plan.athleteId,
      raceGoalId: casual ? null : goal?.id ?? plan.raceGoalId,
      raceDate: casual
          ? _addDays(today, casualHorizonDays)
          : goal?.date ?? plan.endDate,
      sport: goal?.sport ?? rotation.first,
      raceDistanceM: goal?.distanceM,
      raceElevationM: goal?.elevationM,
      targetFinishSeconds: goal?.targetSeconds,
      daysPerWeek: daysPerWeek,
      restDays: restDays,
      dayCapMinutes: dayCapMinutes,
      rampTests: rampTests,
      strengthDays: strengthDays,
      hoursPerWeek: hoursPerWeek,
      maxSessionsPerDay: maxSessionsPerDay,
      gadSports: preferredSports,
      coachId: plan.coachId,
      existingPlanId: planId,
      weekStartsOnMonday: weekStartsOnMonday,
      athlete: athlete,
      goals: goalSet.isEmpty ? null : goalSet,
      casualGoal: casual ? casualGoal : null,
    );
  }

  /// Tries again, on every platform, the removals that failed earlier.
  /// Returns how many went.
  Future<int> retryCleanup() => _providers.retryCleanup();

  /// Ends a plan whose goals are all gone: nothing is left to prepare for.
  /// The planned sessions from today on and their watch entries are removed,
  /// finished and skipped ones stay as the record, and the plan stops being
  /// the active one. Returns how many planned sessions were removed.
  Future<int> endPlan(String planId, {String reason = 'No goals left'}) =>
      _exclusive(() => _endPlan(planId, reason));

  Future<int> _endPlan(String planId, String reason) async {
    final plan = await (_db.select(
      _db.trainingPlans,
    )..where((t) => t.id.equals(planId))).getSingleOrNull();
    if (plan == null || plan.status != 'active') return 0;
    final today = _day(_now());
    // Ended first: from here nothing builds on it or sends it to the watch.
    await (_db.update(
      _db.trainingPlans,
    )..where((t) => t.id.equals(planId))).write(
      TrainingPlansCompanion(
        status: const Value('ended'),
        replannedReason: Value(reason),
        lastReplannedAt: Value(DateTime.now()),
      ),
    );
    // A watch entry that cannot be removed now is queued and tried again;
    // the plan does not wait for the connection.
    await _removeDelivered(plan.athleteId, planId, includeMoved: true);
    final removed =
        await (_db.delete(_db.trainingSessions)..where(
              (t) =>
                  t.planId.equals(planId) &
                  t.sessionDate.isBiggerOrEqualValue(today) &
                  (t.status.equals('planned') | t.status.equals('adapted')),
            ))
            .go();
    log('[Plan] ended $planId ($reason): $removed planned sessions removed');
    return removed;
  }

  // Watch platforms
  // ---------------------------------------------------------------------------

  /// Sends every upcoming planned session that is not on a platform yet to
  /// each platform that takes workouts (all connected push providers, or
  /// [to]). An identical workout already on a calendar is adopted, not sent
  /// again. A platform that fails does not stop the others.
  Future<void> deliverPlan(
    String athleteId, {
    Iterable<WorkoutProvider>? to,
  }) async {
    final today = _day(_now());
    // Only the active plan goes to a watch, never an ended or replaced one.
    final activePlans = [
      for (final p
          in await (_db.select(_db.trainingPlans)..where(
                (t) =>
                    t.athleteId.equals(athleteId) & t.status.equals('active'),
              ))
              .get())
        p.id,
    ];
    final sessions =
        await (_db.select(_db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals(athleteId) &
                    t.planId.isIn(activePlans) &
                    t.sessionDate.isBiggerOrEqualValue(today) &
                    t.status.equals('planned'),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
            .get();
    final targets = to ?? await _providers.pushTargets();
    for (final provider in targets) {
      var open = [
        for (final s in sessions)
          if (!await provider.hasDelivered(s)) s,
      ];
      try {
        final adopted = await provider.adoptExisting(
          open,
          prepare: _prepareWorkout,
        );
        open = [
          for (final s in open)
            if (!adopted.contains(s.id)) s,
        ];
      } catch (e) {
        log('[Planner] ${provider.label} could not check for duplicates: $e');
      }
      for (final s in open) {
        try {
          await deliver(s.id, provider);
        } catch (e) {
          log('[Planner] ${provider.label} push failed for ${s.id}: $e');
        }
      }
    }
  }

  /// New heart-rate zones of [sports] (zone families: running, cycling,
  /// swimming): the coming workouts of those sports that are already on a
  /// platform go up again, with targets in the new zones. Platforms that
  /// cannot be sent to are left alone; a platform sends only what changed.
  /// Returns how many workouts were brought up to date.
  Future<int> redeliverForZones(Set<String> sports) async {
    if (sports.isEmpty) return 0;
    final today = _day(_now());
    final sessions =
        await (_db.select(_db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.sessionDate.isBiggerOrEqualValue(today) &
                    t.status.isIn(const ['planned', 'adapted']),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
            .get();
    final senders = [
      for (final p in await _providers.connected())
        if (await p.mode() == DeliveryMode.push) p,
    ];
    var sent = 0;
    for (final s in sessions) {
      if (isStrengthSport(s.sport) || !sports.contains(zoneSport(s.sport))) {
        continue;
      }
      for (final p in senders) {
        if (!await p.hasDelivered(s)) continue;
        try {
          await deliver(s.id, p);
          sent++;
        } catch (e) {
          log('[Planner] ${p.label} zone update failed for ${s.id}: $e');
        }
      }
    }
    return sent;
  }

  /// Puts the session's workout on [provider]'s platform, replacing what was
  /// sent for it before. Throws with the platform's own message when it
  /// refuses, [WorkoutNotSupported] for a workout it cannot hold.
  Future<void> deliver(String sessionId, WorkoutProvider provider) async {
    final s = await (_db.select(
      _db.trainingSessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (s == null) throw StateError('Workout no longer exists.');
    if (!['planned', 'adapted'].contains(s.status)) {
      throw StateError('Only planned workouts can be pushed.');
    }
    final owner = await (_db.select(
      _db.trainingPlans,
    )..where((t) => t.id.equals(s.planId))).getSingleOrNull();
    if (owner != null && owner.status != 'active') {
      throw StateError('This plan has ended, its workouts are not sent.');
    }
    if (await provider.mode() != DeliveryMode.push) {
      throw StateError('${provider.label} takes workouts as text.');
    }
    // A lift is never sent as a timed heart-rate outline in its place.
    if (isStrengthSport(s.sport) && !provider.supportsStrength) {
      throw WorkoutNotSupported(
        '${provider.label} does not take strength exercises from Fjelia.',
      );
    }
    await provider.deliver(s, () => _prepareWorkout(s));
  }

  /// Takes the planned sessions' workouts off every platform that has them:
  /// the sessions of [planId] from today on, those moved by the athlete only
  /// when [includeMoved]. A removal that fails is queued by the platform.
  Future<void> _removeDelivered(
    String athleteId,
    String planId, {
    bool includeMoved = false,
  }) async {
    final today = _day(_now());
    final sessions =
        await (_db.select(_db.trainingSessions)..where(
              (t) =>
                  t.planId.equals(planId) &
                  (t.status.equals('planned') | t.status.equals('adapted')) &
                  t.sessionDate.isBiggerOrEqualValue(today) &
                  (includeMoved ? const Constant(true) : _isPinned(t).not()),
            ))
            .get();
    for (final s in sessions) {
      await _providers.removeEverywhere(s);
    }
  }

  /// A template's steps as a session of [sport] would get them, for checks
  /// over every template at once.
  @visibleForTesting
  Future<String> resolveTemplateSteps(
    String stepsJson, {
    required String sport,
    bool power = false,
  }) async {
    final fitness = await _readFitnessSnapshot('self', sport);
    final thresholds = await (_db.select(
      _db.athleteThresholds,
    )..where((t) => t.athleteId.equals('self'))).getSingleOrNull();
    return _build.resolveStepsJson(
      stepsJson,
      thresholds?.ftpWatts,
      fitness,
      power: power,
    );
  }

  /// The session's steps with concrete targets and its description, the same
  /// for every watch: heart-rate zones from the athlete's settings first,
  /// power only where it is switched on, notes on every step.
  Future<PreparedWorkout> _prepareWorkout(TrainingSession s) async {
    if (isStrengthSport(s.sport)) return _prepareStrength(s);
    if (s.stepsJson == null) {
      throw StateError('No workout structure is available.');
    }
    final thresholds = await (_db.select(
      _db.athleteThresholds,
    )..where((t) => t.athleteId.equals(s.athleteId))).getSingleOrNull();
    final floors = PlanWorkoutBuilder.zonesFromJson(
      s.sport.contains('swim')
          ? thresholds?.swimHrZonesJson
          : s.sport.contains('cycl')
          ? thresholds?.bikeHrZonesJson
          : thresholds?.runHrZonesJson,
    );
    // Five stored values are the zone floors; the planner's upper-bound list
    // is derived from them, never the floors passed off as upper bounds.
    final fitness = PlanAthleteFitnessSnapshot(
      ctl: 0,
      tsb: 0,
      tier: 'intermediate',
      hrZones: floors.length >= 5 ? zoneUpperBounds(floors) : floors,
      hrFloors: floors.length >= 5 ? floors : const [],
      maxHr: thresholds?.maxHrBpm,
      easyRunZ2: s.sport == 'running' || s.sport == 'trail_running',
    );
    final ftp = thresholds?.ftpWatts;
    final power = s.targetMetric != null
        ? s.targetMetric == 'power'
        : _usesPower(s.sport, s.indoor);
    final steps = PlanWorkoutBuilder.withNotes(
      (jsonDecode(s.stepsJson!) as List)
          .cast<Map<String, dynamic>>()
          .map((st) => _build.resolveStep(st, ftp, fitness, power: power))
          .toList()
          .asMap()
          .entries
          .map((e) => _withoutPlanKeys({...e.value, 'stepOrder': e.key + 1}))
          .toList(),
    );

    final plan = await (_db.select(
      _db.trainingPlans,
    )..where((t) => t.id.equals(s.planId))).getSingleOrNull();
    // The goal the session prepares for; a session planned before goals were
    // linked belongs to the plan's own.
    final goalId = s.goalId ?? plan?.raceGoalId;
    final goal = goalId == null
        ? null
        : await (_db.select(
            _db.raceGoals,
          )..where((t) => t.id.equals(goalId))).getSingleOrNull();
    // Threshold heart rate: the latest test, else the sport's stored value,
    // else the lowest bound of zone 5, where the zones are built on it.
    final lastThreshold =
        await (_db.select(_db.thresholdRecords)
              ..where((t) => t.lt2Bpm.isNotNull())
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(1))
            .getSingleOrNull();
    final sportThreshold = s.sport.contains('cycl')
        ? thresholds?.thresholdHrCyclingBpm
        : s.sport.contains('swim')
        ? thresholds?.thresholdHrSwimBpm
        : thresholds?.thresholdHrBpm;
    final thresholdHr =
        sportThreshold ??
        lastThreshold?.lt2Bpm ??
        (floors.length >= 5 ? floors[4] : null);
    return PreparedWorkout(
      sessionId: s.id,
      title: s.title,
      date: s.sessionDate,
      sport: s.sport,
      steps: steps,
      description: _build.garminDescription(s, steps, power: power, goal: goal),
      thresholdHr: thresholdHr,
      indoor: s.indoor,
    );
  }

  /// [step] without the keys only the planner reads, in repeats too.
  static Map<String, dynamic> _withoutPlanKeys(Map<String, dynamic> step) {
    final out = Map<String, dynamic>.of(step)
      ..remove('fixedTarget')
      ..remove('easyRun');
    final inner = out['workoutSteps'];
    if (inner is List) {
      out['workoutSteps'] = [
        for (final s in inner.cast<Map<String, dynamic>>()) _withoutPlanKeys(s),
      ];
    }
    return out;
  }

  /// A strength session as exercise steps, from its saved or verified
  /// bundled plan. Without exercises there is nothing honest to send.
  Future<PreparedWorkout> _prepareStrength(TrainingSession s) async {
    final found = await StrengthRepository(_db).sessionPlan(s);
    if (found == null || found.plan.isEmpty) {
      throw const WorkoutNotSupported(
        'Add exercises to this workout to send it; it is shared as text.',
      );
    }
    final plan = found.plan;
    final text = [
      if (plan.notes != null) plan.notes!,
      strengthPlanText(plan, MassUnit.kg),
    ].join('\n\n');
    return PreparedWorkout(
      sessionId: s.id,
      title: s.title,
      date: s.sessionDate,
      sport: s.sport,
      steps: garminStrengthPayload(plan).steps,
      description: text.length <= 1500 ? text : '${text.substring(0, 1497)}...',
    );
  }

  /// What a strength upload leaves out (rep ranges, effort, tempo…); empty
  /// for other sessions.
  Future<List<String>> strengthUploadOmissions(String sessionId) async {
    final s = await (_db.select(
      _db.trainingSessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (s == null || !isStrengthSport(s.sport)) return const [];
    final found = await StrengthRepository(_db).sessionPlan(s);
    return found == null ? const [] : garminStrengthPayload(found.plan).omitted;
  }

  /// The session ready for a watch platform: steps with targets, notes and
  /// the threshold heart rate.
  Future<PreparedWorkout> prepareWorkout(String sessionId) async {
    final s = await (_db.select(
      _db.trainingSessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (s == null) throw StateError('Workout no longer exists.');
    return _prepareWorkout(s);
  }

  /// The workout as text for the athlete: title, date and everything the
  /// watch would show. For watches that cannot receive it from Fjelia.
  Future<({String title, DateTime date, String text})> workoutText(
    String sessionId,
  ) async {
    try {
      final w = await prepareWorkout(sessionId);
      return (title: w.title, date: w.date, text: w.description);
    } on WorkoutNotSupported {
      // A strength session without exercises: its notes are what there is.
      final s = (await (_db.select(
        _db.trainingSessions,
      )..where((t) => t.id.equals(sessionId))).getSingle());
      return (
        title: s.title,
        date: s.sessionDate,
        text: [
          s.sessionNotes,
          s.mainSet,
        ].whereType<String>().where((t) => t.isNotEmpty).join('\n\n'),
      );
    }
  }

  /// Deletes every plan and planned session on this phone. Completed
  /// activities are kept. Fast: nothing leaves the phone.
  Future<void> deleteLocalPlans() async {
    await (_db.delete(
      _db.trainingSessions,
    )..where((t) => t.athleteId.equals('self'))).go();
    await (_db.delete(
      _db.trainingPlans,
    )..where((t) => t.athleteId.equals('self'))).go();
    log('[Plan] local plans deleted');
  }

  /// Takes everything Fjelia put on the watch platforms off them ("delete
  /// all"): each of [providers] (or every connected one) removes what it
  /// holds, reporting progress as `(done, total, label)`. [titles] names the
  /// workouts for platforms that can only be searched by name. Returns how
  /// many entries went per platform id. A platform that fails does not stop
  /// the others.
  Future<Map<String, int>> removeFromPlatforms({
    required Set<String> titles,
    Iterable<WorkoutProvider>? providers,
    void Function(int done, int total, String label)? onProgress,
    Duration providerTimeout = const Duration(minutes: 5),
  }) async {
    final targets = providers ?? await _providers.connected();
    final removed = <String, int>{};
    for (final p in targets) {
      try {
        // A platform that stops answering must not hold the others, or the
        // screen, for ever.
        removed[p.id] = await p
            .removeAll(
              titles: titles,
              onProgress: (done, total) =>
                  onProgress?.call(done, total, p.label),
            )
            .timeout(providerTimeout);
      } catch (e) {
        log('[Plan] ${p.label} could not be cleared: $e');
        removed[p.id] = 0;
      }
    }
    return removed;
  }
}

/// Exposed for the planner UI's step legend ordering.
int stepTypeIndex(String type) => planStepTypeIndex[type] ?? 2;
