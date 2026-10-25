import '../../db/database.dart';
import '../../models/prepared_workout.dart';
import 'workout_provider.dart';

/// A platform Fjelia cannot send to yet (Polar, Suunto, and any other that is
/// added before its partner access): the workout is shared as text. It holds
/// nothing of Fjelia's, so there is nothing to remove or retry. When access
/// comes, the platform gets a full provider and nothing else changes.
class ShareOnlyWorkoutProvider extends WorkoutProvider {
  const ShareOnlyWorkoutProvider({
    required this.id,
    required this.label,
    required this.sourceKey,
    required this.connected,
  });

  @override
  final String id;
  @override
  final String label;
  @override
  final String sourceKey;
  /// Whether the platform is connected.
  final Future<bool> Function() connected;

  @override
  Future<bool> isConnected() => connected();

  @override
  Future<DeliveryMode> mode() async => DeliveryMode.share;

  @override
  Future<void> deliver(
    TrainingSession session,
    Future<PreparedWorkout> Function() prepare,
  ) => throw StateError('$label takes workouts as text; it cannot be sent to.');

  @override
  Future<bool> hasDelivered(TrainingSession session) async => false;

  @override
  Future<void> remove(TrainingSession session) async {}

  @override
  Future<int> removeAll({
    required Set<String> titles,
    void Function(int done, int total)? onProgress,
  }) async => 0;

  @override
  Future<int> retryCleanup() async => 0;
}
