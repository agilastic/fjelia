import 'package:drift/drift.dart';

import '../../db/database.dart';
import '../../utils/log.dart';

/// Removals on one platform that failed, kept in `provider_cleanups` so a
/// later run can try again even though the session and its ids are gone from
/// the phone.
class CleanupQueue {
  CleanupQueue(this._db, this.providerId, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final String providerId;
  final DateTime Function() _now;

  /// Remembers an entry to remove later; asking again counts another try.
  Future<void> add(String remoteId, {String? scheduleId, Object? error}) => _db
      .into(_db.providerCleanups)
      .insert(
        ProviderCleanupsCompanion.insert(
          providerId: providerId,
          remoteId: remoteId,
          scheduleId: Value(scheduleId),
          createdAt: _now(),
          lastError: Value(error == null ? null : '$error'),
        ),
        onConflict: DoUpdate(
          (old) => ProviderCleanupsCompanion.custom(
            attempts: old.attempts + const Constant(1),
            lastError: Constant(error == null ? null : '$error'),
          ),
        ),
      );

  Future<List<ProviderCleanup>> waiting({int maxAttempts = 20}) =>
      (_db.select(_db.providerCleanups)..where(
            (t) =>
                t.providerId.equals(providerId) &
                t.attempts.isSmallerThanValue(maxAttempts),
          ))
          .get();

  /// Tries every waiting entry with [remove]. Those that go are forgotten, the
  /// others stay with another try counted. Returns how many went.
  Future<int> retry(
    Future<void> Function(String remoteId, String? scheduleId) remove, {
    int maxAttempts = 20,
  }) async {
    final entries = await waiting(maxAttempts: maxAttempts);
    var removed = 0;
    for (final e in entries) {
      try {
        await remove(e.remoteId, e.scheduleId);
        await (_db.delete(_db.providerCleanups)..where(
              (t) =>
                  t.providerId.equals(providerId) &
                  t.remoteId.equals(e.remoteId),
            ))
            .go();
        removed++;
      } catch (error) {
        await add(e.remoteId, scheduleId: e.scheduleId, error: error);
      }
    }
    if (entries.isNotEmpty) {
      log('[$providerId] cleanup: $removed of ${entries.length} removed');
    }
    return removed;
  }
}
