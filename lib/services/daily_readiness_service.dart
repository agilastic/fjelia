import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

enum ReadinessLevel { green, yellow, red }

enum TrainingSeverity { normal, tierDown, rest }

class TrainingSeverityResult {
  const TrainingSeverityResult(this.severity, [this.reason]);

  final TrainingSeverity severity;
  final String? reason;
}

/// Morning readiness: flags from today's physiology against personal
/// baselines, a 0–10 composite and the resulting traffic-light level.
class ReadinessResult {
  const ReadinessResult({
    required this.level,
    required this.flagCount,
    this.hrvLow = false,
    this.restingHrHigh = false,
    this.respirationHigh = false,
    this.stressHigh = false,
    this.spo2Low = false,
    this.sleepShort = false,
    this.remLow = false,
    this.deepLow = false,
    this.batteryLow = false,
    this.skinTempShift = false,
    this.fatigue = false,
    this.hrvToday,
    this.hrvBaseline,
    this.restingHrToday,
    this.restingHrBaseline,
    this.respirationRate,
    this.stressLevel,
    this.spo2,
    this.sleepScore,
    this.bodyBattery,
    this.skinTempDelta,
    this.tsb,
    this.compositeScore,
    this.severity = TrainingSeverity.normal,
  });

  final ReadinessLevel level;
  final int flagCount;
  final bool hrvLow;
  final bool restingHrHigh;
  final bool respirationHigh;
  final bool stressHigh;
  final bool spo2Low;
  final bool sleepShort;
  final bool remLow;
  final bool deepLow;
  final bool batteryLow;
  final bool skinTempShift;
  final bool fatigue;
  final double? hrvToday;
  final double? hrvBaseline;
  final double? restingHrToday;
  final double? restingHrBaseline;
  final double? respirationRate;
  final double? stressLevel;
  final double? spo2;
  final int? sleepScore;
  final int? bodyBattery;
  final double? skinTempDelta;
  final double? tsb;
  final double? compositeScore;
  final TrainingSeverity severity;

  String get adaptationReason {
    if (level == ReadinessLevel.green) return '';
    return [
      if (hrvLow) 'HRV lower than usual',
      if (restingHrHigh) 'resting HR elevated',
      if (respirationHigh) 'breathing rate elevated',
      if (stressHigh) 'stress load high',
      if (spo2Low) 'low blood oxygen',
      if (sleepShort) 'insufficient sleep',
      if (remLow) 'poor sleep quality (low REM)',
      if (deepLow) 'poor sleep quality (low deep)',
      if (batteryLow) 'body battery depleted',
      if (skinTempShift) 'skin temp shift',
      if (fatigue) 'accumulated fatigue',
    ].join(', ');
  }
}

class DailyReadinessService {
  DailyReadinessService(this._db);

