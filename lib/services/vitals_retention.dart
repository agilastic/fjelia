import 'package:drift/drift.dart';

import '../db/database.dart';
import '../utils/log.dart';

/// How long heart-rate samples and blood pressure readings stay as recorded.
/// Two days, because Hilo uploads and platform syncs often arrive a day late.
const vitalsRawDays = 2;

/// Older data keeps one value per window of this length: 96 a day.
const vitalsBucket = Duration(minutes: 15);

/// Readings that are always kept: a cuff measurement or one the athlete typed
/// in is deliberate and rare.
const _alwaysKept = {'CUFF', 'MANUAL'};

/// Within one window, the reading to keep first: a cuff or manual reading, then
/// one from a Hilo report (the readings Hilo confirmed), then a stream reading.
int _rank(String type) => _alwaysKept.contains(type)
    ? 0
    : type == 'REPORT'
    ? 1
    : 2;

int _bucketOf(DateTime t) =>
    t.toUtc().millisecondsSinceEpoch ~/ vitalsBucket.inMilliseconds;

/// The ids of the blood pressure readings to keep: every cuff and manual
/// reading, and per window the highest-ranked one, closest to the middle of
/// the window. A real reading is kept, never an average: in Apple Health and
/// in the charts it stays a value that was actually measured.
Set<int> bpToKeep(Iterable<BpMeasurement> rows) {
  final keep = <int>{};
  final best = <int, BpMeasurement>{};
  final half = vitalsBucket.inMilliseconds ~/ 2;
  int offset(BpMeasurement r) {
    final ms = r.measuredAt.toUtc().millisecondsSinceEpoch;
    return (ms % vitalsBucket.inMilliseconds - half).abs();
  }

  for (final r in rows) {
    if (_alwaysKept.contains(r.measurementType)) {
      keep.add(r.id);
      continue;
    }
    final b = _bucketOf(r.measuredAt);
    final cur = best[b];
    if (cur == null) {
      best[b] = r;
      continue;
    }
    final byRank = _rank(
      r.measurementType,
    ).compareTo(_rank(cur.measurementType));
    if (byRank < 0 ||
        (byRank == 0 &&
            (offset(r) < offset(cur) ||
                (offset(r) == offset(cur) && r.id < cur.id)))) {
      best[b] = r;
    }
  }
  return keep..addAll(best.values.map((r) => r.id));
}

/// The readings for Apple Health: the same choice as the stored data, so the
/// Health app holds at most one reading per window, also for today.
List<BpMeasurement> bpForExport(List<BpMeasurement> rows) {
  final keep = bpToKeep(rows);
  return [
    for (final r in rows)
      if (keep.contains(r.id)) r,
  ];
}

/// Heart rate per source and window, as the mean of its samples, stamped at
/// the start of the window. A heart rate trend loses nothing by averaging;
/// workouts keep their own samples.
List<HeartRateSamplesCompanion> hrAverages(Iterable<HeartRateSample> rows) {
  final sums = <(String, int), (double, int)>{};
  for (final r in rows) {
    final k = (r.source, _bucketOf(r.measuredAt));
    final (sum, n) = sums[k] ?? (0.0, 0);
    sums[k] = (sum + r.bpm, n + 1);
  }
  return [
    for (final e in sums.entries)
      HeartRateSamplesCompanion.insert(
        source: e.key.$1,
        measuredAt: DateTime.fromMillisecondsSinceEpoch(
          e.key.$2 * vitalsBucket.inMilliseconds,
          isUtc: true,
        ).toLocal(),
        bpm: e.value.$1 / e.value.$2,
      ),
  ];
}

