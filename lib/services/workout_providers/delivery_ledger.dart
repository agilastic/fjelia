import 'package:drift/drift.dart';

import '../../db/database.dart';

/// One platform's record of what Fjelia sent, in `workout_deliveries`.
class DeliveryLedger {
  DeliveryLedger(this._db, this.providerId, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final String providerId;
  final DateTime Function() _now;

  Future<WorkoutDelivery?> get(String sessionId) =>
      (_db.select(_db.workoutDeliveries)..where(
            (t) =>
                t.sessionId.equals(sessionId) &
                t.providerId.equals(providerId),
          ))
          .getSingleOrNull();

  Future<List<WorkoutDelivery>> all() => (_db.select(
    _db.workoutDeliveries,
  )..where((t) => t.providerId.equals(providerId))).get();

  Future<void> put(
    String sessionId, {
    String? fingerprint,
    String? day,
    String? name,
  }) => _db
      .into(_db.workoutDeliveries)
      .insertOnConflictUpdate(
        WorkoutDeliveriesCompanion.insert(
          sessionId: sessionId,
          providerId: providerId,
          fingerprint: Value(fingerprint),
          day: Value(day),
          name: Value(name),
          sentAt: _now(),
        ),
      );

  Future<void> delete(String sessionId) =>
      (_db.delete(_db.workoutDeliveries)..where(
            (t) =>
                t.sessionId.equals(sessionId) & t.providerId.equals(providerId),
          ))
          .go();

  Future<void> deleteAll() => (_db.delete(
    _db.workoutDeliveries,
  )..where((t) => t.providerId.equals(providerId))).go();
}

/// The content of a session as a platform sees it: what changes it changes
/// what was sent. A short stable hash, not for security.
String sessionContentFingerprint(TrainingSession s) {
  var h = 0x811c9dc5;
  for (final unit in [
    s.title,
    '${s.plannedDurationMin}',
    s.stepsJson ?? '',
    s.targetMetric ?? '',
    s.sport,
  ].join('\u0001').codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}
