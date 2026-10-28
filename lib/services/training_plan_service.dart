import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'hr_zone_model.dart';
import '../models/workout_profile.dart' show formatBlockDuration;
import '../models/prepared_workout.dart';
import '../models/strength_workout.dart';
import 'strength/garmin_strength.dart';
import 'strength/strength_templates.dart';
import 'workout_template_library.dart';
import 'strength/strength_plan_edits.dart';
import 'strength/strength_repository.dart';
import '../models/race_profile.dart';
import '../utils/target_time.dart';
import 'workout_semantics.dart';
import '../providers/training_load_provider.dart';
import '../utils/log.dart';
import '../utils/week.dart';
import 'race_goal_service.dart';
import 'season/goal_set.dart';
import 'season/season_goal.dart';
import 'season/season_report.dart';
import 'season/season_timeline.dart';
import 'season/week_allocator.dart';
import 'workout_providers/workout_providers.dart';

/// Every sport the planner can schedule.
const _supportedSports = {
  'running',
  'trail_running',
  'cycling_road',
  'cycling_gravel',
  'cycling_mtb',
  'swimming',
  'triathlon',
  'indoor_rowing',
  'hiking',
  'inline_skating',
  'nordic_skiing',
  'skate_skiing',
};

/// Sports whose fitness is judged by running-style HR/pace metrics.
const _footSports = {
  'running',
  'trail_running',
  'hiking',
  'inline_skating',
  'nordic_skiing',
  'skate_skiing',
};

const _phaseOrder = ['base', 'build', 'peak', 'taper', 'race', 'recovery'];

/// Garmin step type → index used for ordering / zone defaults.
const _stepTypeIndex = {
  'warmup': 0,
  'rest': 1,
  'interval': 2,
  'active': 2,
  'recovery': 3,
  'cooldown': 4,
};

/// Power zones as a fraction of FTP.
const _powerZones = <int, ({double lo, double hi})>{
  1: (lo: 0.45, hi: 0.55),
  2: (lo: 0.56, hi: 0.75),
  3: (lo: 0.76, hi: 0.9),
  4: (lo: 0.91, hi: 1.05),
  5: (lo: 1.06, hi: 1.2),
};

/// Run pace zones as a fraction of threshold speed.
const _paceZones = <int, ({double lo, double hi})>{
  1: (lo: 0.6, hi: 0.75),
  2: (lo: 0.76, hi: 0.82),
  3: (lo: 0.83, hi: 0.88),
  4: (lo: 0.89, hi: 0.94),
  5: (lo: 0.95, hi: 1.05),
};

const _zoneWeights = [1.0, 1.1, 1.2, 3.1, 8.0];

class _SessionSlot {
  const _SessionSlot(
    this.sport,
    this.sessionType,
    this.subType,
    this.zone,
    this.weekday, {
    this.goalId,
    this.goalRole,
    this.objective,
    this.targetMin,
    this.minMin,
    this.maxMin,
    this.rank,
    this.phase,
    this.maxZone,
  });

  /// Set when the season allocator made the slot: the goal it prepares for,
  /// how, why, how long, and the phase its workout is chosen for. Slots of the
  /// weekly templates carry none of it.
  final String? goalId, goalRole, objective, phase;
  final int? targetMin, minMin, maxMin, rank;

  /// The highest zone the finished workout may reach; null for no limit.
  final int? maxZone;

  final String sport;
  final String sessionType;
  final String? subType;
  final int zone;

  /// Preferred ISO weekday (1 = Monday); 0 means any day.
  final int weekday;

  _SessionSlot copyWith({
    String? sport,
    int? weekday,
    String? sessionType,
    String? subType,
    bool clearSubType = false,
    int? zone,
  }) => _SessionSlot(
    sport ?? this.sport,
    sessionType ?? this.sessionType,
    clearSubType ? null : subType ?? this.subType,
    zone ?? this.zone,
    weekday ?? this.weekday,
    goalId: goalId,
    goalRole: goalRole,
    objective: objective,
    targetMin: targetMin,
    minMin: minMin,
    maxMin: maxMin,
    rank: rank,
    phase: phase,
    maxZone: maxZone,
  );
}

const _strengthFull = _SessionSlot('strength', 'key', 'strengthFull', 3, 0);
const _strengthLower = _SessionSlot('strength', 'key', 'strengthLower', 3, 0);
const _strengthCore = _SessionSlot('strength', 'key', 'strengthCore', 3, 0);
const _yoga = _SessionSlot('yoga', 'recovery', null, 1, 5);

/// Default week per sport: (sport, type, subType, zone, weekday).
const _weekTemplates = <String, List<_SessionSlot>>{
  'running': [
    _SessionSlot('running', 'long', 'endurance', 2, 6),
    _SessionSlot('running', 'key', 'intervals', 5, 4),
    _SessionSlot('running', 'key', 'tempo', 4, 3),
    _strengthFull,
    _SessionSlot('running', 'recovery', null, 1, 2),
    _yoga,
    _SessionSlot('running', 'long', 'endurance', 2, 7),
  ],
  'trail_running': [
    _SessionSlot('trail_running', 'long', 'endurance', 2, 6),
    _SessionSlot('trail_running', 'key', 'hills', 4, 3),
    _SessionSlot('running', 'key', 'tempo', 3, 4),
    _strengthLower,
    _SessionSlot('trail_running', 'recovery', null, 1, 2),
    _SessionSlot('trail_running', 'key', 'intervals', 5, 1),
    _yoga,
  ],
  'cycling_road': [
    _SessionSlot('cycling_road', 'long', 'endurance', 2, 6),
    _SessionSlot('cycling_road', 'key', 'intervals', 5, 4),
    _SessionSlot('cycling_road', 'key', 'tempo', 4, 3),
    _strengthFull,
    _SessionSlot('cycling_road', 'recovery', null, 1, 2),
    _yoga,
    _SessionSlot('cycling_road', 'long', 'endurance', 2, 7),
  ],
  'cycling_gravel': [
    _SessionSlot('cycling_gravel', 'long', 'endurance', 2, 6),
    _SessionSlot('cycling_road', 'key', 'intervals', 5, 4),
    _SessionSlot('cycling_road', 'key', 'tempo', 4, 3),
    _strengthFull,
    _SessionSlot('cycling_gravel', 'recovery', null, 1, 2),
    _yoga,
    _SessionSlot('cycling_gravel', 'long', 'endurance', 2, 7),
  ],
  'cycling_mtb': [
    _SessionSlot('cycling_mtb', 'long', 'endurance', 2, 6),
    _SessionSlot('cycling_mtb', 'key', 'intervals', 5, 3),
    _SessionSlot('cycling_road', 'key', 'tempo', 4, 4),
    _strengthLower,
    _SessionSlot('cycling_mtb', 'recovery', null, 1, 2),
    _yoga,
    _SessionSlot('cycling_mtb', 'long', 'endurance', 2, 7),
  ],
  'swimming': [
    _SessionSlot('swimming', 'long', 'poolSwim', 2, 6),
    _SessionSlot('swimming', 'key', 'poolSwim', 4, 4),
    _SessionSlot('swimming', 'key', 'poolSwim', 4, 3),
    _strengthFull,
    _SessionSlot('swimming', 'recovery', null, 1, 2),
    _yoga,
    _SessionSlot('swimming', 'long', 'poolSwim', 2, 7),
  ],
  'triathlon': [
    _SessionSlot('running', 'long', 'endurance', 2, 6),
    _SessionSlot('cycling_road', 'long', 'endurance', 2, 7),
    _SessionSlot('swimming', 'key', 'poolSwim', 4, 2),
    _SessionSlot('running', 'key', 'tempo', 4, 3),
    _SessionSlot('cycling_road', 'key', 'tempo', 4, 4),
    _strengthCore,
  ],
  'indoor_rowing': [
    _SessionSlot('indoor_rowing', 'long', 'endurance', 2, 6),
    _SessionSlot('indoor_rowing', 'key', 'intervals', 5, 4),
    _SessionSlot('indoor_rowing', 'key', 'intervals', 4, 3),
    _strengthFull,
    _SessionSlot('indoor_rowing', 'recovery', null, 1, 2),
    _yoga,
    _SessionSlot('indoor_rowing', 'long', 'endurance', 2, 7),
  ],
  'hiking': [
    _SessionSlot('hiking', 'long', 'endurance', 2, 6),
    _SessionSlot('hiking', 'key', 'hills', 4, 3),
    _SessionSlot('hiking', 'recovery', null, 1, 2),
    _strengthLower,
    _yoga,
    _SessionSlot('hiking', 'long', 'endurance', 2, 7),
  ],
  'inline_skating': [
    _SessionSlot('inline_skating', 'long', 'endurance', 2, 6),
    _SessionSlot('inline_skating', 'key', 'intervals', 5, 4),
    _SessionSlot('inline_skating', 'key', 'tempo', 3, 3),
    _strengthFull,
    _SessionSlot('inline_skating', 'recovery', null, 1, 2),
    _yoga,
    _SessionSlot('inline_skating', 'long', 'endurance', 2, 7),
  ],
  'nordic_skiing': [
    _SessionSlot('nordic_skiing', 'long', 'endurance', 2, 6),
    _SessionSlot('nordic_skiing', 'key', 'intervals', 5, 4),
    _SessionSlot('nordic_skiing', 'key', 'tempo', 3, 3),
    _strengthFull,
    _SessionSlot('nordic_skiing', 'recovery', null, 1, 2),
    _yoga,
    _SessionSlot('nordic_skiing', 'long', 'endurance', 2, 7),
  ],
  'skate_skiing': [
    _SessionSlot('skate_skiing', 'long', 'endurance', 2, 6),
    _SessionSlot('skate_skiing', 'key', 'intervals', 5, 4),
    _SessionSlot('skate_skiing', 'key', 'tempo', 3, 3),
    _strengthFull,
    _SessionSlot('skate_skiing', 'recovery', null, 1, 2),
    _yoga,
    _SessionSlot('skate_skiing', 'long', 'endurance', 2, 7),
  ],
};

