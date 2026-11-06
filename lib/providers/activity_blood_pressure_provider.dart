import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/indoor_recording.dart';
import 'database_provider.dart';
import 'indoor_recording_provider.dart' show indoorStorageProvider;
export '../services/activity_blood_pressure.dart'
    show bloodPressureDuringActivity;

/// The interval is read from the recording, never guessed from active duration
/// (which excludes pauses). Later Hilo/Aktiia/Health syncs remain visible.
final activityCaptureProvider = FutureProvider.autoDispose
    .family<IndoorCapture?, String>(
      (ref, id) => ref.watch(indoorStorageProvider).load(id),
    );

final activityBloodPressureProvider = StreamProvider.autoDispose
    .family<List<BpMeasurement>, DateTime>((ref, start) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.bpMeasurements)
            ..where((t) => t.measuredAt.isBiggerOrEqualValue(start))
            ..orderBy([(t) => OrderingTerm.asc(t.measuredAt)]))
          .watch();
    });
