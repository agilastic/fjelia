import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../db/database.dart';
import '../../models/hrv_pair_assessment.dart';
import '../../models/hrv_training_episode.dart';
import 'activity_interval_resolver.dart';
import 'hrv_pair_assessment_service.dart';
import 'hrv_pairing_service.dart';
import 'hrv_timing_policy.dart';

/// Everything the card, the chart, the reminder and the AI read, built from
/// the same facts in one pass.
class HrvSnapshot {
  const HrvSnapshot({
    required this.episodes,
    required this.measurements,
    required this.pairings,
    required this.assessments,
    required this.intervening,
    required this.asOf,
  });
  final List<EpisodeFact> episodes;
  final List<MeasurementFact> measurements;
  final Map<String, EpisodePairing> pairings;
  final Map<String, HrvPairAssessment> assessments;

  /// Episodes followed by another workout before a post was taken.
  final Set<String> intervening;
  final DateTime asOf;

  EpisodeFact? episode(String id) {
    for (final e in episodes) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// The episode a measurement is the pre or post of, or null.
  String? episodeOfMeasurement(String uid) {
    for (final p in pairings.values) {
      if (p.pre?.uid == uid ||
          p.post?.uid == uid ||
          p.additionalPosts.any((m) => m.uid == uid)) {
        return p.episodeId;
      }
    }
    return null;
  }
}

/// The stable id of a stored reading. Rows written before ids existed get a
/// deterministic stand-in, so a view never loses track of them.
String hrvMeasurementUid(SpotHrvMeasurement r) =>
    r.measurementUid ?? 'row-${r.id}';

/// Sport family used to match like with like.
String hrvSportFamily(String type) {
  final t = type.toLowerCase();
  if (t.contains('run')) return 'running';
  if (t.contains('cycl') || t.contains('bik') || t.contains('ride')) {
    return 'cycling';
  }
  if (t.contains('swim')) return 'swimming';
  if (t.contains('strength') || t.contains('weight')) return 'strength';
  if (t.contains('hik') || t.contains('walk')) return 'walking';
  return 'other';
}

/// Activities that are not exercise: a breathing or relaxation session is a
/// context of its own and never a workout to pair with.
bool _isExercise(ActivityRecord a) {
  final t = a.type.toLowerCase();
  return !(t.contains('breath') ||
      t.contains('meditat') ||
      t.contains('relax') ||
      t == 'steps');
}

/// Resolves workouts into episodes, associates the HRV readings with them and
/// produces the shared assessment. Serialized and idempotent: running it again
/// on the same facts changes nothing.
class HrvTrainingService {
  HrvTrainingService(
    this.db, {
    DateTime Function()? clock,
    this.policy = HrvTimingPolicy.standard,
  }) : _clock = clock ?? DateTime.now,
       _pairing = HrvPairingService(policy: policy),
       _assessor = HrvPairAssessmentService(policy: policy),
       _resolver = ActivityIntervalResolver(policy: policy);

  final AppDatabase db;
  final HrvTimingPolicy policy;
  final DateTime Function() _clock;
  final HrvPairingService _pairing;
  final HrvPairAssessmentService _assessor;
  final ActivityIntervalResolver _resolver;
  static const _uuid = Uuid();

  // One writer at a time per database, across every instance in this isolate.
  static final _tails = Expando<Future<void>>('hrv training writer');

  Future<T> _serialized<T>(Future<T> Function() body) {
    final result = (_tails[db] ?? Future.value()).then((_) => body());
    _tails[db] = result.then((_) {}, onError: (_) {});
    return result;
  }

  DateTime get now => _clock();

  // ── Reconciliation ───────────────────────────────────────────────────────

  /// Brings episodes and links in line with the activities and readings now
  /// stored, then returns the shared snapshot.
  Future<HrvSnapshot> reconcile() => _serialized(_reconcile);

