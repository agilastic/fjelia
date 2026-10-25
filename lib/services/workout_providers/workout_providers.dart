import '../../db/database.dart';
import '../../models/prepared_workout.dart';
import '../../utils/log.dart';
import 'workout_provider.dart';

export 'workout_provider.dart';

/// Every watch platform the app knows, and the one place that lists them.
/// A new platform is one more entry in this list (see `workoutProvidersProvider`).
class WorkoutProviders {
  WorkoutProviders(Iterable<WorkoutProvider> providers)
    : all = List.unmodifiable(providers) {
    final ids = all.map((p) => p.id).toList();
    assert(ids.toSet().length == ids.length, 'provider ids must be unique');
  }

  final List<WorkoutProvider> all;

  WorkoutProvider? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The providers the athlete has connected, in their order of activity
  /// sources ([priority], most important first); those not named come last,
  /// in the order they are listed.
  Future<List<WorkoutProvider>> connected([
    List<String> priority = const [],
  ]) async {
    final out = <WorkoutProvider>[];
    for (final p in all) {
      if (await p.isConnected()) out.add(p);
    }
    int rank(WorkoutProvider p) {
      final i = priority.indexOf(p.sourceKey);
      return i < 0 ? priority.length : i;
    }

    // A stable sort keeps the listed order among equals.
    final indexed = [for (var i = 0; i < out.length; i++) (i, out[i])]
      ..sort((a, b) {
        final byRank = rank(a.$2).compareTo(rank(b.$2));
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  /// Connected providers that take a workout straight onto their calendar.
  Future<List<WorkoutProvider>> pushTargets([
    List<String> priority = const [],
  ]) async => [
    for (final p in await connected(priority))
      if (await p.mode() == DeliveryMode.push) p,
  ];

  /// The providers that have this session's workout on their platform.
  Future<List<WorkoutProvider>> deliveredTo(TrainingSession s) async => [
    for (final p in all)
      if (await p.hasDelivered(s)) p,
  ];

  /// Takes the session's workout off every platform that has it. A platform
  /// that fails keeps the removal queued; none stops the others.
  Future<void> removeEverywhere(TrainingSession s) async {
    for (final p in all) {
      try {
        if (await p.hasDelivered(s)) await p.remove(s);
      } catch (e) {
        log('[Workouts] ${p.label} removal failed for ${s.id}: $e');
      }
    }
  }

  /// Takes a skipped session off every calendar, best effort.
  Future<void> releaseEverywhere(TrainingSession s) async {
    for (final p in all) {
      try {
        if (await p.hasDelivered(s)) await p.release(s);
      } catch (e) {
        log('[Workouts] ${p.label} release failed for ${s.id}: $e');
      }
    }
  }

  /// Tries the removals that failed earlier on every platform.
  Future<int> retryCleanup() async {
    var removed = 0;
    for (final p in all) {
      try {
        removed += await p.retryCleanup();
      } catch (e) {
        log('[Workouts] ${p.label} cleanup failed: $e');
      }
    }
    return removed;
  }
}

/// Builds a workout for a session: what [WorkoutProvider.deliver] takes.
typedef PrepareWorkout = Future<PreparedWorkout> Function();