/// Sports that may appear in a plan: the ones the athlete chose plus the race
/// sport. A triathlon brings running, cycling and swimming with it.
Set<String> allowedPlanSports({
  required String mainSport,
  required List<String> chosen,
}) {
  final allowed = {mainSport, ...chosen};
  if (allowed.contains('triathlon')) {
    allowed.addAll(const ['running', 'cycling_road', 'swimming']);
  }
  return allowed;
}

/// Keeps a week's slots to the sports the athlete asked for. A slot of another
/// endurance sport (a road ride in a gravel week) becomes [mainSport]; yoga,
/// pilates and stretching are dropped unless chosen. Strength is planned only
/// with strength days, which are the athlete's own setting for it.
List<_SessionSlot> _restrictSlotsToSports(
  List<_SessionSlot> slots, {
  required Set<String> allowed,
  required String mainSport,
  required bool strength,
}) {
  const optional = {'yoga', 'pilates', 'stretching'};
  final out = <_SessionSlot>[];
  for (final s in slots) {
    if (s.sport == 'strength') {
      if (strength || allowed.contains('strength')) out.add(s);
    } else if (allowed.contains(s.sport)) {
      out.add(s);
    } else if (optional.contains(s.sport)) {
      continue;
    } else {
      out.add(s.copyWith(sport: mainSport));
    }
  }
  return out;
}

/// Sports used for general athletic development; running-type sports first.
List<String> _gadSportRotation(List<String> sports) {
  final valid = sports.where(_supportedSports.contains).toList();
  if (valid.isEmpty) return ['running'];
  final foot = valid.where(_footSports.contains).toList();
  final other = valid.where((s) => !_footSports.contains(s)).toList();
  return [...foot, ...other];
}

double _weeklyTssFactor(String phase, String tier) {
  final phaseF = switch (phase) {
    'base' => 0.9,
    'build' => 1.1,
    'peak' => 1.15,
    'taper' => 0.6,
    'recovery' => 0.5,
    'race' => 0.4,
    _ => 0.9,
  };
  final easy = phase == 'taper' || phase == 'recovery' || phase == 'race';
  final tierF = easy
      ? 1.0
      : switch (tier) {
          'beginner' => 0.85,
          'advanced' => 1.05,
          _ => 1.0,
        };
  return (phaseF * tierF).clamp(0.5, 1.25);
}

/// Periodisation, see [seasonPhase].
String _phase(int week, int totalWeeks, {int cycle = 4}) =>
    seasonPhase(week, totalWeeks, cycle: cycle);

String _tierFor(double ctl) => ctl < 35
    ? 'beginner'
    : ctl >= 50
    ? 'advanced'
    : 'intermediate';

String _distanceCategory(double? meters) {
  if (meters == null || meters <= 0) return 'general';
  if (meters < 5000) return 'sprint';
  if (meters < 8000) return '5k';
  if (meters < 16000) return '10k';
  if (meters < 30000) return 'half';
  if (meters < 55000) return 'marathon';
  return 'ultra';
}

/// The longest long run for a race of [category]. With a target time the cap
/// follows it: about 85 % of the race time, but no less than 70 % and no more
/// than 120 % of the category's cap, so a slow marathon is not capped as for a
/// fast one and a six-hour ultra is not capped as for a four-hour one.
int maxLongRunMinutes(String category, {int? targetMin}) {
  final base = _maxLongRunMin(category);
  if (targetMin == null || targetMin <= 0) return base;
  return (targetMin * 0.85).round().clamp(
    (base * 0.7).round(),
    (base * 1.2).round(),
  );
}

int _maxLongRunMin(String category) => switch (category) {
  'sprint' => 45,
  '5k' => 60,
  '10k' => 90,
  'half' => 120,
  'marathon' => 180,
  'ultra' => 240,
  _ => 180,
};

/// The zone a share of FTP belongs to (Coggan: up to 55 %, 75 %, 90 %, 105 %,
/// above). Used for templates written as a share of FTP, which carry no zone.
int zoneForFtpFraction(double fraction) {
  if (fraction <= 0.55) return 1;
  if (fraction <= 0.75) return 2;
  if (fraction <= 0.90) return 3;
  if (fraction <= 1.05) return 4;
  return 5;
}

/// Athlete attributes from the user profile that shape the plan.
class PlanAthleteProfile {
  const PlanAthleteProfile({
    this.experienceLevel = 'intermediate',
    this.sex,
    this.age,
    this.levelFromData = false,
  });

  /// beginner | intermediate | advanced. The athlete's own answer only
  /// counts while there is too little training history; with enough, the
  /// level is derived from the data ([withDataLevel]).
  final String experienceLevel;

  /// [experienceLevel] was derived from the training data, not self-reported.
  final bool levelFromData;

  /// The data-derived [tier] replaces the self-reported level once the
  /// history is substantial enough to judge it.
  PlanAthleteProfile withDataLevel({
    required String tier,
    required bool enoughData,
  }) => enoughData
      ? PlanAthleteProfile(
          experienceLevel: tier,
          sex: sex,
          age: age,
          levelFromData: true,
        )
      : this;

  /// 'm', 'f' or other; only used for the max-HR estimate.
  final String? sex;
  final int? age;

  bool get isBeginner => experienceLevel == 'beginner';
  bool get isAdvanced => experienceLevel == 'advanced';

  /// Hard (key) sessions per week; null keeps the week template's count.
  int? get maxKeySessions => isBeginner
      ? 1
      : isAdvanced
      ? 2
      : null;

  /// Load increase per week within a block.
  double get progressionPerWeek => isBeginner
      ? 0.04
      : isAdvanced
      ? 0.07
      : 0.06;

  /// Weekly volume ramp from current training towards the target hours.
  double get volumeRampPerWeek => isBeginner ? 0.08 : 0.10;

  /// Every n-th week of base/build is a recovery week.
  int get recoveryCycle => isBeginner || (age ?? 0) >= 50 ? 3 : 4;

  /// Tanaka (208 − 0.7·age), Gulati for women (206 − 0.88·age).
  int? get maxHrEstimate {
    final a = age;
    if (a == null || a <= 0) return null;
    return sex == 'f' ? (206 - 0.88 * a).round() : (208 - 0.7 * a).round();
  }

