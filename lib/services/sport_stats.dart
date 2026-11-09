import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../db/database.dart';
import '../models/heart_rate.dart';
import '../theme/activity_colors.dart';

/// The two sports with records: running and riding.
enum StatsSport { run, ride }

/// One best effort: the fastest stretch of [meters] inside any activity,
/// all time and this year, each with its day.
class BestEffort {
  const BestEffort(
    this.label,
    this.meters, {
    this.allTime,
    this.allTimeDate,
    this.year,
    this.yearDate,
  });
  final String label;
  final double meters;
  final double? allTime, year;
  final DateTime? allTimeDate, yearDate;
}

/// Totals over a span: activities, distance, moving time, elevation.
class StatsTotals {
  const StatsTotals(this.count, this.meters, this.seconds, this.elevation);

  /// A whole number for a span, an average (one decimal) per week.
  final double count;
  final double meters, seconds, elevation;
}

/// A sport's numbers, like a training log's overview: the last four weeks
/// per week, this year, all time, and the best efforts.
class SportStats {
  const SportStats({
    required this.sport,
    required this.last4PerWeek,
    required this.year,
    required this.allTime,
    required this.efforts,
    this.longest,
    this.longestDate,
    this.mostElevation,
    this.mostElevationDate,
  });
  final StatsSport sport;

  /// The last 28 days divided by four.
  final StatsTotals last4PerWeek;
  final StatsTotals year, allTime;
  final List<BestEffort> efforts;

  /// The longest single activity (metres) and the most climbing in one.
  final double? longest, mostElevation;
  final DateTime? longestDate, mostElevationDate;
}

const runDistances = [
  ('400m', 400.0),
  ('1K', 1000.0),
  ('5K', 5000.0),
  ('10K', 10000.0),
  ('15K', 15000.0),
  ('10 mile', 16093.4),
  ('20K', 20000.0),
  ('Half-Marathon', 21097.5),
  ('Marathon', 42195.0),
  ('50K', 50000.0),
];

const rideDistances = [
  ('10K', 10000.0),
  ('30K', 30000.0),
  ('80K', 80000.0),
  ('100K', 100000.0),
  ('180K', 180000.0),
];

StatsSport? statsSportOf(String type) => switch (activityKind(type)) {
  ActivityKind.running => StatsSport.run,
  ActivityKind.cycling => StatsSport.ride,
  _ => null,
};

/// Best efforts already worked out, by activity id: a stored activity does
/// not change, so each is read once per app run.
final _effortCache = <String, Map<double, double>>{};

/// Works out the numbers for both sports from the stored activities.
Future<Map<StatsSport, SportStats>> computeSportStats(
  AppDatabase db,
  DateTime now,
) async {
  final a = db.activityRecords;
  final rows =
      await (db.selectOnly(a)..addColumns([
            a.activityId,
            a.type,
            a.startDate,
            a.durationSeconds,
            a.distanceMeters,
            a.totalElevation,
          ]))
          .get();
  final yearStart = DateTime(now.year);
  final last4 = DateTime(now.year, now.month, now.day - 27);
  final out = <StatsSport, SportStats>{};
  for (final sport in StatsSport.values) {
    final mine = [
      for (final r in rows)
        if (statsSportOf(r.read(a.type)!) == sport) r,
    ];
    StatsTotals totals(bool Function(DateTime) inSpan, [double divide = 1]) {
      var count = 0;
      var meters = 0.0, seconds = 0.0, elevation = 0.0;
      for (final r in mine) {
        if (!inSpan(r.read(a.startDate)!)) continue;
        count++;
        meters += r.read(a.distanceMeters) ?? 0;
        seconds += r.read(a.durationSeconds)!.toDouble();
        elevation += r.read(a.totalElevation) ?? 0;
      }
      return StatsTotals(
        count / divide,
        meters / divide,
        seconds / divide,
        elevation / divide,
      );
    }

    double? longest, mostElevation;
    DateTime? longestDate, mostElevationDate;
    for (final r in mine) {
      final d = r.read(a.distanceMeters) ?? 0;
      final e = r.read(a.totalElevation) ?? 0;
      if (d > (longest ?? 0)) {
        longest = d;
        longestDate = r.read(a.startDate);
      }
      if (e > (mostElevation ?? 0)) {
        mostElevation = e;
        mostElevationDate = r.read(a.startDate);
      }
    }

    // Best efforts from the samples of every activity long enough for the
    // shortest distance; worked out off the main isolate in batches.
    final distances = sport == StatsSport.run ? runDistances : rideDistances;
    final targets = [for (final d in distances) d.$2];
    final todo = [
      for (final r in mine)
        if ((r.read(a.distanceMeters) ?? 0) >= targets.first &&
            !_effortCache.containsKey(r.read(a.activityId)))
          r.read(a.activityId)!,
    ];
    for (var i = 0; i < todo.length; i += 20) {
      final ids = todo.sublist(i, math.min(todo.length, i + 20));
      final samples =
          await (db.selectOnly(a)
                ..addColumns([a.activityId, a.metricsJson])
                ..where(a.activityId.isIn(ids)))
              .get();
      final batch = [
        for (final s in samples)
          (s.read(a.activityId)!, s.read(a.metricsJson) ?? ''),
      ];
      final results = await _effortsApart(batch, targets);
      for (final (id, efforts) in results) {
        _effortCache[id] = efforts;
      }
    }
    final dates = {
      for (final r in mine) r.read(a.activityId)!: r.read(a.startDate)!,
    };
    final efforts = [
      for (final (label, meters) in distances)
        () {
          double? all, year;
          DateTime? allDate, yearDate;
          for (final id in dates.keys) {
            final t = _effortCache[id]?[meters];
            if (t == null) continue;
            final date = dates[id]!;
            if (all == null || t < all) {
              all = t;
              allDate = date;
            }
            if (!date.isBefore(yearStart) && (year == null || t < year)) {
              year = t;
              yearDate = date;
            }
          }
          return BestEffort(
            label,
            meters,
            allTime: all,
            allTimeDate: allDate,
            year: year,
            yearDate: yearDate,
          );
        }(),
    ];
    out[sport] = SportStats(
      sport: sport,
      last4PerWeek: totals((d) => !d.isBefore(last4), 4),
      year: totals((d) => !d.isBefore(yearStart)),
      allTime: totals((_) => true),
      efforts: efforts,
      longest: longest,
      longestDate: longestDate,
      mostElevation: mostElevation,
      mostElevationDate: mostElevationDate,
    );
  }
  return out;
}

