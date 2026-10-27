import 'dart:convert';

import 'package:drift/drift.dart';

import '../../db/database.dart';
import '../../models/strength_workout.dart';
import 'strength_templates.dart';

/// Who a planned strength document belongs to. Never a date or a title.
class StrengthPlanOwner {
  const StrengthPlanOwner(this.kind, this.key);

  /// An app-planned session.
  factory StrengthPlanOwner.session(String sessionId) =>
      StrengthPlanOwner('session', sessionId);

  /// One scheduled occurrence of a provider workout; a repeated workout
  /// definition is not one shared session.
  factory StrengthPlanOwner.scheduled(String provider, String scheduleId) =>
      StrengthPlanOwner('scheduled', '$provider:$scheduleId');

  /// The athlete's own reusable template.
  factory StrengthPlanOwner.template(String id) =>
      StrengthPlanOwner('template', id);

  final String kind, key;

  @override
  bool operator ==(Object other) =>
      other is StrengthPlanOwner && other.kind == kind && other.key == key;
  @override
  int get hashCode => Object.hash(kind, key);
  @override
  String toString() => '$kind:$key';
}

/// A saved plan revision.
class StoredStrengthPlan {
  const StoredStrengthPlan({
    required this.owner,
    required this.revisionId,
    required this.revision,
    required this.plan,
  });
  final StrengthPlanOwner owner;
  final String revisionId;
  final int revision;
  final StrengthWorkoutPlan plan;
}

/// A save based on an outdated revision; the athlete's draft is kept.
class StrengthConflictException implements Exception {
  StrengthConflictException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Stored strength data that cannot be read. It is never overwritten by an
/// empty replacement.
class StrengthUnreadableException implements Exception {
  StrengthUnreadableException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Older comparable history is shown but marked stale, and never qualifies
/// for a progression proposal. A Fjelia product policy, not a physiological
/// boundary.
const strengthHistoryStaleAfter = Duration(days: 42);

/// The most recent comparable performance of one exercise context.
class StrengthHistoryEntry {
  const StrengthHistoryEntry({
    required this.activityId,
    required this.date,
    required this.source,
    required this.sets,
    required this.stale,
    this.logRevision = 0,
  });
  final String activityId;

  /// Revision of the log the sets came from.
  final int logRevision;
  final DateTime date;
  final String? source;

  /// Recorded working sets, in order.
  final List<StrengthSetResult> sets;
  final bool stale;

  /// The load used in the working sets, when one load was used throughout.
  StrengthLoad? get commonLoad {
    final loads = sets.map((s) => s.load).toList();
    if (loads.isEmpty || loads.any((l) => l == null)) return null;
    final kg = loads.first!.kg;
    return loads.every((l) => (l!.kg - kg).abs() < 1e-9) ? loads.first : null;
  }
}

class StrengthRepository {
  StrengthRepository(this.db);
  final AppDatabase db;

  // ── Plans ───────────────────────────────────────────────────────────────

  /// The current plan of [owner], or null when none was saved.
  /// Throws [StrengthUnreadableException] for a malformed stored document.
  Future<StoredStrengthPlan?> loadPlan(StrengthPlanOwner owner) async {
    final head =
        await (db.select(db.strengthPlanHeads)..where(
              (t) =>
                  t.ownerKind.equals(owner.kind) & t.ownerKey.equals(owner.key),
            ))
            .getSingleOrNull();
    if (head == null) return null;
    return revision(head.revisionId);
  }

  Future<StoredStrengthPlan?> revision(String revisionId) async {
    final row = await (db.select(
      db.strengthPlanRevisions,
    )..where((t) => t.revisionId.equals(revisionId))).getSingleOrNull();
    if (row == null) return null;
    return StoredStrengthPlan(
      owner: StrengthPlanOwner(row.ownerKind, row.ownerKey),
      revisionId: row.revisionId,
      revision: row.revision,
      plan: _decodePlan(row.planJson),
    );
  }