/// Thins heart-rate samples and blood pressure readings older than
/// [vitalsRawDays]. Runs again safely: a day already thinned is skipped, and
/// data that arrives late (a Hilo upload, a report import) is sorted in on the
/// next run.
class VitalsRetentionService {
  VitalsRetentionService(this.db, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final AppDatabase db;
  final DateTime Function() now;

  /// Everything before this stays thinned: the start of the day before
  /// yesterday, so today and yesterday stay as recorded.
  DateTime get cutoff {
    final n = now();
    return DateTime(n.year, n.month, n.day - (vitalsRawDays - 1));
  }

  /// Removes copies of one reading (same minute, same values), keeping the
  /// best-ranked one. Copies were left by syncs that ran at the same time.
  Future<int> removeBpDuplicates() async {
    final rows = await db
        .customSelect(
          'SELECT id FROM ('
          'SELECT id, ROW_NUMBER() OVER ('
          'PARTITION BY measured_at / 60, systolic, diastolic '
          "ORDER BY CASE WHEN measurement_type IN ('CUFF', 'MANUAL') THEN 0 "
          "WHEN measurement_type = 'REPORT' THEN 1 ELSE 2 END, id"
          ') AS n FROM bp_measurements'
          ') WHERE n > 1',
          readsFrom: {db.bpMeasurements},
        )
        .get();
    return _deleteBp([for (final r in rows) r.read<int>('id')]);
  }

  /// Deletes in chunks: SQLite limits the variables of one statement.
  Future<int> _deleteBp(List<int> ids) async {
    var removed = 0;
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      removed += await (db.delete(
        db.bpMeasurements,
      )..where((t) => t.id.isIn(chunk))).go();
    }
    return removed;
  }

  Future<({int bpRemoved, int hrRemoved})> run() async {
    final until = cutoff;
    var bpRemoved = await removeBpDuplicates(), hrRemoved = 0;
    for (final day in await _denseDays(until)) {
      final end = DateTime(day.year, day.month, day.day + 1);
      final stop = end.isAfter(until) ? until : end;
      bpRemoved += await _thinBp(day, stop);
      hrRemoved += await _thinHr(day, stop);
    }
    if (bpRemoved + hrRemoved > 0) {
      log(
        '[Retention] thinned before $until: '
        'bp -$bpRemoved, hr -$hrRemoved',
      );
    }
    return (bpRemoved: bpRemoved, hrRemoved: hrRemoved);
  }

  /// Local days before [until] that hold more than one reading per window
  /// somewhere: only those need work.
  Future<List<DateTime>> _denseDays(DateTime until) async {
    final limit = until.toUtc().millisecondsSinceEpoch ~/ 1000;
    final bucket = vitalsBucket.inSeconds;
    Future<Set<int>> busy(String table, String key) async {
      final rows = await db
          .customSelect(
            'SELECT DISTINCT measured_at / 86400 AS d FROM ('
            'SELECT measured_at, $key, COUNT(*) AS n FROM $table '
            'WHERE measured_at < ? GROUP BY $key, measured_at / $bucket'
            ') WHERE n > 1',
            variables: [Variable.withInt(limit)],
            readsFrom: {db.bpMeasurements, db.heartRateSamples},
          )
          .get();
      return {for (final r in rows) r.read<int>('d')};
    }

    final utcDays = {
      ...await busy('bp_measurements', "'bp'"),
      ...await busy('heart_rate_samples', 'source'),
    };
    // A UTC day touches at most two local days; thinning a local day twice
    // costs nothing.
    final local = <DateTime>{};
    for (final d in utcDays) {
      for (final ms in [d * 86400000, d * 86400000 + 86399999]) {
        final t = DateTime.fromMillisecondsSinceEpoch(ms);
        final day = DateTime(t.year, t.month, t.day);
        if (day.isBefore(until)) local.add(day);
      }
    }
    return local.toList()..sort();
  }

  Future<int> _thinBp(DateTime from, DateTime to) async {
    final rows = await db.getBpInRange(from, to);
    final keep = bpToKeep(rows);
    final drop = [
      for (final r in rows)
        if (!keep.contains(r.id)) r.id,
    ];
    return _deleteBp(drop);
  }

  Future<int> _thinHr(DateTime from, DateTime to) async {
    final rows = await db.getHeartRateSamples(from, to);
    final averaged = hrAverages(rows);
    if (averaged.length >= rows.length) return 0;
    await db.transaction(() async {
      await (db.delete(db.heartRateSamples)..where(
            (t) =>
                t.measuredAt.isBiggerOrEqualValue(from) &
                t.measuredAt.isSmallerThanValue(to),
          ))
          .go();
      await db.batch((b) => b.insertAll(db.heartRateSamples, averaged));
    });
    return rows.length - averaged.length;
  }
}