  /// Upper bounds of HR zones 1–4 from the estimated max HR.
  List<int> get estimatedHrZones {
    final max = maxHrEstimate;
    if (max == null) return const [];
    return [
      for (final f in const [0.68, 0.78, 0.86, 0.93]) (max * f).round(),
    ];
  }
}

/// Planner sport for an activity type, or null when it has no equivalent.
String? _plannerSport(String type) {
  final t = type.toLowerCase();
  if (t.contains('trail')) return 'trail_running';
  if (t.contains('run')) return 'running';
  if (t.contains('gravel')) return 'cycling_gravel';
  if (t.contains('mountain') || t.contains('mtb')) return 'cycling_mtb';
  if (t.contains('cycl') || t.contains('bik') || t.contains('ride')) {
    return 'cycling_road';
  }
  if (t.contains('swim')) return 'swimming';
  if (t.contains('row')) return 'indoor_rowing';
  if (t.contains('hik')) return 'hiking';
  if (t.contains('inline')) return 'inline_skating';
  if (t.contains('skate_ski') || t.contains('skating_ski')) {
    return 'skate_skiing';
  }
  if (t.contains('ski')) return 'nordic_skiing';
  return null;
}

/// One sport's sessions: typical (last 12 weeks) and best (last year).
class _SportHistory {
  const _SportHistory(
    this.sessions,
    this.longestMin,
    this.medianMin,
    this.yearLongestMin,
  );
  final int sessions;

  /// Last 12 weeks.
  final double longestMin, medianMin;

  /// Longest session of the last year.
  final double yearLongestMin;

  /// Clearly longer sessions last year than now: rebuild faster.
  bool get hasYearCapacity => yearLongestMin > longestMin * 1.2;
}

/// What the athlete actually did, in three windows: the last 6 weeks
/// (current volume), 12 weeks (typical sessions and intensity) and a year
/// (peak volume and longest sessions, i.e. what they have handled before).
class _TrainingHistory {
  const _TrainingHistory({
    this.weeklyMinutes = 0,
    this.peakWeeklyMinutes = 0,
    this.sports = const {},
    this.hardShare,
    this.sessions12w = 0,
    this.activeWeeks12w = 0,
  });

  /// Sessions and distinct active weeks in the last 12 weeks.
  final int sessions12w, activeWeeks12w;

  /// Enough training history to judge the athlete's level from data.
  bool get enoughForLevel => sessions12w >= 12 && activeWeeks12w >= 6;

  /// Average of the last 6 weeks.
  final double weeklyMinutes;

  /// Highest 4-week average of the last year.
  final double peakWeeklyMinutes;
  final Map<String, _SportHistory> sports;

  /// Fraction of HR-zone time in zones 4–5 (last 12 weeks); null without
  /// zone data.
  final double? hardShare;

  bool get isEmpty => sports.isEmpty;

  /// Rarely trains hard: introduce intensity gradually.
  bool get mostlyEasy => hardShare != null && hardShare! < 0.05;

  /// History for [sport], falling back to the closest related sport.
  _SportHistory? forSport(String sport) {
    final direct = sports[sport];
    if (direct != null) return direct;
    const related = {
      'trail_running': 'running',
      'running': 'trail_running',
      'cycling_gravel': 'cycling_road',
      'cycling_mtb': 'cycling_road',
      'cycling_road': 'cycling_gravel',
    };
    final alt = related[sport];
    return alt == null ? null : sports[alt];
  }

  static _TrainingHistory fromActivities(
    List<ActivityRecord> activities,
    DateTime now,
  ) {
    if (activities.isEmpty) return const _TrainingHistory();
    final six = now.subtract(const Duration(days: 42));
    final twelve = now.subtract(const Duration(days: 84));
    final recent = <String, List<double>>{};
    final yearLongest = <String, double>{};
    final weekMinutes = <int, double>{};
    var sixMin = 0.0, zoneMin = 0.0, hardMin = 0.0;
    var sessions12w = 0;
    final activeWeeks = <int>{};
    var earliest = now;
    for (final a in activities) {
      final minutes = a.durationSeconds / 60;
      if (minutes <= 0) continue;
      if (a.startDate.isBefore(earliest)) earliest = a.startDate;
      final week = now.difference(a.startDate).inDays ~/ 7;
      weekMinutes[week] = (weekMinutes[week] ?? 0) + minutes;
      final sport = _plannerSport(a.type);
      if (sport != null) {
        yearLongest[sport] = math.max(yearLongest[sport] ?? 0, minutes);
      }
      if (a.startDate.isBefore(twelve)) continue;
      sessions12w++;
      activeWeeks.add(week);
      if (!a.startDate.isBefore(six)) sixMin += minutes;
      if (sport != null) recent.putIfAbsent(sport, () => []).add(minutes);
      final zonesJson = a.hrZonesJson;
      if (zonesJson == null) continue;
      try {
        final zones = jsonDecode(zonesJson) as Map<String, dynamic>;
        double pct(String k) => (zones[k] as num?)?.toDouble() ?? 0;
        final all = [
          'zone1',
          'zone2',
          'zone3',
          'zone4',
          'zone5',
        ].map(pct).fold<double>(0, (x, y) => x + y);
        if (all <= 0) continue;
        zoneMin += minutes;
        hardMin += minutes * (pct('zone4') + pct('zone5')) / all;
      } catch (_) {}
    }
    // Average over the weeks actually covered (at most 6).
    final sixWeeks = (now.difference(earliest).inDays / 7).ceil().clamp(1, 6);
    var peak = 0.0;
    for (var w = 0; w + 3 <= 52; w++) {
      final sum = [for (var i = w; i < w + 4; i++) weekMinutes[i] ?? 0]
          .fold<double>(0, (a, b) => a + b);
      peak = math.max(peak, sum / 4);
    }
    return _TrainingHistory(
      weeklyMinutes: sixMin / sixWeeks,
      peakWeeklyMinutes: peak,
      sports: {
        for (final e in recent.entries)
          e.key: _SportHistory(
            e.value.length,
            e.value.reduce(math.max),
            (List.of(e.value)..sort())[e.value.length ~/ 2],
            yearLongest[e.key] ?? e.value.reduce(math.max),
          ),
      },
      hardShare: zoneMin > 0 ? hardMin / zoneMin : null,
      sessions12w: sessions12w,
      activeWeeks12w: activeWeeks.length,
    );
  }
}

/// Weekly ramp rate: volume handled within the last year ([peakMin]) can be
/// rebuilt faster (15 %/week), otherwise the experience-based rate.
@visibleForTesting
double volumeRampRate({
  required double targetMin,
  required double peakMin,
  required PlanAthleteProfile athlete,
}) => targetMin <= peakMin * 1.05 ? 0.15 : athlete.volumeRampPerWeek;

/// Weekly minutes for week [week]: from current volume towards [targetMin],
/// growing by [rate] per week. Without history start at 70% of the target.
@visibleForTesting
double rampedWeeklyMinutes({
  required double targetMin,
  required double recentMin,
  required int week,
  required double rate,
}) {
  final start = recentMin > 0
      ? math.min(targetMin, recentMin * (1 + rate))
      : targetMin * 0.7;
  return math.min(targetMin, start * math.pow(1 + rate, week)).toDouble();
}

class _AthleteFitnessSnapshot {
  const _AthleteFitnessSnapshot({
    required this.ctl,
    required this.tsb,
    this.vo2max,
    this.lt2Bpm,
    this.lt1Bpm,
    this.hrZones = const [],
    this.hrFloors = const [],
    this.maxHr,
    required this.tier,
    this.hrvRatio = 1.0,
    this.sleepScore,
    this.weeklyTss = 0,
    this.easyRunZ2 = false,
  });

  final double ctl;
  final double tsb;
  final double? vo2max;
  final int? lt2Bpm;
  final int? lt1Bpm;

  /// Upper HR bound of zones 1–4 (zone 5 is open-ended).
  final List<int> hrZones;

  /// Lower HR bound of zones 1 to 5, when known. Preferred over [hrZones]:
  /// a zone then runs from its floor to the next floor minus one.
  final List<int> hrFloors;

