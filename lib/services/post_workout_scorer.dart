import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:fjelia_core/services/planned_zones.dart' as core;
import 'package:fjelia_core/services/execution_scoring.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../models/strength_workout.dart';
import '../providers/training_load_provider.dart';

import 'package:fjelia_core/utils/log.dart';

import 'athlete_thresholds_service.dart';

import 'package:fjelia_core/services/control/execution.dart';
import 'package:fjelia_core/services/control/stimulus.dart';

/// The reason stored for a past session nothing was recorded for. It is not
/// something the athlete decided.
const noActivityReason = 'No matching activity';

/// `modifiedBy` of a session the athlete marked as not done: no activity
/// completes it by itself any more, only by hand.
const undoneByAthlete = 'athlete_undone';

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
    // A gym-mode workout still in progress completes nothing yet.
    if (activity.source == 'fjelia_live' && activity.durationSeconds == 0) {
      return false;
    }
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

  /// Scores [activity] against its matched session, or against [chosen]
  /// when the athlete chose it.
  Future<bool> score(ActivityRecord activity, {TrainingSession? chosen}) async {
    // An activity completes one session, however often it syncs.
    // A gym-mode workout still in progress completes nothing yet.
    if (activity.source == 'fjelia_live' && activity.durationSeconds == 0) {
      return false;
    }
    if (await _isLinked(activity.activityId)) return false;
    final session =
        chosen ??
        await _matchSession(
          activity.startDate,
          activity.type,
          activity.durationSeconds,
          activity.activityId,
        );
    if (session == null) return false;

    final durationSec = activity.durationSeconds.toDouble();
    final zoneSec = await zoneSeconds(activity, session.sport);

    final actualMin = durationSec / 60;
    final planned = _plannedZoneDistribution(session.plannedZonesJson);
    // A lift is not executed in heart-rate zones; its sets are logged
    // separately. The completion link, duration and load stay.
    final strength = isStrengthSport(session.sport);
    final executionScore = strength
        ? null
        : ExecutionScoring.score3Axis(session, actualMin, zoneSec, planned);
    final scoredVsAdapted = session.status == 'adapted';
    final durationRatio = session.plannedDurationMin > 0
        ? actualMin / session.plannedDurationMin
        : 1.0;
    final load = effectiveLoad(activity);
    final tssRatio = session.plannedTrimp > 0
        ? load / session.plannedTrimp
        : null;
    final pi = ExecutionScoring.polarizationIndex(zoneSec);
    final verdict = strength
        ? null
        : ExecutionScoring.verdict(durationRatio, zoneSec, planned);
    // Intensity on its own: an hour at Z4 for an hour planned at Z2 is not
    // a completed session, however long it was.
    final intensity = strength
        ? null
        : intensityVerdict(
            Stimulus.planned(session),
            Stimulus.done(activity, zoneSec),
            loadRatio: tssRatio,
            durationRatio: durationRatio,
          );
    final outcome = executionOutcome(
      durationRatio: durationRatio,
      intensity: intensity,
      readinessLevel: await _readinessOn(activity.startDate),
    );

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
            intensityVerdict: Value(intensity),
            outcome: Value(outcome.name),
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

  /// Seconds in each of six zones: from the activity's own zone split, else
  /// from its heart-rate samples against the athlete's zones for [sport].
  /// All zero when neither is known.
  Future<List<double>> zoneSeconds(
    ActivityRecord activity,
    String sport,
  ) async {
    List<int>? floors;
    final split = ExecutionScoring.zoneSecFromSplit(
      activity.hrZonesJson,
      activity.durationSeconds.toDouble(),
    );
    if (split == null && activity.metricsJson != null) {
      final thresholds = await _thresholds.get();
      floors = thresholds == null
          ? null
          : _thresholds.hrZoneFloorsFor(thresholds, sport);
    }
    return ExecutionScoring.zoneSeconds(activity, floors);
  }

  /// The morning readiness level of [at]'s day, if it was scored.
  Future<String?> _readinessOn(DateTime at) async {
    final day = _day(at);
    final row =
        await (_db.select(_db.dailyReadinessRecords)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.date.isBiggerOrEqualValue(day) &
                    t.date.isSmallerThanValue(day.add(const Duration(days: 1))),
              )
              ..limit(1))
            .getSingleOrNull();
    return row?.level;
  }

  /// The athlete's answer why [sessionId] was shorter; its outcome follows.
  Future<void> setShortReason(String sessionId, String reason) async {
    final a = await (_db.select(
      _db.sessionActuals,
    )..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull();
    if (a == null) return;
    final outcome = executionOutcome(
      durationRatio: a.durationRatio ?? 1,
      intensity: a.intensityVerdict,
      shortReason: reason,
      readinessLevel: a.startedAt == null
          ? null
          : await _readinessOn(a.startedAt!),
    );
    await (_db.update(
      _db.sessionActuals,
    )..where((t) => t.sessionId.equals(sessionId))).write(
      SessionActualsCompanion(
        shortReason: Value(reason),
        outcome: Value(outcome.name),
      ),
    );
  }

  /// Sums the week of [day] again after its sessions changed.
  Future<void> refreshWeek(DateTime day) => _aggregateWeek(_weekStart(day));

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

  List<double>? _plannedZoneDistribution(String? json) =>
      plannedZoneDistribution(json);

  /// Planned share of time per zone (fractions summing to 1).
  static List<double>? plannedZoneDistribution(String? json) =>
      core.plannedZoneDistribution(json);

  /// Whether [activityId] already completed a session.
  Future<bool> _isLinked(String activityId) async =>
      (await (_db.select(_db.sessionActuals)
            ..where((t) => t.activityId.equals(activityId))
            ..limit(1))
          .getSingleOrNull()) !=
      null;

  /// Activities on [session]'s day that complete no session yet: what the
  /// athlete can mark it done with. The same sport comes first.
  Future<List<ActivityRecord>> unlinkedActivitiesFor(
    TrainingSession session,
  ) async {
    final day = _day(session.sessionDate);
    final linked = (await _db.select(_db.sessionActuals).get())
        .map((a) => a.activityId)
        .whereType<String>()
        .toSet();
    final activities =
        (await (_db.select(_db.activityRecords)
                  ..where(
                    (t) =>
                        t.startDate.isBiggerOrEqualValue(day) &
                        t.startDate.isSmallerThanValue(
                          DateTime(day.year, day.month, day.day + 1),
                        ),
                  )
                  ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
                .get())
            .where((a) => !linked.contains(a.activityId))
            .toList();
    int rank(ActivityRecord a) =>
        sportFamilyMatches(session.sport, a.type) ? 0 : 1;
    return [...activities]..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  /// Marks [session] done by hand: scored against [activity], or without
  /// one as done as planned. Whatever was recorded for it before goes.
  Future<void> completeByHand(
    TrainingSession session, {
    ActivityRecord? activity,
  }) async {
    await _clearCompletion(session.id);
    await (_db.update(
      _db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).write(
      TrainingSessionsCompanion(
        status: Value(session.status == 'adapted' ? 'adapted' : 'planned'),
        modifiedBy: const Value('athlete'),
        dateModified: Value(DateTime.now()),
      ),
    );
    final open = await (_db.select(
      _db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).getSingle();
    if (activity != null && await score(activity, chosen: open)) return;
    await _db.transaction(() async {
      await _db
          .into(_db.sessionActuals)
          .insertOnConflictUpdate(
            SessionActualsCompanion.insert(
              sessionId: session.id,
              durationRatio: const Value(1.0),
              outcome: Value(ExecutionOutcome.completed.name),
            ),
          );
      await (_db.update(
        _db.trainingSessions,
      )..where((t) => t.id.equals(session.id))).write(
        TrainingSessionsCompanion(
          status: const Value('completed'),
          actualDurationMin: Value(session.plannedDurationMin),
          dateModified: Value(DateTime.now()),
        ),
      );
    });
    await _aggregateWeek(_weekStart(session.sessionDate));
  }

  /// Marks [session] as not done: its completion goes, it is planned again
  /// and no activity completes it by itself any more.
  Future<void> reopen(TrainingSession session) async {
    final actual = await (_db.select(
      _db.sessionActuals,
    )..where((t) => t.sessionId.equals(session.id))).getSingleOrNull();
    await _clearCompletion(session.id);
    await (_db.update(
      _db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).write(
      TrainingSessionsCompanion(
        status: Value(actual?.scoredVsAdapted == true ? 'adapted' : 'planned'),
        actualDurationMin: const Value(null),
        modifiedBy: const Value(undoneByAthlete),
        dateModified: Value(DateTime.now()),
      ),
    );
    await _aggregateWeek(_weekStart(session.sessionDate));
  }

  Future<void> _clearCompletion(String sessionId) => _db.transaction(() async {
    for (final delete in [
      _db.delete(_db.sessionActuals)
        ..where((t) => t.sessionId.equals(sessionId)),
      _db.delete(_db.sessionNts)..where((t) => t.sessionId.equals(sessionId)),
      _db.delete(_db.sessionXp)..where((t) => t.sessionId.equals(sessionId)),
    ]) {
      await delete.go();
    }
  });

  /// Links completions from before the link existed to their activity, only
  /// where it is certain: the activity starts at exactly the recorded start
  /// and no other activity does. Anything less stays unlinked and can be
  /// corrected later. Returns how many were linked.
  Future<int> linkExistingCompletions() async {
    final open = await (_db.select(
      _db.sessionActuals,
    )..where((t) => t.activityId.isNull() & t.startedAt.isNotNull())).get();
    if (open.isEmpty) return 0;
    final taken = (await _db.select(_db.sessionActuals).get())
        .map((a) => a.activityId)
        .whereType<String>()
        .toSet();
    var linked = 0;
    for (final a in open) {
      final candidates = await (_db.select(
        _db.activityRecords,
      )..where((t) => t.startDate.equals(a.startedAt!))).get();
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
            // Still not to be completed by an activity by itself.
            modifiedBy: Value(
              s.modifiedBy == undoneByAthlete ? undoneByAthlete : 'system',
            ),
          ),
        );
        await _db
            .into(_db.sessionActuals)
            .insertOnConflictUpdate(
              SessionActualsCompanion.insert(
                sessionId: s.id,
                skipReason: const Value(noActivityReason),
                outcome: Value(ExecutionOutcome.missed.name),
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
                        t.status.isIn(const ['planned', 'adapted']) &
                        (t.modifiedBy.isNull() |
                            t.modifiedBy.isNotValue(undoneByAthlete)),
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

  /// Whether an activity of [activityType] can be the planned [sport].
  static bool sportFamilyMatches(String sport, String activityType) =>
      ExecutionScoring.sportFamilyMatches(sport, activityType);
}