  final AppDatabase _db;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<ReadinessResult> compute(DateTime date) async {
    final day = _day(date);
    final hrv7 = (await _db.getHrvRange(7))
        .where((r) => r.date.isBefore(day))
        .toList();
    final hrv30 = (await _db.getHrvRange(30))
        .where((r) => r.date.isBefore(day))
        .toList();
    final hrvToday = await _db.getHrvForDate(day);
    final sleep = await _db.getSleepForDate(day);
    final wellness = await _db.getWellnessForDate(day);
    final sleepHistory = (await _db.getSleepRange(67))
        .where((r) => r.date.isBefore(day))
        .toList();
    final tsb = await _computeTsb();

    // HRV drop vs 7-day baseline.
    final hrvBaseline = _mean(hrv7
        .where((r) => r.hrvLastNight != null)
        .map((r) => r.hrvLastNight!)
        .toList());
    final hrvNow = hrvToday?.hrvLastNight;
    double? hrvDrop;
    if (hrvBaseline != null && hrvNow != null && hrvBaseline > 0) {
      hrvDrop = (hrvBaseline - hrvNow) / hrvBaseline;
    }
    final hrvLow = hrvDrop != null && hrvDrop > 0.08;

    // Resting HR elevation.
    final rhrBaseline = _mean(hrv7
        .where((r) => r.restingHeartRate != null)
        .map((r) => r.restingHeartRate!.toDouble())
        .toList());
    final rhrNow = hrvToday?.restingHeartRate?.toDouble();
    final rhrElevation =
        rhrBaseline != null && rhrNow != null ? rhrNow - rhrBaseline : null;
    final rhrHigh = rhrElevation != null && rhrElevation > 5.0;

    // Breathing rate.
    final respBaseline = _mean(hrv7
        .where((r) => r.respirationRate != null)
        .map((r) => r.respirationRate!)
        .toList());
    final respNow = hrvToday?.respirationRate;
    final respHigh = respBaseline != null &&
        respNow != null &&
        respNow - respBaseline > 1.0;

    // Stress.
    final stressBaseline = _mean(hrv7
        .where((r) => r.stressLevel != null)
        .map((r) => r.stressLevel!)
        .toList());
    final stressNow = wellness?.averageStress ?? hrvToday?.stressLevel;
    final stressHigh = stressNow != null &&
        stressNow > 35.0 &&
        stressBaseline != null &&
        stressNow - stressBaseline > 8.0;

    // Blood oxygen.
    final spo2 = wellness?.avgSpo2 ?? hrvToday?.spo2;
    final spo2Low = spo2 != null && spo2 < 94.0;

    // Sleep quantity and architecture.
    final sleepScore = sleep?.sleepScore?.round();
    var sleepShort = false;
    var remLow = false;
    var deepLow = false;
    if (sleep != null && sleep.totalSleepSeconds > 0) {
      final need = sleep.sleepNeedSeconds;
      if (need != null && need > 0) {
        final ratio = (sleep.totalSleepSeconds / need).clamp(0.0, 1.5);
        sleepShort = ratio < 0.75 && (sleepScore == null || sleepScore < 70);
      }
      final valid =
          sleepHistory.where((s) => s.totalSleepSeconds > 0).toList();
      final remBase = _mean(valid
          .map((s) => s.remSleepSeconds / s.totalSleepSeconds)
          .toList());
      final deepBase = _mean(valid
          .map((s) => s.deepSleepSeconds / s.totalSleepSeconds)
          .toList());
      final remNow = sleep.remSleepSeconds / sleep.totalSleepSeconds;
      final deepNow = sleep.deepSleepSeconds / sleep.totalSleepSeconds;
      remLow = remBase != null && remBase > 0 && remNow < remBase * 0.5;
      deepLow = deepBase != null && deepBase > 0 && deepNow < deepBase * 0.5;
    }

    // Body battery.
    final battery = (wellness?.bodyBatteryHighest ??
            hrvToday?.bodyBattery ??
            hrvToday?.computedEnergie)
        ?.round();
    final batteryLow = battery != null && battery < 25;

    // Skin temperature.
    final skinTemp = hrvToday?.skinTempDelta ?? sleep?.avgOvernightHrv;
    final skinShift = hrvToday?.skinTempDelta != null &&
        hrvToday!.skinTempDelta!.abs() >= 0.5;

    final fatigue = tsb != null && tsb < -20.0;

    final flags = [
      hrvLow, rhrHigh, respHigh, stressHigh, spo2Low, sleepShort, remLow,
      deepLow, batteryLow, skinShift, fatigue,
    ];
    final flagCount = flags.where((f) => f).length;

    final composite = await computeCompositeScore(day);
    final severity = await computeSeverity(day);

    ReadinessLevel level;
    if (severity.severity == TrainingSeverity.rest || flagCount >= 3) {
      level = ReadinessLevel.red;
    } else if (severity.severity == TrainingSeverity.tierDown ||
        flagCount >= 1) {
      level = composite != null && composite >= 7.0 && flagCount == 1
          ? ReadinessLevel.green
          : ReadinessLevel.yellow;
    } else {
      level = ReadinessLevel.green;
    }

    final result = ReadinessResult(
      level: level,
      flagCount: flagCount,
      hrvLow: hrvLow,
      restingHrHigh: rhrHigh,
      respirationHigh: respHigh,
      stressHigh: stressHigh,
      spo2Low: spo2Low,
      sleepShort: sleepShort,
      remLow: remLow,
      deepLow: deepLow,
      batteryLow: batteryLow,
      skinTempShift: skinShift,
      fatigue: fatigue,
      hrvToday: hrvNow,
      hrvBaseline: hrvBaseline,
      restingHrToday: rhrNow,
      restingHrBaseline: rhrBaseline,
      respirationRate: respNow,
      stressLevel: stressNow,
      spo2: spo2,
      sleepScore: sleepScore,
      bodyBattery: battery,
      skinTempDelta: skinTemp,
      tsb: tsb,
      compositeScore: composite,
      severity: severity.severity,
    );

    await _db.into(_db.dailyReadinessRecords).insertOnConflictUpdate(
          DailyReadinessRecordsCompanion(
            id: Value(const Uuid().v4()),
            athleteId: const Value('self'),
            date: Value(day),
            hrv7dBaseline: Value(hrvBaseline),
            hrvToday: Value(hrvNow),
            hrvDropPct: Value(hrvDrop != null ? hrvDrop * 100 : null),
            restingHr7dBaseline: Value(rhrBaseline),
            restingHrToday: Value(rhrNow),
            restingHrElevation: Value(rhrElevation),
            sleepScore: Value(sleepScore),
            bodyBattery: Value(battery),
            skinTempDelta: Value(hrvToday?.skinTempDelta),
            tsb: Value(tsb),
            flagHrv: Value(hrvLow),
            flagHr: Value(rhrHigh),
            flagSleep: Value(sleepShort || remLow || deepLow || spo2Low),
            flagBattery: Value(batteryLow),
            flagSkinTemp: Value(skinShift),
            flagFatigue: Value(fatigue),
            flagCount: Value(flagCount),
            level: Value(level.name),
            computedAt: Value(DateTime.now()),
          ),
        );
    // Unused 30-day window kept for future baselines.
    hrv30.length;
    return result;
  }

