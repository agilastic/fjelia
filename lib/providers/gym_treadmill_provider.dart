import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/gym_workout.dart';
import '../models/training_ble_profile.dart';
import '../services/gym_workout_import_service.dart';
import '../services/matrix_xid_client.dart';
import '../services/training_ble.dart';
import '../services/workout_photo_service.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'device_recording_owner_provider.dart';
import 'hrv_reminder_provider.dart' show hrvCaptureActiveProvider;
import 'hrv_training_provider.dart';
import 'sync_provider.dart';

const _sessionKey = 'matrix_xid_session_v1';
const _autoSyncKey = 'matrix_xid_auto_sync_v1';
final gymBleFactoryProvider = Provider<TrainingBleConnection Function()>(
  (ref) =>
      () => TrainingBleConnection(mtu: null),
);
final workoutPhotoServiceProvider = Provider((ref) => WorkoutPhotoService());
final matrixXidClientProvider = Provider((ref) {
  final client = MatrixXidClient();
  ref.onDispose(client.close);
  return client;
});
final matrixXidSessionProvider = FutureProvider<MatrixXidSession?>((ref) async {
  final raw = await const FlutterSecureStorage().read(key: _sessionKey);
  if (raw == null) return null;
  try {
    return MatrixXidSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});
final matrixXidAutoSyncProvider = FutureProvider<bool>(
  (ref) async =>
      await const FlutterSecureStorage().read(key: _autoSyncKey) != 'false',
);
final matrixXidErrorProvider = StateProvider<String?>((ref) => null);
final gymTreadmillActionsProvider = Provider(GymTreadmillActions.new);

class GymTreadmillActions {
  GymTreadmillActions(this.ref);
  final Ref ref;
  int _accountGeneration = 0;
  Future<void> _sessionWrites = Future.value();

  Future<void> _storeSession(MatrixXidSession? session, {int? generation}) {
    final write = _sessionWrites.then((_) async {
      if (generation != null && generation != _accountGeneration) return;
      if (session == null) {
        await const FlutterSecureStorage().delete(key: _sessionKey);
      } else {
        await const FlutterSecureStorage().write(
          key: _sessionKey,
          value: jsonEncode(session.toJson()),
        );
      }
    });
    _sessionWrites = write.catchError((Object _) {});
    return write;
  }

  Future<List<TrainingDevice>> scan() => scanTrainingDevices();

  Future<TrainingBleReport> inspect(TrainingDevice device) async {
    final owner = ref.read(deviceRecordingOwnerProvider.notifier);
    if (owner.state != null || ref.read(hrvCaptureActiveProvider)) {
      throw StateError(
        'Finish the current measurement before checking equipment.',
      );
    }
    owner.state = 'gym_inspect';
    final connection = ref.read(gymBleFactoryProvider)();
    try {
      await connection.connect(device);
      return connection.report(device);
    } finally {
      await connection.close();
      if (owner.state == 'gym_inspect') owner.state = null;
    }
  }

  Future<void> signIn(String portal, String xid, String passcode) async {
    final generation = ++_accountGeneration;
    final session = await ref
        .read(matrixXidClientProvider)
        .login(portal, xid, passcode);
    if (generation != _accountGeneration) return;
    await _storeSession(session, generation: generation);
    if (generation != _accountGeneration) return;
    ref.read(matrixXidErrorProvider.notifier).state = null;
    ref.invalidate(matrixXidSessionProvider);
  }

  Future<void> disconnect() async {
    ++_accountGeneration;
    await _storeSession(null);
    ref.invalidate(matrixXidSessionProvider);
    ref.read(matrixXidErrorProvider.notifier).state = null;
  }

  Future<void> setAutoSync(bool enabled) async {
    await const FlutterSecureStorage().write(
      key: _autoSyncKey,
      value: '$enabled',
    );
    ref.invalidate(matrixXidAutoSyncProvider);
  }

  Future<MatrixXidBatch> load({int days = 30}) async {
    final generation = _accountGeneration;
    final session = await ref.read(matrixXidSessionProvider.future);
    if (session == null) {
      throw StateError('Sign in to your gym’s xID portal first.');
    }
    final now = DateTime.now().toUtc();
    try {
      final result = await ref
          .read(matrixXidClientProvider)
          .workouts(
            session,
            from: now.subtract(Duration(days: days - 1)),
            through: now,
          );
      if (generation != _accountGeneration) {
        throw StateError('The xID account changed during this request.');
      }
      ref.read(matrixXidErrorProvider.notifier).state = null;
      return result;
    } on MatrixXidException catch (e) {
      if (generation != _accountGeneration) rethrow;
      if (e.expired) {
        ++_accountGeneration;
        await _storeSession(null);
        ref.invalidate(matrixXidSessionProvider);
      }
      ref.read(matrixXidErrorProvider.notifier).state = e.message;
      rethrow;
    }
  }

  Future<GymWorkoutImportResult> save(List<GymWorkout> workouts) async {
    final result = await GymWorkoutImportService(ref.read(databaseProvider))
        .save(workouts);
    if (result.imported > 0) {
      final days = workouts
          .map((w) => w.startedAt.toLocal())
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet();
      for (final day in days) {
        try {
          await ref.read(syncServiceProvider).recalculateEnergie(day);
        } catch (_) {
          // The workout remains saved if a derived summary cannot refresh.
        }
      }
      ref.read(syncStatusListenerProvider.notifier).state++;
      ref.read(hrvActivitiesChangedProvider.notifier).state++;
    }
    return result;
  }

  Future<void> sync() async {
    if (await ref.read(matrixXidSessionProvider.future) == null ||
        !await ref.read(matrixXidAutoSyncProvider.future)) {
      return;
    }
    final batch = await load(days: 7);
    await save(batch.workouts);
  }
}