  StrengthWorkoutPlan _decodePlan(String json) {
    try {
      return StrengthWorkoutPlan.fromJson(jsonDecode(json) as Map);
    } on FormatException catch (e) {
      throw StrengthUnreadableException(
        'This strength plan cannot be read (${e.message}).',
      );
    } on TypeError {
      throw StrengthUnreadableException('This strength plan cannot be read.');
    }
  }

  /// Saves [plan] as the next revision of [owner], atomically with its head.
  /// [expectedRevision] is the revision the editor started from (0 for none).
  Future<StoredStrengthPlan> savePlan(
    StrengthPlanOwner owner,
    StrengthWorkoutPlan plan, {
    required int expectedRevision,
  }) async {
    final errors = plan.validate();
    if (plan.isEmpty) errors.add('Add at least one exercise.');
    if (errors.isNotEmpty) throw StrengthValidationException(errors.first);
    return db.transaction(() async {
      final head =
          await (db.select(db.strengthPlanHeads)..where(
                (t) =>
                    t.ownerKind.equals(owner.kind) &
                    t.ownerKey.equals(owner.key),
              ))
              .getSingleOrNull();
      final current = head?.revision ?? 0;
      if (current != expectedRevision) {
        throw StrengthConflictException(
          'This workout was changed elsewhere. Your edits are kept; reload '
          'to see the newer version.',
        );
      }
      final now = DateTime.now();
      final id = newStrengthId('rev');
      final next = current + 1;
      await db
          .into(db.strengthPlanRevisions)
          .insert(
            StrengthPlanRevisionsCompanion.insert(
              revisionId: id,
              ownerKind: owner.kind,
              ownerKey: owner.key,
              revision: next,
              schemaVersion: plan.schemaVersion,
              planJson: jsonEncode(plan.toJson()),
              createdAt: now,
            ),
          );
      await db
          .into(db.strengthPlanHeads)
          .insertOnConflictUpdate(
            StrengthPlanHeadsCompanion.insert(
              ownerKind: owner.kind,
              ownerKey: owner.key,
              revisionId: id,
              revision: next,
              updatedAt: now,
            ),
          );
      return StoredStrengthPlan(
        owner: owner,
        revisionId: id,
        revision: next,
        plan: plan,
      );
    });
  }

  /// The athlete's saved templates.
  Future<List<StoredStrengthPlan>> templates() async {
    final heads = await (db.select(
      db.strengthPlanHeads,
    )..where((t) => t.ownerKind.equals('template'))).get();
    final out = <StoredStrengthPlan>[];
    for (final h in heads) {
      try {
        final p = await revision(h.revisionId);
        if (p != null) out.add(p);
      } on StrengthUnreadableException {
        continue;
      }
    }
    return out;
  }

  // ── Logs ────────────────────────────────────────────────────────────────

  /// The log of [activityId], or null when nothing was recorded.
  Future<StrengthActivityLog?> loadLog(String activityId) async {
    final row = await (db.select(
      db.strengthActivityLogs,
    )..where((t) => t.activityId.equals(activityId))).getSingleOrNull();
    if (row == null) return null;
    final exercises =
        await (db.select(db.strengthPerformedExercises)
              ..where((t) => t.activityId.equals(activityId))
              ..orderBy([(t) => OrderingTerm(expression: t.position)]))
            .get();
    final sets =
        await (db.select(db.strengthPerformedSets)
              ..where((t) => t.activityId.equals(activityId))
              ..orderBy([(t) => OrderingTerm(expression: t.position)]))
            .get();
    StrengthPlanBaseline? baseline;
    if (row.baselineJson != null) {
      try {
        baseline = StrengthPlanBaseline.fromJson(
          jsonDecode(row.baselineJson!) as Map,
        );
      } on Object {
        throw StrengthUnreadableException(
          'The plan this workout is compared with cannot be read.',
        );
      }
    }
    return StrengthActivityLog(
      activityId: activityId,
      revision: row.revision,
      status: StrengthLogStatus.parse(row.status),
      incompleteAcknowledged: row.incompleteAcknowledged,
      baseline: baseline,
      notes: row.notes,
      exercises: [
        for (final e in exercises)
          StrengthPerformedExercise(
            id: e.id,
            variantId: e.variantId,
            name: e.name,
            equipment: e.equipment,
            convention: StrengthConvention.fromJson(
              jsonDecode(e.conventionJson),
            ),
            plannedExerciseId: e.plannedExerciseId,
            notes: e.notes,
            sets: [
              for (final s in sets.where((s) => s.exerciseId == e.id))
                _setFromRow(s),
            ],
          ),
      ],
    );
  }

