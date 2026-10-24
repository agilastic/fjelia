import 'dart:math' as math;

import 'package:fjelia_service_api/fjelia_service_api.dart';
import '../models/garmin_data.dart';
import '../models/scores.dart';

class ScoreCalculator {
  const ScoreCalculator();

  static const _zoneKeys = ['zone1', 'zone2', 'zone3', 'zone4', 'zone5'];
  static const _zoneWeights = [1.0, 1.1, 1.2, 3.1, 8.0];

  DayScores calculateAll({
    required DateTime date,
    HrvData? hrv,
    SleepData? sleep,
    DailyBpSummary? bp,
    WellnessData? wellness,
    List<GarminActivity> activities = const [],
    List<int> recentRestingHr = const [],
    double accumulatedSleepDebtMinutes = 0.0,
    double previousLoad = 0.0,
    int userAge = 30,
  }) {
    final maxHr = 220 - userAge;
    final strain = calculateStrain(activities, wellness, maxHr: maxHr);
    // A day well below the previous load counts as recovery-supporting.
    final easyDay = previousLoad * 0.85 > strain.score;
    return DayScores(
      date: date,
      recovery: calculateRecovery(hrv, sleep, bp, recentRestingHr,
          easyDay: easyDay),
      sleep: calculateSleep(sleep, previousLoad, accumulatedSleepDebtMinutes),
      strain: strain,
      bloodPressure: calculateBpScore(bp),
    );
  }

  /// Normal-reading share (50), nocturnal dipping (30) and systolic level (20).
  BloodPressureScore? calculateBpScore(DailyBpSummary? bp) {
    if (bp == null) return null;
    final normal = (bp.normalBpPercent ?? 0.0) * 0.5;
    final dip = bp.nightDippingPercent;
    final dipScore = dip == null ? 0.0 : (dip / 10 * 30).clamp(0.0, 30.0);
    final sys = bp.avgSystolic;
    final sysScore = sys < 120
        ? 20.0
        : sys < 130
            ? 15.0
            : sys < 140
                ? 8.0
                : 0.0;
    return BloodPressureScore(
      score: (normal + dipScore + sysScore).clamp(0.0, 100.0),
      nightDippingPercent: dip,
    );
  }

  /// Sleep need grows with the previous day's load and accumulated debt.
  SleepScore? calculateSleep(SleepData? sleep,
      [double previousLoad = 0.0, double sleepDebtMinutes = 0.0]) {
    if (sleep == null) return null;

    Duration need;
    final garminNeed = sleep.sleepNeedSeconds;
    if (garminNeed != null && garminNeed > 0) {
      need = Duration(seconds: garminNeed);
    } else {
      final strainBonus = (previousLoad / 500).clamp(0.0, 1.0) * 60;
      final debtBonus = (sleepDebtMinutes * 0.25).clamp(0.0, 90.0);
      final minutes = (480 + strainBonus + debtBonus).clamp(420.0, 540.0);
      need = Duration(minutes: minutes.round());
    }

    double score;
    final garminScore = sleep.sleepScore;
    if (garminScore != null) {
      score = garminScore.clamp(0.0, 100.0);
    } else {
      final durationScore =
          (sleep.totalSleep.inMinutes / need.inMinutes).clamp(0.0, 1.0) * 40;
      final deepScore = (sleep.deepPercent / 20).clamp(0.0, 1.0) * 25;
      final remScore = (sleep.remPercent / 25).clamp(0.0, 1.0) * 25;
      final effScore = (sleep.efficiency / 100).clamp(0.0, 1.0) * 10;
      score = (durationScore + deepScore + remScore + effScore)
          .clamp(0.0, 100.0);
    }

    return SleepScore(
      score: score,
      duration: sleep.totalSleep,
      need: need,
      deepPercent: sleep.deepPercent,
      remPercent: sleep.remPercent,
      efficiency: sleep.efficiency,
      wakeTime: sleep.sleepEnd,
    );
  }

