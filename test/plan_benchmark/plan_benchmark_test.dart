// Plan benchmark (docs/training-plan-rethink.md, step 0): fixed athletes, a
// table per plan, and the benchmark targets of the review as asserts.
// Run it before and after a planner change to see what the change does:
//   flutter test test/plan_benchmark/plan_benchmark_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/race_goal_service.dart';
import 'package:fjelia_core/services/season/goal_set.dart';
import 'package:fjelia_core/services/session_stress.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia_core/services/workout_semantics.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

final clock = DateTime(2026, 11, 23, 9);

/// One week of history: (days before the week's end, sport, minutes, share of
/// the time in zones 4-5).
typedef HistoryDay = (int, String, int, double);

class Goal {
  const Goal(
    this.id,
    this.sport,
    this.km,
    this.date,
    this.priority, {
    this.elevationM,
  });
  final String id, sport, priority;
  final double km;
  final DateTime date;
  final double? elevationM;
}

/// The zone 5 an athlete's goals ask for: in how many ordinary weeks (a
/// range, not a quota to hit exactly) and how much in one week.
class Zone5 {
  const Zone5({
    required this.minShare,
    this.maxShare = 1.0,
    this.maxSessions = 1,
    this.maxMinutes = 30,
    this.open,
  });

  /// Share of ordinary weeks with a zone 5 session.
  final double minShare, maxShare;

  /// Per week: zone 5 sessions and minutes of zone 5 work in them.
  final int maxSessions, maxMinutes;

  /// Why the target is not met yet: printed with the warning.
  final String? open;
}

/// Long events raced to finish and beginners: about every other week, one
/// short dose. Shorter or performance goals: most weeks, up to two.
const finishZone5 = Zone5(minShare: 0.3, maxShare: 0.8);
const raceZone5 = Zone5(minShare: 0.4, maxSessions: 2, maxMinutes: 45);

class Athlete {
  const Athlete({
    required this.name,
    required this.goals,
    required this.week,
    required this.level,
    required this.hours,
    required this.days,
    required this.sports,
    required this.zone5,
    this.strengthDays = const [2],
    this.expectedLevel,
  });
  final String name, level;
  final List<Goal> goals;
  final List<HistoryDay> week;
  final double hours;
  final int days;
  final List<String> sports;
  final List<int> strengthDays;
  final Zone5 zone5;

  /// The level the plan must use; the self-reported one when null. None of
  /// these histories proves a year of training, so the data cannot raise it.
  final String? expectedLevel;
  String get planLevel => expectedLevel ?? level;
}

const _runner = <HistoryDay>[
  (6, 'running', 50, 0.0),
  (4, 'running', 55, 0.15),
  (2, 'running', 50, 0.0),
  (0, 'running', 110, 0.02),
];
const _ultra = <HistoryDay>[
  (6, 'running', 60, 0.0),
  (5, 'cycling_road', 75, 0.01),
  (4, 'running', 70, 0.0),
  (3, 'cycling_road', 60, 0.0),
  (1, 'running', 180, 0.01),
  (0, 'cycling_road', 240, 0.0),
];
const _rider = <HistoryDay>[
  (5, 'cycling_road', 60, 0.1),
  (3, 'cycling_road', 90, 0.0),
  (1, 'cycling_road', 75, 0.05),
  (0, 'cycling_road', 240, 0.0),
];

