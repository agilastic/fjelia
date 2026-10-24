import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../db/database.dart';
import '../models/spot_hrv.dart';
import '../services/polar_h10_service.dart';
import '../services/spot_hrv_export.dart';
import 'database_provider.dart';
import 'spot_hrv_provider.dart';

export '../services/polar_h10_service.dart' show H10Device, PolarH10Service;

/// The paired Polar H10, or null when none is paired.
final polarH10PairedProvider = FutureProvider<H10Device?>(
  (ref) => ref.read(polarH10ActionsProvider).paired(),
);

final polarH10ActionsProvider = Provider<PolarH10Actions>(PolarH10Actions.new);

/// Spot HRV readings (Polar H10) that started in [start, end).
final spotHrvWindowProvider =
    StreamProvider.family<
      List<SpotHrvMeasurement>,
      ({DateTime start, DateTime end})
    >((ref, range) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.spotHrvMeasurements)
            ..where(
              (t) =>
                  t.startedAt.isBiggerOrEqualValue(range.start) &
                  t.startedAt.isSmallerThanValue(range.end),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.startedAt)]))
          .watch();
    });

/// Pairing, storing and exporting of Polar H10 spot HRV measurements.
class PolarH10Actions {
  PolarH10Actions(this.ref);
  final Ref ref;

  PolarH10Service createSensor() => PolarH10Service();

  Future<H10Device?> paired() async {
    try {
      return await PolarH10Pairing.read();
    } catch (_) {
      return null;
    }
  }

  Future<List<H10Device>> scan() async {
    await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    final sensor = createSensor();
    try {
      return await sensor.scan();
    } finally {
      await sensor.dispose();
    }
  }

  Future<void> pair(H10Device device) async {
    await PolarH10Pairing.write(device);
    ref.invalidate(polarH10PairedProvider);
  }

  Future<void> unpair() async {
    await PolarH10Pairing.clear();
    ref.invalidate(polarH10PairedProvider);
  }

  Future<void> save({
    required SpotHrvCapture capture,
    required SpotHrvContext context,
    required SpotHrvPosture posture,
    required H10Device device,
    required Duration elapsed,
    String notes = '',
    int? minutesAfterTraining,
  }) => saveSpotHrv(
    ref.read(databaseProvider),
    capture: capture,
    context: context,
    posture: posture,
    deviceId: device.id,
    deviceName: device.name,
    elapsed: elapsed,
    notes: notes,
    minutesAfterTraining: minutesAfterTraining,
  );

  Future<void> delete(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(
      db.spotHrvMeasurements,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Writes the RR intervals of [row] to a temporary CSV file and returns its
  /// path.
  Future<String> exportCsv(SpotHrvMeasurement row) async {
    final folder = await getTemporaryDirectory();
    final file = File('${folder.path}/fjelia_h10_hrv_${row.id}.csv');
    await file.writeAsString(spotHrvCsv(row));
    return file.path;
  }
}