  Future<HrvSnapshot> _reconcile() async {
    final readings = await (db.select(
      db.spotHrvMeasurements,
    )..orderBy([(t) => OrderingTerm(expression: t.startedAt)])).get();
    final from = readings.isEmpty
        ? now.subtract(const Duration(days: 30))
        : readings.first.startedAt.subtract(const Duration(days: 1));
    await db.transaction(() async {
      await _syncEpisodes(from);
      await _repairLinks();
    });
    final snapshot = await _snapshot(readings);
    await db.transaction(() => _persistLinks(snapshot));
    return snapshot;
  }

  /// Creates or updates an episode for every exercise activity since [from],
  /// follows aliases, and retires episodes whose activity is gone.
  Future<void> _syncEpisodes(DateTime from) async {
    final activities = await (db.select(
      db.activityRecords,
    )..where((t) => t.startDate.isBiggerOrEqualValue(from))).get();
    final aliases = await db.select(db.hrvEpisodeAliases).get();
    final aliasOf = {
      for (final a in aliases) '${a.source}|${a.sourceActivityId}': a,
    };
    final episodes = {
      for (final e in await db.select(db.hrvTrainingEpisodes).get())
        e.episodeId: e,
    };
    final stamp = now;
    final seen = <String>{};

    for (final a in activities.where(_isExercise)) {
      final source = a.source ?? 'unknown';
      final interval = _resolver.resolve(
        start: a.startDate,
        durationSeconds: a.durationSeconds,
        source: source,
        movingDurationSeconds: a.movingDurationSeconds,
        now: stamp,
      );
      var alias = aliasOf['$source|${a.activityId}'];
      HrvTrainingEpisode? episode = alias == null
          ? null
          : episodes[alias.episodeId];
      // The same workout from another provider joins the episode it matches.
      episode ??= _duplicateOf(a, episodes.values);
      if (episode == null) {
        final id = _uuid.v4();
        await db
            .into(db.hrvTrainingEpisodes)
            .insert(
              HrvTrainingEpisodesCompanion.insert(
                episodeId: id,
                primaryActivityId: Value(a.activityId),
                sport: Value(hrvSportFamily(a.type)),
                actualStartUtc: interval.start.toUtc(),
                actualEndUtc: Value(interval.end?.toUtc()),
                intervalBasis: Value(interval.basis.name),
                intervalSource: Value(source),
                clockUncertain: Value(interval.clockUncertain),
                detectedAtUtc: stamp.toUtc(),
                createdAtUtc: stamp.toUtc(),
                updatedAtUtc: stamp.toUtc(),
              ),
            );
        episode = await (db.select(
          db.hrvTrainingEpisodes,
        )..where((t) => t.episodeId.equals(id))).getSingle();
        episodes[id] = episode;
      } else if (episode.state != 'deleted' &&
          _intervalChanged(episode, interval)) {
        // A user-reported finish is replaced by provider evidence, but a
        // provider interval is only replaced by a provider interval.
        final keepUser =
            episode.intervalBasis == IntervalBasis.userReported.name &&
            interval.basis == IntervalBasis.unknown;
        if (!keepUser) {
          await (db.update(
            db.hrvTrainingEpisodes,
          )..where((t) => t.episodeId.equals(episode!.episodeId))).write(
            HrvTrainingEpisodesCompanion(
              actualStartUtc: Value(interval.start.toUtc()),
              actualEndUtc: Value(interval.end?.toUtc()),
              intervalBasis: Value(interval.basis.name),
              intervalSource: Value(source),
              clockUncertain: Value(interval.clockUncertain),
              intervalRevision: Value(episode.intervalRevision + 1),
              dataRevision: Value(episode.dataRevision + 1),
              updatedAtUtc: Value(stamp.toUtc()),
            ),
          );
        }
      }
      if (episode.state == 'deleted') {
        await (db.update(
          db.hrvTrainingEpisodes,
        )..where((t) => t.episodeId.equals(episode!.episodeId))).write(
          HrvTrainingEpisodesCompanion(
            state: const Value('actualCompleted'),
            primaryActivityId: Value(a.activityId),
            updatedAtUtc: Value(stamp.toUtc()),
          ),
        );
      }
      if (alias == null) {
        await db
            .into(db.hrvEpisodeAliases)
            .insertOnConflictUpdate(
              HrvEpisodeAliasesCompanion.insert(
                source: source,
                sourceActivityId: a.activityId,
                episodeId: episode.episodeId,
                createdAtUtc: stamp.toUtc(),
              ),
            );
      }
      seen.add(episode.episodeId);
    }

    // Activities that were present once and are gone now. A provider that is
    // simply not reachable does not delete rows, so this only follows real
    // removals in our own store.
    final live = {for (final a in activities) a.activityId};
    final all = {
      for (final a in await db.select(db.activityRecords).get()) a.activityId,
    };
    for (final e in episodes.values) {
      if (e.state == 'deleted' || seen.contains(e.episodeId)) continue;
      if (e.intervalBasis == IntervalBasis.userReported.name &&
          e.primaryActivityId == null) {
        continue; // provisional episode from "workout finished"
      }
      final mine = [
        for (final a in aliases)
          if (a.episodeId == e.episodeId) a,
      ];
      final stillThere =
          mine.any((a) => all.contains(a.sourceActivityId)) ||
          (e.primaryActivityId != null &&
              (all.contains(e.primaryActivityId) ||
                  live.contains(e.primaryActivityId)));
      if (stillThere || !e.actualStartUtc.isAfter(from)) continue;
      await (db.update(
        db.hrvTrainingEpisodes,
      )..where((t) => t.episodeId.equals(e.episodeId))).write(
        HrvTrainingEpisodesCompanion(
          state: const Value('deleted'),
          dataRevision: Value(e.dataRevision + 1),
          updatedAtUtc: Value(stamp.toUtc()),
        ),
      );
    }
  }