final athletes = [
  // The case from the review: an 88 km run, then a long event every one to
  // two months, road bike as the second sport, history almost all easy.
  Athlete(
    name: 'long-event series',
    zone5: finishZone5,
    level: 'advanced',
    hours: 10,
    days: 6,
    sports: const ['running', 'cycling_road'],
    goals: [
      Goal(
        'ultra88',
        'running',
        88,
        DateTime(2027, 1, 9),
        'a',
        elevationM: 1500,
      ),
      Goal(
        'trail60',
        'trail_running',
        60,
        DateTime(2027, 2, 27),
        'b',
        elevationM: 2000,
      ),
      Goal(
        'brevet300',
        'cycling_road',
        300,
        DateTime(2027, 4, 17),
        'b',
        elevationM: 2500,
      ),
      Goal(
        'ultra100',
        'running',
        100,
        DateTime(2027, 5, 29),
        'a',
        elevationM: 2000,
      ),
    ],
    week: _ultra,
  ),
  // Ultra trail, a hiking challenge and a brevet: the mix of the athlete
  // behind the review.
  Athlete(
    name: 'trail, hike challenge and brevet',
    zone5: finishZone5,
    level: 'advanced',
    hours: 10,
    days: 6,
    sports: const ['trail_running', 'hiking', 'cycling_road'],
    goals: [
      Goal(
        'megamarsch',
        'hiking',
        50,
        DateTime(2027, 3, 13),
        'b',
        elevationM: 600,
      ),
      Goal(
        'brevet200',
        'cycling_road',
        200,
        DateTime(2027, 4, 24),
        'c',
        elevationM: 1500,
      ),
      Goal(
        'trail100',
        'trail_running',
        100,
        DateTime(2027, 6, 19),
        'a',
        elevationM: 4500,
      ),
    ],
    week: _ultra,
  ),
  // An 18 h ultra trail and a brevet three weeks later: recovery decides.
  Athlete(
    name: '18 h ultra, brevet three weeks later',
    zone5: finishZone5,
    level: 'advanced',
    hours: 11,
    days: 6,
    sports: const ['trail_running', 'cycling_road'],
    goals: [
      Goal(
        'ultra18h',
        'trail_running',
        110,
        DateTime(2027, 4, 10),
        'a',
        elevationM: 6000,
      ),
      Goal(
        'brevet400',
        'cycling_road',
        400,
        DateTime(2027, 5, 1),
        'b',
        elevationM: 3500,
      ),
    ],
    week: _ultra,
  ),
  // A brevet series, BRM 200 to 600, the 600 the A goal.
  Athlete(
    name: 'brevet series 200-600',
    zone5: finishZone5,
    level: 'intermediate',
    hours: 9,
    days: 5,
    sports: const ['cycling_road'],
    goals: [
      Goal(
        'brm200',
        'cycling_road',
        200,
        DateTime(2027, 3, 20),
        'c',
        elevationM: 1500,
      ),
      Goal(
        'brm300',
        'cycling_road',
        300,
        DateTime(2027, 4, 10),
        'b',
        elevationM: 2500,
      ),
      Goal(
        'brm400',
        'cycling_road',
        400,
        DateTime(2027, 5, 1),
        'b',
        elevationM: 3500,
      ),
      Goal(
        'brm600',
        'cycling_road',
        600,
        DateTime(2027, 5, 29),
        'a',
        elevationM: 5500,
      ),
    ],
    week: _rider,
  ),
  // Marathon A with a half (B) and a 10 km (C) on the way.
  Athlete(
    name: 'marathon with half and 10 km',
    zone5: raceZone5,
    level: 'intermediate',
    hours: 7,
    days: 5,
    sports: const ['running'],
    goals: [
      Goal('10k', 'running', 10, DateTime(2027, 2, 14), 'c'),
      Goal('half', 'running', 21.1, DateTime(2027, 3, 14), 'b'),
      Goal('marathon', 'running', 42.195, DateTime(2027, 4, 18), 'a'),
    ],
    week: _runner,
  ),
  // Two A races five weeks apart in different sports.
  Athlete(
    name: 'marathon and 50 km trail, both A',
    zone5: raceZone5,
    level: 'intermediate',
    hours: 8,
    days: 5,
    sports: const ['running', 'trail_running'],
    goals: [
      Goal('marathon', 'running', 42.195, DateTime(2027, 4, 11), 'a'),
      Goal(
        'trail50',
        'trail_running',
        50,
        DateTime(2027, 5, 16),
        'a',
        elevationM: 2500,
      ),
    ],
    week: _runner,
  ),
  // A hiking challenge alone: hills, never zone 5.
  Athlete(
    name: 'hiking challenge only',
    zone5: const Zone5(minShare: 0, maxShare: 0, maxSessions: 0, maxMinutes: 0),
    level: 'intermediate',
    hours: 7,
    days: 5,
    sports: const ['hiking'],
    goals: [
      Goal(
        'megamarsch100',
        'hiking',
        100,
        DateTime(2027, 5, 8),
        'a',
        elevationM: 1200,
      ),
    ],
    week: const [
      (5, 'hiking', 60, 0.0),
      (3, 'hiking', 75, 0.05),
      (0, 'hiking', 240, 0.0),
    ],
  ),
  Athlete(
    name: 'beginner 10 km',
    // One quality session a week, threshold and zone 5 in turn.
    zone5: const Zone5(minShare: 0.4, maxShare: 0.5),
    level: 'beginner',
    hours: 4,
    days: 4,
    sports: const ['running'],
    goals: [Goal('10k', 'running', 10, DateTime(2027, 3, 14), 'a')],
    week: const [
      (5, 'running', 30, 0.0),
      (3, 'running', 35, 0.02),
      (0, 'running', 45, 0.0),
    ],
  ),
  Athlete(
    name: 'intermediate marathon',
    zone5: raceZone5,
    level: 'intermediate',
    hours: 7,
    days: 5,
    sports: const ['running'],
    goals: [Goal('marathon', 'running', 42.195, DateTime(2027, 4, 18), 'a')],
    week: const [
      (6, 'running', 45, 0.0),
      (4, 'running', 55, 0.25),
      (2, 'running', 50, 0.0),
      (0, 'running', 110, 0.02),
    ],
  ),
  Athlete(
    name: 'beginner long triathlon',
    zone5: finishZone5,
    level: 'beginner',
    hours: 10,
    days: 6,
    sports: const ['swimming', 'cycling_road', 'running'],
    goals: [Goal('ironman', 'triathlon', 226, DateTime(2027, 7, 4), 'a')],
    week: const [
      (6, 'swimming', 40, 0.0),
      (5, 'running', 45, 0.05),
      (4, 'cycling_road', 75, 0.05),
      (3, 'swimming', 40, 0.0),
      (1, 'running', 70, 0.0),
      (0, 'cycling_road', 150, 0.0),
    ],
  ),
  Athlete(
    name: 'brevet rider',
    zone5: finishZone5,
    level: 'intermediate',
    hours: 8,
    days: 5,
    sports: const ['cycling_road'],
    goals: [
      Goal(
        'brm300',
        'cycling_road',
        300,
        DateTime(2027, 5, 15),
        'a',
        elevationM: 3000,
      ),
    ],
    week: _rider,
  ),
];

