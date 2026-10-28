import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/garmin_client.dart';
import '../db/database.dart' hide DailyBpSummary;
import '../models/garmin_data.dart';
import '../models/scores.dart';
import '../services/activity_decoder.dart';
import '../services/score_calculator.dart';
import '../utils/log.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'training_load_provider.dart';
import 'user_profile_provider.dart';
import 'week_start_provider.dart';
import '../utils/week.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The day shown on the dashboard.
final selectedDateProvider = StateProvider<DateTime>(
  (ref) => _day(DateTime.now()),
);

/// Bumped after every sync so data providers refetch.
final syncStatusListenerProvider = StateProvider<int>((ref) => 0);

/// Bumped after a full historic sync.
final fullSyncListenerProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Record → model conversion
// ---------------------------------------------------------------------------

WellnessData _wellnessFromRecord(WellnessRecord r) => WellnessData(
  date: r.date,
  steps: r.steps,
  activeCalories: r.activeCalories,
  totalCalories: r.totalCalories,
  averageStress: r.averageStress,
  bodyBatteryHighest: r.bodyBatteryHighest,
  bodyBatteryLowest: r.bodyBatteryLowest,
  floorsAscended: r.floorsAscended,
  intensityMinutes: r.intensityMinutes,
  fitnessAge: r.fitnessAge,
);

SleepData sleepFromRecord(SleepRecord r) {
  final phases = <SleepPhase>[];
  final json = r.phasesJson;
  if (json != null) {
    try {
      for (final p in (jsonDecode(json) as List).cast<Map<String, dynamic>>()) {
        phases.add(
          SleepPhase(
            DateTime.parse(p['s'] as String).toLocal(),
            DateTime.parse(p['e'] as String).toLocal(),
            p['p'] as String,
          ),
        );
      }
    } catch (_) {}
  }
  return SleepData(
    date: r.date,
    totalSleep: Duration(seconds: r.totalSleepSeconds),
    deepSleep: Duration(seconds: r.deepSleepSeconds),
    remSleep: Duration(seconds: r.remSleepSeconds),
    lightSleep: Duration(seconds: r.lightSleepSeconds),
    awakeSleep: Duration(seconds: r.awakeSleepSeconds),
    sleepScore: r.sleepScore,
    sleepStart: r.sleepStart,
    sleepEnd: r.sleepEnd,
    phases: phases,
    avgOvernightHrv: r.avgOvernightHrv,
    sleepNeedSeconds: r.sleepNeedSeconds,
  );
}

HrvData _hrvFromRecord(HrvRecord r) => HrvData(
  date: r.date,
  lastNightAvg: r.hrvLastNight,
  weeklyAvg: r.hrvWeeklyAvg,
  restingHeartRate: r.restingHeartRate,
  spo2: r.spo2,
  respirationRate: r.respirationRate,
  skinTempDelta: r.skinTempDelta,
);

// ---------------------------------------------------------------------------
// Simple per-day lookups
// ---------------------------------------------------------------------------

final hrvForDateProvider = FutureProvider.family<HrvRecord?, DateTime>((
  ref,
  date,
) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(databaseProvider).getHrvForDate(date);
});

final wellnessForDateProvider =
    FutureProvider.family<WellnessRecord?, DateTime>((ref, date) {
      ref.watch(syncStatusListenerProvider);
      return ref.watch(databaseProvider).getWellnessForDate(date);
    });

final bpForDateProvider = FutureProvider.family<List<BpMeasurement>, DateTime>((
  ref,
  date,
) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(databaseProvider).getBpForDate(date);
});

final thresholdHistoryProvider = FutureProvider<List<ThresholdRecord>>(
  (ref) => ref.watch(databaseProvider).getAllThresholdRecords(),
);

final wellness7dProvider = FutureProvider<List<WellnessRecord>>((ref) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(databaseProvider).getWellnessRange(14);
});