  /// The athlete's maximum heart rate, the upper end of zone 5.
  final int? maxHr;
  final String tier;
  final double hrvRatio;
  final int? sleepScore;
  final double weeklyTss;

  /// Running at zone-1 heart rate is close to walking and few runners can do
  /// it. For runs, an "easy" zone 1 is therefore planned as the lower half of
  /// zone 2, which is where an easy run really sits.
  final bool easyRunZ2;

  /// The lower half of zone 2: where a recovery or easy run is run.
  ({int? low, int? high}) easyRunRange() {
    final z2 = hrRangeForZone(2);
    if (z2.low == null || z2.high == null) return z2;
    return (low: z2.low, high: z2.low! + ((z2.high! - z2.low!) / 2).round());
  }

  bool get isFatigued => tsb < -20;

  _AthleteFitnessSnapshot withHrZones(List<int> zones) =>
      _AthleteFitnessSnapshot(
        ctl: ctl,
        tsb: tsb,
        vo2max: vo2max,
        lt2Bpm: lt2Bpm,
        lt1Bpm: lt1Bpm,
        hrZones: zones,
        hrFloors: hrFloors,
        maxHr: maxHr,
        tier: tier,
        hrvRatio: hrvRatio,
        sleepScore: sleepScore,
        weeklyTss: weeklyTss,
        easyRunZ2: easyRunZ2,
      );

