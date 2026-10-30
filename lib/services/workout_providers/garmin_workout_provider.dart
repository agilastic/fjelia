import 'package:drift/drift.dart';

import '../../api/garmin_client.dart';
import '../../db/database.dart';
import '../../models/prepared_workout.dart';
import '../../models/strength_workout.dart';
import '../strength/garmin_strength.dart';
import '../../utils/log.dart';
import '../workout_destination.dart';
import 'cleanup_queue.dart';
import 'delivery_ledger.dart';
import 'workout_provider.dart';

/// Garmin Connect: workouts are created in the library and scheduled on the
/// calendar. The ids stay on the session (`garmin_workout_id`,
/// `garmin_alternative_id`), which other screens read; the content that was
/// sent is on record in the ledger, so a changed session is sent again.
class GarminWorkoutProvider extends WorkoutProvider {
  GarminWorkoutProvider(
    this._db,
    this._client, {
    this.connected,
    this.strengthRevision,
    DateTime Function()? clock,
  }) : _ledger = DeliveryLedger(_db, 'garmin', clock: clock),
       _queue = CleanupQueue(_db, 'garmin', clock: clock);

  final AppDatabase _db;
  final GarminClient _client;

  /// Whether Garmin is connected; without it Garmin counts as connected.
  final Future<bool> Function()? connected;

  /// The revision of a strength session's exercise plan, part of what was
  /// sent: editing exercises sends the workout again.
  final Future<String?> Function(TrainingSession s)? strengthRevision;
  final DeliveryLedger _ledger;
  final CleanupQueue _queue;

  @override
  String get id => 'garmin';
  @override
  String get label => WorkoutDestination.garmin.label;
  @override
  String get sourceKey => WorkoutDestination.garmin.sourceKey;

  @override
  Future<bool> isConnected() async => await connected?.call() ?? true;

  @override
  Future<DeliveryMode> mode() async => DeliveryMode.push;

  @override
  bool get supportsStrength => true;

  Future<String> _fingerprint(TrainingSession s) async =>
      sessionContentFingerprint(
        s,
        extra: isStrengthSport(s.sport)
            ? 'strength:${await strengthRevision?.call(s) ?? ''}'
            : '',
      );

  static String _sportName(String sport) => switch (sport) {
    'running' || 'trail_running' => 'running',
    'cycling_road' || 'cycling_gravel' || 'cycling_mtb' => 'cycling',
    'swimming' => 'swimming',
    'strength' || 'pilates' || 'yoga' || 'stretching' => 'strength',
    'indoor_rowing' => 'cardio',
    _ => 'running',
  };

  Future<void> _write(String sessionId, TrainingSessionsCompanion values) =>
      (_db.update(
        _db.trainingSessions,
      )..where((t) => t.id.equals(sessionId))).write(values);

  @override
  Future<bool> hasDelivered(TrainingSession s) async =>
      s.garminWorkoutId != null || s.garminAlternativeId != null;

