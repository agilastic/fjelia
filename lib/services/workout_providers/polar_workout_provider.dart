import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../api/polar_flow_web_client.dart';
import '../../api/polar_workout.dart';
import '../../db/database.dart';
import '../../models/prepared_workout.dart';
import '../../utils/log.dart';
import '../polar_service.dart';
import '../workout_destination.dart';
import 'cleanup_queue.dart';
import 'delivery_ledger.dart';
import 'workout_provider.dart';

/// Planned targets through the same Flow login as the history importer.
/// Only targets whose ids Fjelia recorded are updated or removed.
class PolarWorkoutProvider extends WorkoutProvider {
  PolarWorkoutProvider(AppDatabase db, this._service, {required this.connected})
    : _db = db,
      _ledger = DeliveryLedger(db, 'polar'),
      _queue = CleanupQueue(db, 'polar');

  final AppDatabase _db;
  final PolarService _service;
  final Future<bool> Function() connected;
  final DeliveryLedger _ledger;
  final CleanupQueue _queue;
  Future<void> _pending = Future.value();

  @override
  String get id => 'polar';
  @override
  String get label => WorkoutDestination.polar.label;
  @override
  String get sourceKey => WorkoutDestination.polar.sourceKey;
  @override
  bool get experimental => true;
  @override
  bool get autoDeliver => false;

  /// Uploads require the Flow login, even when AccessLink is connected.
  Future<bool> get needsFlowLogin async => !await _service.hasFlowLogin;

  @override
  String get pushNote =>
      'Uses your Polar sport profile’s heart-rate zones; check they match '
      'Fjelia. One workout: 16:00. Two workouts: 09:00 and 18:00. '
      'Sync Polar Flow to your watch after sending.';

  @override
  Future<bool> isConnected() async =>
      await connected() || await _service.hasFlowLogin;

  @override
  Future<DeliveryMode> mode() async => DeliveryMode.push;

  /// Use the planned order, regardless of which workout is uploaded first.
  Future<int> _startHour(TrainingSession session, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    final others =
        await (_db.select(_db.trainingSessions)..where(
              (t) =>
                  t.planId.equals(session.planId) &
                  t.athleteId.equals(session.athleteId) &
                  t.id.equals(session.id).not() &
                  t.sessionDate.isBiggerOrEqualValue(start) &
                  t.sessionDate.isSmallerThanValue(end) &
                  t.status.isIn(['planned', 'adapted', 'completed']) &
                  t.plannedDurationMin.isBiggerThanValue(0),
            ))
            .get();
    if (others.isEmpty) return 16;
    final earlier = others.any(
      (other) =>
          other.sessionNumber < session.sessionNumber ||
          (other.sessionNumber == session.sessionNumber &&
              other.id.compareTo(session.id) < 0),
    );
    return earlier ? 18 : 9;
  }

  /// Serializes taps and cleanup so two simultaneous sends cannot create two
  /// targets before either has saved its id.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<void> deliver(
    TrainingSession session,
    Future<PreparedWorkout> Function() prepare,
  ) => _serial(() async {
    final Map<String, dynamic> payload;
    try {
      final workout = await prepare();
      payload = buildPolarWorkout(
        workout,
        defaultStartHour: await _startHour(session, workout.date),
      );
    } on PolarUnsupportedWorkout catch (error) {
      throw WorkoutNotSupported(error.reason);
    }
    final fingerprint = sha256
        .convert(utf8.encode(jsonEncode(payload)))
        .toString();
    final previous = await _ledger.get(session.id);
    await _service.withFlowClient((web) async {
      final previousId = previous?.remoteId;
      final existing = previousId == null
          ? null
          : await web.trainingTarget(previousId);
      if (existing != null && previous!.fingerprint == fingerprint) return;

      final String remoteId;
      if (existing == null) {
        remoteId = await web.createTrainingTarget(payload);
      } else {
        final exerciseTargets = existing['exerciseTargets'] as List;
        if (exerciseTargets.length != 1 ||
            exerciseTargets.single is! Map ||
            (exerciseTargets.single as Map)['id'] == null) {
          throw PolarFlowException('Polar target could not be updated safely.');
        }
        final exercise = (payload['exerciseTargets'] as List).single as Map;
        await web.updateTrainingTarget(previousId!, {
          ...payload,
          if (existing['id'] != null) 'id': existing['id'],
          'exerciseTargets': [
            {...exercise, 'id': (exerciseTargets.single as Map)['id']},
          ],
        });
        remoteId = previousId;
      }
      try {
        await _ledger.put(
          session.id,
          remoteId: remoteId,
          fingerprint: fingerprint,
          day: '${payload['datetime']}'.split('T').first.replaceAll('-', ''),
          name: payload['name'] as String,
        );
      } catch (error) {
        // If the local record cannot be saved, avoid leaving a new target
        // which a retry would otherwise duplicate.
        if (existing == null) {
          try {
            await web.deleteTrainingTarget(remoteId);
          } catch (cleanupError) {
            await _queue.add(remoteId, error: cleanupError);
          }
        }
        rethrow;
      }
    });
  });

  @override
  Future<bool> hasDelivered(TrainingSession session) async =>
      (await _ledger.get(session.id))?.remoteId != null;

  @override
  Future<void> remove(TrainingSession session) => _serial(() async {
    final record = await _ledger.get(session.id);
    if (record != null) await _removeRecords([record]);
  });

  Future<int> _removeRecords(
    List<WorkoutDelivery> records, {
    void Function(int done, int total)? onProgress,
  }) async {
    var removed = 0;
    var done = 0;
    onProgress?.call(0, records.length);
    if (records.isEmpty) return 0;
    try {
      await _service.withFlowClient((web) async {
        for (final record in records) {
          final remoteId = record.remoteId;
          if (remoteId != null) {
            try {
              await web.deleteTrainingTarget(remoteId);
              removed++;
            } catch (error) {
              await _queue.add(remoteId, error: error);
            }
          }
          await _ledger.delete(record.sessionId);
          onProgress?.call(++done, records.length);
        }
      });
    } catch (error) {
      // Missing credentials or a failed login must not prevent ending a plan.
      for (final record in records.skip(done)) {
        if (record.remoteId case final remoteId?) {
          await _queue.add(remoteId, error: error);
        }
        await _ledger.delete(record.sessionId);
        onProgress?.call(++done, records.length);
      }
    }
    return removed;
  }

  @override
  Future<int> removeAll({
    required Set<String> titles,
    void Function(int done, int total)? onProgress,
  }) => _serial(
    () async => _removeRecords(await _ledger.all(), onProgress: onProgress),
  );

  @override
  Future<int> retryCleanup() => _serial(() async {
    if ((await _queue.waiting()).isEmpty) return 0;
    try {
      return await _service.withFlowClient(
        (web) =>
            _queue.retry((remoteId, _) => web.deleteTrainingTarget(remoteId)),
      );
    } catch (error) {
      log('[Polar] target cleanup could not connect: $error');
      return 0;
    }
  });
}