final wellnessRangeProvider = FutureProvider.family<List<WellnessRecord>, int>((
  ref,
  days,
) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(databaseProvider).getWellnessRange(days);
});

final sleep30dProvider = FutureProvider<List<SleepRecord>>((ref) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(databaseProvider).getSleepRange(30);
});

final hrv30dProvider = FutureProvider<List<HrvRecord>>((ref) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(databaseProvider).getHrvRange(30);
});

final hrvRangeProvider = FutureProvider.family<List<HrvRecord>, int>((
  ref,
  days,
) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(databaseProvider).getHrvRange(days);
});

/// Overnight HRV samples (ms) for [date], when the source provides them.
final hrvIntradayProvider =
    FutureProvider.family<List<({DateTime timestamp, int valueMs})>, DateTime>((
      ref,
      date,
    ) async {
      ref.watch(syncStatusListenerProvider);
      final hrv = await ref.watch(databaseProvider).getHrvForDate(date);
      final json = hrv?.hrvIntradayJson;
      if (json == null) return const [];
      try {
        final points =
            (jsonDecode(json) as List)
                .whereType<List>()
                .where((p) => p.length >= 2)
                .map(
                  (p) => (
                    timestamp: DateTime.fromMillisecondsSinceEpoch(
                      (p[0] as num).toInt(),
                    ),
                    valueMs: (p[1] as num).toInt(),
                  ),
                )
                .toList()
              ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return points;
      } catch (_) {
        return const [];
      }
    });

final sleepDataProvider = FutureProvider.family<SleepData?, DateTime>((
  ref,
  date,
) async {
  ref.watch(syncStatusListenerProvider);
  final record = await ref.watch(databaseProvider).getSleepForDate(date);
  return record == null ? null : sleepFromRecord(record);
});

// ---------------------------------------------------------------------------
// Blood pressure
// ---------------------------------------------------------------------------

/// Aggregates raw readings into hourly segments and a daily summary.
DailyBpSummary? buildBpSummaryFromRecords(
  DateTime date,
  List<BpMeasurement> readings,
) {
  if (readings.isEmpty) return null;
  final byHour = <int, List<BpMeasurement>>{};
  for (final m in readings) {
    byHour.putIfAbsent(m.measuredAt.toLocal().hour, () => []).add(m);
  }
  final segments = byHour.entries.map((e) {
    final list = e.value;
    final sys = list.map((m) => m.systolic);
    final first = list.first.measuredAt.toLocal();
    final night = e.key < 6 || e.key >= 22;
    return BpSegment(
      time: DateTime(first.year, first.month, first.day, e.key),
      systolic: (sys.reduce((a, b) => a + b) / list.length).round(),
      diastolic:
          (list.map((m) => m.diastolic).reduce((a, b) => a + b) / list.length)
              .round(),
      heartRate:
          (list.map((m) => m.heartRate).reduce((a, b) => a + b) / list.length)
              .round(),
      maxSystolic: sys.reduce(math.max),
      minSystolic: sys.reduce(math.min),
      count: list.length,
      dayNightTag: night ? 'NIGHT' : 'DAY',
    );
  }).toList()..sort((a, b) => a.time.compareTo(b.time));

  final n = readings.length;
  double avg(int Function(BpMeasurement) f) =>
      readings.map(f).reduce((a, b) => a + b) / n;
  final sys = readings.map((m) => m.systolic);
  final dia = readings.map((m) => m.diastolic);
  final normal = readings
      .where((m) => m.systolic < 130 && m.diastolic < 85)
      .length;
  return DailyBpSummary(
    date: date,
    avgSystolic: avg((m) => m.systolic),
    avgDiastolic: avg((m) => m.diastolic),
    avgHeartRate: avg((m) => m.heartRate),
    maxSystolic: sys.reduce(math.max),
    minSystolic: sys.reduce(math.min),
    maxDiastolic: dia.reduce(math.max),
    minDiastolic: dia.reduce(math.min),
    count: n,
    normalBpPercent: normal / n * 100,
    segments: segments,
  );
}

