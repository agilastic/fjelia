import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'package:fjelia_core/services/hr_zone_model.dart';
import 'package:fjelia_core/services/plan_rules.dart';
import 'package:fjelia_core/services/plan_workout_builder.dart';
import 'package:fjelia_core/models/prepared_workout.dart';
import '../models/strength_workout.dart';
import 'package:fjelia_core/services/strength/garmin_strength.dart';
import 'package:fjelia_core/services/strength/strength_templates.dart';
import 'workout_template_library.dart';
import 'strength/strength_plan_edits.dart';
import 'strength/strength_repository.dart';
import 'package:fjelia_core/models/race_profile.dart';
import 'package:fjelia_core/services/session_stress.dart';
import 'package:fjelia_core/services/workout_semantics.dart';
import '../providers/training_load_provider.dart';
import 'package:fjelia_core/utils/log.dart';
import 'package:fjelia_core/utils/week.dart';
import 'dfa_alpha1_service.dart';
import 'race_goal_service.dart';
import 'package:fjelia_core/services/ramp_test.dart';
import 'package:fjelia_core/services/season/goal_set.dart';
import 'package:fjelia_core/services/season/season_goal.dart';
import 'package:fjelia_core/services/season/season_report.dart';
import 'package:fjelia_core/services/season/season_timeline.dart';
import 'package:fjelia_core/services/season/week_allocator.dart';
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
       _build = PlanWorkoutBuilder(usesPower: usesPower),
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
    final rotation = planGadSportRotation(gadSports.isEmpty ? [sport] : gadSports);
    final mainSport = planSupportedSports.contains(sport) ? sport : rotation.first;
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
    final baseSlots = planWeekTemplates[mainSport] ?? planWeekTemplates['running']!;
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

    // The season: which goal asks what of each week, what the weeks hold and
    // where the days are taken by an event.
    final timeline = SeasonTimeline(
      goals: goalSet,
      anchorWeek: anchorWeek,
      mondayFirst: weekStartsOnMonday,
      cycle: athlete.recoveryCycle,
    );
    final capacities = PlanWorkoutBuilder.capacitiesOf(history);
    final goalSports = {
      for (final g in goalSet.active) ...SeasonTimeline.sportsOf(g).keys,
    };
    // Sports of the same family as a goal sport are not variety: a gravel
    // ride is the road goal's own sport. Variety needs the sport's own
    // history, so a sport the athlete never does is never scheduled.
    String family(String s) => s.startsWith('cycl')
        ? 'cycling'
        : s == 'running' || s == 'trail_running'
        ? 'running'
        : s;
    final goalFamilies = {for (final s in goalSports) family(s)};
    final varietySports = [
      for (final s in planGadSportRotation(gadSports))
        if (!goalFamilies.contains(family(s)) && history.sports[s] != null) s,
    ];
    final allocations = <WeekAllocation>[];
    final weekReports = <WeekReport>[];
    // Days that carried a long session or an event, with its minutes: the day
    // next to one is no place for a second hard day.
    final longDates = <DateTime, int>{
      for (final g in goalSet.relevant)
        if (g.demand.planningMinutes >= 150)
          g.date: g.demand.planningMinutes.round(),
    };
    // Days that already hold a quality (key, not strength) session.
    final keyDates = <DateTime>{};
    // The load of each day (session_stress.dart), events included: a key
    // session does not go next to a day that, with it, is too much.
    final dayStress = <DateTime, double>{
      for (final g in goalSet.relevant)
        localDay(g.date): sessionStress(
          sport: g.demand.sport,
          minutes: g.demand.planningMinutes.round(),
          zone: 3,
        ),
    };
    // The load a slot will have before its workout exists: a key session
    // at zone 4 or more, since its template may reach zone 4 (a steady slot
    // can get a tempo workout), and at least 50 min.
    double plannedStress(PlanSessionSlot s) {
      final key = s.sessionType == 'key' && s.sport != 'strength';
      return sessionStress(
        sport: s.sport,
        minutes: key ? math.max(50, s.targetMin ?? 60) : s.targetMin ?? 60,
        zone: key ? math.max(4, s.zone) : s.zone,
      );
    }

    bool heavyNextTo(DateTime day, double stress) => [-1, 1].any(
      (n) => heavyPair(stress, dayStress[_addDays(day, n)] ?? 0, margin: 0.9),
    );
    // A long event raced to finish (6 h on foot, 4 h otherwise, without the
    // ambition "performance") needs a short dose of zone 5, not a big one.
    bool longFinish(String? goalId) {
      final g =
          goalSet.all
              .where((g) => g.id == (goalId ?? raceGoalId))
              .firstOrNull ??
          goalSet.display;
      if (g == null || g.ambition == Ambition.performance) return false;
      return g.demand.planningMinutes >= (g.demand.isFoot ? 360 : 240);
    }

    final sportFitness = <String, PlanAthleteFitnessSnapshot>{mainSport: fitness};
    Future<PlanAthleteFitnessSnapshot> fitnessFor(String sport) async {
      if (!multi) return fitness;
      final key = sport.contains('cycl')
          ? 'cycling'
          : sport.contains('swim')
          ? 'swimming'
          : 'running';
      final cached = sportFitness[key];
      if (cached != null) return cached;
      var read = await _readFitnessSnapshot(athleteId, sport);
      // No measured zones for this sport either: the age estimate stands in.
      if (read.hrZones.length < 4 && athlete.estimatedHrZones.isNotEmpty) {
        read = read.withHrZones(athlete.estimatedHrZones);
      }
      return sportFitness[key] = read;
    }

    for (var g = firstIndex; g < weeks; g++) {
      // g counts from the season anchor, w from this plan run.
      final w = g - firstIndex;
      final weekStart = _addDays(anchorWeek, g * 7);
      final weekIntents = multi
          ? timeline.intentsFor(weekStart)
          : const <GoalWeek>[];
      var needs = SeasonTimeline.needsOf(weekIntents);
      if (multi && prependRecovery && w == 0) {
        needs = [
          for (final n in needs)
            SportNeed(
              sport: n.sport,
              weight: n.weight,
              intent: GoalIntent.unload,
              goal: n.goal,
              weeksToEvent: n.weeksToEvent,
              progress: n.progress,
            ),
        ];
      }
      var phase = (prependRecovery && w == 0)
          ? 'recovery'
          : casual
          // No race: base training, with the usual recovery weeks.
          ? (g % athlete.recoveryCycle == athlete.recoveryCycle - 1
                ? 'recovery'
                : 'base')
          : multi
          ? (needs.isEmpty ? 'base' : needs.first.intent.phase)
          : planPhase(g, weeks, cycle: athlete.recoveryCycle);
      final weeksIntoBlock = g % athlete.recoveryCycle;
      final progression = phase == 'taper' || phase == 'recovery'
          ? 1.0
          : 1.0 + athlete.progressionPerWeek * weeksIntoBlock;
      // Volume ramps from what the athlete currently does to the target.
      var weeklyBudgetMin = rampedWeeklyMinutes(
        targetMin: targetWeeklyMin,
        recentMin: history.weeklyMinutes,
        week: w,
        rate: volumeRampRate(
          targetMin: targetWeeklyMin,
          peakMin: history.peakWeeklyMinutes,
          athlete: athlete,
        ),
      );
      if (!multi && (phase == 'recovery' || phase == 'taper')) {
        weeklyBudgetMin *= 0.7;
      }
      final weekTss =
          (baseWeeklyTss *
                  planWeeklyTssFactor(phase, fitness.tier) *
                  progression *
                  (w == 0 ? readiness : 1.0))
              .round();
      final weekTssCap = (weekTss * 1.1).round();

      // Choose slots for the week.
      var slots = phase == 'recovery'
          ? _build.recoveryWeekSlots(mainSport)
          : List<PlanSessionSlot>.of(baseSlots);
      slots = planRestrictSlotsToSports(
        slots,
        allowed: allowedSports,
        mainSport: mainSport,
        strength: strengthDays.isNotEmpty,
      );
      if (phase == 'taper') {
        slots = slots
            .where((s) => s.sessionType != 'long' || s.weekday == 6)
            .toList();
      }
      // A beginner gets one long session a week: the second long slot of the
      // template becomes an easy run.
      if (athlete.isBeginner) {
        var longs = 0;
        for (var i = 0; i < slots.length; i++) {
          if (slots[i].sessionType == 'long' && ++longs > 1) {
            slots[i] = slots[i].copyWith(
              sessionType: 'recovery',
              clearSubType: true,
              zone: 2,
            );
          }
        }
      }
      // Rotate the general-development sport into easy slots.
      if (rotation.length > 1) {
        slots = slots.map((s) {
          if (s.sessionType != 'recovery' || s.sport == 'yoga') return s;
          final alt = rotation[gadIndex++ % rotation.length];
          return s.copyWith(sport: alt);
        }).toList();
      }
      // Hard sessions: capped by experience; athletes who rarely train hard
      // get one moderate (tempo) key session in the first two weeks of the
      // season. Counted from the season, not from this plan run: a replan
      // would otherwise start over, and the easy weeks it plans keep the
      // history easy for the next one.
      final easyStart = history.mostlyEasy && g < 2;
      final easingIn = List.generate(
        7,
        (i) => _addDays(_addDays(anchorWeek, g * 7), i),
      ).any(easeInDays.contains);
      final maxKeys = easingIn
          ? 0
          // For the fun of it: every session easy. To get fitter: one hard
          // session a week, two for an advanced athlete.
          : casualGoal == 'fun' && casual
          ? 0
          : casual
          ? (athlete.isAdvanced ? 2 : 1)
          : easyStart
          ? 1
          : athlete.maxKeySessions;
      // Fewer hard sessions allowed than the week has: they take turns by
      // week, so a beginner's one session is threshold one week and zone 5
      // the next, not the template's first one every week.
      final keySlots = [
        for (var i = 0; i < slots.length; i++)
          if (slots[i].sessionType == 'key' && slots[i].sport != 'strength') i,
      ];
      final keep = maxKeys == null || maxKeys >= keySlots.length
          ? keySlots.toSet()
          : {
              for (var k = 0; k < maxKeys; k++)
                keySlots[(g + k) % keySlots.length],
            };
      for (var i = 0; i < slots.length; i++) {
        final s = slots[i];
        if (s.sessionType != 'key' || s.sport == 'strength') continue;
        if (!keep.contains(i)) {
          slots[i] = s.copyWith(
            sessionType: 'recovery',
            clearSubType: true,
            zone: 2,
          );
        } else {
          if (easyStart) {
            // A hike keeps its hills: its effort comes from climbing.
            slots[i] = s.copyWith(
              subType: s.sport == 'hiking' ? 'hills' : 'tempo',
              zone: math.min(s.zone, 3),
            );
          }
        }
      }
      // A hilly race gets hill work in the build and peak: one tempo session
      // becomes a hill session, every other week on rolling to hilly courses
      // and every week on mountainous ones.
      if ((phase == 'build' || phase == 'peak') &&
          planFootSports.contains(mainSport) &&
          (terrain == Terrain.mountainous ||
              (terrain == Terrain.hilly && g.isEven))) {
        final i = slots.indexWhere(
          (s) =>
              s.sessionType == 'key' &&
              s.subType == 'tempo' &&
              planFootSports.contains(s.sport),
        );
        if (i >= 0) slots[i] = slots[i].copyWith(subType: 'hills', zone: 4);
      }
      // A triathlon keeps the top end too: the bike key session is zone 5
      // intervals every other week, tempo in between. One discipline is
      // enough; swim and run stay at threshold (finding 10 of the review).
      if (mainSport == 'triathlon' &&
          const {'base', 'build', 'peak'}.contains(phase) &&
          g.isOdd) {
        final i = slots.indexWhere(
          (s) => s.sessionType == 'key' && s.sport == 'cycling_road',
        );
        if (i >= 0) {
          slots[i] = slots[i].copyWith(subType: 'intervals', zone: 5);
        }
      }
      // Strength goes on every strength day the athlete chose, aimed at the
      // race: base and build use each day, peak at most two, taper one
      // short session, race weeks none, recovery weeks core and stability.
      // Sessions A and B alternate from day to day and week to week.
      final strengthWeek =
          strengthDays.isNotEmpty &&
          (phase == 'recovery' || slots.any((s) => s.sport == 'strength'));
      slots.removeWhere((s) => s.sport == 'strength');
      if (strengthWeek) {
        final count = switch (phase) {
          'base' || 'build' => math.min(strengthDays.length, 3),
          'peak' => math.min(strengthDays.length, 2),
          'taper' || 'recovery' => 1,
          _ => 0,
        };
        final focus = strengthFocusFor(
          mainSport,
          hilly: terrain == Terrain.hilly || terrain == Terrain.mountainous,
        );
        for (var i = 0; i < count; i++) {
          slots.add(
            planStrengthFull.copyWith(
              subType: phase == 'recovery'
                  ? 'strengthCore'
                  : strengthProgrammeId(focus, phase, g + i),
              weekday: strengthDays[i],
            ),
          );
        }
      }
      // Few hours a week (under three): no more sessions than the week's
      // minutes hold at half an hour each. One hour a week is two sessions
      // of 30 minutes or one of an hour, not five short ones that add up to
      // well over the hour.
      final smallWeek = targetWeeklyMin < 180;
      final maxSessions = math.max(
        1,
        math.min(
          daysPerWeek * maxSessionsPerDay,
          smallWeek ? weeklyBudgetMin ~/ 30 : 1 << 30,
        ),
      );
      // Keep long and key sessions first when trimming.
      int rank(PlanSessionSlot s) => switch (s.sessionType) {
        'long' => 0,
        'key' => s.sport == 'strength' ? 2 : 1,
        _ => 3,
      };
      slots.sort((a, b) => rank(a).compareTo(rank(b)));
      if (slots.length > maxSessions) slots = slots.sublist(0, maxSessions);

      final weekNotes = <String>[];
      var weekBudget = 0.0;
      // What the week really holds, to set against what was allocated: the
      // report describes the sessions that are stored, not the intention.
      WeekAllocation? weekAllocation;
      Map<String, dynamic>? reportAllocation;
      var weekPartial = false;
      final actualRows =
          <({String sport, String type, String? sub, int minutes})>[];
      void dropped(PlanSessionSlot slot, String why) {
        final allocation = weekAllocation;
        if (allocation == null) return;
        final what = (slot.objective ?? '${slot.sport} session').toLowerCase();
        final protectedSession = (slot.rank ?? 9) <= 1;
        final message = '$what was dropped: $why.';
        // A part week cannot fail a long session it never had the days for.
        if (protectedSession && !weekPartial) {
          allocation.unmet.add(message);
        } else if ((slot.rank ?? 9) <= 3) {
          allocation.tradeoffs.add(message);
        }
      }

      if (multi) {
        // The season allocator shares the week between the goals' sports
        // before any day is chosen; the weekly template is not used.
        final events = [
          for (final gw in weekIntents)
            if (gw.intent == GoalIntent.event)
              (
                name: gw.goal.name,
                minutes: gw.goal.demand.planningMinutes.round(),
              ),
        ];
        final eventMinutes = events.fold<int>(0, (a, e) => a + e.minutes);
        // Read from every goal's intent, so a goal that shares its sport with
        // a later one is still recovered from.
        var budget =
            weeklyBudgetMin *
            (prependRecovery && w == 0
                ? 0.7
                : WeekAllocator.budgetFactor(weekIntents));
        budget = math.max(budget * 0.3, budget - eventMinutes);
        // A week already begun, or ending at the last event, has fewer days
        // to train in: its time and its sessions shrink with them.
        var daysLeft = 0;
        for (var off = 0; off < 7; off++) {
          final date = _addDays(weekStart, off);
          if (date.isBefore(today) || date.isAfter(end)) continue;
          if (restDays.contains(date.weekday)) continue;
          if (healthDays.contains(date)) continue;
          if (goalSet.loadOn(date) == DayLoad.blocked) continue;
          daysLeft++;
        }
        final trainingDays = math.max(
          1,
          math.min(daysPerWeek, 7 - restDays.length),
        );
        if (daysLeft < trainingDays) {
          budget *= math.max(1, daysLeft) / trainingDays;
        }
        final sessionCap = math.max(
          1,
          math.min(maxSessions, daysLeft * maxSessionsPerDay),
        );
        final allocation = const WeekAllocator().allocate(
          AllocationInput(
            needs: needs,
            budgetMin: budget,
            sessionCap: sessionCap,
            strengthDays: strengthDays,
            recoveringFromEvent: WeekAllocator.isRecoveringFromLongEvent(
              weekIntents,
            ),
            partialWeek: daysLeft < trainingDays,
            capacities: capacities,
            weekInRun: w,
            weekIndex: g,
            maxKeySessions: easingIn
                ? 0
                : easyStart
                ? 1
                : athlete.maxKeySessions,
            easyStart: easyStart,
            varietySports: varietySports,
            footLongCap: (goal) => maxLongRunMinutes(
              planDistanceCategory(goal.distanceM),
              targetMin: goal.targetSeconds == null
                  ? null
                  : (goal.targetSeconds! / 60).round(),
            ),
            allowedSports: allowedSports,
            events: events,
            goalWeeks: weekIntents,
            cycle: athlete.recoveryCycle,
          ),
        );
        allocations.add(allocation);
        weekAllocation = allocation;
        weekPartial = daysLeft < trainingDays;
        weekBudget = budget;
        slots = [for (final a in allocation.slots) PlanWorkoutBuilder.slotOf(a)]
          ..sort((a, b) => (a.rank ?? 9).compareTo(b.rank ?? 9));
        reportAllocation = allocation.toJson();
        weekReports.add(
          WeekReport(
            weekStart: weekStart,
            phase: phase,
            intents: {for (final gw in weekIntents) gw.goal.id: gw.intent.name},
            allocation: reportAllocation,
            notes: weekNotes,
          ),
        );
      }

      // Assign each slot to a day offset in the week.
      final used = <int, int>{};
      final dayMinutes = <int, int>{};
      final usedSports = <int, Set<String>>{};
      bool isPreRaceRest(DateTime d) => d == _addDays(raceDay, -1);

      int? bestOffset(PlanSessionSlot s) {
        final candidates = <int>[];
        for (var off = 0; off < 7; off++) {
          final date = _addDays(weekStart, off);
          // An event day belongs to the event, not to an ordinary session.
          if (multi) {
            if (date.isAfter(end)) continue;
            final load = goalSet.loadOn(date);
            if (load == DayLoad.blocked) continue;
            if (load == DayLoad.easyOnly && !PlanWorkoutBuilder.easyEnough(s)) continue;
          } else if (!date.isBefore(raceDay)) {
            continue;
          }
          // Days already gone cannot take a session.
          if (date.isBefore(today)) continue;
          // After an event a day holds only what its recovery allows: no
          // second session on a day that has less than 20 min of it left.
          if (s.sport != 'strength' &&
              goalSet.volumeFactorOn(date) != null &&
              (capOn(date) ?? 999) - (dayMinutes[off] ?? 0) < 20) {
            continue;
          }
          if (restDays.contains(date.weekday)) continue;
          if (healthDays.contains(date)) continue;
          if (!multi && isPreRaceRest(date)) continue;
          final count = used[off] ?? 0;
          if (count >= maxSessionsPerDay) continue;
          if (count > 0 && (usedSports[off]?.contains(s.sport) ?? false)) {
            continue;
          }
          candidates.add(off);
        }
        // The first week back from an illness or injury has no hard or
        // long session.
        if (s.sessionType == 'key' || s.sessionType == 'long') {
          candidates.removeWhere(
            (off) => easeInDays.contains(_addDays(weekStart, off)),
          );
        }
        if (candidates.isEmpty) return null;
        // A day whose training window is too short for the session is used
        // only when no day has room for it.
        final wanted = s.sport == 'strength'
            ? null
            : s.targetMin ?? (s.sessionType == 'long' ? 90 : null);
        if (wanted != null) {
          final fits = [
            for (final off in candidates)
              if ((capOn(_addDays(weekStart, off)) ?? wanted) >= wanted) off,
          ];
          if (fits.isNotEmpty) {
            candidates
              ..clear()
              ..addAll(fits);
          }
        }
        // Strength days are the athlete's own choice in the settings: a
        // strength session takes its day whenever that day is open at all.
        if (s.sport == 'strength' && s.weekday != 0) {
          for (final off in candidates) {
            if (_addDays(weekStart, off).weekday == s.weekday) return off;
          }
        }
        if (s.weekday == 0) {
          // The quietest day: fewest sessions, then fewest minutes.
          candidates.sort((a, b) {
            final byCount = (used[a] ?? 0).compareTo(used[b] ?? 0);
            return byCount != 0
                ? byCount
                : (dayMinutes[a] ?? 0).compareTo(dayMinutes[b] ?? 0);
          });
          return candidates.first;
        }
        int dist(int off) {
          final wd = _addDays(weekStart, off).weekday;
          final d = (wd - s.weekday).abs();
          var cost = math.min(d, 7 - d) * 10 + (used[off] ?? 0);
          // A hard or long day next to a long one, or on top of one, is the
          // last choice: the legs and the week are not asked twice.
          final minutes = s.targetMin;
          if (multi && minutes != null) {
            final demanding = s.sessionType == 'key' || minutes >= 90;
            if (demanding) {
              final day = _addDays(weekStart, off);
              for (final next in [-1, 1]) {
                final neighbour = longDates[_addDays(day, next)] ?? 0;
                if (neighbour >= 150 || (minutes >= 150 && neighbour >= 100)) {
                  cost += 50;
                }
              }
            }
            if ((dayMinutes[off] ?? 0) >= 90 && (demanding || minutes >= 60)) {
              cost += 80;
            }
          }
          // Never a hard session the day before or after another one, in
          // either path (≥ 48 h between them, §3 #5 of the plan review),
          // unless no other day is open. A very long day counts as hard
          // too: hours in zone 2 tire as much as intervals.
          final day = _addDays(weekStart, off);
          bool nextTo(bool Function(DateTime) hard) =>
              hard(_addDays(day, -1)) || hard(_addDays(day, 1));
          final key = s.sessionType == 'key' && s.sport != 'strength';
          // No key session the day before or after another (§3 #5): a
          // zone 3 slot can still get a template with zone 5 in it.
          if (key && nextTo(keyDates.contains)) cost += 100;
          // One quality session a day: a tempo run and trail intervals are
          // two sports but one pair of legs.
          if (key && keyDates.contains(day)) cost += 200;
          // Nor next to a heavy day that, together with it, is too much:
          // minutes × intensity × the sport's impact, so 3 h on a trail
          // weighs and 150 min of easy riding does not (§3 #5).
          final stress = plannedStress(s);
          if (key && heavyNextTo(day, stress)) cost += 100;
          // Nor on a day that is heavy already (the long run's day).
          if (key && (dayStress[day] ?? 0) >= heavyDayStress * 0.9) {
            cost += 100;
          }
          // A heavy session does not go next to a key day the same way.
          if (!key &&
              [-1, 1].any(
                (n) =>
                    keyDates.contains(_addDays(day, n)) &&
                    heavyPair(
                      dayStress[_addDays(day, n)] ?? 0,
                      stress,
                      margin: 0.9,
                    ),
              )) {
            cost += 100;
          }
          return cost;
        }

        candidates.sort((a, b) => dist(a).compareTo(dist(b)));
        return candidates.first;
      }

      var weekPlannedTrimp = 0;
      var weekPlannedMin = 0;
      var weekSessions = 0;

      // What stays of the old plan takes its place: the day is used, the
      // time counts, and the slot it stands for is not planned a second time.
      // A skipped session takes nothing and is not made up for.
      final weekEndExclusive = _addDays(weekStart, 7);
      bool inWeek(DateTime d) =>
          !d.isBefore(weekStart) && d.isBefore(weekEndExclusive);
      // A session the athlete moved to another week still stands for its
      // slot here, in the week it was planned for: that week does not plan
      // it a second time on its old day.
      for (final p in kept) {
        final original = DateTime.tryParse(p.sessionDateOriginal ?? '');
        if (original == null ||
            !inWeek(_day(original)) ||
            inWeek(p.sessionDate)) {
          continue;
        }
        final i = slots.indexWhere(
          (s) => s.sport == p.sport && s.sessionType == p.sessionType,
        );
        if (i >= 0) slots.removeAt(i);
      }
      var unmatchedMin = 0;
      for (final p in kept.where(
        (p) =>
            !p.sessionDate.isBefore(weekStart) &&
            p.sessionDate.isBefore(weekEndExclusive),
      )) {
        final i = slots.indexWhere(
          (s) => s.sport == p.sport && s.sessionType == p.sessionType,
        );
        if (i >= 0) {
          slots.removeAt(i);
        } else if (p.status != 'skipped') {
          unmatchedMin += p.actualDurationMin ?? p.plannedDurationMin;
        }
        if (p.status == 'skipped') continue;
        final off = daysBetween(weekStart, p.sessionDate);
        final minutes = p.actualDurationMin ?? p.plannedDurationMin;
        used[off] = (used[off] ?? 0) + 1;
        usedSports.putIfAbsent(off, () => <String>{}).add(p.sport);
        weekPlannedTrimp += p.plannedTrimp;
        weekPlannedMin += minutes;
        weekSessions++;
        sessionNumber++;
        dayMinutes[off] = (dayMinutes[off] ?? 0) + minutes;
        if (minutes >= 100) longDates[_day(p.sessionDate)] = minutes;
        if (p.sessionType == 'key' && p.sport != 'strength') {
          keyDates.add(_day(p.sessionDate));
        }
        dayStress.update(
          _day(p.sessionDate),
          (v) =>
              v +
              sessionStress(
                sport: p.sport,
                minutes: minutes,
                zone: p.primaryZone,
              ),
          ifAbsent: () => sessionStress(
            sport: p.sport,
            minutes: minutes,
            zone: p.primaryZone,
          ),
        );
        // A moved session that sits on an event, or hard next to one, stays
        // where the athlete put it, and the report says so.
        if (multi && (p.status == 'planned' || p.status == 'adapted')) {
          final load = goalSet.loadOn(p.sessionDate);
          final easy =
              p.sessionType == 'recovery' ||
              (p.plannedDurationMin <= 60 && p.primaryZone <= 2);
          if (load == DayLoad.blocked) {
            weekNotes.add('movedOntoEvent');
          } else if (load == DayLoad.easyOnly && !easy) {
            weekNotes.add('movedHardNearEvent');
          }
        }
      }
      for (final d in doneToday) {
        final off = daysBetween(weekStart, d.day);
        if (off < 0 || off > 6) continue;
        used[off] = (used[off] ?? 0) + 1;
        dayMinutes[off] = (dayMinutes[off] ?? 0) + d.minutes;
        weekPlannedMin += d.minutes;
        unmatchedMin += d.minutes;
      }
      // Time already spent that no slot stands for comes out of what is
      // planned: the least important sessions give way.
      if (multi && unmatchedMin > 0) {
        final room = PlanWorkoutBuilder.makeRoom(slots, weekBudget - unmatchedMin);
        slots = room.kept;
        for (final d in room.removed) {
          dropped(d, 'time was already spent that week');
        }
      }

      // The ramp test takes the week's first hard session in its sport, or in
      // a recovery week an easy one late in the week: at the end of a
      // recovery week or the start of a block, rested. Never in a taper, a
      // race week or a first week back from illness or injury.
      PlanSessionSlot? rampSlot, rampOriginal;
      final due = nextRamp;
      if (due != null &&
          !_addDays(weekStart, 6).isBefore(due) &&
          !easingIn &&
          (phase == 'recovery' || weeksIntoBlock == 0) &&
          phase != 'taper' &&
          List.generate(7, (i) => _addDays(weekStart, i)).every(
            (d) => multi
                ? goalSet.loadOn(d) == DayLoad.free
                : d.isBefore(_addDays(raceDay, -6)),
          )) {
        // The sport tested longest ago first.
        final families = lastRamp.keys.toList()
          ..sort((a, b) {
            final x = lastRamp[a], y = lastRamp[b];
            if (x == null) return y == null ? 0 : -1;
            return y == null ? 1 : x.compareTo(y);
          });
        var i = -1;
        for (final family in families) {
          i = slots.indexWhere(
            (s) => s.sessionType == 'key' && rampFamilyOf(s.sport) == family,
          );
          if (i >= 0) break;
          for (var j = 0; j < slots.length; j++) {
            final s = slots[j];
            if (s.sessionType == 'recovery' &&
                rampFamilyOf(s.sport) == family &&
                (i < 0 || s.weekday > slots[i].weekday)) {
              i = j;
            }
          }
          if (i >= 0) break;
        }
        if (i >= 0) {
          final old = slots[i];
          rampOriginal = old;
          rampSlot = PlanSessionSlot(
            old.sport == 'trail_running' ? 'running' : old.sport,
            'key',
            rampTestSubType,
            4,
            old.sessionType == 'key' ? old.weekday : 5,
            goalId: old.goalId,
            goalRole: old.goalRole,
            objective: 'Ramp test',
            targetMin: 50,
            rank: old.rank,
            phase: old.phase,
          );
          slots[i] = rampSlot;
          // The test is the week's hard session: the others are easy, so
          // it is run rested and not next to another hard day.
          for (var j = 0; j < slots.length; j++) {
            final s = slots[j];
            if (j != i && s.sessionType == 'key' && s.sport != 'strength') {
              slots[j] = s.copyWith(
                sessionType: 'recovery',
                clearSubType: true,
                zone: 2,
              );
            }
          }
        }
      }

      // A long event raced to finish needs one short zone 5 dose a week, not
      // two: a second zone 5 slot for such a goal becomes threshold work.
      var topSlots = 0;
      for (var i = 0; i < slots.length; i++) {
        final s = slots[i];
        if (s.sessionType != 'key' || s.sport == 'strength' || s.zone < 5) {
          continue;
        }
        if (longFinish(s.goalId) && ++topSlots > 1) {
          slots[i] = s.copyWith(
            subType: s.sport == 'cycling_road' ? 'threshold' : 'tempo',
            zone: 4,
          );
        }
      }
      // Strength first: its days are fixed by the athlete, the rest of the
      // week arranges itself around them. Then the long sessions, so a key
      // session knows which days are heavy and keeps away from them.
      slots = [
        ...slots.where((s) => s.sport == 'strength'),
        ...slots.where((s) => s.sport != 'strength' && s.sessionType == 'long'),
        // Key sessions the hardest first (in a crowded week zone 5 is the
        // rarer one), then by their preferred day, so the second takes a day
        // two apart (Tuesday and Thursday).
        ...slots
            .where((s) => s.sport != 'strength' && s.sessionType == 'key')
            .toList()
          ..sort((a, b) {
            final byZone = b.zone.compareTo(a.zone);
            return byZone != 0 ? byZone : a.weekday.compareTo(b.weekday);
          }),
        ...slots.where(
          (s) =>
              s.sport != 'strength' &&
              s.sessionType != 'long' &&
              s.sessionType != 'key',
        ),
      ];
      for (var slot in slots) {
        final off = bestOffset(slot);
        // A key session that only fits next to a hard or very long day (a
        // race week, or the easy days after an event, leave few open days)
        // is run easy instead (§3 #5).
        if (off != null &&
            slot.sessionType == 'key' &&
            slot.sport != 'strength' &&
            slot.zone >= 3) {
          final day = _addDays(weekStart, off);
          final stress = plannedStress(slot);
          if (keyDates.contains(_addDays(day, -1)) ||
              keyDates.contains(_addDays(day, 1)) ||
              heavyNextTo(day, stress)) {
            slot = slot.copyWith(
              sessionType: 'recovery',
              clearSubType: true,
              zone: 2,
            );
          }
        }
        if (off == null) {
          log(
            '[Plan] w$w ${slot.sport}/${slot.sessionType}'
            '(p$phase,z${slot.zone}) → SKIP rest=$restDays used=$used',
          );
          continue;
        }
        final date = _addDays(weekStart, off);
        if (date.isBefore(today)) continue;
        // The ramp test needs its whole length, known thresholds and its
        // due date; otherwise the session it replaced is planned after all.
        final sportFit = await fitnessFor(slot.sport);
        final rampLt2 =
            sportFit.lt2Bpm ??
            sportFit.hrRangeForZone(5).low ??
            sportFit.hrRangeForZone(4).high;
        // A few days early is fine; a week early is not.
        if (identical(slot, rampSlot) &&
            (rampLt2 == null ||
                (capOn(date) ?? 999) < 50 ||
                date.isBefore(_addDays(due!, -3)))) {
          slot = rampOriginal!;
        }
        final ramp = identical(slot, rampSlot);
        // A long session that could not take its usual day is said, not
        // hidden: the athlete's rest days and the other sessions decided it.
        if (multi &&
            slot.sessionType == 'long' &&
            (slot.targetMin ?? 0) >= 150 &&
            slot.weekday != 0) {
          final apart = (date.weekday - slot.weekday).abs();
          if (math.min(apart, 7 - apart) >= 2) {
            weekNotes.add('longAwayFromUsualDay');
          }
        }

        // A slot from the season allocator already has the length its goal
        // and the athlete's history support; the rules below size the slots
        // of a weekly template.
        var duration =
            slot.targetMin ??
            _build.ctlScaledDuration(
              PlanWorkoutBuilder.baseDuration(slot.sessionType),
              slot.sessionType,
              fitness.tier,
              fitness.ctl,
            );
        // The longest long session the athlete's history supports, if any.
        int? historyLongCap;
        if (slot.targetMin == null) {
          if (phase == 'taper') duration = (duration * 0.7).round();
          if (phase == 'recovery') duration = (duration * 0.7).round();
          if (slot.sessionType == 'long' && planFootSports.contains(slot.sport)) {
            duration = math.min(duration, longRunCap);
          }
          if (slot.sessionType == 'long' && phase == 'peak') {
            duration = (duration * 1.4).round();
            if (planFootSports.contains(slot.sport)) {
              duration = math.min(duration, longRunCap);
            }
          }
          final sportHistory = history.forSport(slot.sport);
          if (sportHistory != null && sportHistory.longestMin >= 20) {
            if (slot.sessionType == 'long') {
              // At most ~12% above the longest recent session, growing 5% per
              // week (8% back towards last year's longest).
              final growth = sportHistory.hasYearCapacity ? 0.08 : 0.05;
              var cap = sportHistory.longestMin * (1.12 + growth * w);
              if (sportHistory.hasYearCapacity) {
                cap = math.min(
                  cap,
                  math.max(
                    sportHistory.yearLongestMin,
                    sportHistory.longestMin * 1.12,
                  ),
                );
              }
              historyLongCap = cap.round();
              duration = math.min(duration, historyLongCap);
            } else if (slot.sessionType == 'recovery') {
              // Easy sessions sized like the athlete's usual sessions.
              duration = duration
                  .clamp(
                    (sportHistory.medianMin * 0.6).round(),
                    math.max(20, sportHistory.medianMin.round()),
                  )
                  .toInt();
            }
          }
          if (weekPlannedMin + duration > weeklyBudgetMin &&
              slot.sessionType != 'long') {
            duration = math.max(20, (weeklyBudgetMin - weekPlannedMin).round());
          }
        }
        duration = duration.clamp(slot.minMin ?? 20, slot.maxMin ?? 240);
        // A small week: every session, the long one too, gets its share of
        // the week's minutes and at least half an hour.
        final smallWeekShare = smallWeek
            ? math.max(30, weeklyBudgetMin / slots.length).round()
            : null;
        if (smallWeekShare != null) {
          duration = math.min(duration, smallWeekShare);
        }
        // No longer than the day's training window or a first week back,
        // and after an event no more than its recovery allows that day, all
        // sessions of the day together.
        var dayCap = capOn(date);
        if (dayCap != null && goalSet.volumeFactorOn(date) != null) {
          dayCap -= dayMinutes[off] ?? 0;
        }
        if (dayCap != null && duration > dayCap) {
          duration = math.max(20, dayCap);
        }

        // The workout is chosen first and its steps decide the duration, so
        // what the app shows, what the load estimate counts and what the watch
        // executes are the same. A steady session is fitted to the wanted
        // length; a structured one is chosen close to it and left whole.
        final slotPhase = slot.phase ?? phase;
        // Zones and thresholds are the sport's own, not the main sport's.
        final fit = await fitnessFor(slot.sport);
        var template = _build.pickTemplateFromCache(
          templates,
          slot.sport,
          slot.sessionType,
          slot.subType,
          slotPhase,
          duration,
          w + sessionNumber,
          // Endurance quality only: a strength session keeps its programme.
          minZone:
              slot.sessionType == 'key' &&
                  slot.sport != 'strength' &&
                  slot.zone >= 3
              ? math.min(slot.zone, slot.maxZone ?? 5)
              : null,
          maxZone5Min:
              slot.sessionType == 'key' &&
                  slot.sport != 'strength' &&
                  slot.zone >= 5
              ? (longFinish(slot.goalId) ? 25 : 40)
              : null,
          // The triathlon's bike alternates threshold and zone 5 also in base.
          baseIntervals: mainSport == 'triathlon',
        );
        String? stepsJson;
        var scaled = false;
        var semantics = const WorkoutSemantics();
        void compileSteps(String raw, int wantedMin) {
          final resolved = _build.resolveStepsJson(
            raw,
            ftp,
            fit,
            power: _usesPower(slot.sport, false),
          );
          final fitted = fitSteadyWorkout(resolved, wantedMin * 60.0);
          stepsJson = fitted.stepsJson;
          scaled = fitted.scaled;
          semantics = WorkoutSemantics.of(stepsJson, sport: slot.sport);
        }

        void compile(WorkoutTemplate t, int wantedMin) =>
            compileSteps(t.stepsJson, wantedMin);

        if (template != null) compile(template, duration);
        if (ramp) {
          final lt2 = rampLt2!;
          final lt1 = fit.lt1Bpm ?? fit.hrRangeForZone(2).high ?? (lt2 - 30);
          int zoneOf(int hr) {
            for (var z = 5; z >= 1; z--) {
              final low = fit.hrRangeForZone(z).low;
              if (low != null && hr >= low) return z;
            }
            return hr >= lt2 ? 5 : (hr >= lt1 ? 3 : 2);
          }

          final usesPower = _usesPower(slot.sport, false) && ftp != null;
          template = null;
          stepsJson = _build.resolveStepsJson(
            jsonEncode(
              rampTestSteps(
                lt1: lt1,
                lt2: lt2,
                zoneOf: zoneOf,
                power: usesPower,
              ),
            ),
            ftp,
            fit,
            power: usesPower,
          );
          scaled = false;
          semantics = WorkoutSemantics.of(stepsJson, sport: slot.sport);
          nextRamp = _addDays(date, rampTestEvery.inDays);
          lastRamp[rampFamilyOf(slot.sport)!] = date;
        }
        // No template is as long as a long session the allocator asked for:
        // a steady one is built, so the plan never shows a length the steps
        // do not run.
        var synthetic = false;
        var steadyLead = 'Long endurance';
        final steady =
            slot.sessionType == 'recovery' ||
            (slot.sessionType == 'long' && slot.subType == 'endurance');
        // An easy session is asked for in its zone; a recovery template is
        // zone 1, so an easy endurance session gets a steady workout instead.
        final wrongZone =
            slot.sessionType == 'recovery' &&
            semantics.dominantZone != null &&
            semantics.dominantZone != slot.zone;
        if (slot.targetMin != null &&
            steady &&
            (template == null ||
                wrongZone ||
                (template.estimatedDurationMin - duration).abs() >
                    duration * (slot.sessionType == 'long' ? 0.3 : 0.25))) {
          compileSteps(PlanWorkoutBuilder.steadySteps(duration, slot.zone), duration);
          template = null;
          synthetic = true;
        }
        // A hard session that would take the week over its load cap is
        // replaced by a lighter one of the same kind, not clipped on paper.
        if (template != null &&
            slot.sessionType == 'key' &&
            slotPhase != 'peak' &&
            weekPlannedTrimp + semantics.legacyLoad > weekTssCap) {
          final lighter = _build.pickTemplateFromCache(
            templates,
            slot.sport,
            slot.sessionType,
            slot.subType,
            slotPhase,
            (duration * 0.75).round(),
            w + sessionNumber,
          );
          if (lighter != null && lighter.id != template.id) {
            final before = semantics.legacyLoad;
            final previous = (template, stepsJson, scaled, semantics);
            compile(lighter, (duration * 0.75).round());
            if (semantics.legacyLoad < before) {
              template = lighter;
            } else {
              template = previous.$1;
              stepsJson = previous.$2;
              scaled = previous.$3;
              semantics = previous.$4;
            }
          }
        }
        // An athlete who rarely trains hard gets steady work, not intervals:
        // the finished steps are held to the zone limit, whatever the
        // template asked for.
        final limit = slot.maxZone;
        if (limit != null &&
            template != null &&
            semantics.mainZoneSeconds.entries.any(
              (e) => e.key > limit && e.value > 0,
            )) {
          compileSteps(PlanWorkoutBuilder.steadySteps(duration, limit), duration);
          template = null;
          synthetic = true;
          steadyLead = 'Steady';
        }
        // Nor longer than an event's recovery allows that day: then a steady
        // session of the allowed length.
        if (dayCap != null &&
            goalSet.volumeFactorOn(date) != null &&
            semantics.totalMinutes > math.max(20, dayCap)) {
          compileSteps(
            PlanWorkoutBuilder.steadySteps(math.max(20, dayCap), math.min(slot.zone, 2)),
            math.max(20, dayCap),
          );
          template = null;
          synthetic = true;
        }
        // A structured long session is left whole, but never longer than the
        // athlete's history allows: then a steady one of the allowed length.
        if (historyLongCap != null &&
            template != null &&
            semantics.totalMinutes > historyLongCap) {
          compileSteps(PlanWorkoutBuilder.steadySteps(duration, slot.zone), duration);
          template = null;
          synthetic = true;
        }
        // The hours the athlete gave are a limit, not a hope: a workout whose
        // steps run longer than the week has left is made shorter, or left
        // out, and the report says which.
        if (multi && !ramp && slot.targetMin != null && weekBudget > 0) {
          final actual = semantics.isEmpty
              ? duration
              : semantics.totalMinutes.clamp(
                  1,
                  WeekAllocator.longestSessionMin,
                );
          final room = (weekBudget - weekPlannedMin).floor();
          if (actual > room) {
            final minimum = slot.minMin ?? 20;
            if (slot.sport != 'strength' && room >= minimum) {
              final zone = math.min(slot.zone, slot.maxZone ?? 4);
              compileSteps(PlanWorkoutBuilder.steadySteps(room, zone), room);
              template = null;
              synthetic = true;
              steadyLead = slot.sessionType == 'key'
                  ? (zone >= 4 ? 'Tempo' : 'Steady')
                  : 'Long endurance';
              duration = room;
            } else if (slot.sport == 'strength' && room >= minimum) {
              // A shorter strength workout, or none.
              final shorter = _build.pickTemplateFromCache(
                templates,
                slot.sport,
                slot.sessionType,
                slot.subType,
                slotPhase,
                room,
                w + sessionNumber,
              );
              if (shorter != null) compile(shorter, room);
              final after = semantics.isEmpty
                  ? room
                  : semantics.totalMinutes.clamp(
                      1,
                      WeekAllocator.longestSessionMin,
                    );
              if (shorter == null || after > room) {
                weekNotes.add('noRoom');
                dropped(slot, 'its workout ran longer than the time left');
                continue;
              }
              template = shorter;
            } else {
              weekNotes.add('noRoom');
              dropped(slot, 'its workout ran longer than the time left');
              continue;
            }
          }
        }
        // The share of a small week holds also when the chosen workout's
        // steps run longer: then a steady session of that length.
        if (smallWeekShare != null &&
            !ramp &&
            slot.sport != 'strength' &&
            semantics.totalMinutes > smallWeekShare) {
          compileSteps(PlanWorkoutBuilder.steadySteps(smallWeekShare, slot.zone), smallWeekShare);
          template = null;
          synthetic = true;
          duration = smallWeekShare;
        }
        var title =
            template?.name ??
            '${slot.sessionType[0].toUpperCase()}${slot.sessionType.substring(1)} '
                '${slot.sport.replaceAll('_', ' ')}';
        var trimp = 0.0;
        if (semantics.isEmpty) {
          trimp = duration * planZoneWeights[(slot.zone - 1).clamp(0, 4)];
        } else {
          duration = semantics.totalMinutes.clamp(
            1,
            WeekAllocator.longestSessionMin,
          );
          trimp = semantics.legacyLoad;
          if (scaled) title = retimeTitle(title, duration);
        }
        if (ramp) title = rampTestTitle;
        if (synthetic) {
          title = PlanWorkoutBuilder.steadyTitle(
            slot.sport,
            duration,
            lead: slot.sessionType == 'recovery' ? 'Easy' : steadyLead,
          );
        }

        // A quality session is stored with the zone it works at; an easy one
        // with the zone it mostly is.
        var zone =
            (slot.sessionType == 'key' && slot.sport != 'strength'
                ? semantics.topZone
                : semantics.dominantZone) ??
            slot.zone;
        // An easy run is run in the lower half of zone 2, not in zone 1.
        final easyRun = fit.easyRunZ2 && zone == 1;
        if (easyRun) zone = 2;
        final hr = easyRun ? fit.easyRunRange() : fit.hrRangeForZone(zone);
        final hrJson = jsonEncode({
          'low': hr.low,
          'high': hr.high,
          'zone': zone,
          'lt2': fit.lt2Bpm,
          'lt1': fit.lt1Bpm,
        });

        String? paceJson;
        // Measured threshold pace first; without one, the goal pace gives an
        // estimate (and says so).
        final measuredPace = thresholds?.thresholdPaceMps;
        final paceProfile = PlanWorkoutBuilder.paceProfile(goalSet, slot, raceProfile, multi);
        final pace = measuredPace ?? paceProfile?.estimatedThresholdSpeedMps;
        if ((slot.sport == 'running' || slot.sport == 'trail_running') &&
            pace != null &&
            pace > 0) {
          final z = planPaceZones[zone.clamp(1, 5)]!;
          paceJson = jsonEncode({
            'low_sec_per_km': (1000 / (pace * z.hi)).round(),
            'high_sec_per_km': (1000 / (pace * z.lo)).round(),
            'zone': zone,
            'basis': measuredPace != null ? 'threshold' : 'goal',
            if (paceProfile?.flatEquivalentPaceSecPerKm != null)
              'goal_sec_per_km': paceProfile!.flatEquivalentPaceSecPerKm!
                  .round(),
          });
        }
        String? powerJson;
        if (slot.sport.contains('cycl') && ftp != null) {
          final z = planPowerZones[zone.clamp(1, 5)]!;
          powerJson = jsonEncode({
            'low_watts': (ftp * z.lo).round(),
            'high_watts': (ftp * z.hi).round(),
            'zone': zone,
            'ftp': ftp,
          });
        }

        final warm = stepsJson == null
            ? (text: null, minutes: null)
            : _build.extractWarmUpDescription(stepsJson!);

        sessionNumber++;
        weekSessions++;
        weekPlannedTrimp += trimp.round();
        weekPlannedMin += duration;
        actualRows.add((
          sport: slot.sport,
          type: slot.sessionType,
          sub: slot.subType,
          minutes: duration,
        ));
        used[off] = (used[off] ?? 0) + 1;
        usedSports.putIfAbsent(off, () => <String>{}).add(slot.sport);
        dayMinutes[off] = (dayMinutes[off] ?? 0) + duration;
        if (duration >= 100) longDates[date] = duration;
        final stress = sessionStress(
          sport: slot.sport,
          minutes: duration,
          zone: zone,
        );
        dayStress.update(date, (v) => v + stress, ifAbsent: () => stress);
        if (slot.sessionType == 'key' && slot.sport != 'strength') {
          keyDates.add(date);
        }

        await _db
            .into(_db.trainingSessions)
            .insert(
              TrainingSessionsCompanion.insert(
                id: const Uuid().v4(),
                planId: planId,
                athleteId: athleteId,
                coachId: Value(coachId),
                sessionDate: date,
                sessionNumber: sessionNumber,
                weekNumber: g + 1,
                sport: slot.sport,
                sessionType: slot.sessionType,
                // A strength session names the template it was made from, so
                // its type, title and exercises always agree.
                subType: Value(
                  slot.sport == 'strength'
                      ? template?.subType ?? slot.subType
                      : slot.subType,
                ),
                phase: slotPhase,
                primaryZone: zone,
                title: title,
                sessionNotes: Value(
                  ramp ? rampTestDescription : template?.description,
                ),
                mainSet: Value(ramp ? rampTestCues : template?.coachingCues),
                warmUp: Value(warm.text),
                warmUpDurationMin: Value(warm.minutes),
                stepsJson: Value(stepsJson),
                hrRangesJson: Value(hrJson),
                paceRangesJson: Value(paceJson),
                powerRangesJson: Value(powerJson),
                plannedDurationMin: duration,
                plannedTrimp: trimp.round(),
                sessionLevel: PlanWorkoutBuilder.sessionLevel(slot.sessionType, zone, slotPhase),
                goalId: Value(
                  slot.goalId ?? (slot.sport == 'strength' ? null : raceGoalId),
                ),
                goalRole: Value(
                  slot.goalRole ??
                      (slot.sport == 'strength' ? 'support' : 'primary'),
                ),
                goalObjective: Value(slot.objective),
                status: const Value('planned'),
              ),
            );
      }

      if (multi && weekAllocation != null && reportAllocation != null) {
        reportAllocation
          ..clear()
          ..addAll(weekAllocation.toJsonActual(actualRows));
      }

      final weekStartMonday = weekStart.subtract(
        Duration(days: weekStart.weekday - 1),
      );
      await _db
          .into(_db.weekSummaries)
          .insert(
            WeekSummariesCompanion.insert(
              athleteId: athleteId,
              weekStart: weekStartMonday,
              weekNumber: g + 1,
              phase: phase,
              isRecoveryWeek: Value(phase == 'recovery'),
              plannedTrimp: Value(weekPlannedTrimp),
              sessionsPlanned: Value(weekSessions),
              ctl: Value(fitness.ctl),
              tsb: Value(fitness.tsb),
            ),
            onConflict: DoUpdate(
              (old) => WeekSummariesCompanion(
                weekNumber: Value(w + 1),
                phase: Value(phase),
                isRecoveryWeek: Value(phase == 'recovery'),
                plannedTrimp: Value(weekPlannedTrimp),
                sessionsPlanned: Value(weekSessions),
              ),
            ),
          );
    }

    // What the season decided, kept with the plan so the screens and the
    // coach can say why it looks as it does.
    final report = SeasonReport.build(
      goals: goalSet,
      weeks: weekReports,
      allocations: allocations,
      capacities: capacities,
      weeksPrepared: allocations.length,
    );
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
            title: PlanWorkoutBuilder.steadyTitle(sport, firstCasualMinutes, lead: 'Easy'),
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
            sessionLevel: PlanWorkoutBuilder.sessionLevel('recovery', 2, 'base'),
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
        final adopted = await provider.adoptExisting(open);
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
          .map(
            (e) => {...e.value, 'stepOrder': e.key + 1}..remove('fixedTarget'),
          )
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
