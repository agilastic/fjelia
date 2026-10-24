import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../providers/training_load_provider.dart';
import '../utils/log.dart';
import 'athlete_thresholds_service.dart';

/// After a workout syncs: match it to the planned session, score execution,
/// record zone time / XP / normalized training stress and refresh the week.
class PostWorkoutScorer {
  PostWorkoutScorer(this._db) : _thresholds = AthleteThresholdsService(_db);

  final AppDatabase _db;
  final AthleteThresholdsService _thresholds;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Scores [activity] unless its matched session already has actuals.
  Future<bool> scoreIfUnscored(
    ActivityRecord activity, {
    Set<String> alreadyScored = const {},
  }) async {
    if (await _isLinked(activity.activityId)) return false;
    final session = await _matchSession(
      activity.startDate,
      activity.type,
      activity.durationSeconds,
      activity.activityId,
    );
    if (session == null || alreadyScored.contains(session.id)) return false;
    final existing = await (_db.select(
      _db.sessionActuals,
    )..where((t) => t.sessionId.equals(session.id))).getSingleOrNull();
    if (existing != null) return false;
    return score(activity);
  }

  Future<bool> score(ActivityRecord activity) async {
    // An activity completes one session, however often it syncs.
    if (await _isLinked(activity.activityId)) return false;
    final session = await _matchSession(
      activity.startDate,
      activity.type,
      activity.durationSeconds,
      activity.activityId,
    );
    if (session == null) return false;

    final durationSec = activity.durationSeconds.toDouble();
    var zoneSec = _parseZoneSec(activity.hrZonesJson, durationSec);
    if (zoneSec == null && activity.metricsJson != null) {
      final thresholds = await _thresholds.get();
      final floors = thresholds == null
          ? null
          : _thresholds.hrZoneFloorsFor(thresholds, session.sport);
      if (floors != null) {
        zoneSec = _zoneSecFromSamples(
          activity.metricsJson!,
          floors,
          durationSec,
        );
      }
    }
    zoneSec ??= List<double>.filled(6, 0.0);

    final actualMin = durationSec / 60;
    final planned = _plannedZoneDistribution(session.plannedZonesJson);
    final executionScore = _executionScore3Axis(
      session,
      actualMin,
      zoneSec,
      planned,
    );
    final scoredVsAdapted = session.status == 'adapted';
    final durationRatio = session.plannedDurationMin > 0
        ? actualMin / session.plannedDurationMin
        : 1.0;
    final load = effectiveLoad(activity);
    final tssRatio = session.plannedTrimp > 0
        ? load / session.plannedTrimp
        : null;
    final pi = _polarizationIndex(zoneSec);
    final verdict = _executionVerdict(durationRatio, zoneSec, planned);

    await _db
        .into(_db.sessionActuals)
        .insertOnConflictUpdate(
          SessionActualsCompanion(
            sessionId: Value(session.id),
            z1ActualSeconds: Value(zoneSec[0].round()),
            z2ActualSeconds: Value(zoneSec[1].round()),
            z3ActualSeconds: Value(zoneSec[2].round()),
            z4ActualSeconds: Value(zoneSec[3].round()),
            z5ActualSeconds: Value(zoneSec[4].round()),
            z6ActualSeconds: Value(zoneSec[5].round()),
            executionScore: Value(executionScore),
            durationRatio: Value(durationRatio),
            tssRatio: Value(tssRatio),
            scoredVsAdapted: Value(scoredVsAdapted),
            avgHrBpm: Value(activity.avgHeartRate?.round()),
            maxHrBpm: Value(activity.maxHeartRate?.round()),
            avgPaceSecPerKm: Value(
              activity.distanceMeters != null && activity.distanceMeters! > 0
                  ? durationSec / (activity.distanceMeters! / 1000)
                  : null,
            ),
            avgPowerWatts: Value(activity.avgWatts?.round()),
            polarizationIndex: Value(pi),
            executionVerdict: Value(verdict),
            activityId: Value(activity.activityId),
            startedAt: Value(activity.startDate),
            completedAt: Value(
              activity.startDate.add(
                Duration(seconds: activity.durationSeconds),
              ),
            ),
          ),
        );

    await (_db.update(
      _db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).write(
      TrainingSessionsCompanion(
        status: const Value('completed'),
        actualDurationMin: Value(actualMin.round()),
        dateModified: Value(DateTime.now()),
      ),
    );

    // Normalized training stress per zone (hours × zone weight).
    final totalSec = zoneSec.reduce((a, b) => a + b);
    final ntsZones = [for (final s in zoneSec) s / 3600 * 100];
    await _db
        .into(_db.sessionNts)
        .insertOnConflictUpdate(
          SessionNtsCompanion(
            id: Value(const Uuid().v4()),
            sessionId: Value(session.id),
            ntsType: const Value('hr'),
            nts: Value(totalSec > 0 ? load : 0.0),
            ntsz1: Value(ntsZones[0]),
            ntsz2: Value(ntsZones[1]),
            ntsz3: Value(ntsZones[2]),
            ntsz4: Value(ntsZones[3]),
            ntsz5: Value(ntsZones[4]),
            ntsz6: Value(ntsZones[5]),
          ),
        );

    // XP: planned minutes are the possible points; execution scales them.
    final possible = session.plannedDurationMin;
    final factor = ((executionScore ?? 100) / 100).clamp(0.5, 1.0);
    await _db
        .into(_db.sessionXp)
        .insertOnConflictUpdate(
          SessionXpCompanion(
            sessionId: Value(session.id),
            earnedPoints: Value((possible * factor).round()),
            possiblePoints: Value(possible),
          ),
        );

    await _aggregateWeek(_weekStart(session.sessionDate));

    // FTP assessment rides feed the estimated FTP (95 % of 20-min power).
    final type = activity.type.toLowerCase();
    final isRide = type.contains('cycl') || type.contains('bike');
    final isAssessment = (session.subType ?? session.sessionType)
        .toLowerCase()
        .contains('assessment');
    if (isRide && isAssessment && activity.avgWatts != null) {
      final ftp = (activity.avgWatts! * 0.95).round();
      await _thresholds.proposeEftpUpdate(ftp);
      await (_db.update(
        _db.sessionActuals,
      )..where((t) => t.sessionId.equals(session.id))).write(
        SessionActualsCompanion(
          normalizedPowerWatts: Value(activity.avgWatts!.round()),
          intensityFactor: Value(activity.avgWatts! / math.max(ftp, 1)),
        ),
      );
    }

    await _calibrateUpcomingSessions();
    return true;
  }

  /// Shifts pace targets of upcoming runs when the last runs show cardiac
  /// drift against plan (1.5 s/km per bpm, max ±15 s/km).
  Future<void> _calibrateUpcomingSessions() async {
    final recent =
        await (_db.select(_db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.status.equals('completed') &
                    t.sport.isIn(const ['running', 'trail_running']),
              )
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.sessionDate,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(5))
            .get();
    final drifts = <double>[];
    for (final s in recent.take(3)) {
      final actual = await (_db.select(
        _db.sessionActuals,
      )..where((t) => t.sessionId.equals(s.id))).getSingleOrNull();
      final ranges = s.hrRangesJson;
      if (actual?.avgHrBpm == null || ranges == null) continue;
      final decoded = jsonDecode(ranges);
      final range = decoded is List && decoded.isNotEmpty
          ? decoded.first
          : decoded;
      if (range is! Map) continue;
      final low = (range['low'] as num?)?.toDouble();
      final high = (range['high'] as num?)?.toDouble();
      if (low == null || high == null) continue;
      final mid = (low + high) / 2;
      drifts.add(actual!.avgHrBpm! - mid);
    }
    if (drifts.length < 2) return;
    final drift = drifts.reduce((a, b) => a + b) / drifts.length;
    if (drift.abs() < 2.0) return;
    final adjust = (drift * 1.5).clamp(-15.0, 15.0);
    log(
      '[Scorer] HR drift ${drift.toStringAsFixed(1)} bpm over ${drifts.length} '
      'sessions → pace adjustment ${adjust > 0 ? '+' : ''}'
      '${adjust.toStringAsFixed(0)} s/km on upcoming running sessions',
    );

    final now = DateTime.now();
    final upcoming =
        await (_db.select(_db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.status.equals('planned') &
                    t.sessionDate.isBiggerOrEqualValue(_day(now)) &
                    t.sport.isIn(const ['running', 'trail_running']),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.sessionDate)]))
            .get();
    for (final s in upcoming) {
      final raw = s.paceRangesJson;
      if (raw == null) continue;
      final decoded = jsonDecode(raw);
      final list = decoded is List ? decoded : [decoded];
      final updated = list.map((r) {
        if (r is! Map) return r;
        final m = Map<String, dynamic>.from(r);
        for (final key in const ['low_sec_per_km', 'high_sec_per_km']) {
          final v = (m[key] as num?)?.toDouble();
          if (v != null) m[key] = (v + adjust).clamp(150.0, 600.0);
        }
        m['calibrated'] = true;
        m['calibrated_drift_bpm'] = double.parse(drift.toStringAsFixed(1));
        m['calibrated_sessions'] = drifts.length;
        return m;
      }).toList();
      await (_db.update(
        _db.trainingSessions,
      )..where((t) => t.id.equals(s.id))).write(
        TrainingSessionsCompanion(
          paceRangesJson: Value(
            jsonEncode(decoded is List ? updated : updated.first),
          ),
        ),
      );
    }
  }

  static DateTime _weekStart(DateTime d) {
    final day = _day(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  Future<void> _aggregateWeek(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final sessions =
        await (_db.select(_db.trainingSessions)..where(
              (t) =>
                  t.athleteId.equals('self') &
                  t.sessionDate.isBiggerOrEqualValue(weekStart) &
                  t.sessionDate.isSmallerThanValue(weekEnd),
            ))
            .get();
    if (sessions.isEmpty) return;

    final completed = sessions.where((s) => s.status == 'completed').length;
    final adapted = sessions.where((s) => s.status == 'adapted').length;
    final now = DateTime.now();
    final missed = sessions
        .where(
          (s) =>
              (s.status == 'planned' || s.status == 'adapted') &&
              s.sessionDate.isBefore(_day(now)),
        )
        .length;
    final plannedTrimp = sessions.fold<int>(
      0,
      (sum, s) => sum + s.plannedTrimp,
    );

    var xpEarned = 0, xpPossible = 0;
    final nts = List<double>.filled(6, 0.0);
    for (final s in sessions) {
      final xp = await (_db.select(
        _db.sessionXp,
      )..where((t) => t.sessionId.equals(s.id))).getSingleOrNull();
      if (xp != null) {
        xpEarned += xp.earnedPoints;
        xpPossible += xp.possiblePoints;
      }
      final n = await (_db.select(
        _db.sessionNts,
      )..where((t) => t.sessionId.equals(s.id))).getSingleOrNull();
      if (n != null) {
        final z = [n.ntsz1, n.ntsz2, n.ntsz3, n.ntsz4, n.ntsz5, n.ntsz6];
        for (var i = 0; i < 6; i++) {
          nts[i] += z[i];
        }
      }
    }

    final activities =
        await (_db.select(_db.activityRecords)..where(
              (t) =>
                  t.startDate.isBiggerOrEqualValue(weekStart) &
                  t.startDate.isSmallerThanValue(weekEnd),
            ))
            .get();
    final seen = <String>{};
    var actualTrimp = 0.0;
    for (final a in activities) {
      // Same workout from two sources counts once.
      final key = '${a.startDate.millisecondsSinceEpoch ~/ 300000}_${a.type}';
      if (!seen.add(key)) continue;
      actualTrimp += effectiveLoad(a);
    }

    final readiness =
        await (_db.select(_db.dailyReadinessRecords)..where(
              (t) =>
                  t.athleteId.equals('self') &
                  t.date.isBiggerOrEqualValue(weekStart) &
                  t.date.isSmallerThanValue(weekEnd),
            ))
            .get();

    final first = sessions.first;
    await _db
        .into(_db.weekSummaries)
        .insertOnConflictUpdate(
          WeekSummariesCompanion(
            athleteId: const Value('self'),
            weekStart: Value(weekStart),
            weekNumber: Value(first.weekNumber),
            phase: Value(first.phase.isEmpty ? 'base' : first.phase),
            plannedTrimp: Value(plannedTrimp),
            actualTrimp: Value(actualTrimp.round()),
            sessionsPlanned: Value(sessions.length),
            sessionsCompleted: Value(completed),
            sessionsMissed: Value(missed),
            sessionsAdapted: Value(adapted),
            weeklyXpEarned: Value(xpEarned),
            weeklyXpPossible: Value(xpPossible),
            weeklyNtsz1: Value(nts[0]),
            weeklyNtsz2: Value(nts[1]),
            weeklyNtsz3: Value(nts[2]),
            weeklyNtsz4: Value(nts[3]),
            weeklyNtsz5: Value(nts[4]),
            weeklyNtsz6: Value(nts[5]),
            greenDays: Value(readiness.where((r) => r.level == 'green').length),
            yellowDays: Value(
              readiness.where((r) => r.level == 'yellow').length,
            ),
            redDays: Value(readiness.where((r) => r.level == 'red').length),
          ),
        );
  }

  /// `off_plan` (< 40 % of planned), `under` (< 80 %), `over` (> 125 %)
  /// or `on_target`.
  String _executionVerdict(
    double durationRatio,
    List<double> zoneSec,
    List<double>? planned,
  ) {
    if (durationRatio < 0.4) return 'off_plan';
    if (durationRatio < 0.8) return 'under';
    if (durationRatio > 1.25) return 'over';
    return 'on_target';
  }

  /// Treff polarization index: log10((Z1/Z2) × Z3 × 100) on a 3-zone model.
  double? _polarizationIndex(List<double> zoneSec) {
    final total = zoneSec.fold<double>(0.0, (a, b) => a + b);
    if (total < 300) return null;
    final z1 = (zoneSec[0] + zoneSec[1]) / total;
    final z2 = zoneSec[2] / total;
    final z3 = zoneSec.skip(3).fold<double>(0.0, (a, b) => a + b) / total;
    if (z2 <= 0 || z3 <= 0) return null;
    final pi = math.log((z1 / z2) * z3 * 100) / math.ln10;
    return double.parse(pi.toStringAsFixed(2));
  }

  /// Duration (30 %), zone distribution (30 %) and intensity (40 %), 0–100.
  int? _executionScore3Axis(
    TrainingSession session,
    double actualMin,
    List<double> zoneSec,
    List<double>? planned,
  ) {
    if (session.plannedDurationMin <= 0) return null;
    final durationAxis =
        (1 - (actualMin / session.plannedDurationMin - 1).abs()).clamp(
          0.0,
          1.0,
        );

    final total = zoneSec.reduce((a, b) => a + b);
    double? zoneAxis;
    if (planned != null && total > 0) {
      var diff = 0.0;
      for (var i = 0; i < 6 && i < planned.length; i++) {
        diff += (zoneSec[i] / total - planned[i]).abs();
      }
      zoneAxis = (1 - diff / 2).clamp(0.0, 1.0);
    }

    double? intensityAxis;
    if (total > 0) {
      final target = session.primaryZone.clamp(1, 6);
      final weighted =
          [
            for (var i = 0; i < 6; i++) zoneSec[i] * (i + 1),
          ].reduce((a, b) => a + b) /
          total;
      intensityAxis = (1 - (weighted - target).abs() / 3).clamp(0.0, 1.0);
    }

    var score = 0.0, weight = 0.0;
    score += durationAxis * 0.3;
    weight += 0.3;
    if (zoneAxis != null) {
      score += zoneAxis * 0.3;
      weight += 0.3;
    }
    if (intensityAxis != null) {
      score += intensityAxis * 0.4;
      weight += 0.4;
    }
    return (score / weight * 100).round();
  }

  /// Planned share of time per zone (fractions summing to 1).
  List<double>? _plannedZoneDistribution(String? json) {
    if (json == null) return null;
    final decoded = jsonDecode(json);
    List<double> values;
    if (decoded is List) {
      values = decoded.map((e) => (e as num).toDouble()).toList();
    } else if (decoded is Map) {
      values = [
        for (var i = 1; i <= 6; i++) ((decoded['z$i'] ?? 0) as num).toDouble(),
      ];
    } else {
      return null;
    }
    final sum = values.fold<double>(0.0, (a, b) => a + b);
    if (sum <= 0) return null;
    return values.map((v) => v / sum).toList();
  }

  /// Seconds per zone from per-sample HR against the athlete's zone floors.
  List<double> _zoneSecFromSamples(
    String metricsJson,
    List<int> floors,
    double durationSec,
  ) {
    final hrs = (jsonDecode(metricsJson) as List)
        .whereType<Map<String, dynamic>>()
        .map((s) => (s['hr'] as num?)?.toDouble())
        .where((hr) => hr != null && hr > 0)
        .cast<double>()
        .toList();
    final zones = List<double>.filled(6, 0.0);
    if (hrs.isEmpty) return zones;
    final perSample = durationSec / hrs.length;
    for (final hr in hrs) {
      var z = 0;
      for (var i = 0; i < floors.length; i++) {
        if (hr >= floors[i]) z = i;
      }
      zones[z] += perSample;
    }
    return zones;
  }

  /// `{zone1: %, …}` → seconds per zone.
  List<double>? _parseZoneSec(String? json, double durationSec) {
    if (json == null) return null;
    final m = jsonDecode(json) as Map<String, dynamic>;
    final zones = List<double>.filled(6, 0.0);
    var any = false;
    for (var i = 1; i <= 5; i++) {
      final pct = (m['zone$i'] as num?)?.toDouble() ?? 0.0;
      if (pct > 0) any = true;
      zones[i - 1] = durationSec * pct / 100;
    }
    return any ? zones : null;
  }

  /// Whether [activityId] already completed a session.
  Future<bool> _isLinked(String activityId) async =>
      (await (_db.select(_db.sessionActuals)
                ..where((t) => t.activityId.equals(activityId))
                ..limit(1))
              .getSingleOrNull()) !=
          null;

  /// Links completions from before the link existed to their activity, only
  /// where it is certain: the activity starts at exactly the recorded start
  /// and no other activity does. Anything less stays unlinked and can be
  /// corrected later. Returns how many were linked.
  Future<int> linkExistingCompletions() async {
    final open = await (_db.select(_db.sessionActuals)
          ..where((t) => t.activityId.isNull() & t.startedAt.isNotNull()))
        .get();
    if (open.isEmpty) return 0;
    final taken = (await _db.select(_db.sessionActuals).get())
        .map((a) => a.activityId)
        .whereType<String>()
        .toSet();
    var linked = 0;
    for (final a in open) {
      final candidates = await (_db.select(_db.activityRecords)
            ..where((t) => t.startDate.equals(a.startedAt!)))
          .get();
      final free = candidates.where((c) => !taken.contains(c.activityId));
      if (candidates.length != 1 || free.length != 1) continue;
      final id = free.single.activityId;
      await (_db.update(_db.sessionActuals)
            ..where((t) => t.sessionId.equals(a.sessionId)))
          .write(SessionActualsCompanion(activityId: Value(id)));
      taken.add(id);
      linked++;
    }
    return linked;
  }

  /// Undoes completions that an earlier matching put on the wrong day, scores
  /// those workouts again and closes the sessions nothing was done for.
  /// Returns how many sessions were reset.
  Future<int> repairMatches({DateTime? now}) async {
    final sessions = {
      for (final s in await _db.select(_db.trainingSessions).get()) s.id: s,
    };
    final wrong = <TrainingSession>[];
    final adapted = <String>{};
    for (final a in await _db.select(_db.sessionActuals).get()) {
      final s = sessions[a.sessionId];
      if (s == null || s.status != 'completed') continue;
      final at =
          a.startedAt ??
          a.completedAt?.subtract(Duration(minutes: s.actualDurationMin ?? 0));
      if (at == null || _day(at) == _day(s.sessionDate)) continue;
      wrong.add(s);
      if (a.scoredVsAdapted) adapted.add(s.id);
    }
    if (wrong.isNotEmpty) {
      await _db.transaction(() async {
        for (final s in wrong) {
          for (final delete in [
            _db.delete(_db.sessionActuals)
              ..where((t) => t.sessionId.equals(s.id)),
            _db.delete(_db.sessionNts)..where((t) => t.sessionId.equals(s.id)),
            _db.delete(_db.sessionXp)..where((t) => t.sessionId.equals(s.id)),
          ]) {
            await delete.go();
          }
          await (_db.update(
            _db.trainingSessions,
          )..where((t) => t.id.equals(s.id))).write(
            TrainingSessionsCompanion(
              status: Value(adapted.contains(s.id) ? 'adapted' : 'planned'),
              actualDurationMin: const Value(null),
              dateModified: Value(DateTime.now()),
            ),
          );
        }
      });
      final from = wrong
          .map((s) => _day(s.sessionDate))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final to = _day(now ?? DateTime.now()).add(const Duration(days: 1));
      final activities =
          await (_db.select(_db.activityRecords)
                ..where((t) => t.startDate.isBetweenValues(from, to))
                ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
              .get();
      final scored = (await _db.select(_db.sessionActuals).get())
          .map((a) => a.sessionId)
          .toSet();
      for (final a in activities) {
        try {
          if (await scoreIfUnscored(a, alreadyScored: scored)) {
            scored.addAll(
              (await _db.select(_db.sessionActuals).get()).map(
                (x) => x.sessionId,
              ),
            );
          }
        } catch (e) {
          log('[Scorer] repair: ${a.activityId}: $e');
        }
      }
      for (final week in {for (final s in wrong) _weekStart(s.sessionDate)}) {
        await _aggregateWeek(week);
      }
    }
    await closePastSessions(now: now);
    return wrong.length;
  }

  /// Marks planned sessions from before yesterday that nothing was recorded for
  /// as skipped, so they do not stay open forever. Yesterday is left alone
  /// because its activities may not have synced yet.
  Future<int> closePastSessions({DateTime? now}) async {
    final today = _day(now ?? DateTime.now());
    final cutoff = DateTime(today.year, today.month, today.day - 1);
    final done = (await _db.select(_db.sessionActuals).get())
        .map((a) => a.sessionId)
        .toSet();
    final open =
        await (_db.select(_db.trainingSessions)..where(
              (t) =>
                  t.status.isIn(const ['planned', 'adapted']) &
                  t.sessionDate.isSmallerThanValue(cutoff),
            ))
            .get();
    var closed = 0;
    for (final s in open) {
      if (done.contains(s.id)) continue;
      await _db.transaction(() async {
        await (_db.update(
          _db.trainingSessions,
        )..where((t) => t.id.equals(s.id))).write(
          TrainingSessionsCompanion(
            status: const Value('skipped'),
            dateModified: Value(DateTime.now()),
            modifiedBy: const Value('system'),
          ),
        );
        await _db
            .into(_db.sessionActuals)
            .insertOnConflictUpdate(
              SessionActualsCompanion.insert(
                sessionId: s.id,
                skipReason: const Value('No matching activity'),
              ),
            );
      });
      closed++;
    }
    return closed;
  }

  /// Planned session on the activity's day in the same sport family; with
  /// several, the one whose duration is closest (82–118 % preferred).
  Future<TrainingSession?> _matchSession(
    DateTime start,
    String activityType,
    int durationSec,
    String activityId,
  ) async {
    final day = _day(start);
    final candidates =
        (await (_db.select(_db.trainingSessions)
                  ..where(
                    (t) =>
                        t.athleteId.equals('self') &
                        // The next day's midnight belongs to the next day.
                        t.sessionDate.isBiggerOrEqualValue(day) &
                        t.sessionDate.isSmallerThanValue(
                          DateTime(day.year, day.month, day.day + 1),
                        ) &
                        t.status.isIn(const ['planned', 'adapted']),
                  )
                  ..orderBy([(t) => OrderingTerm(expression: t.sessionNumber)]))
                .get())
            .where((s) => sportFamilyMatches(s.sport, activityType))
            .toList();
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    final minutes = durationSec / 60;
    double closeness(TrainingSession s) {
      final ratio = s.plannedDurationMin > 0
          ? minutes / s.plannedDurationMin
          : 0;
      final inBand = ratio >= 0.82 && ratio <= 1.18;
      return (ratio - 1.0).abs() + (inBand ? 0.0 : 1.0);
    }

    final sorted = [...candidates]
      ..sort((a, b) => closeness(a).compareTo(closeness(b)));
    return sorted.first;
  }

  /// Whether an activity of [activityType] can be the planned [sport]. A sport
  /// without a family of its own matches only an activity of that name, never
  /// everything.
  @visibleForTesting
  static bool sportFamilyMatches(String sport, String activityType) {
    final t = activityType.toLowerCase();
    bool any(List<String> keys) => keys.any(t.contains);
    switch (sport) {
      case 'running' || 'trail_running':
        return any(['run', 'trail', 'treadmill']);
      case 'cycling_road' || 'cycling_gravel' || 'cycling_mtb':
        return any(['cycl', 'bike', 'biking', 'ride', 'virtual']);
      case 'swimming':
        return any(['swim']);
      case 'strength':
        return any(['strength', 'gym', 'weight']);
      case 'indoor_rowing':
        return any(['row']);
      case 'hiking' || 'walking':
        return any(['hik', 'walk']);
      case 'inline_skating':
        return any(['skat', 'inline']);
      case 'nordic_skiing' || 'skate_skiing' || 'skiing':
        return any(['ski']);
      case 'yoga' || 'pilates' || 'stretching':
        return any(['yoga', 'pilates', 'stretch', 'mobility', 'flexib']);
      case 'triathlon':
        return any(['run', 'cycl', 'bike', 'swim']);
      default:
        final name = sport.replaceAll('_', '');
        return name.isNotEmpty && t.replaceAll('_', '').contains(name);
    }
  }
}