/// Daily BP summary from stored readings; today's readings are refreshed
/// from Aktiia in the background.
/// Last background fetch per day, so a rebuild cannot trigger a request loop.
final _bpLastFetch = <DateTime, DateTime>{};

final bpSummaryForDateProvider =
    FutureProvider.family<DailyBpSummary?, DateTime>((ref, date) async {
      final readings = await ref.watch(bpForDateProvider(date).future);
      final today = _day(DateTime.now());
      if (!_day(date).isBefore(today)) {
        final aktiia = ref.read(aktiiaClientProvider);
        final last = _bpLastFetch[_day(date)];
        final throttled =
            last != null &&
            DateTime.now().difference(last) < const Duration(seconds: 30);
        if (!throttled && await aktiia.isLoggedIn) {
          _bpLastFetch[_day(date)] = DateTime.now();
          Future(() async {
            try {
              final from = _day(date);
              final fresh = await aktiia.getMeasurements(
                from,
                from.add(const Duration(days: 1)),
              );
              if (fresh.length > readings.length) {
                await ref
                    .read(databaseProvider)
                    .insertBpMeasurements(
                      fresh
                          .map(
                            (m) => BpMeasurementsCompanion.insert(
                              measuredAt: m.dateTime,
                              timezone: Value(m.timezone),
                              systolic: m.systolic,
                              diastolic: m.diastolic,
                              heartRate: m.heartRate,
                              measurementType: Value(m.measurementType),
                              dayNightTag: Value(m.dayNightTag),
                              isBedTime: Value(m.isBedTime),
                              isWakeUpTime: Value(m.isWakeUpTime),
                            ),
                          )
                          .toList(),
                    );
                ref.invalidate(bpForDateProvider(date));
              }
            } catch (_) {}
          });
        }
      }
      return buildBpSummaryFromRecords(date, readings);
    });

final aktiiasDailyBpProvider = FutureProvider.family<DailyBpSummary?, DateTime>(
  (ref, date) => ref.watch(bpSummaryForDateProvider(date).future),
);

final bpPeriodReadingsProvider =
    FutureProvider.family<
      List<BpMeasurement>,
      ({DateTime start, DateTime end})
    >((ref, range) {
      ref.watch(syncStatusListenerProvider);
      return ref.watch(databaseProvider).getBpInRange(range.start, range.end);
    });

/// Per-day summaries for the week starting [weekStart].
final bpWeekSummaryProvider =
    FutureProvider.family<List<DailyBpSummary>, DateTime>((
      ref,
      weekStart,
    ) async {
      ref.watch(syncStatusListenerProvider);
      final readings = await ref
          .watch(databaseProvider)
          .getBpForWeek(weekStart);
      final byDay = <DateTime, List<BpMeasurement>>{};
      for (final m in readings) {
        byDay.putIfAbsent(_day(m.measuredAt.toLocal()), () => []).add(m);
      }
      final days = byDay.keys.toList()..sort();
      return [for (final d in days) buildBpSummaryFromRecords(d, byDay[d]!)!];
    });

// ---------------------------------------------------------------------------
// Body battery
// ---------------------------------------------------------------------------

BodyBatteryReport? _bodyBatteryReportFromDb(DateTime date, String json) {
  final samples = <BodyBatterySample>[];
  try {
    for (final e in jsonDecode(json) as List) {
      if (e is! List || e.length < 2) continue;
      final v = (e[1] as num).toDouble();
      if (v < 0 || v > 100) continue;
      samples.add(
        BodyBatterySample(
          DateTime.fromMillisecondsSinceEpoch(
            (e[0] as num).toInt(),
            isUtc: true,
          ),
          v.round(),
        ),
      );
    }
  } catch (_) {
    return null;
  }
  if (samples.isEmpty) return null;
  samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  log(
    '[BB] _bodyBatteryReportFromDb: ${samples.length} samples, '
    'currentValue=${samples.last.value}',
  );
  return BodyBatteryReport(date: date, samples: samples);
}