/// What the benchmark reads from one plan week.
class WeekRow {
  WeekRow(this.start);
  final DateTime start;
  final minutes = <String, int>{};
  final sessions = <String, int>{};
  final longest = <String, int>{};
  final phases = <String>{};
  final keyZones = <int>[];
  var zone5Minutes = 0.0;
  var hardInRow = 0;
  var heavyPairs = 0;
  var event = false;

  int get total => minutes.values.fold(0, (a, b) => a + b);

  /// Quality sessions as the goals ask for them (key sessions other than
  /// strength): race intensity in zone 3 for a long event raced to finish,
  /// hills for a hike, threshold and zone 5 otherwise. A key session planned
  /// in zone 2 is easy work, whatever its name.
  int get quality => keyZones.where((z) => z >= 3).length;
  int get zone5 => keyZones.where((z) => z >= 5).length;
}

bool isHard(TrainingSession s) => s.sport != 'strength' && s.primaryZone >= 4;

/// A day long enough to count against the easy days after an event.
const veryLongMin = 150;

double stressOf(TrainingSession s) => sessionStress(
  sport: s.sport,
  minutes: s.plannedDurationMin,
  zone: s.primaryZone,
);

DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

class Plan {
  Plan(this.weeks, this.goals, this.sessions, this.ordinaryDayMin, this.level);

  /// The level the planner used (its log line).
  final String? level;
  final List<WeekRow> weeks;
  final GoalSet goals;
  final List<TrainingSession> sessions;

  /// An ordinary training day of the athlete's week, in minutes.
  final double ordinaryDayMin;
}