  bool _intervalChanged(HrvTrainingEpisode e, ActualInterval i) =>
      e.actualStartUtc.toUtc() != i.start.toUtc() ||
      e.actualEndUtc?.toUtc() != i.end?.toUtc() ||
      e.intervalBasis != i.basis.name ||
      e.clockUncertain != i.clockUncertain;

  /// Two copies of one workout: the same start within a minute and the same
  /// length within two percent. An episode whose end is not known yet, or was
  /// reported by the athlete, also takes a provider copy that starts with it
  /// and ends within five minutes of the reported finish. Proximity alone
  /// merges nothing else.
  HrvTrainingEpisode? _duplicateOf(
    ActivityRecord a,
    Iterable<HrvTrainingEpisode> episodes,
  ) {
    for (final e in episodes) {
      if (e.state == 'deleted') continue;
      if (e.actualStartUtc.difference(a.startDate).inSeconds.abs() > 60) {
        continue;
      }
      final end = e.actualEndUtc;
      if (end == null) return e;
      final length = end.difference(e.actualStartUtc).inSeconds;
      if ((length - a.durationSeconds).abs() <= (length * .02).ceil()) {
        return e;
      }
      if (e.intervalBasis == IntervalBasis.userReported.name &&
          (length - a.durationSeconds).abs() <= 300) {
        return e;
      }
    }
    return null;
  }

  /// Retracts links whose reading or workout no longer exists.
  Future<void> _repairLinks() async {
    final uids = {
      for (final r in await db.select(db.spotHrvMeasurements).get())
        r.measurementUid,
    };
    final episodes = {
      for (final e in await db.select(db.hrvTrainingEpisodes).get())
        if (e.state != 'deleted' && e.state != 'cancelled') e.episodeId,
    };
    final active = await (db.select(
      db.hrvEpisodeMeasurements,
    )..where((t) => t.state.equals('active'))).get();
    for (final l in active) {
      if (uids.contains(l.measurementUid) && episodes.contains(l.episodeId)) {
        continue;
      }
      await _retract(l.linkId, 'sourceGone');
    }
  }

