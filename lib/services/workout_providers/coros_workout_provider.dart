import '../../api/coros_workout.dart' show CorosUnsupportedWorkout;
import '../../db/database.dart';
import '../../models/prepared_workout.dart';
import '../coros_service.dart';
import '../workout_destination.dart';
import 'workout_provider.dart';

/// Connected COROS accounts receive workouts through the Training Hub.
class CorosWorkoutProvider extends WorkoutProvider {
  CorosWorkoutProvider(this._service, {required this.connected});

  final CorosService _service;
  final Future<bool> Function() connected;

  @override
  String get id => 'coros';
  @override
  String get label => WorkoutDestination.coros.label;
  @override
  String get sourceKey => WorkoutDestination.coros.sourceKey;
  @override
  bool get experimental => true;

  @override
  String get pushNote =>
      'Sync COROS to your watch after sending. A changed or moved workout '
      'replaces the earlier one in the Training Hub.';

  @override
  Future<bool> isConnected() => connected();

  @override
  Future<DeliveryMode> mode() async => DeliveryMode.push;

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