/// Garmin Body Battery for [date]; stored JSON first, then the API, then a
/// single point from the computed Energie score.
final bodyBatteryReportProvider =
    FutureProvider.family<BodyBatteryReport?, DateTime>((ref, date) async {
      ref.watch(syncStatusListenerProvider);
      final db = ref.watch(databaseProvider);
      final wellness = await db.getWellnessForDate(date);
      log('[BB] bodyBatteryJson present: ${wellness?.bodyBatteryJson != null}');
      final stored = wellness?.bodyBatteryJson;
      if (stored != null) {
        final report = _bodyBatteryReportFromDb(date, stored);
        if (report != null) {
          return BodyBatteryReport(
            date: report.date,
            samples: report.samples,
            charged: wellness?.bodyBatteryCharged,
            drained: wellness?.bodyBatteryDrained,
          );
        }
      }

      final garmin = ref.read(garminClientProvider);
      if (await garmin.isLoggedIn) {
        try {
          final report = await garmin.getBodyBattery(date);
          if (report != null && report.samples.isNotEmpty) {
            final json = jsonEncode(
              report.samples
                  .map((s) => [s.timestamp.millisecondsSinceEpoch, s.value])
                  .toList(),
            );
            await db.upsertWellness(
              WellnessRecordsCompanion(
                date: Value(_day(date)),
                source: const Value('garmin_api'),
                bodyBatteryJson: Value(json),
                bodyBatteryCharged: Value(report.charged),
                bodyBatteryDrained: Value(report.drained),
              ),
            );
            return report;
          }
        } catch (_) {}
      }

      final hrv = await db.getHrvForDate(date);
      final energie = hrv?.computedEnergie;
      if (energie != null && energie > 0) {
        log('[BB] using computedEnergie=$energie for $date');
        final sleep = await db.getSleepForDate(date);
        final at = sleep?.sleepEnd ?? DateTime.now();
        return BodyBatteryReport(
          date: date,
          samples: [BodyBatterySample(at.toUtc(), energie.round())],
        );
      }
      return null;
    });

// ---------------------------------------------------------------------------
// Scores & training load
// ---------------------------------------------------------------------------