  Future<void> _retract(int linkId, String reason) =>
      (db.update(
        db.hrvEpisodeMeasurements,
      )..where((t) => t.linkId.equals(linkId))).write(
        HrvEpisodeMeasurementsCompanion(
          state: const Value('retracted'),
          reason: Value(reason),
          retractedAtUtc: Value(now.toUtc()),
        ),
      );

  // ── Facts ────────────────────────────────────────────────────────────────

  MeasurementFact _fact(SpotHrvMeasurement r) {
    final end =
        r.samplingEndedAt ??
        r.startedAt.add(Duration(seconds: r.durationSeconds));
    return MeasurementFact(
      uid: hrvMeasurementUid(r),
      startedAt: r.startedAt,
      endedAt: end,
      context: r.context,
      posture: r.posture,
      durationSeconds: r.durationSeconds,
      settleSeconds: r.settleSeconds,
      rmssdMs: r.rmssdMs,
      sdnnMs: r.sdnnMs,
      deviceId: r.deviceId,
      metricKind: r.metricKind,
      usable: r.qualityState != 'invalid',
      legacyQualityUnknown: r.qualityState == 'legacyUnverified',
      clockUncertain: (r.qualityReasons ?? '').contains('clockUncertain'),
      reportedMinutesAfter: r.minutesAfterTraining,
      revision: r.revision,
    );
  }

  EpisodeFact _episodeFact(HrvTrainingEpisode e) => EpisodeFact(
    id: e.episodeId,
    sport: e.sport,
    parentId: e.parentEpisodeId,
    detectedAt: e.detectedAtUtc,
    plannedSessionId: e.plannedSessionId,
    activityId: e.primaryActivityId,
    intervalRevision: e.intervalRevision,
    state: EpisodeState.values.firstWhere(
      (s) => s.name == e.state,
      orElse: () => EpisodeState.actualCompleted,
    ),
    interval: ActualInterval(
      start: e.actualStartUtc,
      end: e.actualEndUtc,
      basis: IntervalBasis.parse(e.intervalBasis),
      clockUncertain: e.clockUncertain,
    ),
  );

  Future<HrvSnapshot> _snapshot(List<SpotHrvMeasurement> readings) async {
    final episodeRows = await db.select(db.hrvTrainingEpisodes).get();
    final episodes = [
      for (final e in episodeRows)
        if (e.state != 'deleted' && e.state != 'cancelled') _episodeFact(e),
    ];
    final measurements = [for (final r in readings) _fact(r)];
    final links = await (db.select(
      db.hrvEpisodeMeasurements,
    )..where((t) => t.state.equals('active'))).get();
    final pins = [
      for (final l in links)
        if (l.associationMethod != AssociationMethod.automaticTimeline.name)
          HrvPin(
            l.measurementUid,
            l.episodeId,
            l.role == 'pre' ? HrvRole.pre : HrvRole.post,
            method: AssociationMethod.values.firstWhere(
              (m) => m.name == l.associationMethod,
            ),
          ),
    ];
    final result = _pairing.resolve(
      episodes: episodes,
      measurements: measurements,
      pins: pins,
    );
    final intervening = <String>{};
    for (final e in episodes) {
      final end = e.end;
      if (end == null || e.parentId != null) continue;
      final hit = episodes.any(
        (o) =>
            o.id != e.id &&
            o.parentId == null &&
            !o.start.isBefore(end) &&
            o.start.isBefore(end.add(policy.expiry)),
      );
      if (hit) intervening.add(e.id);
    }
    final assessments = <String, HrvPairAssessment>{
      for (final e in episodes)
        if (result.of(e.id) != null)
          e.id: _assessor.assess(
            e,
            result.of(e.id)!,
            interveningWorkout:
                intervening.contains(e.id) && result.of(e.id)!.post == null,
          ),
    };
    return HrvSnapshot(
      episodes: episodes,
      measurements: measurements,
      pairings: result.pairings,
      assessments: assessments,
      intervening: intervening,
      asOf: now,
    );
  }