  ({int? low, int? high}) hrRangeForZone(int zone) {
    if (hrFloors.length >= 5 && zone >= 1) {
      final z = zone.clamp(1, 5);
      final low = hrFloors[z - 1];
      final high = z == 5
          ? (maxHr != null && maxHr! > low ? maxHr : null)
          : hrFloors[z] - 1;
      return (low: low, high: high);
    }
    if (hrZones.length < 4 || zone < 1) return (low: null, high: null);
    final z = zone.clamp(1, 5);
    final low = z == 1 ? null : hrZones[z - 2];
    final high = z == 5 ? null : hrZones[z - 1];
    return (low: low, high: high);
  }
}

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
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final WorkoutProviders _providers;

  /// The watch platforms workouts go to.
  WorkoutProviders get providers => _providers;
  final bool Function(String sport, bool indoor) _usesPower;

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

  Future<_AthleteFitnessSnapshot> _readFitnessSnapshot(
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

    // CTL/ATL (42/7-day EWMA) over a year of daily strain.
    final since = DateTime.now().subtract(const Duration(days: 365));
    final scores =
        await (_db.select(_db.dayScoreRecords)
              ..where((t) => t.date.isBiggerOrEqualValue(since))
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();
    var ctl = 0.0, atl = 0.0;
    for (final s in scores) {
      final load = s.strainScore ?? 0.0;
      ctl += (load - ctl) * (2 / 43);
      atl += (load - atl) * 0.25;
    }
    final tsb = ctl - atl;

    // Average weekly load over the last 6 weeks.
    final sixWeeks = DateTime.now().subtract(const Duration(days: 42));
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

    final now = DateTime.now();
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

    final tier = _tierFor(ctl);
    final snapshot = _AthleteFitnessSnapshot(
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

  /// 0.7–1.1 multiplier from form (TSB), HRV ratio and sleep.
  double _readinessFactor(_AthleteFitnessSnapshot s) {
    final form = ((s.tsb + 20) / 40).clamp(0.0, 1.0);
    final hrv = ((s.hrvRatio - 0.9) / 0.15).clamp(0.0, 1.0);
    final sleep = s.sleepScore == null
        ? 0.5
        : ((s.sleepScore! - 50) / 35).clamp(0.0, 1.0);
    return 0.7 + 0.4 * (form * 0.4 + hrv * 0.4 + sleep * 0.2);
  }

  int _ctlScaledDuration(
    int baseMin,
    String sessionType,
    String tier,
    double ctl,
  ) {
    if (sessionType == 'recovery') return baseMin;
    final ctlF = ctl < 30
        ? 0.7
        : ctl < 60
        ? 1.0
        : ctl < 90
        ? 1.15
        : 1.3;
    final tierF = switch (tier) {
      'beginner' => 0.9,
      'advanced' => 1.1,
      _ => 1.0,
    };
    final factor = (ctlF * tierF).clamp(0.6, 1.4);
    return (baseMin * factor).round().clamp(20, 240);
  }

  static int _baseDuration(String sessionType) => switch (sessionType) {
    'long' => 90,
    'key' => 55,
    'recovery' => 40,
    'assessment' => 50,
    _ => 45,
  };

  /// Drops the least important sessions until the rest fits in [limit]
  /// minutes. Used when time has already been spent that no session stands
  /// for.
  static ({List<_SessionSlot> kept, List<_SessionSlot> removed}) _makeRoom(
    List<_SessionSlot> slots,
    double limit,
  ) {
    final list = [...slots];
    final removed = <_SessionSlot>[];
    int total() => list.fold(0, (a, s) => a + (s.targetMin ?? 0));
    while (list.isNotEmpty && total() > limit) {
      var worst = 0;
      for (var i = 1; i < list.length; i++) {
        final a = list[i], b = list[worst];
        final byRank = (a.rank ?? 9).compareTo(b.rank ?? 9);
        if (byRank > 0 ||
            (byRank == 0 && (a.targetMin ?? 0) < (b.targetMin ?? 0))) {
          worst = i;
        }
      }
      removed.add(list.removeAt(worst));
    }
    return (kept: list, removed: removed);
  }

  /// The race a run is paced against: the goal the session prepares for when
  /// that is a running goal, else the most important running goal. A ride
  /// goal never sets a run's pace.
  static RaceProfile? _paceProfile(
    GoalSet goals,
    _SessionSlot slot,
    RaceProfile? single,
    bool multi,
  ) {
    if (!multi) return single;
    bool foot(SeasonGoal g) =>
        g.sport == 'running' || g.sport == 'trail_running';
    var goal = slot.goalId == null ? null : goals.byId(slot.goalId!);
    if (goal == null || !foot(goal)) {
      final runs = goals.active.where(foot).toList()
        ..sort((a, b) {
          final byPriority = a.priority.index.compareTo(b.priority.index);
          return byPriority != 0 ? byPriority : a.date.compareTo(b.date);
        });
      goal = runs.isEmpty ? null : runs.first;
    }
    return goal?.profile;
  }

  /// What the athlete has done in each sport, as the allocator reads it.
  static Map<String, SportCapacity> _capacitiesOf(_TrainingHistory history) => {
    for (final e in history.sports.entries)
      e.key: SportCapacity(
        sessions: e.value.sessions,
        longestMin: e.value.longestMin,
        medianMin: e.value.medianMin,
        yearLongestMin: e.value.yearLongestMin,
      ),
  };

  /// The allocator's session as a slot of the weekly scheduling loop.
  static _SessionSlot _slotOf(AllocatedSlot a) => _SessionSlot(
    a.sport,
    a.sessionType,
    a.subType,
    a.zone,
    a.weekday,
    goalId: a.goalId,
    goalRole: a.role,
    objective: a.objective,
    targetMin: a.targetMin,
    minMin: a.minMin,
    maxMin: a.maxMin,
    rank: a.rank,
    phase: a.phase.isEmpty ? null : a.phase,
    maxZone: a.maxZone,
  );

  /// Days after an event take easy sessions only, and short ones.
  static bool _easyEnough(_SessionSlot s) =>
      s.sport != 'strength' &&
      s.zone <= 2 &&
      (s.targetMin ?? 60) <= 60 &&
      s.sessionType != 'key';

  /// A steady endurance workout of [minutes] in [zone]: a short warm-up, one
  /// long block and a cool-down. Used where no template is as long as the
  /// session; the heart-rate or power target is filled in like any other.
  static String _steadySteps(int minutes, int zone) {
    Map<String, dynamic> step(String type, int id, int seconds, int z) => {
      'type': 'ExecutableStepDTO',
      'stepType': {'stepTypeId': id, 'stepTypeKey': type},
      'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
      'endConditionValue': seconds,
      'targetType': {
        'workoutTargetTypeId': 4,
        'workoutTargetTypeKey': 'heart.rate.zone',
      },
      'zoneNumber': z,
    };
    final warm = minutes >= 45 ? 600 : 300;
    final cool = minutes >= 45 ? 300 : 0;
    final main = math.max(300, minutes * 60 - warm - cool);
    return jsonEncode([
      step('warmup', 1, warm, 1),
      step('interval', 3, main, zone),
      if (cool > 0) step('cooldown', 2, cool, 1),
    ]);
  }

  static String _steadyTitle(
    String sport,
    int minutes, {
    String lead = 'Long endurance',
  }) {
    final noun = sport.startsWith('cycl')
        ? 'ride'
        : sport == 'running' || sport == 'trail_running'
        ? 'run'
        : sport.replaceAll('_', ' ');
    return '$lead $noun ($minutes min)';
  }

  List<_SessionSlot> _recoveryWeekSlots(String sport) {
    final main = switch (sport) {
      'cycling_road' || 'cycling_gravel' || 'cycling_mtb' => sport,
      'swimming' => 'swimming',
      'indoor_rowing' => 'indoor_rowing',
      'triathlon' => 'running',
      _ => sport,
    };
    return [
      _SessionSlot(main, 'long', 'endurance', 2, 6),
      _SessionSlot(main, 'recovery', null, 1, 3),
      _yoga,
      _SessionSlot(main, 'recovery', null, 1, 1),
    ];
  }

  // ---------------------------------------------------------------------------
  // Templates & steps
  // ---------------------------------------------------------------------------

  WorkoutTemplate? _pickTemplateFromCache(
    List<WorkoutTemplate> templates,
    String sport,
    String sessionType,
    String? subType,
    String phase,
    int durationMin,
    int seed,
  ) {
    final templateSport =
        sport.startsWith('cycling') && !templates.any((t) => t.sport == sport)
        ? 'cycling_road'
        : sport;
    var pool = templates
        .where((t) => t.sport == templateSport && t.sessionType == sessionType)
        .toList();
    if (pool.isEmpty) return null;

    // Phase match, widening to neighbouring phases if needed.
    final idx = _phaseOrder.indexOf(phase);
    final phases = <String>{phase};
    if (idx > 0) phases.add(_phaseOrder[idx - 1]);
    if (idx >= 0 && idx < _phaseOrder.length - 1) {
      phases.add(_phaseOrder[idx + 1]);
    }
    final exact = pool
        .where((t) => t.targetPhase.split(',').contains(phase))
        .toList();
    final near = pool
        .where((t) => t.targetPhase.split(',').any(phases.contains))
        .toList();
    pool = exact.isNotEmpty
        ? exact
        : near.isNotEmpty
        ? near
        : pool;

    // Base-phase intervals on the bike are threshold work.
    var wanted = subType;
    if (wanted == 'intervals' &&
        phase == 'base' &&
        sport.startsWith('cycling')) {
      wanted = 'threshold';
    }
    if (wanted != null) {
      final bySub = pool.where((t) => t.subType == wanted).toList();
      if (bySub.isNotEmpty) pool = bySub;
    }

    // Close to the wanted length: within 15 %, else within 40 %, else the
    // nearest few. Never an arbitrary template of the pool, whose steps would
    // run for a different time than the plan shows.
    List<WorkoutTemplate> within(double share) => pool
        .where(
          (t) =>
              (t.estimatedDurationMin - durationMin).abs() <=
              durationMin * share,
        )
        .toList();
    var closest = within(0.15);
    if (closest.isEmpty) closest = within(0.4);
    if (closest.isEmpty) {
      final byCloseness = [...pool]
        ..sort(
          (a, b) => (a.estimatedDurationMin - durationMin).abs().compareTo(
            (b.estimatedDurationMin - durationMin).abs(),
          ),
        );
      closest = byCloseness.take(3).toList();
    }
    pool = closest;

    return pool[seed % pool.length];
  }

  /// Makes the targets of a step concrete.
  ///
  /// Every step gets its zone number, taken from the template or, for a
  /// template written as a share of FTP, worked out from that share. The target
  /// is then heart rate in the athlete's zones. Only where [power] is true and
  /// an FTP is known does a step keep a power target in watts: a heart-rate
  /// workout must not turn into a power workout for someone without a meter.
  Map<String, dynamic> _resolveStep(
    Map<String, dynamic> step,
    int? ftp,
    _AthleteFitnessSnapshot fitness, {
    required bool power,
  }) {
    if (step['type'] == 'RepeatGroupDTO') {
      final iterations =
          (step['numberOfIterations'] as num?)?.toInt() ??
          (step['endConditionValue'] as num?)?.toInt() ??
          1;
      final inner =
          (step['workoutSteps'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((s) => _resolveStep(s, ftp, fitness, power: power))
              .toList() ??
          <Map<String, dynamic>>[];
      return Map<String, dynamic>.of(step)
        ..['numberOfIterations'] = iterations
        ..['workoutSteps'] = inner;
    }

    final out = Map<String, dynamic>.from(step);
    final hasFraction =
        out.containsKey('ftpFraction') || out.containsKey('ftpLow');
    final fraction = _stepFraction(out, ftp);
    var zone = (out['zoneNumber'] as num?)?.toInt();
    // Sprints are written as a sixth zone; heart rate has five, and the top one
    // runs to the maximum, so that is where a sprint reads on the watch.
    if (zone != null && zone > 5) zone = 5;
    if ((zone == null || zone < 1 || zone > 5) && fraction != null) {
      zone = zoneForFtpFraction(fraction);
    }
    // Zone 1 for a runner is the lower half of zone 2 (see easyRunZ2). A
    // warm-up, cool-down or rest step stays as planned: walking or jogging
    // there is what those steps are for.
    final stepKey = (out['stepType'] as Map?)?['stepTypeKey'];
    final easyRun =
        fitness.easyRunZ2 &&
        zone == 1 &&
        stepKey != 'warmup' &&
        stepKey != 'cooldown' &&
        stepKey != 'recovery' &&
        stepKey != 'rest';
    if (easyRun) zone = 2;
    if (zone != null && zone >= 1 && zone <= 5) out['zoneNumber'] = zone;

    final key = (out['targetType'] as Map?)?['workoutTargetTypeKey'];
    final isPowerStep = hasFraction || key == 'power.zone';
    if (power && ftp != null && hasFraction) {
      if (out.containsKey('ftpFraction')) {
        final f = (out['ftpFraction'] as num).toDouble();
        out['targetValueOne'] = (ftp * f * 0.95).round().toDouble();
        out['targetValueTwo'] = (ftp * f * 1.05).round().toDouble();
      } else {
        out['targetValueOne'] = (ftp * (out['ftpLow'] as num).toDouble())
            .round()
            .toDouble();
        out['targetValueTwo'] = (ftp * (out['ftpHigh'] as num).toDouble())
            .round()
            .toDouble();
      }
      out['targetType'] = {
        'workoutTargetTypeId': 2,
        'workoutTargetTypeKey': 'power.zone',
        'displayOrder': 2,
      };
    } else if (power &&
        ftp != null &&
        !isPowerStep &&
        zone != null &&
        zone >= 1 &&
        zone <= 5) {
      // Planned as heart rate, ridden on a smart trainer: the zone gives the
      // watts, and the heart-rate range stays as the guide beside them.
      final w = _powerZones[zone]!;
      final hr = fitness.hrRangeForZone(zone);
      out['targetValueOne'] = (ftp * w.lo).round().toDouble();
      out['targetValueTwo'] = (ftp * w.hi).round().toDouble();
      out['targetType'] = {
        'workoutTargetTypeId': 2,
        'workoutTargetTypeKey': 'power.zone',
        'displayOrder': 2,
      };
      if (hr.low != null || hr.high != null) {
        final own = (out['description'] as String?)?.trim();
        final guide =
            'HR ${hr.low ?? (hr.high! - 15)}–${hr.high ?? (hr.low! + 15)} bpm';
        out['description'] = own == null || own.isEmpty
            ? guide
            : '$guide · $own';
      }
    } else if (isPowerStep && !(power && ftp != null)) {
      // Heart rate instead. A zone is always given with its heart rates, a
      // short effort included: the athlete reads the range on the watch, and
      // the data is there for whoever looks at the workout later.
      final useHr = zone != null && zone >= 1 && zone <= 5;
      out['targetType'] = useHr
          ? {
              'workoutTargetTypeId': 4,
              'workoutTargetTypeKey': 'heart.rate.zone',
              'displayOrder': 4,
            }
          : {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
              'displayOrder': 1,
            };
      out.remove('targetValueOne');
      out.remove('targetValueTwo');
    }
    // A step that names a zone but has no target gets the zone's heart rates:
    // a zone without its data is only half an instruction. Steps that use
    // power, or a target of their own (pace, cadence), are left alone.
    final tail = (out['targetType'] as Map?)?['workoutTargetTypeKey'];
    if ((tail == null || tail == 'no.target') &&
        zone != null &&
        zone >= 1 &&
        zone <= 5) {
      out['targetType'] = {
        'workoutTargetTypeId': 4,
        'workoutTargetTypeKey': 'heart.rate.zone',
        'displayOrder': 4,
      };
    }
    out
      ..remove('ftpFraction')
      ..remove('ftpLow')
      ..remove('ftpHigh');

    final target = out['targetType'] as Map?;
    if (target?['workoutTargetTypeKey'] == 'heart.rate.zone') {
      final z = (out['zoneNumber'] as num?)?.toInt();
      if (z != null) {
        final r = easyRun ? fitness.easyRunRange() : fitness.hrRangeForZone(z);
        if (r.low != null || r.high != null) {
          out['targetValueOne'] = (r.low ?? (r.high! - 15)).toDouble();
          out['targetValueTwo'] = (r.high ?? (r.low! + 15)).toDouble();
        }
      }
    }
    return out;
  }

  /// The share of FTP a step asks for: from its own fields, or from the
  /// target values (fractions below 3, watts above 5 with an [ftp]).
  static double? _stepFraction(Map<String, dynamic> step, int? ftp) {
    double? number(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
    final single = number(step['ftpFraction']);
    if (single != null) return single;
    final low = number(step['ftpLow']), high = number(step['ftpHigh']);
    if (low != null && high != null) return (low + high) / 2;
    final one = number(step['targetValueOne']);
    final two = number(step['targetValueTwo']);
    if (one == null || two == null) return null;
    final mean = (one + two) / 2;
    if (mean > 0 && mean < 3) return mean;
    if (mean > 5 && ftp != null && ftp > 0) return mean / ftp;
    return null;
  }

  String _resolveStepsJson(
    String stepsJson,
    int? ftp,
    _AthleteFitnessSnapshot fitness, {
    required bool power,
  }) {
    final steps = (jsonDecode(stepsJson) as List).cast<Map<String, dynamic>>();
    return jsonEncode(
      steps.map((s) => _resolveStep(s, ftp, fitness, power: power)).toList(),
    );
  }

  ({String? text, int? minutes}) _extractWarmUpDescription(String stepsJson) {
    try {
      final steps = (jsonDecode(stepsJson) as List)
          .cast<Map<String, dynamic>>();
      for (final s in steps) {
        final type =
            (s['stepType'] as Map<String, dynamic>?)?['stepTypeKey'] ??
            s['intensity'];
        if (type?.toString().toLowerCase() != 'warmup') continue;
        final secs = (s['endConditionValue'] as num?)?.toInt();
        final text = s['stepName'] as String? ?? s['description'] as String?;
        return (
          text:
              text ?? (secs == null ? 'Warm-up' : 'Warm-up ${secs ~/ 60} min'),
          minutes: secs == null ? null : secs ~/ 60,
        );
      }
    } catch (_) {}
    return (text: null, minutes: null);
  }

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
    final multi =
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
    final rotation = _gadSportRotation(gadSports.isEmpty ? [sport] : gadSports);
    final mainSport = _supportedSports.contains(sport) ? sport : rotation.first;
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
    final history = _TrainingHistory.fromActivities(
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
    );
    log(
      '[Plan] athlete: level=${athlete.experienceLevel} '
      '(${athlete.levelFromData ? 'from data, self-reported $selfReported' : 'self-reported'}) '
      'age=${athlete.age} '
      'sex=${athlete.sex} maxHr=${athlete.maxHrEstimate} '
      'cycle=${athlete.recoveryCycle} | history: '
      '${history.weeklyMinutes.round()} min/week '
      '(peak ${history.peakWeeklyMinutes.round()}), '
      'hard=${history.hardShare?.toStringAsFixed(2)}, sports='
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
    final category = _distanceCategory(raceDistanceM);
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
    final baseSlots = _weekTemplates[mainSport] ?? _weekTemplates['running']!;
    final targetWeeklyMin = hoursPerWeek * 60;
    final baseWeeklyTss = math.max(fitness.weeklyTss, 50.0);
    final readiness = _readinessFactor(fitness);
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
    final capacities = _capacitiesOf(history);
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
      for (final s in _gadSportRotation(gadSports))
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
    final sportFitness = <String, _AthleteFitnessSnapshot>{mainSport: fitness};
    Future<_AthleteFitnessSnapshot> fitnessFor(String sport) async {
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
          : multi
          ? (needs.isEmpty ? 'base' : needs.first.intent.phase)
          : _phase(g, weeks, cycle: athlete.recoveryCycle);
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
                  _weeklyTssFactor(phase, fitness.tier) *
                  progression *
                  (w == 0 ? readiness : 1.0))
              .round();
      final weekTssCap = (weekTss * 1.1).round();

      // Choose slots for the week.
      var slots = phase == 'recovery'
          ? _recoveryWeekSlots(mainSport)
          : List<_SessionSlot>.of(baseSlots);
      slots = _restrictSlotsToSports(
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
      // Rotate the general-development sport into easy slots.
      if (rotation.length > 1) {
        slots = slots.map((s) {
          if (s.sessionType != 'recovery' || s.sport == 'yoga') return s;
          final alt = rotation[gadIndex++ % rotation.length];
          return s.copyWith(sport: alt);
        }).toList();
      }
      // Hard sessions: capped by experience; athletes who rarely train hard
      // get one moderate (tempo) key session in the first two weeks.
      final easyStart = history.mostlyEasy && w < 2;
      final maxKeys = easyStart ? 1 : athlete.maxKeySessions;
      var keys = 0;
      for (var i = 0; i < slots.length; i++) {
        final s = slots[i];
        if (s.sessionType != 'key' || s.sport == 'strength') continue;
        if (maxKeys != null && keys >= maxKeys) {
          slots[i] = s.copyWith(
            sessionType: 'recovery',
            clearSubType: true,
            zone: 2,
          );
        } else {
          keys++;
          if (easyStart) {
            slots[i] = s.copyWith(subType: 'tempo', zone: math.min(s.zone, 3));
          }
        }
      }
      // A hilly race gets hill work in the build and peak: one tempo session
      // becomes a hill session, every other week on rolling to hilly courses
      // and every week on mountainous ones.
      if ((phase == 'build' || phase == 'peak') &&
          _footSports.contains(mainSport) &&
          (terrain == Terrain.mountainous ||
              (terrain == Terrain.hilly && g.isEven))) {
        final i = slots.indexWhere(
          (s) =>
              s.sessionType == 'key' &&
              s.subType == 'tempo' &&
              _footSports.contains(s.sport),
        );
        if (i >= 0) slots[i] = slots[i].copyWith(subType: 'hills', zone: 4);
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
            _strengthFull.copyWith(
              subType: phase == 'recovery'
                  ? 'strengthCore'
                  : strengthProgrammeId(focus, phase, g + i),
              weekday: strengthDays[i],
            ),
          );
        }
      }
      final maxSessions = math.max(1, daysPerWeek * maxSessionsPerDay);
      // Keep long and key sessions first when trimming.
      int rank(_SessionSlot s) => switch (s.sessionType) {
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
      void dropped(_SessionSlot slot, String why) {
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
            maxKeySessions: easyStart ? 1 : athlete.maxKeySessions,
            easyStart: easyStart,
            varietySports: varietySports,
            footLongCap: (goal) => maxLongRunMinutes(
              _distanceCategory(goal.distanceM),
              targetMin: goal.targetSeconds == null
                  ? null
                  : (goal.targetSeconds! / 60).round(),
            ),
            allowedSports: allowedSports,
            events: events,
          ),
        );
        allocations.add(allocation);
        weekAllocation = allocation;
        weekPartial = daysLeft < trainingDays;
        weekBudget = budget;
        slots = [for (final a in allocation.slots) _slotOf(a)]
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

      int? bestOffset(_SessionSlot s) {
        final candidates = <int>[];
        for (var off = 0; off < 7; off++) {
          final date = _addDays(weekStart, off);
          // An event day belongs to the event, not to an ordinary session.
          if (multi) {
            if (date.isAfter(end)) continue;
            final load = goalSet.loadOn(date);
            if (load == DayLoad.blocked) continue;
            if (load == DayLoad.easyOnly && !_easyEnough(s)) continue;
          } else if (!date.isBefore(raceDay)) {
            continue;
          }
          // Days already gone cannot take a session.
          if (date.isBefore(today)) continue;
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
        if (candidates.isEmpty) return null;
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
        if (multi && minutes >= 100) {
          longDates[_day(p.sessionDate)] = minutes;
        }
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
        final room = _makeRoom(slots, weekBudget - unmatchedMin);
        slots = room.kept;
        for (final d in room.removed) {
          dropped(d, 'time was already spent that week');
        }
      }

      // Strength first: its days are fixed by the athlete, the rest of the
      // week arranges itself around them.
      slots = [
        ...slots.where((s) => s.sport == 'strength'),
        ...slots.where((s) => s.sport != 'strength'),
      ];
      for (final slot in slots) {
        final off = bestOffset(slot);
        if (off == null) {
          log(
            '[Plan] w$w ${slot.sport}/${slot.sessionType}'
            '(p$phase,z${slot.zone}) → SKIP rest=$restDays used=$used',
          );
          continue;
        }
        final date = _addDays(weekStart, off);
        if (date.isBefore(today)) continue;
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
            _ctlScaledDuration(
              _baseDuration(slot.sessionType),
              slot.sessionType,
              fitness.tier,
              fitness.ctl,
            );
        if (slot.targetMin == null) {
          if (phase == 'taper') duration = (duration * 0.7).round();
          if (phase == 'recovery') duration = (duration * 0.7).round();
          if (slot.sessionType == 'long' && _footSports.contains(slot.sport)) {
            duration = math.min(duration, longRunCap);
          }
          if (slot.sessionType == 'long' && phase == 'peak') {
            duration = (duration * 1.4).round();
            if (_footSports.contains(slot.sport)) {
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
              duration = math.min(duration, cap.round());
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

        // The workout is chosen first and its steps decide the duration, so
        // what the app shows, what the load estimate counts and what the watch
        // executes are the same. A steady session is fitted to the wanted
        // length; a structured one is chosen close to it and left whole.
        final slotPhase = slot.phase ?? phase;
        // Zones and thresholds are the sport's own, not the main sport's.
        final fit = await fitnessFor(slot.sport);
        var template = _pickTemplateFromCache(
          templates,
          slot.sport,
          slot.sessionType,
          slot.subType,
          slotPhase,
          duration,
          w + sessionNumber,
        );
        String? stepsJson;
        var scaled = false;
        var semantics = const WorkoutSemantics();
        void compileSteps(String raw, int wantedMin) {
          final resolved = _resolveStepsJson(
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
          compileSteps(_steadySteps(duration, slot.zone), duration);
          template = null;
          synthetic = true;
        }
        // A hard session that would take the week over its load cap is
        // replaced by a lighter one of the same kind, not clipped on paper.
        if (template != null &&
            slot.sessionType == 'key' &&
            slotPhase != 'peak' &&
            weekPlannedTrimp + semantics.legacyLoad > weekTssCap) {
          final lighter = _pickTemplateFromCache(
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
          compileSteps(_steadySteps(duration, limit), duration);
          template = null;
          synthetic = true;
          steadyLead = 'Steady';
        }
        // The hours the athlete gave are a limit, not a hope: a workout whose
        // steps run longer than the week has left is made shorter, or left
        // out, and the report says which.
        if (multi && slot.targetMin != null && weekBudget > 0) {
          final actual = semantics.isEmpty
              ? duration
              : semantics.totalMinutes.clamp(1, 600);
          final room = (weekBudget - weekPlannedMin).floor();
          if (actual > room) {
            final minimum = slot.minMin ?? 20;
            if (slot.sport != 'strength' && room >= minimum) {
              final zone = math.min(slot.zone, slot.maxZone ?? 4);
              compileSteps(_steadySteps(room, zone), room);
              template = null;
              synthetic = true;
              steadyLead = slot.sessionType == 'key'
                  ? (zone >= 4 ? 'Tempo' : 'Steady')
                  : 'Long endurance';
              duration = room;
            } else if (slot.sport == 'strength' && room >= minimum) {
              // A shorter strength workout, or none.
              final shorter = _pickTemplateFromCache(
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
                  : semantics.totalMinutes.clamp(1, 600);
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
        var title =
            template?.name ??
            '${slot.sessionType[0].toUpperCase()}${slot.sessionType.substring(1)} '
                '${slot.sport.replaceAll('_', ' ')}';
        var trimp = 0.0;
        if (semantics.isEmpty) {
          trimp = duration * _zoneWeights[(slot.zone - 1).clamp(0, 4)];
        } else {
          duration = semantics.totalMinutes.clamp(1, 600);
          trimp = semantics.legacyLoad;
          if (scaled) title = retimeTitle(title, duration);
        }
        if (synthetic) {
          title = _steadyTitle(
            slot.sport,
            duration,
            lead: slot.sessionType == 'recovery' ? 'Easy' : steadyLead,
          );
        }

        var zone = semantics.dominantZone ?? slot.zone;
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
        final paceProfile = _paceProfile(goalSet, slot, raceProfile, multi);
        final pace = measuredPace ?? paceProfile?.estimatedThresholdSpeedMps;
        if ((slot.sport == 'running' || slot.sport == 'trail_running') &&
            pace != null &&
            pace > 0) {
          final z = _paceZones[zone.clamp(1, 5)]!;
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
          final z = _powerZones[zone.clamp(1, 5)]!;
          powerJson = jsonEncode({
            'low_watts': (ftp * z.lo).round(),
            'high_watts': (ftp * z.hi).round(),
            'zone': zone,
            'ftp': ftp,
          });
        }

        final warm = stepsJson == null
            ? (text: null, minutes: null)
            : _extractWarmUpDescription(stepsJson!);

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
        if (multi && duration >= 100) longDates[date] = duration;

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
                sessionNotes: Value(template?.description),
                mainSet: Value(template?.coachingCues),
                warmUp: Value(warm.text),
                warmUpDurationMin: Value(warm.minutes),
                stepsJson: Value(stepsJson),
                hrRangesJson: Value(hrJson),
                paceRangesJson: Value(paceJson),
                powerRangesJson: Value(powerJson),
                plannedDurationMin: duration,
                plannedTrimp: trimp.round(),
                sessionLevel: _sessionLevel(slot.sessionType, zone, slotPhase),
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
        seasonJson: Value(report.encode()),
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

  /// Rebuilds the remaining weeks of [planId] (e.g. after a readiness
  /// trigger or a settings change), bumping the plan version.
  Future<void> replan({
    required String planId,
    required String reason,
    int daysPerWeek = 5,
    List<int> restDays = const [7],
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
    final rotation = _gadSportRotation(preferredSports);

    await _generatePlan(
      athleteId: plan.athleteId,
      raceGoalId: goal?.id ?? plan.raceGoalId,
      raceDate: goal?.date ?? plan.endDate,
      sport: goal?.sport ?? rotation.first,
      raceDistanceM: goal?.distanceM,
      raceElevationM: goal?.elevationM,
      targetFinishSeconds: goal?.targetSeconds,
      daysPerWeek: daysPerWeek,
      restDays: restDays,
      strengthDays: strengthDays,
      hoursPerWeek: hoursPerWeek,
      maxSessionsPerDay: maxSessionsPerDay,
      gadSports: preferredSports,
      coachId: plan.coachId,
      existingPlanId: planId,
      weekStartsOnMonday: weekStartsOnMonday,
      athlete: athlete,
      goals: goalSet.isEmpty ? null : goalSet,
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

  /// Session difficulty 1–9 from type, zone and phase.
  static int _sessionLevel(String sessionType, int zone, String phase) {
    var level = switch (sessionType) {
      'recovery' => 2,
      'long' => 5,
      'key' => 4 + zone.clamp(1, 5) - 2,
      'assessment' => 7,
      _ => 4,
    };
    if (phase == 'peak') level += 1;
    if (phase == 'taper' || phase == 'recovery') level -= 1;
    return level.clamp(1, 9);
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
    return _resolveStepsJson(
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
    final floors = _zonesFromJson(
      s.sport.contains('swim')
          ? thresholds?.swimHrZonesJson
          : s.sport.contains('cycl')
          ? thresholds?.bikeHrZonesJson
          : thresholds?.runHrZonesJson,
    );
    // Five stored values are the zone floors; the planner's upper-bound list
    // is derived from them, never the floors passed off as upper bounds.
    final fitness = _AthleteFitnessSnapshot(
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
    final steps = _withNotes(
      (jsonDecode(s.stepsJson!) as List)
          .cast<Map<String, dynamic>>()
          .map((st) => _resolveStep(st, ftp, fitness, power: power))
          .toList()
          .asMap()
          .entries
          .map((e) => {...e.value, 'stepOrder': e.key + 1})
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
      description: _garminDescription(s, steps, power: power, goal: goal),
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

  /// Lines about the race goal and, for a run, the pace that goes with this
  /// session. The pace is a guide; the heart-rate target decides.
  static List<String>? _goalLines(TrainingSession s, RaceGoal? goal) {
    final lines = <String>[];
    // The A goal is "the race goal"; any other is named, so a brevet ride
    // never reads like marathon preparation.
    final isTop = goal?.priority.toLowerCase() == 'a';
    final label = goal == null || isTop
        ? 'Race goal'
        : 'Goal ${goal.priority.toUpperCase()} · ${goal.name}';
    if (goal != null && goal.targetFinishSeconds != null) {
      final profile = RaceProfile(
        sport: goal.primarySport,
        distanceM: goal.distanceM,
        elevationM: goal.elevationM,
        targetSeconds: goal.targetFinishSeconds,
      );
      final flat = profile.flatEquivalentPaceSecPerKm;
      final climb = profile.isRide && goal.elevationM != null
          ? ', ${goal.elevationM!.round()} m climbing'
          : '';
      lines.add(
        '$label: ${formatTargetTime(goal.targetFinishSeconds!)} for '
        '${(goal.distanceM / 1000).toStringAsFixed(1)} km'
        '${profile.isRide
            ? ' (${profile.goalSpeedKmh!.toStringAsFixed(1)} km/h)$climb'
            : flat == null
            ? ''
            : ' (${formatPace(profile.goalPaceSecPerKm!)}, ${formatPace(flat)} on the flat)'}.',
      );
    } else if (goal != null && !isTop) {
      lines.add(
        '$label: ${(goal.distanceM / 1000).toStringAsFixed(1)} km'
        '${goal.elevationM == null ? '' : ', ${goal.elevationM!.round()} m climbing'}.',
      );
    }
    if (s.goalObjective != null) {
      lines.add('Purpose: ${s.goalObjective}.');
    }
    try {
      final json = s.paceRangesJson;
      if (json != null) {
        final pace = jsonDecode(json) as Map<String, dynamic>;
        final low = pace['low_sec_per_km'], high = pace['high_sec_per_km'];
        if (low is num && high is num) {
          lines.add(
            'Pace guide: ${formatPace(low.toDouble())} to ${formatPace(high.toDouble())}'
            '${pace['basis'] == 'goal' ? ', estimated from your goal' : ''}. '
            'Heart rate decides.',
          );
        }
      }
    } catch (_) {}
    return lines.isEmpty ? null : lines;
  }

  /// Each step gets its target as a note ("Z2 · 110–127 bpm") so the watch
  /// shows what is asked even where it hides the target type.
  static List<Map<String, dynamic>> _withNotes(
    List<Map<String, dynamic>> steps,
  ) => [
    for (final step in steps)
      if (step['workoutSteps'] is List)
        {
          ...step,
          'workoutSteps': _withNotes(
            (step['workoutSteps'] as List).cast<Map<String, dynamic>>(),
          ),
        }
      else
        () {
          final note = _stepNote(step);
          if (note == null) return step;
          final own = (step['description'] as String?)?.trim();
          return {
            ...step,
            'description': own == null || own.isEmpty ? note : '$note · $own',
          };
        }(),
  ];

  static String? _stepNote(Map<String, dynamic> step) {
    final zone = (step['zoneNumber'] as num?)?.toInt();
    final key = (step['targetType'] as Map?)?['workoutTargetTypeKey'];
    final one = step['targetValueOne'], two = step['targetValueTwo'];
    final parts = <String>[
      if (zone != null && zone >= 1) 'Z$zone',
      if (key == 'heart.rate.zone' && one is num && two is num)
        '${one.round()}–${two.round()} bpm',
      if (key == 'power.zone' && one is num && two is num)
        '${one.round()}–${two.round()} W',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// The comment on the Garmin workout: the session's notes, then everything
  /// the athlete needs to carry it out, so nothing depends on reading the
  /// targets from the watch screen.
  String _garminDescription(
    TrainingSession s,
    List<Map<String, dynamic>> steps, {
    required bool power,
    RaceGoal? goal,
  }) {
    String label(Map<String, dynamic> step) {
      final type = (step['stepType'] as Map?)?['stepTypeKey'];
      return switch (type) {
        'warmup' => 'Warm-up',
        'cooldown' => 'Cool-down',
        'recovery' => 'Recovery',
        'rest' => 'Rest',
        'interval' => 'Interval',
        _ => 'Step',
      };
    }

    String length(Map<String, dynamic> step) {
      final condition = (step['endCondition'] as Map?)?['conditionTypeKey'];
      final value = (step['endConditionValue'] as num?)?.toDouble();
      if (value == null || value <= 0) return 'Until lap press';
      return condition == 'distance'
          ? (value >= 1000
                ? '${(value / 1000).toStringAsFixed(1)} km'
                : '${value.round()} m')
          : formatBlockDuration(value);
    }

    final lines = <String>[];
    void walk(List<Map<String, dynamic>> items, String indent) {
      for (final step in items) {
        if (step['workoutSteps'] is List) {
          final n = (step['numberOfIterations'] as num?)?.toInt() ?? 1;
          lines.add('$indent$n× repeat');
          walk(
            (step['workoutSteps'] as List).cast<Map<String, dynamic>>(),
            '$indent  ',
          );
          continue;
        }
        final note = _stepNote(step);
        lines.add(
          '$indent${length(step)} ${label(step)}${note == null ? '' : ' · $note'}',
        );
      }
    }

    walk(steps, '');
    final total = WorkoutSemantics.of(jsonEncode(steps), sport: s.sport);
    final notes = s.sessionNotes?.trim();
    final text = [
      if (notes != null && notes.isNotEmpty) ...[notes, ''],
      power
          ? 'TARGETS: power where it is set, with heart rate as the guide.'
          : 'TARGETS: heart rate in your zones. No power or pace targets.',
      ...lines,
      'Total ${total.totalMinutes} min${total.isExact ? '' : ' (partly estimated)'}.',
      ...?_goalLines(s, goal),
    ].join('\n');
    // The description has a length limit; keep the targets, shorten the rest.
    return text.length <= 1500 ? text : '${text.substring(0, 1497)}...';
  }

  static List<int> _zonesFromJson(String? json) {
    if (json == null) return const [];
    try {
      return (jsonDecode(json) as List).map((e) => (e as num).round()).toList();
    } catch (_) {
      return const [];
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
int stepTypeIndex(String type) => _stepTypeIndex[type] ?? 2;