  StrengthSetResult _setFromRow(StrengthSetRow s) => StrengthSetResult(
    id: s.id,
    plannedSetId: s.plannedSetId,
    kind: StrengthSetKind.parse(s.kind),
    status: StrengthSetStatus.parse(s.status),
    reps: s.reps,
    durationSeconds: s.durationSeconds,
    load: s.loadKg == null
        ? null
        : StrengthLoad(s.loadKg!, unit: MassUnit.parse(s.loadUnit)),
    resistance: s.resistance,
    restSeconds: s.restSeconds,
    restOrigin: s.restOrigin == null
        ? null
        : StrengthOrigin.parse(s.restOrigin),
    effort: s.effortScale == null || s.effortValue == null
        ? null
        : StrengthEffort.fromJson({
            'scale': s.effortScale,
            'value': s.effortValue,
          }),
    notes: s.notes,
    origins: s.originsJson == null
        ? const {}
        : {
            for (final e in (jsonDecode(s.originsJson!) as Map).entries)
              e.key as String: StrengthOrigin.parse(e.value),
          },
  );

  /// Saves the whole log atomically as its next revision.
  /// [log.revision] is the revision the editor started from.
  Future<StrengthActivityLog> saveLog(StrengthActivityLog log) async {
    final errors = log.validate();
    if (errors.isNotEmpty) throw StrengthValidationException(errors.first);
    return db.transaction(() async {
      final activity = await db.getActivityById(log.activityId);
      if (activity == null) {
        throw StateError('This activity no longer exists.');
      }
      final row = await (db.select(
        db.strengthActivityLogs,
      )..where((t) => t.activityId.equals(log.activityId))).getSingleOrNull();
      final current = row?.revision ?? 0;
      if (current != log.revision) {
        throw StrengthConflictException(
          'This log was changed elsewhere. Your entries are kept; reload to '
          'see the newer version.',
        );
      }
      final next = current + 1;
      await (db.delete(
        db.strengthPerformedSets,
      )..where((t) => t.activityId.equals(log.activityId))).go();
      await (db.delete(
        db.strengthPerformedExercises,
      )..where((t) => t.activityId.equals(log.activityId))).go();
      for (var i = 0; i < log.exercises.length; i++) {
        final e = log.exercises[i];
        await db
            .into(db.strengthPerformedExercises)
            .insert(
              StrengthPerformedExercisesCompanion.insert(
                id: e.id,
                activityId: log.activityId,
                position: i,
                variantId: e.variantId,
                contextKey: e.contextKey,
                name: e.name,
                equipment: e.equipment,
                conventionJson: jsonEncode(e.convention.toJson()),
                plannedExerciseId: Value(e.plannedExerciseId),
                notes: Value(e.notes),
              ),
            );
        for (var j = 0; j < e.sets.length; j++) {
          final s = e.sets[j];
          await db
              .into(db.strengthPerformedSets)
              .insert(
                StrengthPerformedSetsCompanion.insert(
                  id: s.id,
                  exerciseId: e.id,
                  activityId: log.activityId,
                  position: j,
                  plannedSetId: Value(s.plannedSetId),
                  kind: s.kind.name,
                  status: s.status.name,
                  reps: Value(s.reps),
                  durationSeconds: Value(s.durationSeconds),
                  loadKg: Value(s.load?.kg),
                  loadUnit: Value(s.load?.unit.name),
                  resistance: Value(s.resistance),
                  restSeconds: Value(s.restSeconds),
                  restOrigin: Value(s.restOrigin?.name),
                  effortScale: Value(s.effort?.scale.name),
                  effortValue: Value(s.effort?.value),
                  notes: Value(s.notes),
                  originsJson: Value(
                    s.origins.isEmpty
                        ? null
                        : jsonEncode({
                            for (final o in s.origins.entries)
                              o.key: o.value.name,
                          }),
                  ),
                ),
              );
        }
      }
      await db
          .into(db.strengthActivityLogs)
          .insertOnConflictUpdate(
            StrengthActivityLogsCompanion.insert(
              activityId: log.activityId,
              revision: next,
              status: log.status.name,
              incompleteAcknowledged: Value(log.incompleteAcknowledged),
              baselineJson: Value(
                log.baseline == null
                    ? null
                    : jsonEncode(log.baseline!.toJson()),
              ),
              notes: Value(log.notes),
              activityStart: activity.startDate,
              updatedAt: DateTime.now(),
            ),
          );
      return log.copyWith(revision: next);
    });
  }

