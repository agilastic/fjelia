import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/prepared_workout.dart';
import 'package:fjelia/services/workout_providers/cleanup_queue.dart';
import 'package:fjelia/services/workout_providers/delivery_ledger.dart';
import 'package:fjelia/services/workout_providers/workout_provider.dart';

/// A made-up platform that keeps its records in the shared ledger and queue,
/// the way a real new provider would. Nothing in the planner knows its name:
/// it is here to show that any provider works the same.
class RecordingProvider extends WorkoutProvider {
  RecordingProvider(
    AppDatabase db,
    this.id, {
    this.label = 'Acme',
    this.connected = true,
    this.kind = DeliveryMode.push,
  }) : ledger = DeliveryLedger(db, id),
       queue = CleanupQueue(db, id);

  @override
  final String id;
  @override
  final String label;
  @override
  String get sourceKey => '${id}_source';

  bool connected;
  DeliveryMode kind;
  bool offline = false;
  final DeliveryLedger ledger;
  final CleanupQueue queue;

  /// Everything the platform has been told, in order.
  final delivered = <String>[];
  final removed = <String>[];
  final released = <String>[];

  @override
  Future<bool> isConnected() async => connected;

  @override
  Future<DeliveryMode> mode() async => kind;

  @override
  Future<void> deliver(
    TrainingSession session,
    Future<PreparedWorkout> Function() prepare,
  ) async {
    if (offline) throw StateError('$label is offline');
    final workout = await prepare();
    delivered.add(session.id);
    await ledger.put(
      session.id,
      fingerprint: sessionContentFingerprint(session),
      name: workout.title,
    );
  }

  @override
  Future<bool> hasDelivered(TrainingSession session) async =>
      await ledger.get(session.id) != null;

  @override
  Future<void> remove(TrainingSession session) async {
    if (offline) {
      await queue.add(session.id, error: 'offline');
    } else {
      removed.add(session.id);
    }
    await ledger.delete(session.id);
  }

  @override
  Future<void> release(TrainingSession session) async {
    if (offline) return;
    released.add(session.id);
  }

  @override
  Future<int> removeAll({
    required Set<String> titles,
    void Function(int done, int total)? onProgress,
  }) async {
    if (offline) throw StateError('$label is offline');
    final all = await ledger.all();
    var done = 0;
    for (final d in all) {
      removed.add(d.sessionId);
      onProgress?.call(++done, all.length);
    }
    await ledger.deleteAll();
    return all.length;
  }

  @override
  Future<int> retryCleanup() => queue.retry((remoteId, _) async {
    if (offline) throw StateError('$label is offline');
    removed.add(remoteId);
  });
}