  @override
  Future<void> deliver(
    TrainingSession s,
    Future<PreparedWorkout> Function() prepare,
  ) async {
    final fingerprint = await _fingerprint(s);
    final record = await _ledger.get(s.id);
    // Without a record the content is taken as unchanged: it went up before
    // records were kept.
    final unchanged =
        s.garminWorkoutId != null &&
        (record?.fingerprint == null || record!.fingerprint == fingerprint);
    // What the calendar holds on that day: an entry already there is kept,
    // and copies of this session left by earlier pushes come off.
    final onDay = await _calendarOn(s.sessionDate);
    if (unchanged) {
      final placed = onDay
          ?.where((e) => e.workoutId == s.garminWorkoutId)
          .map((e) => e.scheduleId)
          .toList();
      String? schedule;
      if (placed != null && placed.isNotEmpty) {
        schedule = placed.contains(s.garminAlternativeId)
            ? s.garminAlternativeId
            : placed.first;
        if (s.garminAlternativeId != null &&
            s.garminAlternativeId != schedule) {
          await _client.unscheduleWorkout(s.garminAlternativeId!);
        }
      } else {
        if (s.garminAlternativeId != null) {
          await _client.unscheduleWorkout(s.garminAlternativeId!);
        }
        schedule = await _client.scheduleWorkout(
          s.garminWorkoutId!,
          s.sessionDate,
        );
      }
      await _dropCopies(s, onDay, keep: {?schedule, ?s.garminAlternativeId});
      await _write(
        s.id,
        TrainingSessionsCompanion(
          garminAlternativeId: Value(schedule),
          dateModified: Value(DateTime.now()),
        ),
      );
      await _ledger.put(s.id, fingerprint: fingerprint, name: s.title);
      return;
    }
    if (s.stepsJson == null && !isStrengthSport(s.sport)) {
      throw StateError('No workout structure is available to push.');
    }
    // A calendar entry of an earlier definition (the session changed since)
    // comes down before the new one goes up, and so does the old definition.
    if (s.garminAlternativeId != null) {
      await _client.unscheduleWorkout(s.garminAlternativeId!);
      await _write(
        s.id,
        const TrainingSessionsCompanion(garminAlternativeId: Value(null)),
      );
    }
    final old = s.garminWorkoutId;
    if (old != null) {
      try {
        await _client.deleteWorkout(old);
      } catch (e) {
        await _queue.add(old, error: e);
      }
      await _write(
        s.id,
        const TrainingSessionsCompanion(garminWorkoutId: Value(null)),
      );
    }
    final prepared = await prepare();
    String workoutId;
    try {
      workoutId = await _client.createWorkout(
        s.title,
        _sportName(s.sport),
        prepared.steps,
        description: prepared.description,
      );
    } on GarminApiException catch (e) {
      // An exercise name Garmin does not accept: send the sets without
      // names; each step still names its exercise in its description.
      if (!hasGarminExerciseNames(prepared.steps) ||
          !e.toString().contains(' 400')) {
        rethrow;
      }
      log('[Garmin] strength names refused, sending without: $e');
      workoutId = await _client.createWorkout(
        s.title,
        _sportName(s.sport),
        withoutGarminExerciseNames(prepared.steps),
        description: prepared.description,
      );
    }
    // Save the definition before scheduling so a retry cannot create
    // duplicates.
    await _write(
      s.id,
      TrainingSessionsCompanion(garminWorkoutId: Value(workoutId)),
    );
    final scheduleId = await _client.scheduleWorkout(workoutId, s.sessionDate);
    await _write(
      s.id,
      TrainingSessionsCompanion(
        garminWorkoutId: Value(workoutId),
        garminAlternativeId: Value(scheduleId),
        dateModified: Value(DateTime.now()),
      ),
    );
    await _ledger.put(s.id, fingerprint: fingerprint, name: s.title);
    await _dropCopies(s, onDay, keep: {?scheduleId, ?s.garminAlternativeId});
  }

  /// The workouts on Garmin's calendar on [day]; null when it cannot be read,
  /// and the push goes on without the check.
  Future<List<GarminCalendarWorkout>?> _calendarOn(DateTime day) async {
    try {
      return await _client.calendarWorkoutsOn(day);
    } catch (e) {
      log('[Garmin] could not read the calendar of $day: $e');
      return null;
    }
  }

  /// Takes copies of [s] off the calendar: entries with its title on its day
  /// that are not [keep] and belong to no other session. They are left over
  /// from earlier pushes and showed the workout several times on the watch.
  Future<void> _dropCopies(
    TrainingSession s,
    List<GarminCalendarWorkout>? onDay, {
    required Set<String> keep,
  }) async {
    if (onDay == null) return;
    final copies = [
      for (final e in onDay)
        if (e.title == s.title && !keep.contains(e.scheduleId)) e.scheduleId,
    ];
    if (copies.isEmpty) return;
    final owned = {
      for (final x in await (_db.select(
        _db.trainingSessions,
      )..where((t) => t.garminAlternativeId.isIn(copies))).get())
        x.garminAlternativeId,
    };
    for (final id in copies) {
      if (owned.contains(id)) continue;
      try {
        await _client.unscheduleWorkout(id);
        log('[Garmin] removed a copy of "${s.title}" from the calendar: $id');
      } catch (e) {
        log('[Garmin] could not remove the copy $id: $e');
      }
    }
  }

  @override
  Future<void> remove(TrainingSession s) async {
    final workoutId = s.garminWorkoutId;
    final scheduleId = s.garminAlternativeId;
    if (workoutId == null && scheduleId == null) return;
    try {
      if (workoutId != null) {
        await _client.deleteWorkout(workoutId, scheduleId: scheduleId);
      } else {
        await _client.unscheduleWorkout(scheduleId!);
      }
      log('[Garmin] removed workout ${workoutId ?? '-'} for session ${s.id}');
    } catch (e) {
      log('[Garmin] removal failed for ${workoutId ?? scheduleId}: $e');
      await _queue.add(
        workoutId ?? 'schedule:$scheduleId',
        scheduleId: scheduleId,
        error: e,
      );
    }
    await _write(
      s.id,
      const TrainingSessionsCompanion(
        garminWorkoutId: Value(null),
        garminAlternativeId: Value(null),
      ),
    );
    await _ledger.delete(s.id);
  }