  /// Makes the stored links equal the resolved ones. Removed links are
  /// retracted, not deleted, so the history stays.
  Future<void> _persistLinks(HrvSnapshot snapshot) async {
    final desired = <HrvLink>{};
    for (final p in snapshot.pairings.values) {
      for (final m in [p.pre, p.post, ...p.additionalPosts]) {
        if (m == null) continue;
        final role = m == p.pre ? HrvRole.pre : HrvRole.post;
        desired.add(
          HrvLink(
            episodeId: p.episodeId,
            measurementUid: m.uid,
            role: role,
            selection: m == p.pre || m == p.post
                ? LinkSelection.primary
                : LinkSelection.additional,
            method: AssociationMethod.automaticTimeline,
          ),
        );
      }
    }
    final stored = await (db.select(
      db.hrvEpisodeMeasurements,
    )..where((t) => t.state.equals('active'))).get();
    bool same(HrvEpisodeMeasurement s, HrvLink d) =>
        s.episodeId == d.episodeId &&
        s.measurementUid == d.measurementUid &&
        s.role == d.role.name &&
        s.selection == d.selection.name;
    // Fixed, athlete-made links are kept while their timing holds; a pin
    // that no longer fits its workout is dropped with a reason.
    final matched = <int>{};
    final missing = <HrvLink>[];
    for (final d in desired) {
      final s = stored.where((s) => same(s, d)).firstOrNull;
      if (s != null) {
        matched.add(s.linkId);
      } else {
        missing.add(d);
      }
    }
    for (final s in stored) {
      if (matched.contains(s.linkId)) continue;
      await _retract(
        s.linkId,
        s.associationMethod == AssociationMethod.automaticTimeline.name
            ? 'reconciled'
            : 'timingContradiction',
      );
    }
    for (final d in missing) {
      await db
          .into(db.hrvEpisodeMeasurements)
          .insert(
            HrvEpisodeMeasurementsCompanion.insert(
              episodeId: d.episodeId,
              measurementUid: d.measurementUid,
              role: d.role.name,
              selection: d.selection.name,
              associationMethod: d.method.name,
              policyVersion: policy.version,
              evidenceRevision: Value(
                snapshot.assessments[d.episodeId] == null
                    ? 0
                    : snapshot.episode(d.episodeId)?.intervalRevision ?? 0,
              ),
              createdAtUtc: now.toUtc(),
            ),
          );
    }
  }

  // ── Corrections ──────────────────────────────────────────────────────────

  /// Fixes a reading to a workout in a role. Atomic: the reading's earlier
  /// link is retracted in the same transaction, and the audit keeps both.
  Future<HrvSnapshot> correct(
    String measurementUid,
    String episodeId,
    HrvRole role, {
    String reason = 'userCorrection',
    AssociationMethod method = AssociationMethod.userCorrection,
  }) => _serialized(() async {
    await db.transaction(() async {
      final active =
          await (db.select(db.hrvEpisodeMeasurements)..where(
                (t) =>
                    t.state.equals('active') &
                    (t.measurementUid.equals(measurementUid) |
                        (t.episodeId.equals(episodeId) &
                            t.role.equals(role.name) &
                            t.selection.equals('primary'))),
              ))
              .get();
      for (final l in active) {
        await _retract(l.linkId, 'replacedBy:$reason');
      }
      await db
          .into(db.hrvEpisodeMeasurements)
          .insert(
            HrvEpisodeMeasurementsCompanion.insert(
              episodeId: episodeId,
              measurementUid: measurementUid,
              role: role.name,
              selection: 'primary',
              associationMethod: method.name,
              reason: Value(reason),
              policyVersion: policy.version,
              createdAtUtc: now.toUtc(),
            ),
          );
    });
    return _reconcile();
  });

