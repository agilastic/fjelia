import 'package:fjelia_core/services/energie.dart';
import 'package:fjelia_core/services/training_load.dart';
import 'package:fjelia_core/utils/log.dart';

import '../db/database.dart';

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
    for (
      var day = target.subtract(const Duration(days: _warmupDays));
      !day.isAfter(target);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final result = Energie.day(maps, day, level);
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
    for (
      var day = today.subtract(Duration(days: days));
      !day.isAfter(today);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final result = Energie.day(maps, day, level);
      level = result.end.toDouble();
      if (maps.hrv.containsKey(day)) {
        await _db.updateHrvEnergie(day, result.end);
      }
      _logComparison(day, maps, result);
    }
  }

  Future<EnergieInputs> _loadMaps(int days) async {
    final hrv = await _db.getHrvRange(days);
    final sleep = await _db.getSleepRange(days);
    final wellness = await _db.getWellnessRange(days);
    final activities = await _db.getActivitiesInRange(days);
    final load = <DateTime, double>{};
    for (final a in activities) {
      final day = _midnight(a.startDate);
      load[day] = (load[day] ?? 0.0) + effectiveLoad(a);
    }
    return EnergieInputs(
      {for (final r in hrv) _midnight(r.date): r},
      {for (final r in sleep) _midnight(r.date): r},
      {for (final r in wellness) _midnight(r.date): r},
      load,
    );
  }

  void _logComparison(DateTime day, EnergieInputs maps, EnergieDay r) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final sleep = maps.sleep[day];
    final sleepText = sleep != null
        ? '${(sleep.totalSleepSeconds / 3600).toStringAsFixed(1)}h'
        : 'no-sleep';
    final garmin = maps.hrv[day]?.bodyBattery;
    if (garmin != null) {
      final diff = r.end - garmin.round();
      log(
        '[Energie] $key  garmin=${garmin.round()}  computed=${r.end}  '
        'diff=${diff > 0 ? '+' : ''}$diff  charge=${r.charge}  '
        'drain=${r.drain}  sleep=$sleepText',
      );
    } else {
      log(
        '[Energie] $key  garmin= —   computed=${r.end}'
        '              charge=${r.charge}  drain=${r.drain}  sleep=$sleepText',
      );
    }
  }
}