Future<Plan> plan(Athlete a) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await WorkoutTemplateLibrary(db).seedIfEmpty();
  var n = 0;
  // Daily strain (the TRIMP sum the app stores per day) feeds CTL and the
  // level from data: about 1.2 a minute easy, three times that in zones 4-5.
  final strain = <DateTime, double>{};
  for (var week = 12; week >= 1; week--) {
    for (final (offset, sport, minutes, hard) in a.week) {
      final zones = {
        'zone1': 0.2 * (1 - hard),
        'zone2': 0.7 * (1 - hard),
        'zone3': 0.1 * (1 - hard),
        'zone4': hard * 0.7,
        'zone5': hard * 0.3,
      };
      final when = clock.subtract(Duration(days: week * 7 - offset));
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'h${n++}',
              name: sport,
              type: sport,
              startDate: when,
              durationSeconds: minutes * 60,
              distanceMeters: Value(switch (sport) {
                'swimming' => minutes * 30.0,
                'running' || 'trail_running' => minutes * 170.0,
                'hiking' => minutes * 90.0,
                _ => minutes * 450.0,
              }),
              hrZonesJson: Value(
                jsonEncode({
                  for (final e in zones.entries)
                    e.key: (e.value * minutes * 60).round(),
                }),
              ),
              source: const Value('garmin'),
            ),
          );
      final d = day(when);
      strain[d] = (strain[d] ?? 0) + minutes * (1.2 + 2.4 * hard);
    }
  }
  for (final e in strain.entries) {
    await db
        .into(db.dayScoreRecords)
        .insert(
          DayScoreRecordsCompanion.insert(
            date: e.key,
            strainScore: Value(e.value),
          ),
        );
  }
  await db
      .into(db.athleteThresholds)
      .insert(
        AthleteThresholdsCompanion.insert(
          athleteId: 'self',
          lastUpdatedAt: Value(clock),
          ftpWatts: const Value(250),
          maxHrBpm: const Value(185),
          runHrZonesJson: const Value('[92,110,128,146,165]'),
          bikeHrZonesJson: const Value('[100,118,134,148,162]'),
        ),
        mode: InsertMode.insertOrReplace,
      );
  for (final g in a.goals) {
    await db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: g.id,
            athleteId: 'self',
            name: g.id,
            primarySport: g.sport,
            distanceM: g.km * 1000,
            raceDate: g.date,
            priority: g.priority,
            elevationM: Value(g.elevationM),
            participation: const Value('committed'),
            source: 'manual',
            createdAt: clock,
          ),
        );
  }
  final goals = await RaceGoalService(db).resolveGoalSet(today: clock);
  final shown = goals.display!;
  final service = TrainingPlanService(
    db,
    garminProviders(db, FakeWorkoutGarmin()),
    clock: () => clock,
  );
  // The planner logs the level it plans with; the benchmark reads it there.
  final logged = <String>[];
  final planId = await runZoned(
    () => service.generatePlan(
      athleteId: 'self',
      raceGoalId: shown.id,
      raceDate: shown.date,
      sport: shown.sport,
      raceDistanceM: shown.distanceM,
      daysPerWeek: a.days,
      restDays: const [1],
      strengthDays: a.strengthDays,
      hoursPerWeek: a.hours,
      maxSessionsPerDay: 2,
      gadSports: a.sports,
      athlete: PlanAthleteProfile(experienceLevel: a.level),
      goals: goals,
    ),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        logged.add(line);
        parent.print(zone, line);
      },
    ),
  );
  final level = logged
      .map((l) => RegExp(r'\[Plan\] athlete: level=(\w+)').firstMatch(l))
      .whereType<RegExpMatch>()
      .map((m) => m.group(1))
      .firstOrNull;
  final sessions =
      await (db.select(db.trainingSessions)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
          .get();
  final events = {for (final g in a.goals) day(g.date)};
  final rows = <DateTime, WeekRow>{};
  final hardDays = <DateTime>{};
  final stress = <DateTime, double>{
    for (final g in goals.relevant)
      day(g.date): sessionStress(
        sport: g.demand.sport,
        minutes: g.demand.planningMinutes.round(),
        zone: 3,
      ),
  };
  final keyDays = <DateTime>{};
  for (final s in sessions) {
    final d = day(s.sessionDate);
    final start = d.subtract(Duration(days: d.weekday - 1));
    final row = rows.putIfAbsent(start, () => WeekRow(start));
    row.minutes[s.sport] = (row.minutes[s.sport] ?? 0) + s.plannedDurationMin;
    row.sessions[s.sport] = (row.sessions[s.sport] ?? 0) + 1;
    row.longest[s.sport] = math.max(
      row.longest[s.sport] ?? 0,
      s.plannedDurationMin,
    );
    row.phases.add(s.phase);
    if (s.sessionType == 'key' && s.sport != 'strength') {
      row.keyZones.add(s.primaryZone);
    }
    final z5 = WorkoutSemantics.of(s.stepsJson, sport: s.sport).zoneSeconds;
    row.zone5Minutes += ((z5[5] ?? 0) + (z5[6] ?? 0)) / 60;
    if (isHard(s)) hardDays.add(d);
    if (s.sessionType == 'key' && s.sport != 'strength') keyDays.add(d);
    stress[d] = (stress[d] ?? 0) + stressOf(s);
  }
  for (final row in rows.values) {
    for (var i = 0; i < 7; i++) {
      final d = row.start.add(Duration(days: i));
      final next = d.add(const Duration(days: 1));
      if (events.contains(d)) row.event = true;
      if (hardDays.contains(d) && hardDays.contains(next)) row.hardInRow++;
      // A key session next to a heavy day, the two together too much.
      final a = stress[d] ?? 0, b = stress[next] ?? 0;
      if ((keyDays.contains(d) && heavyPair(a, b)) ||
          (keyDays.contains(next) && heavyPair(b, a))) {
        row.heavyPairs++;
      }
    }
  }
  return Plan(
    rows.values.toList()..sort((x, y) => x.start.compareTo(y.start)),
    goals,
    sessions,
    a.hours * 60 / a.days,
    level,
  );
}

