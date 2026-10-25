import '../../api/coros_workout.dart' show CorosUnsupportedWorkout;
import '../../db/database.dart';
import '../../models/prepared_workout.dart';
import '../coros_service.dart';
import '../workout_destination.dart';
import 'workout_provider.dart';

/// COROS Training Hub, by the unofficial web interface its own page uses. It
/// is a push route only while the athlete has switched it on knowingly
/// (Settings, Training); otherwise COROS gets the workout as text.
class CorosWorkoutProvider extends WorkoutProvider {
  CorosWorkoutProvider(
    this._service, {
    required this.connected,
    required this.pushEnabled,
    required this.enablePush,
  });

  final CorosService _service;
  /// Whether COROS is connected, whether the experimental push route is on,
  /// and how to turn it on.
  final Future<bool> Function() connected;
  final Future<bool> Function() pushEnabled;
  final Future<void> Function() enablePush;

  @override
  String get id => 'coros';
  @override
  String get label => WorkoutDestination.coros.label;
  @override
  String get sourceKey => WorkoutDestination.coros.sourceKey;
  @override
  bool get experimental => true;

  @override
  String get shareNote =>
      '${super.shareNote} Or turn on the experimental COROS route in '
      'Settings, Training.';

  @override
  OptIn? get optIn => OptIn(
    title: 'Send workouts to COROS?',
    message:
        'COROS has no workout import, so this uses the Training Hub\'s '
        'unofficial web interface with your COROS login. It is not endorsed '
        'by COROS, can stop working, and a workout should be checked in the '
        'Training Hub afterwards. Turn it on?',
    buttonLabel: 'Send to COROS instead (experimental)',
    enable: enablePush,
  );

  @override
  String get pushNote =>
      'Experimental: sent through the COROS Training Hub\'s unofficial '
      'interface. Check the workout in the Training Hub; a changed or moved '
      'workout replaces the earlier one there.';

  @override
  Future<bool> isConnected() => connected();

  @override
  Future<DeliveryMode> mode() async =>
      await pushEnabled() ? DeliveryMode.push : DeliveryMode.share;

  @override
  Future<void> deliver(
    TrainingSession session,
    Future<PreparedWorkout> Function() prepare,
  ) async {
    try {
      await _service.pushWorkout(await prepare());
    } on CorosUnsupportedWorkout catch (e) {
      throw WorkoutNotSupported(e.reason);
    }
  }

  @override
  Future<bool> hasDelivered(TrainingSession session) =>
      _service.hasDelivered(session.id);

  @override
  Future<void> remove(TrainingSession session) =>
      _service.removeDelivered(session.id);

  @override
  Future<int> removeAll({
    required Set<String> titles,
    void Function(int done, int total)? onProgress,
  }) async {
    try {
      return await _service.removeSentWorkouts(titles, onProgress: onProgress);
    } catch (_) {
      // COROS being unreachable must not stop the other platforms.
      return 0;
    }
  }

  @override
  Future<int> retryCleanup() => _service.retryCleanup();
}