  // ── Plan links ──────────────────────────────────────────────────────────

  /// The planned session explicitly linked to [activityId], if any. Never a
  /// date match.
  Future<String?> linkedSessionId(String activityId) async {
    final row = await (db.select(
      db.sessionActuals,
    )..where((t) => t.activityId.equals(activityId))).getSingleOrNull();
    return row?.sessionId;
  }

  /// A baseline frozen from the current revision of [owner].
  Future<StrengthPlanBaseline?> baselineFor(
    StrengthPlanOwner owner, {
    bool retrospective = false,
  }) async {
    final stored = await loadPlan(owner);
    if (stored == null) return null;
    return StrengthPlanBaseline(
      ownerKind: owner.kind,
      ownerKey: owner.key,
      revisionId: stored.revisionId,
      plan: stored.plan,
      retrospective: retrospective,
    );
  }

  /// The baseline of an app-planned session. A session made from a verified
  /// bundled template without a saved plan gets that structure saved as its
  /// first revision, so the baseline names a revision. Null when the session
  /// has no exercises.
  Future<StrengthPlanBaseline?> sessionBaseline(String sessionId) async {
    final owner = StrengthPlanOwner.session(sessionId);
    if (await loadPlan(owner) == null) {
      final session = await (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
      final bundled = session == null
          ? null
          : bundledStrengthPlanFor(
              subType: session.subType,
              sessionNotes: session.sessionNotes,
            );
      if (bundled == null) return null;
      await savePlan(owner, bundled, expectedRevision: 0);
    }
    return baselineFor(owner);
  }

  /// The plan a session's strength workout is sent from: its saved plan, or
  /// a verified bundled structure. Null when it has no exercises.
  Future<({StrengthWorkoutPlan plan, String revision})?> sessionPlan(
    TrainingSession s,
  ) async {
    final stored = await loadPlan(StrengthPlanOwner.session(s.id));
    if (stored != null) {
      return (plan: stored.plan, revision: stored.revisionId);
    }
    final bundled = bundledStrengthPlanFor(
      subType: s.subType,
      sessionNotes: s.sessionNotes,
    );
    final t = bundled?.template;
    return bundled == null || t == null
        ? null
        : (plan: bundled, revision: 'bundled:${t.id}@${t.revision}');
  }

  // ── Live workouts (Stage C) ─────────────────────────────────────────────

  /// Source of an activity recorded live in Fjelia's gym mode.
  static const liveSource = 'fjelia_live';

  /// Starts gym mode: a local activity, and its log with [stored] frozen as
  /// the baseline and every set unrecorded.
  Future<StrengthActivityLog> startLiveSession({
    required StoredStrengthPlan stored,
    required String title,
    DateTime? now,
  }) => db.transaction(() async {
    final id = 'fjelia-live:${newStrengthId('act')}';
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: title,
            type: 'strength_training',
            startDate: now ?? DateTime.now(),
            durationSeconds: 0,
            source: const Value(liveSource),
          ),
        );
    return saveLog(
      StrengthActivityLog(
        activityId: id,
        baseline: StrengthPlanBaseline(
          ownerKind: stored.owner.kind,
          ownerKey: stored.owner.key,
          revisionId: stored.revisionId,
          plan: stored.plan,
        ),
        exercises: logLayoutFromPlan(stored.plan),
      ),
    );
  });