/// A week the plan treats as normal training: no event in it or next to it,
/// no recovery or taper, past the cautious start.
List<WeekRow> ordinary(List<WeekRow> weeks) => [
  for (var i = 2; i < weeks.length; i++)
    if (!weeks[i].event &&
        !weeks[i - 1].event &&
        (i + 1 >= weeks.length || !weeks[i + 1].event) &&
        !weeks[i].phases.any(
          (p) => const {'recovery', 'taper', 'race'}.contains(p),
        ))
      weeks[i],
];

/// Days after an event whose planned minutes (strength aside) go over the
/// volume the recovery allows.
List<String> overRecoveryVolume(Plan p) {
  final minutes = <DateTime, int>{};
  for (final s in p.sessions) {
    if (s.sport == 'strength') continue;
    final d = day(s.sessionDate);
    minutes[d] = (minutes[d] ?? 0) + s.plannedDurationMin;
  }
  return [
    for (final e in minutes.entries)
      if (p.goals.volumeFactorOn(e.key) case final factor?)
        if (e.value > math.max(20, p.ordinaryDayMin * factor) + 5)
          '${e.key.toIso8601String().substring(0, 10)}: ${e.value} min '
              '(recovery allows ${(factor * 100).round()} % of a '
              '${p.ordinaryDayMin.round()} min day)',
  ];
}

/// Hard or very long sessions in the easy days after each event.
List<String> earlyHard(Plan p) => [
  for (final g in p.goals.all)
    for (final s in p.sessions)
      if (isHard(s) || s.plannedDurationMin >= veryLongMin)
        if (day(s.sessionDate).difference(day(g.date)).inDays case final after
            when after > 0 && after <= g.demand.easyDaysAfter)
          '${g.id}: ${s.title} $after days after '
              '(easy for ${g.demand.easyDaysAfter})',
];

String table(Athlete a, List<WeekRow> weeks) {
  final sports = {for (final w in weeks) ...w.minutes.keys}.toList()..sort();
  final out = StringBuffer('\n${a.name}\n')
    ..writeln(
      'week        phase           hours  qual  z5 z5min inRow    heavy keyZ   '
      '${sports.map((s) => s.padRight(14)).join()}',
    );
  for (final w in weeks) {
    final perSport = sports
        .map((s) => '${w.sessions[s] ?? 0}×/${w.longest[s] ?? 0}m'.padRight(14))
        .join();
    out.writeln(
      '${w.start.toIso8601String().substring(0, 10)}  '
      '${(w.phases.where((p) => p != 'strength').join('/')).padRight(15)} '
      '${(w.total / 60).toStringAsFixed(1).padLeft(5)}  '
      '${'${w.quality}'.padLeft(4)} ${'${w.zone5}'.padLeft(3)} '
      '${w.zone5Minutes.round().toString().padLeft(5)} '
      '${'${w.hardInRow}'.padLeft(5)} ${'${w.heavyPairs}'.padLeft(8)} '
      '${w.keyZones.join(',').padRight(6)} $perSport${w.event ? ' EVENT' : ''}',
    );
  }
  final normal = ordinary(weeks);
  out.writeln(
    'ordinary weeks ${normal.length}, without a quality session '
    '${normal.where((w) => w.quality == 0).length}, with zone 5 '
    '${normal.where((w) => w.zone5 > 0).length}, hard days in a row '
    '${weeks.fold(0, (s, w) => s + w.hardInRow)}, heavy pairs '
    '${weeks.fold(0, (s, w) => s + w.heavyPairs)}',
  );
  return out.toString();
}