final dayScoresProvider = FutureProvider.family<DayScores, DateTime>((
  ref,
  date,
) async {
  final db = ref.watch(databaseProvider);
  ref.watch(syncStatusListenerProvider);
  final day = _day(date);

  final hrv = await ref.watch(hrvForDateProvider(day).future);
  var sleep = await db.getSleepForDate(day);
  final bp = await ref.watch(bpSummaryForDateProvider(day).future);
  final wellness = await ref.watch(wellnessForDateProvider(day).future);
  final activities = await db.getActivitiesForDate(day);
  // Before last night's sleep has synced, fall back to the previous night.
  if (sleep == null && day == _day(DateTime.now())) {
    sleep = await db.getSleepForDate(day.subtract(const Duration(days: 1)));
  }

  final profile = await ref.watch(userProfileProvider.future);
  final age = profile.age?.round() ?? 30;
  final yesterday = await db.getScoreForDate(
    day.subtract(const Duration(days: 1)),
  );
  final recentSleep = await db.getSleepRange(7);
  final debt = recentSleep.fold<double>(0, (sum, s) {
    final need = (s.sleepNeedSeconds ?? 8 * 3600) / 60;
    return sum + math.max(0, need - s.totalSleepSeconds / 60);
  });

  var scores = const ScoreCalculator().calculateAll(
    date: day,
    hrv: hrv == null ? null : _hrvFromRecord(hrv),
    sleep: sleep == null ? null : sleepFromRecord(sleep),
    bp: bp,
    wellness: wellness == null ? null : _wellnessFromRecord(wellness),
    activities: activities.map(decodeActivityRecord).toList(),
    previousLoad: yesterday?.strainScore ?? 0.0,
    accumulatedSleepDebtMinutes: debt,
    userAge: age,
  );

  // Prefer stored values for days synced from other sources.
  final stored = await db.getScoreForDate(day);
  if (stored != null) {
    final storedStrain = (stored.strainScore ?? 0).clamp(0.0, 2000.0);
    scores = DayScores(
      date: day,
      recovery:
          scores.recovery ??
          (stored.recoveryScore == null
              ? null
              : RecoveryScore(
                  score: stored.recoveryScore,
                  recommendation: stored.recommendation ?? 'rest',
                )),
      sleep:
          scores.sleep ??
          (stored.sleepScore == null
              ? null
              : SleepScore(
                  score: stored.sleepScore!,
                  duration: Duration.zero,
                  need: const Duration(hours: 8),
                  deepPercent: 0,
                  remPercent: 0,
                  efficiency: 0,
                )),
      strain: StrainScore(
        score: activities.isNotEmpty
            ? activities.fold<double>(0, (sum, a) => sum + effectiveLoad(a))
            : storedStrain,
        zones: scores.strain.zones,
      ),
      bloodPressure: scores.bloodPressure,
    );
  }
  if (stored == null) {
    scores = DayScores(
      date: scores.date,
      recovery: scores.recovery,
      sleep: scores.sleep,
      strain: StrainScore(
        score: activities.fold<double>(0, (sum, a) => sum + effectiveLoad(a)),
        zones: scores.strain.zones,
      ),
      bloodPressure: scores.bloodPressure,
    );
  }
  return scores;
});

/// Acute/chronic load (ATL 7-day, CTL 42-day EWMA) and the athlete's
/// typical daily range.
class TrainingLoadMetrics {
  const TrainingLoadMetrics({
    required this.ctl,
    required this.atl,
    required this.optimalLow,
    required this.optimalHigh,
    required this.peak,
  });

  final double ctl;
  final double atl;

  /// Productive daily-load band around the chronic load.
  final double optimalLow;
  final double optimalHigh;

  /// 90th percentile of daily load.
  final double peak;

  double get tsb => ctl - atl;
}

final trainingLoadProvider = FutureProvider<TrainingLoadMetrics>((ref) async {
  ref.watch(syncStatusListenerProvider);
  ref.watch(fullSyncListenerProvider);
  final history = await _readTrainingLoadHistory(ref.watch(databaseProvider));
  final latest = history.points.lastOrNull;
  if (latest == null) {
    return const TrainingLoadMetrics(
      ctl: 0,
      atl: 0,
      optimalLow: 0,
      optimalHigh: 0,
      peak: 0,
    );
  }
  final ctl = latest.ctl, atl = latest.atl;
  final sorted = history.daily.values.where((v) => v > 0).toList()..sort();
  final peak = sorted.isEmpty
      ? ctl * 1.1
      : sorted[((sorted.length - 1) * 0.9).round()];
  return TrainingLoadMetrics(
    ctl: ctl,
    atl: atl,
    optimalLow: ctl * 0.8,
    optimalHigh: (ctl * 1.1).clamp(ctl * 0.8, ctl * 2),
    peak: peak * 1.1,
  );
});

/// Highest single-day load ever recorded.
final peakLoadProvider = FutureProvider<double>((ref) async {
  ref.watch(syncStatusListenerProvider);
  final scores = await ref.read(databaseProvider).getAllScores();
  return scores.fold<double>(
    0,
    (m, s) => math.max(m, (s.strainScore ?? 0).clamp(0.0, 2000.0)),
  );
});

/// One day of the form chart.
class FormPoint {
  const FormPoint({
    required this.date,
    required this.ctl,
    required this.atl,
    required this.load,
    this.historyStart,
  });

