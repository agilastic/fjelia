import '../db/database.dart';
import '../providers/training_load_provider.dart';
import '../utils/log.dart';

class _EnergieResult {
  const _EnergieResult(this.end, this.charge, this.drain);

  final int end;
  final int charge;
  final int drain;
}

class _DayMaps {
  const _DayMaps(this.hrv, this.sleep, this.wellness, this.load);

  final Map<DateTime, HrvRecord> hrv;
  final Map<DateTime, SleepRecord> sleep;
  final Map<DateTime, WellnessRecord> wellness;
  final Map<DateTime, double> load;
}

/// "Energie": Fjelia's own body-battery estimate. Each day starts from the
/// previous evening's level, is charged by sleep (quality, HRV, resting HR)
/// and drained by stress, training, calories and steps. Stored in
/// `hrv_records.computed_energie` and compared against Garmin's value.
class EnergieCalculator {
  EnergieCalculator(this._db);

  final AppDatabase _db;

  static const _historyDays = 68;
  static const _warmupDays = 60;

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Replays the last 60 days so [date]'s starting level is realistic.
  Future<void> recalculateForDate(DateTime date) async {
    final target = _midnight(date);
    final maps = await _loadMaps(_historyDays);
    var level = 50.0;
    for (var day = target.subtract(const Duration(days: _warmupDays));
        !day.isAfter(target);
        day = DateTime(day.year, day.month, day.day + 1)) {
      final result = _calculate(maps, day, level);
      level = result.end.toDouble();
      if (day == target) {
        await _db.updateHrvEnergie(day, result.end);
        _logComparison(day, maps, result);
      }
    }
  }

  Future<void> recalculateRange(int days) async {
    final today = _midnight(DateTime.now());
    final maps = await _loadMaps(days + 8);
    var level = 50.0;
    for (var day = today.subtract(Duration(days: days));
        !day.isAfter(today);
        day = DateTime(day.year, day.month, day.day + 1)) {
      final result = _calculate(maps, day, level);
      level = result.end.toDouble();
      if (maps.hrv.containsKey(day)) {
        await _db.updateHrvEnergie(day, result.end);
      }
      _logComparison(day, maps, result);
    }
  }

  Future<_DayMaps> _loadMaps(int days) async {
    final hrv = await _db.getHrvRange(days);
    final sleep = await _db.getSleepRange(days);
    final wellness = await _db.getWellnessRange(days);
    final activities = await _db.getActivitiesInRange(days);
    final load = <DateTime, double>{};
    for (final a in activities) {
      final day = _midnight(a.startDate);
      load[day] = (load[day] ?? 0.0) + effectiveLoad(a);
    }
    return _DayMaps(
      {for (final r in hrv) _midnight(r.date): r},
      {for (final r in sleep) _midnight(r.date): r},
      {for (final r in wellness) _midnight(r.date): r},
      load,
    );
  }

  double? _avg7dayHrv(_DayMaps maps, DateTime day) {
    var sum = 0.0;
    var n = 0;
    for (var i = 1; i <= 7; i++) {
      final v = maps.hrv[day.subtract(Duration(days: i))]?.hrvLastNight;
      if (v != null && v > 0) {
        sum += v;
        n++;
      }
    }
    return n == 0 ? null : sum / n;
  }

  _EnergieResult _calculate(_DayMaps maps, DateTime day, double previous) {
    final start = previous.clamp(5.0, 100.0);
    final sleep = maps.sleep[day];
    final hrv = maps.hrv[day];
    final wellness = maps.wellness[day];
    final avg7 = _avg7dayHrv(maps, day);
    final hrvToday = hrv?.hrvLastNight;

    // Overnight charge.
    var charge = 0.0;
    final total = sleep?.totalSleepSeconds ?? 0;
    if (sleep != null && total > 0) {
      final hours = total / 3600;
      final needHours = (sleep.sleepNeedSeconds ?? 8 * 3600) / 3600;
      final base = (hours / needHours * 50).clamp(0.0, 50.0);
      final stages =
          ((sleep.deepSleepSeconds + sleep.remSleepSeconds) / total / 0.35)
              .clamp(0.5, 1.3);
      final hrvFactor = hrvToday != null && avg7 != null && avg7 > 0
          ? (hrvToday / avg7).clamp(0.4, 1.4)
          : 1.0;
      final rhr = hrv?.restingHeartRate;
      final rhrFactor = rhr == null
          ? 1.0
          : rhr < 50
              ? 1.15
              : rhr > 70
                  ? 0.8
                  : 1.0;
      charge = (base * stages * hrvFactor * rhrFactor).clamp(0.0, 95.0);
    }
    final wake = (start + charge).clamp(5.0, 100.0);

    // Daytime drain.
    final strainFactor = hrvToday != null && hrvToday > 0 && avg7 != null
        ? (avg7 / hrvToday).clamp(0.5, 1.8)
        : 1.0;
    var drain = 12 * strainFactor;
    final stress = wellness?.averageStress;
    if (stress != null && stress > 25) {
      drain += (stress - 25) / 75 * 60 / 10;
    }
    final load = maps.load[day] ?? 0.0;
    if (load > 0) drain += (load / 350 * 40).clamp(0.0, 40.0);
    final calories = wellness?.activeCalories;
    if (calories != null && calories > 0) {
      drain += (calories / 800 * 30).clamp(0.0, 30.0);
    }
    final steps = wellness?.steps;
    if (steps != null && steps > 0) {
      drain += (steps / 15000 * 10).clamp(0.0, 10.0);
    }
    drain = drain.clamp(0.0, 55.0);

    final end = (wake - drain).clamp(5.0, 100.0);
    return _EnergieResult(end.round(), charge.round(), drain.round());
  }

  void _logComparison(DateTime day, _DayMaps maps, _EnergieResult r) {
    final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final sleep = maps.sleep[day];
    final sleepText = sleep != null
        ? '${(sleep.totalSleepSeconds / 3600).toStringAsFixed(1)}h'
        : 'no-sleep';
    final garmin = maps.hrv[day]?.bodyBattery;
    if (garmin != null) {
      final diff = r.end - garmin.round();
      log('[Energie] $key  garmin=${garmin.round()}  computed=${r.end}  '
          'diff=${diff > 0 ? '+' : ''}$diff  charge=${r.charge}  '
          'drain=${r.drain}  sleep=$sleepText');
    } else {
      log('[Energie] $key  garmin= —   computed=${r.end}'
          '              charge=${r.charge}  drain=${r.drain}  sleep=$sleepText');
    }
  }
}