  /// Removes a reading from its workout. The reading itself stays.
  Future<HrvSnapshot> unlink(String measurementUid) => _serialized(() async {
    await db.transaction(() async {
      final active =
          await (db.select(db.hrvEpisodeMeasurements)..where(
                (t) =>
                    t.state.equals('active') &
                    t.measurementUid.equals(measurementUid),
              ))
              .get();
      for (final l in active) {
        await _retract(l.linkId, 'userUnlinked');
      }
    });
    return _reconcile();
  });

  // ── Reading the result ───────────────────────────────────────────────────

  /// The episode of an activity, following aliases of merged copies.
  Future<String?> episodeIdOfActivity(String activityId) async {
    final alias = await (db.select(
      db.hrvEpisodeAliases,
    )..where((t) => t.sourceActivityId.equals(activityId))).getSingleOrNull();
    if (alias != null) return alias.episodeId;
    final episode = await (db.select(
      db.hrvTrainingEpisodes,
    )..where((t) => t.primaryActivityId.equals(activityId))).getSingleOrNull();
    return episode?.episodeId;
  }

  /// Records the athlete's own report that a workout finished, for a source
  /// that cannot say so in time. Evidence of the user, not of a provider.
  Future<String> reportFinish({
    required DateTime start,
    required DateTime end,
    String sport = 'other',
    String? activityId,
  }) => _serialized(() async {
    if (!end.isAfter(start)) {
      throw ArgumentError('The finish must be after the start.');
    }
    final stamp = now;
    final id = _uuid.v4();
    await db
        .into(db.hrvTrainingEpisodes)
        .insert(
          HrvTrainingEpisodesCompanion.insert(
            episodeId: id,
            primaryActivityId: Value(activityId),
            sport: Value(sport),
            actualStartUtc: start.toUtc(),
            actualEndUtc: Value(end.toUtc()),
            intervalBasis: Value(IntervalBasis.userReported.name),
            intervalSource: const Value('user'),
            state: const Value('actualCompleted'),
            detectedAtUtc: stamp.toUtc(),
            createdAtUtc: stamp.toUtc(),
            updatedAtUtc: stamp.toUtc(),
          ),
        );
    return id;
  });

  // ── Feedback ─────────────────────────────────────────────────────────────

  Future<void> recordFeedback(
    String episodeId, {
    int? rpe,
    String? note,
    String context = 'postTraining',
  }) async {
    if (rpe != null && (rpe < 0 || rpe > 10)) {
      throw ArgumentError('RPE is 0 to 10.');
    }
    final previous =
        await (db.select(db.hrvEpisodeFeedback)..where(
              (t) => t.episodeId.equals(episodeId) & t.context.equals(context),
            ))
            .get();
    await db
        .into(db.hrvEpisodeFeedback)
        .insert(
          HrvEpisodeFeedbackCompanion.insert(
            feedbackUid: _uuid.v4(),
            episodeId: episodeId,
            context: context,
            recordedAtUtc: now.toUtc(),
            rpe: Value(rpe),
            note: Value(
              note == null || note.trim().isEmpty ? null : note.trim(),
            ),
            revision: Value(previous.length),
          ),
        );
  }

  /// The newest explicit report for the context, else null. The caller falls
  /// back to the session's own RPE and labels it as that.
  Future<HrvEpisodeFeedbackData?> latestFeedback(
    String episodeId, {
    String context = 'postTraining',
  }) =>
      (db.select(db.hrvEpisodeFeedback)
            ..where(
              (t) => t.episodeId.equals(episodeId) & t.context.equals(context),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.recordedAtUtc),
              (t) => OrderingTerm.desc(t.revision),
            ])
            ..limit(1))
          .getSingleOrNull();
}
