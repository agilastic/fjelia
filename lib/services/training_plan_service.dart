import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

import '../api/garmin_client.dart';
import '../db/database.dart';
import 'hr_zone_model.dart';
import '../providers/training_load_provider.dart';
import '../utils/log.dart';

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
    this.weekday,
  );

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

/// Periodisation: base → build → peak → taper, with every [cycle]th week of
/// base and build an unloading week.
String _phase(int week, int totalWeeks, {int cycle = 4}) {
  if (totalWeeks <= 2) return week == totalWeeks - 1 ? 'taper' : 'base';
  final taper = totalWeeks >= 8 ? 2 : 1;
  final peak = math.max(1, (totalWeeks * 0.2).round());
  final build = math.max(1, (totalWeeks * 0.35).round());
  final remaining = totalWeeks - week;
  String phase;
  if (remaining <= taper) {
    phase = 'taper';
  } else if (remaining <= taper + peak) {
    phase = 'peak';
  } else if (remaining <= taper + peak + build) {
    phase = 'build';
  } else {
    phase = 'base';
  }
  if ((phase == 'base' || phase == 'build') && week % cycle == cycle - 1) {
    return 'recovery';
  }
  return phase;
}

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

int _maxLongRunMin(String category) => switch (category) {
  'sprint' => 45,
  '5k' => 60,
  '10k' => 90,
  'half' => 120,
  'marathon' => 180,
  'ultra' => 240,
  _ => 180,
};

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
      final sum = [
        for (var i = w; i < w + 4; i++) weekMinutes[i] ?? 0,
      ].fold<double>(0, (a, b) => a + b);
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
    required this.tier,
    this.hrvRatio = 1.0,
    this.sleepScore,
    this.weeklyTss = 0,
  });

  final double ctl;
  final double tsb;
  final double? vo2max;
  final int? lt2Bpm;
  final int? lt1Bpm;

  /// Upper HR bound of zones 1–4 (zone 5 is open-ended).
  final List<int> hrZones;
  final String tier;
  final double hrvRatio;
  final int? sleepScore;
  final double weeklyTss;

  bool get isFatigued => tsb < -20;

  _AthleteFitnessSnapshot withHrZones(List<int> zones) =>
      _AthleteFitnessSnapshot(
        ctl: ctl,
        tsb: tsb,
        vo2max: vo2max,
        lt2Bpm: lt2Bpm,
        lt1Bpm: lt1Bpm,
        hrZones: zones,
        tier: tier,
        hrvRatio: hrvRatio,
        sleepScore: sleepScore,
        weeklyTss: weeklyTss,
      );

  ({int? low, int? high}) hrRangeForZone(int zone) {
    if (hrZones.length < 4 || zone < 1) return (low: null, high: null);
    final z = zone.clamp(1, 5);
    final low = z == 1 ? null : hrZones[z - 2];
    final high = z == 5 ? null : hrZones[z - 1];
    return (low: low, high: high);
  }
}

class TrainingPlanService {
  TrainingPlanService(this._db, this._garmin);