  /// Takes the entry off the calendar and keeps the definition, so a restored
  /// session is scheduled again without being created twice. A failure is
  /// logged and leaves the entry id in place for a later attempt.
  @override
  Future<void> release(TrainingSession s) async {
    final id = s.garminAlternativeId;
    if (id == null) return;
    try {
      await _client.unscheduleWorkout(id);
      await _write(
        s.id,
        const TrainingSessionsCompanion(garminAlternativeId: Value(null)),
      );
    } catch (e) {
      log('[Garmin] could not release calendar entry $id: $e');
    }
  }

  @override
  Future<Set<String>> adoptExisting(List<TrainingSession> sessions) async {
    if (sessions.isEmpty) return const {};
    List<GarminCalendarWorkout> calendar;
    try {
      calendar = await _client.calendarWorkoutEntries();
    } catch (e) {
      log('[Garmin] could not read the calendar to find duplicates: $e');
      return const {};
    }
    final byKey = <String, List<GarminCalendarWorkout>>{};
    for (final e in calendar) {
      (byKey['${e.title}|${e.date}'] ??= []).add(e);
    }
    final adopted = <String>{};
    for (final s in sessions) {
      final key =
          '${s.title}|${s.sessionDate.toIso8601String().substring(0, 10)}';
      final found = byKey[key];
      if (found == null || found.isEmpty) continue;
      final entry = found.first;
      log('[Garmin] adopting workout ${entry.workoutId} for "${s.title}"');
      // The calendar entry is kept too: without it the next push put the
      // workout on the calendar a second time.
      await _write(
        s.id,
        TrainingSessionsCompanion(
          garminWorkoutId: Value(entry.workoutId),
          garminAlternativeId: Value(entry.scheduleId),
        ),
      );
      await _ledger.put(
        s.id,
        fingerprint: await _fingerprint(s),
        name: s.title,
      );
      await _dropCopies(s, found, keep: {entry.scheduleId});
      adopted.add(s.id);
    }
    return adopted;
  }

  @override
  Future<int> removeAll({
    required Set<String> titles,
    void Function(int done, int total)? onProgress,
  }) async {
    onProgress?.call(0, 0);
    var calendar = <({String workoutId, String? scheduleId})>[];
    var ids = <String>[];
    try {
      calendar = [
        for (final c in await _client.listCalendarWorkouts())
          (workoutId: c.workoutId, scheduleId: c.scheduleId as String?),
      ];
    } catch (e) {
      log('[Garmin] could not list the calendar: $e');
    }
    try {
      ids = await _client.listWorkoutIds();
    } catch (e) {
      log('[Garmin] could not list the library: $e');
    }
    final total = calendar.length + ids.length;
    var done = 0;
    var removed = 0;
    onProgress?.call(0, total);
    for (final c in calendar) {
      try {
        await _client.deleteWorkout(c.workoutId, scheduleId: c.scheduleId);
        removed++;
      } catch (e) {
        log('[Garmin] delete failed for ${c.workoutId}: $e');
        await _queue.add(c.workoutId, scheduleId: c.scheduleId, error: e);
      }
      onProgress?.call(++done, total);
    }
    for (final id in ids) {
      try {
        await _client.deleteWorkout(id);
        removed++;
      } catch (e) {
        log('[Garmin] library delete failed for $id: $e');
        await _queue.add(id, error: e);
      }
      onProgress?.call(++done, total);
    }
    await (_db.update(_db.trainingSessions)).write(
      const TrainingSessionsCompanion(
        garminWorkoutId: Value(null),
        garminAlternativeId: Value(null),
      ),
    );
    await _ledger.deleteAll();
    return removed;
  }

  @override
  Future<int> retryCleanup() => _queue.retry((remoteId, scheduleId) async {
    if (remoteId.startsWith('schedule:')) {
      await _client.unscheduleWorkout(scheduleId!);
    } else {
      await _client.deleteWorkout(remoteId, scheduleId: scheduleId);
    }
  });
}