  /// Severity for the training plan: from the composite and TSB.
  Future<TrainingSeverityResult> computeSeverity(DateTime date) async {
    final tsb = await _computeTsb();
    final composite = await computeCompositeScore(date);
    if (composite != null) {
      if (composite < 3.5) {
        return TrainingSeverityResult(TrainingSeverity.rest,
            'Readiness ${composite.toStringAsFixed(1)}/10 — rest recommended');
      }
      if (composite < 5.5) {
        return TrainingSeverityResult(TrainingSeverity.tierDown,
            'Readiness ${composite.toStringAsFixed(1)}/10 — reduced effort recommended');
      }
      if (tsb == null || tsb >= -20) {
        return TrainingSeverityResult(TrainingSeverity.normal,
            'Readiness ${composite.toStringAsFixed(1)}/10 — good to train');
      }
    }
    if (tsb != null && tsb < -20.0) {
      return TrainingSeverityResult(TrainingSeverity.tierDown,
          'TSB ${tsb.toStringAsFixed(1)} — accumulated fatigue');
    }
    if (tsb != null && tsb > 10.0) {
      return TrainingSeverityResult(TrainingSeverity.normal,
          'TSB ${tsb.toStringAsFixed(1)} — fresh and primed');
    }
    return const TrainingSeverityResult(TrainingSeverity.normal);
  }

