import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';

import '../db/database.dart';
import 'hr_zone_history.dart';
import 'hr_zone_model.dart';

/// The time in Z1–Z5 of every workout, computed once and kept (FjeliaPro
/// zone trends). The rules, documented here:
/// - Zones: the athlete's zones for the workout's sport family (running,
///   cycling, swimming; other sports use the running zones), as they were in
///   force when the workout started (hr_zone_definitions).
/// - Samples: the workout's own timestamped heart rate, else the shared heart
///   rate timeline in its window (its own platform first). Never the average.
/// - Each interval between two samples belongs to the zone of the earlier
///   one, at most [maxGapSeconds] of it; longer gaps count as missing.
///   Readings outside 30–240 bpm are no heart rate. Boundaries are lower
///   inclusive: a reading on Z3's lower bound is Z3.
/// - Missing heart rate is reported as such and never assigned to Z1; the
///   zone seconds add up to the covered seconds, which never exceed the
///   workout's own duration.
/// - Two recordings of the same workout (same sport family, overlapping by
///   half the shorter one) count once: the one with more heart-rate time.
/// - A summary keeps its zone definition; a later change to the zones does
///   not rewrite it. A new [algorithmVersion] recomputes all.
class HrZoneSummaryService {
  HrZoneSummaryService(this._db);
  final AppDatabase _db;

  static const algorithmVersion = 1;
  static const maxGapSeconds = 15.0;
  static const minBpm = 30.0, maxBpm = 240.0;

  /// The zones' sport family of an activity type, or null for none.
  static String? sportFamily(String type) => zoneFamily(type);

  /// Computes the summaries that are missing or from an older algorithm,
  /// then marks duplicates. Returns how many were (re)computed.
  Future<int> update({DateTime? since}) async {
    final definitions = await _db.select(_db.hrZoneDefinitions).get();
    if (definitions.isEmpty) return 0;
    final current = {
      for (final row
          in await (_db.selectOnly(_db.hrZoneSummaries)
                ..addColumns([_db.hrZoneSummaries.activityId])
                ..where(
                  _db.hrZoneSummaries.algorithmVersion.equals(algorithmVersion),
                ))
              .get())
        row.read(_db.hrZoneSummaries.activityId)!,
    };
    // Ids and types first: the samples are read only for what is missing.
    final a0 = _db.activityRecords;
    final candidates = _db.selectOnly(a0)
      ..addColumns([a0.activityId, a0.type, a0.durationSeconds]);
    if (since != null) {
      candidates.where(a0.startDate.isBiggerOrEqualValue(since));
    }
    final missing = [
      for (final row in await candidates.get())
        if (!current.contains(row.read(a0.activityId)) &&
            sportFamily(row.read(a0.type)!) != null &&
            (row.read(a0.durationSeconds) ?? 0) > 0)
          row.read(a0.activityId)!,
    ];
    final activities = [
      for (var i = 0; i < missing.length; i += 200)
        ...await (_db.select(
          _db.activityRecords,
        )..where((t) => t.activityId.isIn(missing.skip(i).take(200)))).get(),
    ];
    var computed = 0;
    for (final a in activities) {
      final family = sportFamily(a.type);
      if (family == null || a.durationSeconds <= 0) continue;
      final definition = definitionAt(
        definitions,
        family == 'other' ? 'running' : family,
        a.startDate,
      );
      if (definition == null) continue;
      final floors = floorsOf(definition.floorsJson);
      if (floors == null) continue;
      final samples = await _samplesOf(a);
      final zones = zoneTime(
        samples,
        floors,
        elapsedSeconds: a.durationSeconds.toDouble(),
      );
      await _db
          .into(_db.hrZoneSummaries)
          .insertOnConflictUpdate(
            HrZoneSummariesCompanion.insert(
              activityId: a.activityId,
              definitionId: definition.id,
              algorithmVersion: algorithmVersion,
              sport: family,
              startDate: a.startDate,
              elapsedSeconds: a.durationSeconds.toDouble(),
              coveredSeconds: zones.covered,
              zoneSecondsJson: jsonEncode(zones.seconds),
              computedAt: DateTime.now(),
            ),
          );
      computed++;
    }
    await _markDuplicates();
    return computed;
  }

  /// The definition of [sport] in force at [at]: the latest one from before
  /// it, or the earliest when the workout is older than all of them.
  static HrZoneDefinition? definitionAt(
    List<HrZoneDefinition> all,
    String sport,
    DateTime at,
  ) => HrZoneBook(all).definitionAt(sport, at);

  /// Five lower bounds, also from the older four upper bounds of Z1–Z4.
  static List<int>? floorsOf(String json) => zoneFloorsOf(json);