  final DateTime date;
  final double ctl;
  final double atl;
  final double load;
  final DateTime? historyStart;

  /// Calendar days of available history, including rest days. Null for points
  /// supplied without initialization metadata (for example, imported series).
  int? get historyDays => historyStart == null
      ? null
      : DateTime.utc(date.year, date.month, date.day)
                .difference(
                  DateTime.utc(
                    historyStart!.year,
                    historyStart!.month,
                    historyStart!.day,
                  ),
                )
                .inDays +
            1;

  double get tsb => ctl - atl;
}

/// Initialize from the earliest usable load record, then process every local
/// calendar day through [through]. The visible chart range never resets the
/// calculation. Keep the existing smoothing coefficients used by Fjelia.
List<FormPoint> buildTrainingFormSeries({
  required Map<DateTime, double> dailyLoads,
  required DateTime through,
}) {
  final end = _day(through);
  final daily = <DateTime, double>{};
  // Ignore Unix-epoch placeholder dates while retaining all real imported
  // history. A sentinel row otherwise makes the chart claim to start in 1970.
  final earliestUsableDate = DateTime(1970, 1, 2);
  for (final entry in dailyLoads.entries) {
    final d = _day(entry.key);
    final load = entry.value;
    if (d.isBefore(earliestUsableDate) ||
        d.isAfter(end) ||
        !load.isFinite ||
        load < 0) {
      continue;
    }
    daily[d] = (daily[d] ?? 0) + load;
  }
  if (daily.isEmpty) return [];
  final start = (daily.keys.toList()..sort()).first;
  final span = DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  var ctl = 0.0, atl = 0.0;
  final points = <FormPoint>[];
  for (var i = 0; i <= span; i++) {
    final d = DateTime(start.year, start.month, start.day + i);
    final load = daily[d] ?? 0;
    ctl += (load - ctl) * (2 / 43);
    atl += (load - atl) * 0.25;
    points.add(
      FormPoint(date: d, ctl: ctl, atl: atl, load: load, historyStart: start),
    );
  }
  return points;
}

class _TrainingLoadHistory {
  const _TrainingLoadHistory(this.daily, this.points);
  final Map<DateTime, double> daily;
  final List<FormPoint> points;
}

/// Shared history for the chart and dashboard. Cache-only daily loads remain
/// available; actual activities replace the cache for their day.
Future<_TrainingLoadHistory> _readTrainingLoadHistory(AppDatabase db) async {
  final today = _day(DateTime.now());
  final daily = <DateTime, double>{};
  for (final score in await db.getAllScores()) {
    // Scores use UTC calendar keys, rather than activity timestamps.
    final d = _day(score.date.toUtc());
    final load = score.strainScore;
    if (d.isAfter(today) || load == null || !load.isFinite || load < 0) {
      continue;
    }
    daily[d] = load.clamp(0.0, 2000.0);
  }
  // Read all dates, but only the load inputs: GPS and sample arrays can be large.
  final t = db.activityRecords;
  final activities =
      await (db.selectOnly(t)
            ..addColumns([
              t.startDate,
              t.durationSeconds,
              t.trainingLoad,
              t.totalElevation,
              t.hrZonesJson,
              t.avgHeartRate,
            ])
            ..where(
              t.startDate.isSmallerThanValue(
                DateTime(today.year, today.month, today.day + 1),
              ),
            ))
          .get();
  final activityDaily = <DateTime, double>{};
  for (final activity in activities) {
    final d = _day(activity.read(t.startDate)!.toLocal());
    final load = effectiveLoadFromSummary(
      durationSeconds: activity.read(t.durationSeconds)!,
      recordedLoad: activity.read(t.trainingLoad),
      elevationMeters: activity.read(t.totalElevation),
      hrZonesJson: activity.read(t.hrZonesJson),
      averageHeartRate: activity.read(t.avgHeartRate),
    );
    if (!load.isFinite || load < 0) continue;
    activityDaily[d] = (activityDaily[d] ?? 0) + load;
  }
  daily.addAll(activityDaily);
  return _TrainingLoadHistory(
    daily,
    buildTrainingFormSeries(dailyLoads: daily, through: today),
  );
}