  /// Weighted blend of HRV (55 %), resting-HR trend (20 %), sleep (20 %) and
  /// blood pressure (5 %); missing inputs drop out of the weighting.
  RecoveryScore calculateRecovery(
    HrvData? hrv,
    SleepData? sleep,
    DailyBpSummary? bp,
    List<int> recentRestingHr, {
    bool easyDay = false,
  }) {
    double? hrvComp;
    final last = hrv?.lastNightAvg;
    final weekly = hrv?.weeklyAvg;
    if (last != null && weekly != null && weekly > 0) {
      hrvComp = ((last / weekly - 0.5) / 1.0).clamp(0.0, 1.0);
    }

    double? rhrComp;
    final rhr = hrv?.restingHeartRate;
    if (rhr != null && recentRestingHr.length >= 3) {
      final baseline =
          recentRestingHr.reduce((a, b) => a + b) / recentRestingHr.length;
      final elevation = (rhr - baseline) / baseline;
      rhrComp = (1 - elevation / 0.1).clamp(0.0, 1.0);
    } else if (rhr != null) {
      rhrComp = ((80 - rhr) / 40).clamp(0.0, 1.0);
    }

    double? sleepComp;
    if (sleep != null) {
      final garminScore = sleep.sleepScore;
      if (garminScore != null) {
        sleepComp = (garminScore / 100).clamp(0.0, 1.0);
      } else {
        final duration = (sleep.totalSleep.inMinutes / 480).clamp(0.0, 1.0);
        final quality = (sleep.deepPercent / 20 * 0.5 +
                sleep.remPercent / 25 * 0.5)
            .clamp(0.0, 1.0);
        sleepComp = (duration * 0.6 + quality * 0.4).clamp(0.0, 1.0);
      }
    }

    double? bpComp;
    if (bp != null && bp.avgSystolic > 0) {
      bpComp = ((135 - bp.avgSystolic) / 20).clamp(0.0, 1.0);
    }

    const weights = [0.55, 0.2, 0.2, 0.05];
    final comps = [hrvComp, rhrComp, sleepComp, bpComp];
    var sum = 0.0, weightSum = 0.0;
    for (var i = 0; i < 4; i++) {
      final c = comps[i];
      if (c == null) continue;
      sum += c * weights[i];
      weightSum += weights[i];
    }
    if (weightSum == 0) {
      return const RecoveryScore(score: null, recommendation: 'rest');
    }
    var score = (sum / weightSum * 100).clamp(0.0, 100.0);
    if (easyDay) score = math.min(100.0, score);
    final recommendation = score >= 67
        ? 'hard'
        : score >= 34
            ? 'moderate'
            : 'rest';
    return RecoveryScore(score: score, recommendation: recommendation);
  }

  /// Daily load: zone-weighted minutes when HR zones are known, otherwise
  /// Banister TRIMP from average HR; plus small elevation and step bonuses.
  StrainScore calculateStrain(
    List<GarminActivity> activities,
    WellnessData? wellness, {
    int maxHr = 190,
    int restingHr = 55,
  }) {
    var total = 0.0;
    for (final a in activities) {
      final minutes = a.duration.inSeconds / 60;
      final elevation = a.elevationGain ?? 0.0;
      final elevationBonus = elevation > 0 ? elevation / 10 : 0.0;

      var zoneLoad = 0.0;
      if (a.hrZoneSeconds.isNotEmpty) {
        for (var i = 0; i < 5; i++) {
          final pct = a.hrZoneSeconds[_zoneKeys[i]] ?? 0.0;
          zoneLoad += minutes * (pct / 100) * _zoneWeights[i];
        }
      }

      var load = zoneLoad;
      final avgHr = a.avgHeartRate;
      if (load == 0.0 && avgHr != null) {
        final x = ((avgHr - restingHr) / (maxHr - restingHr)).clamp(0.0, 1.0);
        load = minutes * x * math.exp(1.92 * x);
      }
      if (load > 0) total += load + elevationBonus;
    }

    final steps = wellness?.steps;
    if (steps != null) total += steps / 10000 * 30;

    return StrainScore(score: total.clamp(0.0, 2000.0), zones: const []);
  }
}