/// Hiking: zone 4 at most, and mostly zone 1-2 (at least 80 % of the
/// hiking time), counted from the workout steps.
List<String> hikingIntensity(Plan p) {
  final out = <String>[];
  var easy = 0.0, all = 0.0;
  for (final s in p.sessions.where((s) => s.sport == 'hiking')) {
    final zones = WorkoutSemantics.of(s.stepsJson, sport: s.sport).zoneSeconds;
    final top = zones.entries.where((e) => e.value > 0).map((e) => e.key);
    if (top.any((z) => z > 4)) {
      out.add(
        '${day(s.sessionDate).toIso8601String().substring(0, 10)}: '
        '${s.title} goes above zone 4',
      );
    }
    // Zone 3-4 comes from climbing: only in uphill (hills) sessions.
    if (s.subType != 'hills' &&
        zones.entries.any((e) => e.key >= 3 && e.value >= 60)) {
      out.add(
        '${day(s.sessionDate).toIso8601String().substring(0, 10)}: '
        '${s.title} has zone 3-4 without climbing',
      );
    }
    for (final e in zones.entries) {
      all += e.value;
      if (e.key <= 2) easy += e.value;
    }
  }
  if (all > 0 && easy / all < 0.8) {
    out.add(
      'hiking ${(easy / all * 100).round()} % in zone 1-2 (at least 80 %)',
    );
  }
  return out;
}

/// Every benchmark target the athlete misses.
List<String> misses(Athlete a, Plan p) {
  final weeks = p.weeks;
  final normal = ordinary(weeks);
  final out = <String>[];
  final noQuality = normal.where((w) => w.quality == 0).length;
  if (noQuality > 0) out.add('$noQuality ordinary weeks without quality');
  final inRow = weeks.fold(0, (s, w) => s + w.hardInRow);
  if (inRow > 0) out.add('$inRow hard days in a row');
  final heavy = weeks.fold(0, (s, w) => s + w.heavyPairs);
  if (heavy > 0) out.add('$heavy hard days in a too heavy pair of days');
  out.addAll(earlyHard(p));
  out.addAll(overRecoveryVolume(p));
  out.addAll(hikingIntensity(p));
  // Step 3: the level the plan uses is the athlete's, unless proven
  // otherwise, and a beginner has at most one quality session a week.
  if (p.level != a.planLevel) {
    out.add('planned as ${p.level}, the athlete is ${a.planLevel}');
  }
  if (a.planLevel == 'beginner') {
    for (final w in weeks.where((w) => w.quality > 1)) {
      out.add(
        '${w.start.toIso8601String().substring(0, 10)}: ${w.quality} quality '
        'sessions for a beginner (at most 1)',
      );
    }
  }
  // The zone 5 range is a benchmark corridor, not physiology: a warning.
  final z = a.zone5;
  final share = normal.isEmpty
      ? 0.0
      : normal.where((w) => w.zone5 > 0).length / normal.length;
  if (share < z.minShare || share > z.maxShare) {
    // ignore: avoid_print
    print(
      'WARN ${a.name}: zone 5 in ${(share * 100).round()} % of ordinary '
      'weeks, corridor ${(z.minShare * 100).round()}-'
      '${(z.maxShare * 100).round()} %${z.open == null ? '' : ' (${z.open})'}',
    );
  }
  for (final w in weeks) {
    final when = w.start.toIso8601String().substring(0, 10);
    if (w.zone5 > z.maxSessions) {
      out.add('$when: ${w.zone5} zone 5 sessions (at most ${z.maxSessions})');
    }
    if (w.zone5Minutes > z.maxMinutes) {
      out.add(
        '$when: ${w.zone5Minutes.round()} min in zone 5 '
        '(at most ${z.maxMinutes})',
      );
    }
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final a in athletes) {
    test('benchmark: ${a.name}', () async {
      final p = await plan(a);
      // ignore: avoid_print
      print(table(a, p.weeks));
      expect(ordinary(p.weeks), isNotEmpty);
      expect(misses(a, p), isEmpty, reason: a.name);
    });
  }
}