/// [bestEfforts] for a batch of activities on another isolate. Its own
/// function, so the closure carries only the samples, not the database.
Future<List<(String, Map<double, double>)>> _effortsApart(
  List<(String, String)> batch,
  List<double> targets,
) => Isolate.run(
  () => [for (final (id, json) in batch) (id, bestEfforts(json, targets))],
);

/// The fastest moving time (s) over each of [targets] metres in one
/// activity's samples. Time stopped (a gap with almost no distance) does not
/// count, so a red light does not spoil a record. Distances the activity is
/// too short for are left out.
Map<double, double> bestEfforts(String metricsJson, List<double> targets) {
  if (metricsJson.isEmpty) return const {};
  final Object? decoded;
  try {
    decoded = jsonDecode(metricsJson);
  } catch (_) {
    return const {};
  }
  if (decoded is! List) return const {};
  final times = <double>[];
  final dists = <double>[];
  var moving = 0.0;
  DateTime? lastAt;
  double? lastD;
  for (final s in decoded) {
    if (s is! Map) continue;
    final d = (s['d'] as num?)?.toDouble();
    if (d == null || !d.isFinite) continue;
    final at = heartRateTimestamp(s['t']);
    final spd = (s['spd'] as num?)?.toDouble();
    if (lastD != null) {
      final step = d - lastD;
      if (step < 0) continue;
      double dt;
      if (at != null && lastAt != null) {
        dt = at.difference(lastAt).inMilliseconds / 1000;
      } else if (spd != null && spd > .1) {
        dt = step / spd;
      } else {
        continue;
      }
      // Standing: more than 5 s with less than 0.5 m/s does not count.
      if (dt > 5 && step / dt < .5) dt = 0;
      moving += dt;
    }
    times.add(moving);
    dists.add(d);
    lastAt = at ?? lastAt;
    lastD = d;
  }
  final out = <double, double>{};
  if (dists.length < 2) return out;
  for (final target in targets) {
    if (dists.last - dists.first < target) continue;
    var best = double.infinity;
    var j = 0;
    for (var i = 0; i < dists.length; i++) {
      while (j < dists.length && dists[j] - dists[i] < target) {
        j++;
      }
      if (j >= dists.length) break;
      // The stretch may run a little past the target: scale back to it.
      final covered = dists[j] - dists[i];
      final t = (times[j] - times[i]) * target / covered;
      if (t > 0 && t < best) best = t;
    }
    if (best.isFinite) out[target] = best;
  }
  return out;
}

String _duration(double seconds) {
  final s = seconds.round();
  final h = s ~/ 3600, m = s ~/ 60 % 60, sec = s % 60;
  return h > 0
      ? '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}'
      : '$m:${sec.toString().padLeft(2, '0')}';
}

String _hours(double seconds) =>
    '${seconds ~/ 3600}h ${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}m';

/// The numbers as context lines for the Pro analyses.
List<String> sportStatsLines(Map<StatsSport, SportStats> stats, DateTime now) {
  String day(DateTime? d) =>
      d == null ? '' : ' (${DateFormat('yyyy-MM-dd').format(d)})';
  String totals(StatsTotals t) =>
      'act ${countText(t.count)},dist ${(t.meters / 1000).toStringAsFixed(1)}km,'
      'time ${_hours(t.seconds)},elev ${t.elevation.round()}m';
  final lines = <String>[];
  for (final s in stats.values) {
    if (s.allTime.count == 0) continue;
    final name = s.sport == StatsSport.run ? 'Run' : 'Ride';
    lines.add(
      '[SportStats:$name,Last4wPerWeek(${totals(s.last4PerWeek)}),'
      'Year${now.year}(${totals(s.year)}),AllTime(${totals(s.allTime)})'
      '${s.longest == null ? '' : ',Longest:${(s.longest! / 1000).toStringAsFixed(1)}km${day(s.longestDate)}'}'
      '${s.mostElevation == null ? '' : ',MostElevation:${s.mostElevation!.round()}m${day(s.mostElevationDate)}'}]',
    );
    final efforts = [
      for (final e in s.efforts)
        if (e.allTime != null)
          '${e.label}:${_duration(e.allTime!)}${day(e.allTimeDate)}'
              '${e.year == null ? '' : ' year ${_duration(e.year!)}${day(e.yearDate)}'}',
    ];
    if (efforts.isNotEmpty) {
      lines.add('[BestEfforts:$name,${efforts.join(',')}]');
    }
  }
  return lines;
}

/// A count as a whole number, or with one decimal when it is an average.
String countText(double count) => count == count.roundToDouble()
    ? '${count.round()}'
    : count.toStringAsFixed(1);

/// For the view: a duration like 22:02 or 1:47:27.
String effortTime(double seconds) => _duration(seconds);

/// For the view: hours and minutes like 3h 27m.
String statsHours(double seconds) => _hours(seconds);
