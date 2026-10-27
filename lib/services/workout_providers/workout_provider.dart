import '../../db/database.dart';
import '../../models/prepared_workout.dart';

/// How a platform takes a workout.
enum DeliveryMode {
  /// Fjelia puts it on the platform's calendar.
  push,

  /// Fjelia hands it over as text, to be entered in the platform's app.
  share,
}

/// A route that is off until the athlete turns it on, knowingly: what to ask
/// them and how to switch it on.
class OptIn {
  const OptIn({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.enable,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final Future<void> Function() enable;
}

/// The platform cannot hold this workout; it is shared as text instead.
class WorkoutNotSupported implements Exception {
  const WorkoutNotSupported(this.reason);
  final String reason;
  @override
  String toString() => reason;
}

/// A watch or training platform that planned workouts go to.
///
/// Nothing in the planner names a platform: it asks the providers that are
/// connected. Adding one means writing one of these and listing it in
/// [WorkoutProviders]; sending, replacing, removing, "delete all" and the
/// retry of failed removals then work for it without further changes.
///
/// A provider keeps its own record of what it put where. Most use
/// `DeliveryLedger` and `CleanupQueue`, which are shared and need no table of
/// their own.
abstract class WorkoutProvider {
  const WorkoutProvider();

  /// Stable key: stored with deliveries and queued removals. Never changes.
  String get id;

  /// Name shown to the athlete.
  String get label;

  /// The key of this platform in the athlete's source-priority lists.
  String get sourceKey;

  /// The route is unofficial and may break without notice.
  bool get experimental => false;

  /// Whether plan generation sends upcoming sessions without a button press.
  /// Some platforms initially offer delivery only for an explicitly chosen workout.
  bool get autoDeliver => true;

  /// What to tell the athlete when workouts are shared, not sent.
  String get shareNote =>
      'Sending workouts straight to $label needs $label\'s partner access. '
      'Until then, share the workout and enter it in the $label app: the text '
      'carries every step with its heart-rate zone.';

  /// Set while the platform is shared to because pushing is off, and the
  /// athlete may turn pushing on. Null for a platform with nothing to opt
  /// into.
  OptIn? get optIn => null;

  /// A note under the push button, for a platform whose route needs one.
  String? get pushNote => null;

  /// Whether the platform takes strength workouts as exercises, sets, reps
  /// and loads. Without it a strength session is not uploaded as a timed
  /// outline; it is shared as an exercise list.
  bool get supportsStrength => false;

  /// The athlete has this platform connected.
  Future<bool> isConnected();

  /// Whether workouts are sent or shared, for this athlete now (an
  /// experimental route can be switched).
  Future<DeliveryMode> mode();

  /// Puts the session's workout on the platform, replacing what it sent for
  /// this session before. [prepare] builds the steps and targets; a provider
  /// that only reschedules need not call it. Throws with the platform's own
  /// message when it refuses, and [WorkoutNotSupported] for a workout it
  /// cannot hold.
  Future<void> deliver(
    TrainingSession session,
    Future<PreparedWorkout> Function() prepare,
  );

  /// Whether this session's workout is on the platform.
  Future<bool> hasDelivered(TrainingSession session);

  /// Takes the session's workout off the platform. A removal that fails is
  /// queued for a later retry; this does not throw for it, so a plan can end
  /// whatever the connection.
  Future<void> remove(TrainingSession session);

  /// Takes the session off the platform's calendar for now, for a skipped
  /// session that may come back. Best effort. By default the same as
  /// [remove].
  Future<void> release(TrainingSession session) => remove(session);

  /// Takes everything Fjelia put on the platform off it ("delete all").
  /// [titles] names the workouts of the plans being deleted, for platforms that
  /// can only be searched by name. Reports progress as it goes and returns how
  /// many entries went.
  Future<int> removeAll({
    required Set<String> titles,
    void Function(int done, int total)? onProgress,
  });

  /// Tries the removals that failed earlier. Returns how many went.
  Future<int> retryCleanup();

  /// Sessions that are already on the platform though Fjelia has no record of
  /// it (an identical workout on the calendar). They are recorded, and not
  /// sent again. Returns their ids. By default none.
  Future<Set<String>> adoptExisting(List<TrainingSession> sessions) async =>
      const {};
}