  final AppDatabase _db;
  final GarminClient _garmin;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
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
    final zonesJson = cycling
        ? thresholds?.bikeHrZonesJson
        : swim
        ? thresholds?.swimHrZonesJson
        : thresholds?.runHrZonesJson;
    if (zonesJson != null) {
      try {
        // Stored as five zone floors; targets need the upper bounds.
        hrZones = zoneUpperBounds(
          (jsonDecode(zonesJson) as List)
              .map((e) => (e as num).round())
              .toList(),
        );
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
      tier: tier,
      hrvRatio: hrvRatio,
      sleepScore: readiness?.sleepScore,
      weeklyTss: weeklyTss,
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

    final lo = (durationMin * 0.6).floor();
    final hi = (durationMin * 1.4).ceil();
    final byDuration = pool
        .where(
          (t) => t.estimatedDurationMin >= lo && t.estimatedDurationMin <= hi,
        )
        .toList();
    if (byDuration.isNotEmpty) pool = byDuration;

    return pool[seed % pool.length];
  }

  /// Fills FTP-relative and zone targets so the steps are concrete for Garmin.
  Map<String, dynamic> _resolveStep(
    Map<String, dynamic> step,
    int? ftp,
    _AthleteFitnessSnapshot fitness,
  ) {
    if (step['type'] == 'RepeatGroupDTO') {
      final iterations =
          (step['numberOfIterations'] as num?)?.toInt() ??
          (step['endConditionValue'] as num?)?.toInt() ??
          1;
      final inner =
          (step['workoutSteps'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((s) => _resolveStep(s, ftp, fitness))
              .toList() ??
          <Map<String, dynamic>>[];
      return Map<String, dynamic>.of(step)
        ..['numberOfIterations'] = iterations
        ..['workoutSteps'] = inner;
    }

    final out = Map<String, dynamic>.from(step);
    if (ftp != null &&
        (out.containsKey('ftpFraction') || out.containsKey('ftpLow'))) {
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
    } else if (out.containsKey('ftpFraction') || out.containsKey('ftpLow')) {
      // No FTP: use the step's heart-rate zone, except for very short
      // efforts where a heart-rate target is meaningless.
      final zone = (out['zoneNumber'] as num?)?.toInt();
      final seconds = (out['endConditionValue'] as num?)?.toInt() ?? 0;
      final useHr = zone != null && zone >= 1 && zone <= 5 && seconds >= 45;
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
    out
      ..remove('ftpFraction')
      ..remove('ftpLow')
      ..remove('ftpHigh');

    final target = out['targetType'] as Map?;
    if (target?['workoutTargetTypeKey'] == 'heart.rate.zone') {
      final zone = (out['zoneNumber'] as num?)?.toInt();
      if (zone != null) {
        final r = fitness.hrRangeForZone(zone);
        if (r.low != null || r.high != null) {
          out['targetValueOne'] = (r.low ?? (r.high! - 15)).toDouble();
          out['targetValueTwo'] = (r.high ?? (r.low! + 15)).toDouble();
        }
      }
    }
    return out;
  }

  String _resolveStepsJson(
    String stepsJson,
    int? ftp,
    _AthleteFitnessSnapshot fitness,
  ) {
    final steps = (jsonDecode(stepsJson) as List).cast<Map<String, dynamic>>();
    return jsonEncode(steps.map((s) => _resolveStep(s, ftp, fitness)).toList());
  }

  double _trimpFromSteps(String stepsJson) {
    try {
      final steps = (jsonDecode(stepsJson) as List)
          .cast<Map<String, dynamic>>();
      return _trimpFromStepList(steps, 1);
    } catch (_) {
      return 0.0;
    }
  }

  double _trimpFromStepList(List<Map<String, dynamic>> steps, int repeat) {
    var total = 0.0;
    for (final s in steps) {
      if (s['type'] == 'RepeatGroupDTO') {
        final n = (s['numberOfIterations'] as num?)?.toInt() ?? 1;
        final inner =
            (s['workoutSteps'] as List?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
        total += _trimpFromStepList(inner, n);
        continue;
      }
      final seconds = (s['endConditionValue'] as num?)?.toDouble() ?? 0.0;
      final zone = ((s['zoneNumber'] as num?)?.toInt() ?? 1).clamp(1, 5);
      total += seconds / 60.0 * repeat * _zoneWeights[zone - 1];
    }
    return total;
  }

  int _dominantZoneFromSteps(String stepsJson, int fallback) {
    final minutes = <int, double>{};
    void collect(List<Map<String, dynamic>> steps, int repeat) {
      for (final s in steps) {
        if (s['type'] == 'RepeatGroupDTO') {
          collect(
            (s['workoutSteps'] as List?)?.cast<Map<String, dynamic>>() ??
                const [],
            repeat * ((s['numberOfIterations'] as num?)?.toInt() ?? 1),
          );
          continue;
        }
        final type = (s['stepType'] as Map?)?['stepTypeKey'];
        if (type == 'warmup' || type == 'cooldown') continue;
        final zone = (s['zoneNumber'] as num?)?.toInt();
        if (zone == null || zone == 0) continue;
        final secs = (s['endConditionValue'] as num?)?.toDouble() ?? 0;
        minutes[zone] = (minutes[zone] ?? 0) + secs * repeat;
      }
    }

    try {
      collect((jsonDecode(stepsJson) as List).cast<Map<String, dynamic>>(), 1);
    } catch (_) {}
    if (minutes.isEmpty) return fallback;
    return minutes.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
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
    int daysPerWeek = 5,
    List<int> restDays = const [7],
    List<int> strengthDays = const [3],
    double hoursPerWeek = 8.0,
    int maxSessionsPerDay = 1,
    List<String> gadSports = const [],
    String? coachId,
    String? existingPlanId,
    PlanAthleteProfile athlete = const PlanAthleteProfile(),
  }) async {
    final today = _day(DateTime.now());
    final rotation = _gadSportRotation(gadSports.isEmpty ? [sport] : gadSports);
    final mainSport = _supportedSports.contains(sport) ? sport : rotation.first;
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
      DateTime.now(),
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

    final end = raceDate.isAfter(today) ? _day(raceDate) : _addDays(today, 28);
    final weeks =
        (DateTime.utc(end.year, end.month, end.day)
                    .difference(
                      DateTime.utc(today.year, today.month, today.day),
                    )
                    .inDays /
                7)
            .ceil()
            .clamp(1, 104);

    // Plan row.
    String planId;
    if (existingPlanId != null) {
      planId = existingPlanId;
      await _deleteGarminWorkoutsForAthlete(athleteId, planId);
      await (_db.delete(_db.trainingSessions)..where(
            (t) =>
                t.planId.equals(planId) &
                t.sessionDate.isBiggerOrEqualValue(today) &
                (t.status.equals('planned') | t.status.equals('adapted')),
          ))
          .go();
      await (_db.update(
        _db.trainingPlans,
      )..where((t) => t.id.equals(planId))).write(
        TrainingPlansCompanion(
          startDate: Value(today),
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

    final templates = await _db.select(_db.workoutTemplates).get();
    final category = _distanceCategory(raceDistanceM);
    final baseSlots = _weekTemplates[mainSport] ?? _weekTemplates['running']!;
    final targetWeeklyMin = hoursPerWeek * 60;
    final baseWeeklyTss = math.max(fitness.weeklyTss, 50.0);
    final readiness = _readinessFactor(fitness);
    final raceDay = _day(raceDate);

    var sessionNumber = 0;
    var gadIndex = 0;

    for (var w = 0; w < weeks; w++) {
      final weekStart = _addDays(today, w * 7);
      var phase = (prependRecovery && w == 0)
          ? 'recovery'
          : _phase(w, weeks, cycle: athlete.recoveryCycle);
      final weeksIntoBlock = w % athlete.recoveryCycle;
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
      if (phase == 'recovery' || phase == 'taper') weeklyBudgetMin *= 0.7;
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
      // Strength slots go on the athlete's strength days.
      final strength = slots.where((s) => s.sport == 'strength').toList();
      slots.removeWhere((s) => s.sport == 'strength');
      for (var i = 0; i < strength.length && i < strengthDays.length; i++) {
        slots.add(strength[i].copyWith(weekday: strengthDays[i]));
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

      // Assign each slot to a day offset in the week.
      final used = <int, int>{};
      final usedSports = <int, Set<String>>{};
      bool isPreRaceRest(DateTime d) => d == _addDays(raceDay, -1);

      int? bestOffset(_SessionSlot s) {
        final candidates = <int>[];
        for (var off = 0; off < 7; off++) {
          final date = _addDays(weekStart, off);
          if (date.isAfter(raceDay)) continue;
          if (restDays.contains(date.weekday)) continue;
          if (isPreRaceRest(date)) continue;
          final count = used[off] ?? 0;
          if (count >= maxSessionsPerDay) continue;
          if (count > 0 && (usedSports[off]?.contains(s.sport) ?? false)) {
            continue;
          }
          candidates.add(off);
        }
        if (candidates.isEmpty) return null;
        if (s.weekday == 0) {
          candidates.sort((a, b) => (used[a] ?? 0).compareTo(used[b] ?? 0));
          return candidates.first;
        }
        int dist(int off) {
          final wd = _addDays(weekStart, off).weekday;
          final d = (wd - s.weekday).abs();
          return math.min(d, 7 - d) * 10 + (used[off] ?? 0);
        }

        candidates.sort((a, b) => dist(a).compareTo(dist(b)));
        return candidates.first;
      }

      var weekPlannedTrimp = 0;
      var weekPlannedMin = 0;
      var weekSessions = 0;

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

        var duration = _ctlScaledDuration(
          _baseDuration(slot.sessionType),
          slot.sessionType,
          fitness.tier,
          fitness.ctl,
        );
        if (phase == 'taper') duration = (duration * 0.7).round();
        if (phase == 'recovery') duration = (duration * 0.7).round();
        if (date == raceDay) duration = (duration * 0.5).round();
        if (slot.sessionType == 'long' && _footSports.contains(slot.sport)) {
          duration = math.min(duration, _maxLongRunMin(category));
        }
        if (slot.sessionType == 'long' && phase == 'peak') {
          duration = (duration * 1.4).round();
          if (_footSports.contains(slot.sport)) {
            duration = math.min(duration, _maxLongRunMin(category));
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
        duration = duration.clamp(20, 240);

        final template = _pickTemplateFromCache(
          templates,
          slot.sport,
          slot.sessionType,
          slot.subType,
          phase,
          duration,
          w + sessionNumber,
        );
        final stepsJson = template == null
            ? null
            : _resolveStepsJson(template.stepsJson, ftp, fitness);

        var trimp = stepsJson == null ? 0.0 : _trimpFromSteps(stepsJson);
        if (trimp <= 0) {
          trimp = duration * _zoneWeights[(slot.zone - 1).clamp(0, 4)];
        } else if (template != null && template.estimatedDurationMin > 0) {
          trimp *= duration / template.estimatedDurationMin;
        }
        if (weekPlannedTrimp + trimp > weekTssCap &&
            slot.sessionType == 'key' &&
            phase != 'peak') {
          trimp = math.max(0, weekTssCap - weekPlannedTrimp).toDouble();
        }

        final zone = stepsJson == null
            ? slot.zone
            : _dominantZoneFromSteps(stepsJson, slot.zone);
        final hr = fitness.hrRangeForZone(zone);
        final hrJson = jsonEncode({
          'low': hr.low,
          'high': hr.high,
          'zone': zone,
          'lt2': fitness.lt2Bpm,
          'lt1': fitness.lt1Bpm,
        });

        String? paceJson;
        final pace = thresholds?.thresholdPaceMps;
        if ((slot.sport == 'running' || slot.sport == 'trail_running') &&
            pace != null &&
            pace > 0) {
          final z = _paceZones[zone.clamp(1, 5)]!;
          paceJson = jsonEncode({
            'low_sec_per_km': (1000 / (pace * z.hi)).round(),
            'high_sec_per_km': (1000 / (pace * z.lo)).round(),
            'zone': zone,
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
            : _extractWarmUpDescription(stepsJson);
        final title =
            template?.name ??
            '${slot.sessionType[0].toUpperCase()}${slot.sessionType.substring(1)} '
                '${slot.sport.replaceAll('_', ' ')}';

        sessionNumber++;
        weekSessions++;
        weekPlannedTrimp += trimp.round();
        weekPlannedMin += duration;
        used[off] = (used[off] ?? 0) + 1;
        usedSports.putIfAbsent(off, () => <String>{}).add(slot.sport);

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
                weekNumber: w + 1,
                sport: slot.sport,
                sessionType: slot.sessionType,
                subType: Value(slot.subType),
                phase: phase,
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
                sessionLevel: _sessionLevel(slot.sessionType, zone, phase),
                status: const Value('planned'),
              ),
            );
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
              weekNumber: w + 1,
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

    log(
      '[Plan] generatePlan done — planId=$planId sessions=$sessionNumber '
      'weeks=$weeks days=$daysPerWeek maxPerDay=$maxSessionsPerDay '
      'GAD rotation=$rotation race=$category sport=$mainSport',
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
  }) async {
    final plan = await (_db.select(
      _db.trainingPlans,
    )..where((t) => t.id.equals(planId))).getSingleOrNull();
    if (plan == null) return;
    final today = _day(DateTime.now());
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

    final goal =
        await (_db.select(_db.raceGoals)
              ..where(
                (t) =>
                    t.athleteId.equals(plan.athleteId) &
                    t.raceDate.isBiggerOrEqualValue(today),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.raceDate)])
              ..limit(1))
            .getSingleOrNull();
    final rotation = _gadSportRotation(preferredSports);

    await generatePlan(
      athleteId: plan.athleteId,
      raceGoalId: goal?.id ?? plan.raceGoalId,
      raceDate: goal?.raceDate ?? plan.endDate,
      sport: goal?.primarySport ?? rotation.first,
      raceDistanceM: goal?.distanceM,
      daysPerWeek: daysPerWeek,
      restDays: restDays,
      strengthDays: strengthDays,
      hoursPerWeek: hoursPerWeek,
      maxSessionsPerDay: maxSessionsPerDay,
      gadSports: preferredSports,
      coachId: plan.coachId,
      existingPlanId: planId,
      athlete: athlete,
    );
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

  // ---------------------------------------------------------------------------
  // Garmin
  // ---------------------------------------------------------------------------

  static String _garminSportName(String sport) => switch (sport) {
    'running' || 'trail_running' => 'running',
    'cycling_road' || 'cycling_gravel' || 'cycling_mtb' => 'cycling',
    'swimming' => 'swimming',
    'strength' || 'pilates' || 'yoga' || 'stretching' => 'strength',
    'indoor_rowing' => 'cardio',
    _ => 'running',
  };

  /// Pushes all upcoming sessions that aren't on Garmin yet, adopting
  /// identical workouts already on the Garmin calendar.
  Future<void> pushPlanToGarmin(String athleteId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessions =
        await (_db.select(_db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals(athleteId) &
                    t.sessionDate.isBiggerOrEqualValue(today) &
                    t.garminWorkoutId.isNull() &
                    t.status.equals('planned'),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
            .get();

    var existing = <String, String>{};
    try {
      existing = await _garmin.calendarWorkoutsByTitleDate();
    } catch (e) {
      log('[Planner] Could not fetch Garmin calendar for dedup: $e');
    }

    for (final s in sessions) {
      final key =
          '${s.title}|${s.sessionDate.toIso8601String().substring(0, 10)}';
      final adopted = existing[key];
      if (adopted != null) {
        log(
          '[Planner] Adopting existing Garmin workout $adopted for '
          '"${s.title}" on ${s.sessionDate}',
        );
        await (_db.update(_db.trainingSessions)
              ..where((t) => t.id.equals(s.id)))
            .write(TrainingSessionsCompanion(garminWorkoutId: Value(adopted)));
        continue;
      }
      try {
        await pushToGarmin(s.id);
      } catch (e) {
        log('[Planner] Garmin push failed for ${s.id}: $e');
      }
    }
  }

  /// Creates the session's workout on Garmin and schedules it on its date.
  Future<void> pushToGarmin(String sessionId) async {
    final s = await (_db.select(
      _db.trainingSessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (s == null) throw StateError('Workout no longer exists.');
    if (!['planned', 'adapted'].contains(s.status)) {
      throw StateError('Only planned workouts can be pushed.');
    }
    if (s.garminWorkoutId != null) {
      if (s.garminAlternativeId != null) {
        await _garmin.unscheduleWorkout(s.garminAlternativeId!);
      }
      final schedule = await _garmin.scheduleWorkout(
        s.garminWorkoutId!,
        s.sessionDate,
      );
      await (_db.update(
        _db.trainingSessions,
      )..where((t) => t.id.equals(s.id))).write(
        TrainingSessionsCompanion(
          garminAlternativeId: Value(schedule),
          dateModified: Value(DateTime.now()),
        ),
      );
      return;
    }
    if (s.stepsJson == null) {
      throw StateError('No workout structure is available to push.');
    }
    final thresholds = await (_db.select(
      _db.athleteThresholds,
    )..where((t) => t.athleteId.equals(s.athleteId))).getSingleOrNull();
    final fitness = _AthleteFitnessSnapshot(
      ctl: 0,
      tsb: 0,
      tier: 'intermediate',
      hrZones: _zonesFromJson(
        s.sport.contains('swim')
            ? thresholds?.swimHrZonesJson
            : s.sport.contains('cycl')
            ? thresholds?.bikeHrZonesJson
            : thresholds?.runHrZonesJson,
      ),
    );
    final ftp = thresholds?.ftpWatts;
    final steps = (jsonDecode(s.stepsJson!) as List)
        .cast<Map<String, dynamic>>()
        .map((st) => _resolveStep(st, ftp, fitness))
        .toList()
        .asMap()
        .entries
        .map((e) => {...e.value, 'stepOrder': e.key + 1})
        .toList();

    final workoutId = await _garmin.createWorkout(
      s.title,
      _garminSportName(s.sport),
      steps,
      description: s.sessionNotes,
    );
    // Save the definition before scheduling so a retry cannot create duplicates.
    await (_db.update(_db.trainingSessions)..where((t) => t.id.equals(s.id)))
        .write(TrainingSessionsCompanion(garminWorkoutId: Value(workoutId)));
    final scheduleId = await _garmin.scheduleWorkout(workoutId, s.sessionDate);
    await (_db.update(
      _db.trainingSessions,
    )..where((t) => t.id.equals(s.id))).write(
      TrainingSessionsCompanion(
        garminWorkoutId: Value(workoutId),
        garminAlternativeId: Value(scheduleId),
        dateModified: Value(DateTime.now()),
      ),
    );
  }

  static List<int> _zonesFromJson(String? json) {
    if (json == null) return const [];
    try {
      return (jsonDecode(json) as List).map((e) => (e as num).round()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _deleteGarminWorkoutsForAthlete(
    String athleteId,
    String planId,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessions =
        await (_db.select(_db.trainingSessions)..where(
              (t) =>
                  t.planId.equals(planId) &
                  t.garminWorkoutId.isNotNull() &
                  (t.status.equals('planned') | t.status.equals('adapted')) &
                  t.sessionDate.isBiggerOrEqualValue(today),
            ))
            .get();
    for (final s in sessions) {
      try {
        await _garmin.deleteWorkout(
          s.garminWorkoutId!,
          scheduleId: s.garminAlternativeId,
        );
        log(
          '[Plan] deleted Garmin workout ${s.garminWorkoutId} '
          'for session ${s.id}',
        );
      } catch (e) {
        log('[Plan] Garmin delete failed for ${s.garminWorkoutId}: $e');
      }
    }
  }

  /// Removes every planned workout from Garmin (calendar and library) and
  /// deletes the local plans.
  Future<void> deleteAllPlannedWorkouts() async {
    try {
      final calendar = await _garmin.listCalendarWorkouts();
      log(
        '[Plan] deleteAllPlannedWorkouts: ${calendar.length} '
        'calendar workouts to delete',
      );
      for (final c in calendar) {
        try {
          await _garmin.deleteWorkout(c.workoutId, scheduleId: c.scheduleId);
        } catch (e) {
          log(
            '[Plan] Garmin delete failed for wid=${c.workoutId} '
            'sid=${c.scheduleId}: $e',
          );
        }
      }
    } catch (e) {
      log('[Plan] listCalendarWorkouts failed: $e');
    }
    try {
      final ids = await _garmin.listWorkoutIds();
      log(
        '[Plan] deleteAllPlannedWorkouts: ${ids.length} '
        'workout definitions to delete',
      );
      for (final id in ids) {
        try {
          await _garmin.deleteWorkout(id);
        } catch (e) {
          log('[Plan] Garmin library delete failed for $id: $e');
        }
      }
    } catch (e) {
      log('[Plan] listWorkoutIds failed: $e');
    }
    await (_db.delete(
      _db.trainingSessions,
    )..where((t) => t.athleteId.equals('self'))).go();
    await (_db.delete(
      _db.trainingPlans,
    )..where((t) => t.athleteId.equals('self'))).go();
    log('[Plan] deleteAllPlannedWorkouts done for self');
  }
}

/// Exposed for the planner UI's step legend ordering.
int stepTypeIndex(String type) => _stepTypeIndex[type] ?? 2;