/// The daily CTL/ATL/TSB history through today, for code outside the
/// providers (the coach context).
Future<List<FormPoint>> readTrainingFormSeries(AppDatabase db) async =>
    (await _readTrainingLoadHistory(db)).points;

/// CTL/ATL/TSB from the first available load through today. The card independently
/// selects its display window (60 days by default), preserving all earlier load.
final trainingFormSeriesProvider = FutureProvider<List<FormPoint>>((ref) async {
  ref.watch(syncStatusListenerProvider);
  ref.watch(fullSyncListenerProvider);
  return (await _readTrainingLoadHistory(ref.watch(databaseProvider))).points;
});

/// Dashboard training-monitor card.
class TrainingMonitorSummary {
  const TrainingMonitorSummary({
    required this.dayLoad,
    required this.ctl,
    required this.atl,
    required this.optimalLow,
    required this.optimalHigh,
    this.vo2max,
    this.vo2maxCycling,
    required this.weekHours,
    required this.previousWeekHours,
    required this.weekKm,
    required this.previousWeekKm,
    required this.weekLoad,
  });

  final double dayLoad;
  final double ctl;
  final double atl;
  final double optimalLow;
  final double optimalHigh;
  final double? vo2max;
  final double? vo2maxCycling;
  final double weekHours;
  final double previousWeekHours;
  final double weekKm;
  final double previousWeekKm;
  final double weekLoad;

  double get tsb => ctl - atl;
}

final trainingMonitorProvider =
    FutureProvider.family<TrainingMonitorSummary, DateTime>((ref, date) async {
      ref.watch(syncStatusListenerProvider);
      ref.watch(fullSyncListenerProvider);
      final db = ref.watch(databaseProvider);
      final scores = await ref.watch(dayScoresProvider(date).future);
      final load = await ref.watch(trainingLoadProvider.future);

      double? vo2, vo2Bike;
      for (final w in (await db.getWellnessRange(30)).reversed) {
        vo2 ??= w.vo2max;
        vo2Bike ??= w.vo2maxCycling;
      }

      final day = _day(date);
      final monday = weekStartOf(
        day,
        mondayFirst: ref.watch(weekStartsOnMondayProvider),
      );
      final prevMonday = monday.subtract(const Duration(days: 7));
      final nextMonday = monday.add(const Duration(days: 7));
      final activities = await db.getActivitiesInRange(28);
      var weekSec = 0.0,
          prevSec = 0.0,
          weekM = 0.0,
          prevM = 0.0,
          weekLoad = 0.0;
      for (final a in activities) {
        final d = _day(a.startDate);
        if (!d.isBefore(monday) && d.isBefore(nextMonday)) {
          weekSec += a.durationSeconds;
          weekM += a.distanceMeters ?? 0;
          weekLoad += effectiveLoad(a);
        } else if (!d.isBefore(prevMonday) && d.isBefore(monday)) {
          prevSec += a.durationSeconds;
          prevM += a.distanceMeters ?? 0;
        }
      }

      return TrainingMonitorSummary(
        dayLoad: scores.strain.score,
        ctl: load.ctl,
        atl: load.atl,
        optimalLow: load.optimalLow,
        optimalHigh: load.optimalHigh,
        vo2max: vo2,
        vo2maxCycling: vo2Bike,
        weekHours: weekSec / 3600,
        previousWeekHours: prevSec / 3600,
        weekKm: weekM / 1000,
        previousWeekKm: prevM / 1000,
        weekLoad: weekLoad,
      );
    });