  /// Time in Z1–Z5 from [samples] (time, bpm), with the gap policy above.
  static ({List<double> seconds, double covered}) zoneTime(
    List<(DateTime, double)> samples,
    List<int> floors, {
    required double elapsedSeconds,
  }) {
    final sorted = [...samples]..sort((a, b) => a.$1.compareTo(b.$1));
    final seconds = List<double>.filled(hrZoneCount, 0);
    for (var i = 0; i + 1 < sorted.length; i++) {
      final (at, bpm) = sorted[i];
      if (!bpm.isFinite || bpm < minBpm || bpm > maxBpm) continue;
      final gap = sorted[i + 1].$1.difference(at).inMilliseconds / 1000;
      if (gap <= 0) continue;
      seconds[zoneOf(bpm, floors) - 1] += math.min(gap, maxGapSeconds);
    }
    var covered = seconds.fold(0.0, (a, b) => a + b);
    // A clock running a little ahead never makes more heart-rate time than
    // the workout had.
    if (covered > elapsedSeconds && covered > 0) {
      final scale = elapsedSeconds / covered;
      for (var i = 0; i < hrZoneCount; i++) {
        seconds[i] *= scale;
      }
      covered = elapsedSeconds;
    }
    return (seconds: seconds, covered: covered);
  }

  Future<List<(DateTime, double)>> _samplesOf(ActivityRecord a) async {
    final own = <(DateTime, double)>[];
    try {
      final decoded = a.metricsJson == null ? null : jsonDecode(a.metricsJson!);
      if (decoded is List) {
        for (final s in decoded) {
          if (s is! Map) continue;
          final hr = s['hr'], t = s['t'], timer = s['timer'];
          if (hr is! num) continue;
          final at = t is num
              ? DateTime.fromMillisecondsSinceEpoch(t.toInt())
              : timer is num
              ? a.startDate.add(Duration(milliseconds: (timer * 1000).round()))
              : null;
          if (at != null) own.add((at, hr.toDouble()));
        }
      }
    } catch (_) {}
    if (own.length >= 10) return own;
    final timeline = await _db.getHeartRateSamples(
      a.startDate,
      a.startDate.add(Duration(seconds: a.durationSeconds)),
    );
    final same = timeline.where((s) => s.source == a.source).toList();
    final use = same.length >= 10 ? same : timeline;
    // Several platforms in one window would count the same minute twice:
    // one platform, the one with the most samples.
    if (use == timeline && timeline.isNotEmpty) {
      final bySource = <String, int>{};
      for (final s in timeline) {
        bySource[s.source] = (bySource[s.source] ?? 0) + 1;
      }
      final best = bySource.entries
          .reduce((x, y) => x.value >= y.value ? x : y)
          .key;
      return [
        for (final s in timeline)
          if (s.source == best) (s.measuredAt, s.bpm),
      ];
    }
    return [for (final s in use) (s.measuredAt, s.bpm)];
  }

  /// Marks the weaker of two overlapping recordings of one workout; a
  /// deleted recording leaves its partner counted again.
  Future<void> _markDuplicates() async {
    final rows =
        await (_db.select(_db.hrZoneSummaries)
              ..where((t) => t.activityId.isInQuery(_existing()))
              ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
            .get();
    final duplicate = <String>{};
    for (var i = 0; i < rows.length; i++) {
      final a = rows[i];
      final aEnd = a.startDate.add(Duration(seconds: a.elapsedSeconds.round()));
      for (var j = i + 1; j < rows.length; j++) {
        final b = rows[j];
        if (!b.startDate.isBefore(aEnd)) break;
        if (a.sport != b.sport) continue;
        final bEnd = b.startDate.add(
          Duration(seconds: b.elapsedSeconds.round()),
        );
        final overlap = (aEnd.isBefore(bEnd) ? aEnd : bEnd)
            .difference(b.startDate)
            .inSeconds;
        final shorter = math.min(a.elapsedSeconds, b.elapsedSeconds);
        if (overlap < shorter / 2) continue;
        duplicate.add(
          a.coveredSeconds >= b.coveredSeconds ? b.activityId : a.activityId,
        );
      }
    }
    for (final r in rows) {
      final dup = duplicate.contains(r.activityId);
      if (dup == r.duplicate) continue;
      await (_db.update(_db.hrZoneSummaries)
            ..where((t) => t.activityId.equals(r.activityId)))
          .write(HrZoneSummariesCompanion(duplicate: Value(dup)));
    }
  }

  /// The ids of the activities that still exist.
  BaseSelectStatement _existing() =>
      _db.selectOnly(_db.activityRecords)
        ..addColumns([_db.activityRecords.activityId]);

  /// The kept summaries as the trends read them: no duplicates and no
  /// workouts deleted since.
  Future<List<HrZoneWorkout>> workouts({DateTime? since}) async {
    final query = _db.select(_db.hrZoneSummaries)
      ..where(
        (t) => t.duplicate.equals(false) & t.activityId.isInQuery(_existing()),
      );
    if (since != null) {
      query.where((t) => t.startDate.isBiggerOrEqualValue(since));
    }
    return [
      for (final s in await query.get())
        HrZoneWorkout(
          activityId: s.activityId,
          sport: s.sport,
          start: s.startDate.toLocal(),
          elapsedSeconds: s.elapsedSeconds,
          coveredSeconds: s.coveredSeconds,
          zoneSeconds: [
            for (final x in jsonDecode(s.zoneSecondsJson) as List)
              (x as num).toDouble(),
          ],
          definitionId: s.definitionId,
        ),
    ];
  }
}
