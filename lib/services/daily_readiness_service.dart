import 'package:drift/drift.dart';
import 'package:fjelia_core/services/readiness.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

import '../db/database.dart';

export 'package:fjelia_core/services/readiness.dart'
    show
        ReadinessLevel,
        ReadinessResult,
        TrainingSeverity,
        TrainingSeverityResult;

/// Loads the day's data, runs [Readiness] from fjelia_core and stores the
/// result.
class DailyReadinessService {
  DailyReadinessService(this._db);

  final AppDatabase _db;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static ReadinessHrvDay _hrv(HrvRecord r) => ReadinessHrvDay(
    date: r.date,
    hrvLastNight: r.hrvLastNight,
    restingHeartRate: r.restingHeartRate,
    respirationRate: r.respirationRate,
    stressLevel: r.stressLevel,
    spo2: r.spo2,
    bodyBattery: r.bodyBattery,
    computedEnergie: r.computedEnergie,
    skinTempDelta: r.skinTempDelta,
  );

  static ReadinessSleepNight _sleep(SleepRecord r) => ReadinessSleepNight(
    date: r.date,
    totalSleepSeconds: r.totalSleepSeconds,
    remSleepSeconds: r.remSleepSeconds,
    deepSleepSeconds: r.deepSleepSeconds,
    sleepNeedSeconds: r.sleepNeedSeconds,
    sleepScore: r.sleepScore,
  );

  static ReadinessWellnessDay _wellness(WellnessRecord r) =>
      ReadinessWellnessDay(
        averageStress: r.averageStress,
        avgSpo2: r.avgSpo2,
        bodyBatteryHighest: r.bodyBatteryHighest,
      );

  Future<List<ReadinessHrvDay>> _hrvBefore(DateTime day, int days) async =>
      (await _db.getHrvRange(
        days,
      )).where((r) => r.date.isBefore(day)).map(_hrv).toList();

  Future<List<ReadinessSleepNight>> _sleepBefore(
    DateTime day,
    int days,
  ) async => (await _db.getSleepRange(
    days,
  )).where((r) => r.date.isBefore(day)).map(_sleep).toList();

  Future<ReadinessResult> compute(DateTime date) async {
    final day = _day(date);
    final hrv7 = await _hrvBefore(day, 7);
    final hrvRow = await _db.getHrvForDate(day);
    final sleepRow = await _db.getSleepForDate(day);
    final wellnessRow = await _db.getWellnessForDate(day);
    final sleepHistory = await _sleepBefore(day, 67);
    final tsb = await _computeTsb(day);
    final composite = await computeCompositeScore(day);
    final severity = await computeSeverity(day);

    final evaluation = Readiness.evaluate(
      hrv7: hrv7,
      hrvToday: hrvRow == null ? null : _hrv(hrvRow),
      sleep: sleepRow == null ? null : _sleep(sleepRow),
      wellness: wellnessRow == null ? null : _wellness(wellnessRow),
      sleepHistory: sleepHistory,
      tsb: tsb,
      composite: composite,
      severity: severity,
    );
    final result = evaluation.result;
    final hrvDrop = evaluation.hrvDrop;

    await _db
        .into(_db.dailyReadinessRecords)
        .insertOnConflictUpdate(
          DailyReadinessRecordsCompanion(
            id: Value(const Uuid().v4()),
            athleteId: const Value('self'),
            date: Value(day),
            hrv7dBaseline: Value(result.hrvBaseline),
            hrvToday: Value(result.hrvToday),
            hrvDropPct: Value(hrvDrop != null ? hrvDrop * 100 : null),
            restingHr7dBaseline: Value(result.restingHrBaseline),
            restingHrToday: Value(result.restingHrToday),
            restingHrElevation: Value(evaluation.restingHrElevation),
            sleepScore: Value(result.sleepScore),
            bodyBattery: Value(result.bodyBattery),
            skinTempDelta: Value(result.skinTempDelta),
            tsb: Value(tsb),
            flagHrv: Value(result.hrvLow),
            flagHr: Value(result.restingHrHigh),
            flagSleep: Value(
              result.sleepShort ||
                  result.remLow ||
                  result.deepLow ||
                  result.spo2Low,
            ),
            flagBattery: Value(result.batteryLow),
            flagSkinTemp: Value(result.skinTempShift),
            flagFatigue: Value(result.fatigue),
            flagCount: Value(result.flagCount),
            level: Value(result.level.name),
            computedAt: Value(DateTime.now()),
          ),
        );
    return result;
  }

  /// Severity for the training plan: from the composite and TSB.
  Future<TrainingSeverityResult> computeSeverity(DateTime date) async =>
      Readiness.severity(
        composite: await computeCompositeScore(date),
        tsb: await _computeTsb(date),
      );

  /// Weighted z-scores of nine markers, mapped to 0–10 (5 = personal norm).
  /// Null when less than 40 % of the weight has data.
  Future<double?> computeCompositeScore(DateTime date) async {
    final day = _day(date);
    final today = await _db.getHrvForDate(day);
    final sleep = await _db.getSleepForDate(day);
    final wellness = await _db.getWellnessForDate(day);
    return Readiness.compositeScore(
      history: await _hrvBefore(day, 30),
      today: today == null ? null : _hrv(today),
      sleep: sleep == null ? null : _sleep(sleep),
      sleepHistory: await _sleepBefore(day, 30),
      wellness: wellness == null ? null : _wellness(wellness),
    );
  }

  /// Form (CTL − ATL) at the start of [date], from the days before it only.
  @visibleForTesting
  Future<double?> tsbAsOf(DateTime date) => _computeTsb(date);

  Future<double?> _computeTsb([DateTime? asOf]) async {
    final scores = await _db.getAllScores();
    return Readiness.formBefore({
      for (final s in scores)
        if (s.strainScore != null) s.date: s.strainScore!,
    }, asOf ?? DateTime.now());
  }
}