  /// Weighted z-scores of nine markers, mapped to 0–10 (5 = personal norm).
  /// Null when less than 40 % of the weight has data.
  Future<double?> computeCompositeScore(DateTime date) async {
    final day = _day(date);
    final history = (await _db.getHrvRange(30))
        .where((r) => r.date.isBefore(day))
        .toList();
    final today = await _db.getHrvForDate(day);
    final sleep = await _db.getSleepForDate(day);
    final sleepHistory = (await _db.getSleepRange(30))
        .where((r) => r.date.isBefore(day))
        .toList();
    final wellness = await _db.getWellnessForDate(day);
    await _computeTsb();

    double? score(double? value, List<double> baseline, {bool invert = false}) {
      if (value == null || baseline.length < 3) return null;
      final z = _zscore(value, baseline);
      return (5 + (invert ? -z : z) * 2.5).clamp(0.0, 10.0);
    }

    List<double> pick(double? Function(HrvRecord) f) =>
        history.map(f).whereType<double>().toList();

    final hrv = score(today?.hrvLastNight, pick((r) => r.hrvLastNight));
    final rhr = score(today?.restingHeartRate?.toDouble(),
        pick((r) => r.restingHeartRate?.toDouble()),
        invert: true);
    final resp = score(today?.respirationRate, pick((r) => r.respirationRate),
        invert: true);
    final stress = score(
        wellness?.averageStress ?? today?.stressLevel, pick((r) => r.stressLevel),
        invert: true);
    final spo2Value = wellness?.avgSpo2 ?? today?.spo2;
    final spo2 = spo2Value == null
        ? null
        : ((spo2Value - 90) / 1.0).clamp(0.0, 10.0);
    final sleepScore = sleep?.sleepScore == null
        ? null
        : (sleep!.sleepScore! / 10).clamp(0.0, 10.0);
    final sleepDuration = sleep == null
        ? null
        : score(
            sleep.totalSleepSeconds.toDouble(),
            sleepHistory
                .where((s) => s.totalSleepSeconds > 0)
                .map((s) => s.totalSleepSeconds.toDouble())
                .toList(),
          );
    final battery = today?.bodyBattery == null
        ? null
        : (today!.bodyBattery! / 10).clamp(0.0, 10.0);
    final skin = today?.skinTempDelta == null
        ? null
        : (7 - today!.skinTempDelta!.abs() * 5).clamp(0.0, 10.0);

    final parts = <(double, double?)>[
      (0.25, hrv),
      (0.10, rhr),
      (0.10, resp),
      (0.08, stress),
      (0.05, spo2),
      (0.15, sleepScore),
      (0.15, sleepDuration),
      (0.10, battery),
      (0.02, skin),
    ];
    var sum = 0.0, weight = 0.0;
    for (final (w, v) in parts) {
      if (v == null) continue;
      sum += w * v;
      weight += w;
    }
    if (weight < 0.4) return null;
    return double.parse((sum / weight).toStringAsFixed(1));
  }

  double _zscore(double value, List<double> baseline) {
    final mean = _mean(baseline) ?? value;
    final sd = _stddev(baseline);
    if (sd == 0) return 0.0;
    return ((value - mean) / sd).clamp(-3.0, 3.0);
  }

  double _stddev(List<double> values) {
    if (values.length < 2) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    return math.sqrt(variance);
  }

  double? _mean(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Training-stress balance (CTL − ATL) over the daily strain history.
  Future<double?> _computeTsb() async {
    final scores = await _db.getAllScores();
    final load = <DateTime, double>{};
    for (final s in scores) {
      final v = s.strainScore;
      if (v == null) continue;
      load[DateTime(s.date.year, s.date.month, s.date.day)] = v;
    }
    if (load.isEmpty) return null;
    final days = load.keys.toList()..sort();
    var ctl = 0.0, atl = 0.0;
    const ctlAlpha = 2 / 43; // 42-day EWMA
    const atlAlpha = 0.25; // 7-day EWMA
    final today = _day(DateTime.now());
    for (var d = days.first;
        d.isBefore(today);
        d = DateTime(d.year, d.month, d.day + 1)) {
      final l = load[d] ?? 0.0;
      ctl += ctlAlpha * (l - ctl);
      atl += atlAlpha * (l - atl);
    }
    return ctl - atl;
  }
}