// ---------------------------------------------------------------------------
// Garmin plan & calendar
// ---------------------------------------------------------------------------

final trainingPlanMetaProvider = FutureProvider<TrainingPlanMeta?>((ref) async {
  ref.watch(syncStatusListenerProvider);
  final garmin = ref.read(garminClientProvider);
  if (!await garmin.isLoggedIn) return null;
  try {
    return await garmin.getTrainingPlanMeta();
  } catch (_) {
    return null;
  }
});

ScheduledWorkout scheduledWorkoutFromRecord(ScheduledWorkoutRecord r) {
  var steps = <WorkoutStep>[];
  final json = r.stepsJson;
  if (json != null) {
    try {
      steps = (jsonDecode(json) as List)
          .cast<Map<String, dynamic>>()
          .map(WorkoutStep.fromJson)
          .toList();
    } catch (_) {}
  }
  return ScheduledWorkout(
    workoutId: r.workoutId,
    scheduleId: r.scheduleId,
    trainingPlanId: r.trainingPlanId,
    name: r.name,
    sportType: r.sportType,
    scheduledDate: r.scheduledDate,
    estimatedDuration: r.estimatedDurationSeconds == null
        ? null
        : Duration(seconds: r.estimatedDurationSeconds!),
    estimatedDistanceMeters: r.estimatedDistanceMeters,
    description: r.description,
    itemType: r.itemType,
    seriesName: r.seriesName,
    steps: steps,
    userNote: r.userNote,
  );
}

final scheduledWorkoutsProvider = FutureProvider<List<ScheduledWorkout>>((
  ref,
) async {
  ref.watch(syncStatusListenerProvider);
  final rows = await ref.read(databaseProvider).getUpcomingWorkouts();
  return rows.map(scheduledWorkoutFromRecord).toList();
});

// ---------------------------------------------------------------------------
// Activity list (paginated)
// ---------------------------------------------------------------------------

class ActivityListState {
  const ActivityListState({
    this.activities = const [],
    this.isLoading = false,
    this.hasMore = true,
  });

  final List<GarminActivity> activities;
  final bool isLoading;
  final bool hasMore;

  ActivityListState copyWith({
    List<GarminActivity>? activities,
    bool? isLoading,
    bool? hasMore,
  }) => ActivityListState(
    activities: activities ?? this.activities,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
  );
}

final activityListProvider =
    StateNotifierProvider<ActivityListNotifier, ActivityListState>(
      (ref) => ActivityListNotifier(ref),
    );

class ActivityListNotifier extends StateNotifier<ActivityListState> {
  ActivityListNotifier(this._ref) : super(const ActivityListState()) {
    _loadFirst();
    _ref.listen<int>(syncStatusListenerProvider, (_, _) => refresh());
    _ref.listen<int>(fullSyncListenerProvider, (_, _) => refresh());
  }

  final Ref _ref;
  int _page = 0;
  bool _loadingMore = false;

  static const _pageSize = 20;

  Future<void> _loadFirst() async {
    state = state.copyWith(isLoading: true);
    final rows = await _ref.read(databaseProvider).getActivitiesPaginated(0);
    if (!mounted) return;
    _page = 0;
    state = state.copyWith(
      activities: rows.map(decodeActivityRecord).toList(),
      isLoading: false,
      hasMore: rows.length >= _pageSize,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, hasMore: true);
    await _loadFirst();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !state.hasMore) return;
    _loadingMore = true;
    state = state.copyWith(isLoading: true);
    try {
      final rows = await _ref
          .read(databaseProvider)
          .getActivitiesPaginated(_page + 1);
      if (!mounted) return;
      _page++;
      state = state.copyWith(
        activities: [...state.activities, ...rows.map(decodeActivityRecord)],
        isLoading: false,
        hasMore: rows.length >= _pageSize,
      );
    } finally {
      _loadingMore = false;
    }
  }
}