  Future<DateTime?> activityStart(String activityId) async =>
      (await db.getActivityById(activityId))?.startDate;

  /// An unfinished live workout of [owner], to resume.
  Future<StrengthActivityLog?> openLiveSession(StrengthPlanOwner owner) async {
    final open =
        await (db.select(db.activityRecords)
              ..where(
                (t) =>
                    t.source.equals(liveSource) & t.durationSeconds.equals(0),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
            .get();
    for (final a in open) {
      final log = await loadLog(a.activityId);
      final b = log?.baseline;
      if (b != null && b.ownerKind == owner.kind && b.ownerKey == owner.key) {
        return log;
      }
    }
    return null;
  }

  /// Ends a live workout: its duration is the time since it started. When
  /// [sessionId] is given, the planned session is completed by it, unless
  /// the session or the activity is already linked.
  Future<void> finishLiveSession(
    String activityId, {
    String? sessionId,
    DateTime? now,
  }) => db.transaction(() async {
    final a = await db.getActivityById(activityId);
    if (a == null) throw StateError('This workout no longer exists.');
    final end = now ?? DateTime.now();
    final seconds = end.difference(a.startDate).inSeconds;
    await (db.update(
      db.activityRecords,
    )..where((t) => t.activityId.equals(activityId))).write(
      ActivityRecordsCompanion(
        durationSeconds: Value(seconds < 1 ? 1 : seconds),
      ),
    );
    if (sessionId == null) return;
    final linked =
        await (db.select(db.sessionActuals)..where(
              (t) =>
                  t.sessionId.equals(sessionId) |
                  t.activityId.equals(activityId),
            ))
            .get();
    if (linked.any((r) => r.activityId != null)) return;
    await db
        .into(db.sessionActuals)
        .insertOnConflictUpdate(
          SessionActualsCompanion(
            sessionId: Value(sessionId),
            activityId: Value(activityId),
            startedAt: Value(a.startDate),
            completedAt: Value(end),
          ),
        );
    await (db.update(
      db.trainingSessions,
    )..where((t) => t.id.equals(sessionId))).write(
      TrainingSessionsCompanion(
        status: const Value('completed'),
        actualDurationMin: Value((seconds / 60).round()),
        dateModified: Value(end),
      ),
    );
  });

  /// Removes a live workout that was started by mistake.
  Future<void> discardLiveSession(String activityId) async {
    final a = await db.getActivityById(activityId);
    if (a?.source != liveSource) return;
    await db.deleteActivityById(activityId);
  }

  /// One physical session, one history: a finished live workout that a
  /// watch or Health later records too (the same sport, overlapping by at
  /// least half of the shorter one) moves its log and its plan link to that
  /// activity, and the local copy goes. A log the athlete wrote on the
  /// imported activity is never replaced; both then stay. Returns how many
  /// were merged.
  Future<int> reconcileLiveSessions() async {
    final lives =
        await (db.select(db.activityRecords)..where(
              (t) =>
                  t.source.equals(liveSource) &
                  t.durationSeconds.isBiggerThanValue(0),
            ))
            .get();
    var merged = 0;
    for (final live in lives) {
      final liveEnd = live.startDate.add(
        Duration(seconds: live.durationSeconds),
      );
      final near =
          await (db.select(db.activityRecords)..where(
                (t) =>
                    t.activityId.equals(live.activityId).not() &
                    t.startDate.isBiggerThanValue(
                      live.startDate.subtract(const Duration(hours: 6)),
                    ) &
                    t.startDate.isSmallerThanValue(liveEnd),
              ))
              .get();
      ActivityRecord? best;
      var bestOverlap = 0;
      for (final a in near) {
        if (a.source == liveSource || !isStrengthSport(a.type)) continue;
        final end = a.startDate.add(Duration(seconds: a.durationSeconds));
        final from = a.startDate.isAfter(live.startDate)
            ? a.startDate
            : live.startDate;
        final to = end.isBefore(liveEnd) ? end : liveEnd;
        final overlap = to.difference(from).inSeconds;
        final shorter = a.durationSeconds < live.durationSeconds
            ? a.durationSeconds
            : live.durationSeconds;
        if (shorter > 0 && overlap * 2 >= shorter && overlap > bestOverlap) {
          best = a;
          bestOverlap = overlap;
        }
      }
      if (best == null) continue;
      final target = best;
      final existing = await loadLog(target.activityId);
      final importOnly =
          existing == null ||
          existing.exercises.every((e) => e.id.startsWith('garmin:'));
      if (!importOnly) continue;
      await db.transaction(() async {
        await db.deleteStrengthLog(target.activityId);
        for (final table in const [
          'strength_activity_logs',
          'strength_performed_exercises',
          'strength_performed_sets',
        ]) {
          await db.customUpdate(
            'UPDATE $table SET activity_id = ? WHERE activity_id = ?',
            variables: [
              Variable.withString(target.activityId),
              Variable.withString(live.activityId),
            ],
          );
        }
        await (db.update(
          db.strengthActivityLogs,
        )..where((t) => t.activityId.equals(target.activityId))).write(
          StrengthActivityLogsCompanion(activityStart: Value(target.startDate)),
        );
        final targetLinked =
            await (db.select(db.sessionActuals)
                  ..where((t) => t.activityId.equals(target.activityId)))
                .getSingleOrNull();
        await (db.update(
          db.sessionActuals,
        )..where((t) => t.activityId.equals(live.activityId))).write(
          SessionActualsCompanion(
            activityId: Value(targetLinked == null ? target.activityId : null),
          ),
        );
        final intake =
            await (db.select(db.nutritionRecords)..where(
                  (t) => t.recordKey.equals('intake:${target.activityId}'),
                ))
                .getSingleOrNull();
        if (intake == null) {
          await (db.update(db.nutritionRecords)
                ..where((t) => t.recordKey.equals('intake:${live.activityId}')))
              .write(
                NutritionRecordsCompanion(
                  recordKey: Value('intake:${target.activityId}'),
                ),
              );
        }
        await (db.delete(
          db.activityRecords,
        )..where((t) => t.activityId.equals(live.activityId))).go();
      });
      merged++;
    }
    return merged;
  }

  // ── History ─────────────────────────────────────────────────────────────

  /// The latest recorded working sets of one exercise context before
  /// [before]: same movement, equipment and load convention. Warm-ups,
  /// unrecorded and skipped sets do not count.
  Future<StrengthHistoryEntry?> recentComparableHistory(
    String contextKey, {
    required DateTime before,
    String? excludeActivityId,
    DateTime? now,
  }) async {
    final rows = await db
        .customSelect(
          'SELECT s.*, l.activity_start AS started, l.revision AS log_rev, '
          'a.source AS src '
          'FROM strength_performed_sets s '
          'JOIN strength_performed_exercises e ON e.id = s.exercise_id '
          'JOIN strength_activity_logs l ON l.activity_id = s.activity_id '
          'LEFT JOIN activity_records a ON a.activity_id = s.activity_id '
          'WHERE e.context_key = ? AND l.activity_start < ? '
          "AND s.kind != 'warmup' "
          "AND s.status IN ('completed', 'partial', 'failed') "
          'AND s.activity_id != ? '
          'AND l.activity_id = ('
          '  SELECT l2.activity_id FROM strength_activity_logs l2 '
          '  JOIN strength_performed_exercises e2 ON e2.activity_id = l2.activity_id '
          '  JOIN strength_performed_sets s2 ON s2.exercise_id = e2.id '
          '  WHERE e2.context_key = ? AND l2.activity_start < ? '
          "  AND s2.kind != 'warmup' "
          "  AND s2.status IN ('completed', 'partial', 'failed') "
          '  AND l2.activity_id != ? '
          '  ORDER BY l2.activity_start DESC LIMIT 1) '
          'ORDER BY e.position, s.position',
          variables: [
            Variable.withString(contextKey),
            Variable.withDateTime(before),
            Variable.withString(excludeActivityId ?? ''),
            Variable.withString(contextKey),
            Variable.withDateTime(before),
            Variable.withString(excludeActivityId ?? ''),
          ],
          readsFrom: {
            db.strengthPerformedSets,
            db.strengthPerformedExercises,
            db.strengthActivityLogs,
          },
        )
        .get();
    if (rows.isEmpty) return null;
    final first = rows.first;
    final date = first.read<DateTime>('started');
    final sets = [
      for (final r in rows) _setFromRow(db.strengthPerformedSets.map(r.data)),
    ];
    return StrengthHistoryEntry(
      activityId: first.read<String>('activity_id'),
      date: date,
      source: first.readNullable<String>('src'),
      logRevision: first.read<int>('log_rev'),
      sets: sets,
      stale:
          (now ?? DateTime.now()).difference(date) > strengthHistoryStaleAfter,
    );
  }

  /// The latest [limit] logged sessions of one exercise context before
  /// [before], newest first, with every working set whatever its status:
  /// a failed or skipped set must be visible to the progression rule.
  Future<List<StrengthHistoryEntry>> recentComparableSessions(
    String contextKey, {
    required DateTime before,
    int limit = 3,
    DateTime? now,
  }) async {
    final logs = await db
        .customSelect(
          'SELECT l.activity_id, l.activity_start, l.revision, a.source '
          'FROM strength_activity_logs l '
          'LEFT JOIN activity_records a ON a.activity_id = l.activity_id '
          'WHERE l.activity_start < ? AND EXISTS ('
          '  SELECT 1 FROM strength_performed_exercises e '
          '  JOIN strength_performed_sets s ON s.exercise_id = e.id '
          '  WHERE e.activity_id = l.activity_id AND e.context_key = ? '
          "  AND s.kind != 'warmup') "
          'ORDER BY l.activity_start DESC LIMIT ?',
          variables: [
            Variable.withDateTime(before),
            Variable.withString(contextKey),
            Variable.withInt(limit),
          ],
          readsFrom: {db.strengthActivityLogs, db.strengthPerformedExercises},
        )
        .get();
    final out = <StrengthHistoryEntry>[];
    for (final l in logs) {
      final id = l.read<String>('activity_id');
      final rows = await db
          .customSelect(
            'SELECT s.* FROM strength_performed_sets s '
            'JOIN strength_performed_exercises e ON e.id = s.exercise_id '
            'WHERE e.activity_id = ? AND e.context_key = ? '
            "AND s.kind != 'warmup' ORDER BY e.position, s.position",
            variables: [
              Variable.withString(id),
              Variable.withString(contextKey),
            ],
            readsFrom: {
              db.strengthPerformedSets,
              db.strengthPerformedExercises,
            },
          )
          .get();
      final date = l.read<DateTime>('activity_start');
      out.add(
        StrengthHistoryEntry(
          activityId: id,
          date: date,
          source: l.readNullable<String>('source'),
          logRevision: l.read<int>('revision'),
          sets: [
            for (final r in rows)
              _setFromRow(db.strengthPerformedSets.map(r.data)),
          ],
          stale:
              (now ?? DateTime.now()).difference(date) >
              strengthHistoryStaleAfter,
        ),
      );
    }
    return out;
  }

  // ── Progression decisions ───────────────────────────────────────────────

  /// Decisions taken for an owner's exercises, by fingerprint.
  Future<Map<String, StrengthProposalDecisionRow>> proposalDecisions(
    StrengthPlanOwner owner,
  ) async {
    final rows =
        await (db.select(db.strengthProposalDecisions)..where(
              (t) =>
                  t.ownerKind.equals(owner.kind) & t.ownerKey.equals(owner.key),
            ))
            .get();
    return {for (final r in rows) r.fingerprint: r};
  }

  /// Keeps the current load; the same proposal is not offered again.
  Future<void> dismissProposal({
    required StrengthPlanOwner owner,
    required String exerciseId,
    required String fingerprint,
    required int ruleVersion,
    required double fromKg,
    required double toKg,
  }) => db
      .into(db.strengthProposalDecisions)
      .insertOnConflictUpdate(
        StrengthProposalDecisionsCompanion.insert(
          fingerprint: fingerprint,
          ownerKind: owner.kind,
          ownerKey: owner.key,
          exerciseId: exerciseId,
          ruleVersion: ruleVersion,
          fromKg: fromKg,
          toKg: toKg,
          decision: 'dismissed',
          decidedAt: DateTime.now(),
        ),
      );

  /// Saves [plan] (with the accepted load) as a new revision and records the
  /// acceptance, atomically.
  Future<StoredStrengthPlan> acceptProposal({
    required StrengthPlanOwner owner,
    required StrengthWorkoutPlan plan,
    required int expectedRevision,
    required String exerciseId,
    required String fingerprint,
    required int ruleVersion,
    required double fromKg,
    required double toKg,
  }) => db.transaction(() async {
    final saved = await savePlan(
      owner,
      plan,
      expectedRevision: expectedRevision,
    );
    await db
        .into(db.strengthProposalDecisions)
        .insertOnConflictUpdate(
          StrengthProposalDecisionsCompanion.insert(
            fingerprint: fingerprint,
            ownerKind: owner.kind,
            ownerKey: owner.key,
            exerciseId: exerciseId,
            ruleVersion: ruleVersion,
            fromKg: fromKg,
            toKg: toKg,
            decision: 'accepted',
            decidedAt: DateTime.now(),
          ),
        );
    return saved;
  });

  // ── Increments and custom exercises ─────────────────────────────────────

  Future<StrengthLoad?> increment(String contextKey) async {
    final row = await (db.select(
      db.strengthEquipmentIncrements,
    )..where((t) => t.contextKey.equals(contextKey))).getSingleOrNull();
    return row == null
        ? null
        : StrengthLoad(row.incrementKg, unit: MassUnit.parse(row.unit));
  }

  Future<void> rememberIncrement(String contextKey, StrengthLoad step) async {
    if (!step.kg.isFinite || step.kg <= 0) {
      throw StrengthValidationException('An increment must be positive.');
    }
    await db
        .into(db.strengthEquipmentIncrements)
        .insertOnConflictUpdate(
          StrengthEquipmentIncrementsCompanion.insert(
            contextKey: contextKey,
            incrementKg: step.kg,
            unit: step.unit.name,
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<List<StrengthExerciseVariant>> customVariants() async {
    final rows = await (db.select(
      db.strengthExerciseVariants,
    )..where((t) => t.archived.equals(false))).get();
    return [
      for (final r in rows)
        StrengthExerciseVariant(
          id: r.id,
          name: r.name,
          equipment: r.equipment,
          convention: StrengthConvention.fromJson(jsonDecode(r.conventionJson)),
          timed: r.timed,
        ),
    ];
  }

  /// A new custom exercise with a fresh id; ids are never reused.
  Future<StrengthExerciseVariant> addCustomVariant({
    required String name,
    required String equipment,
    StrengthConvention convention = const StrengthConvention(),
    bool timed = false,
  }) async {
    if (name.trim().isEmpty) {
      throw StrengthValidationException('Name the exercise.');
    }
    final v = StrengthExerciseVariant(
      id: newStrengthId('custom'),
      name: name.trim(),
      equipment: equipment.trim(),
      convention: convention,
      timed: timed,
    );
    await db
        .into(db.strengthExerciseVariants)
        .insert(
          StrengthExerciseVariantsCompanion.insert(
            id: v.id,
            name: v.name,
            equipment: v.equipment,
            conventionJson: jsonEncode(convention.toJson()),
            timed: Value(timed),
            createdAt: DateTime.now(),
          ),
        );
    return v;
  }

  /// Hides a custom exercise from the picker; history keeps its snapshots.
  Future<void> archiveCustomVariant(String id) =>
      (db.update(
        db.strengthExerciseVariants,
      )..where((t) => t.id.equals(id))).write(
        const StrengthExerciseVariantsCompanion(archived: Value(true)),
      );
}
