import 'package:drift/drift.dart';

import '../db/database.dart';
import 'omron_ble_service.dart';

/// Stores readings imported from a Bluetooth blood-pressure monitor.
class OmronReadingStore {
  OmronReadingStore(this.db, {this.onSaved});
  final AppDatabase db;

  /// Called after a save so the day views read the new readings.
  final void Function()? onSaved;

  /// Saves [records] and returns how many were new. Readings already stored
  /// (same minute and values) and impossible ones are skipped by the database.
  Future<int> save(List<OmronBpRecord> records, {String? model}) async {
    final count = await db.insertBpMeasurements([
      for (final r in records)
        BpMeasurementsCompanion.insert(
          measuredAt: r.measuredAt,
          systolic: r.systolic,
          diastolic: r.diastolic,
          heartRate: r.heartRate,
          measurementType: Value(
            model == null || model == standardBpModel
                ? 'BLE_STANDARD'
                : 'OMRON',
          ),
        ),
    ]);
    onSaved?.call();
    return count;
  }
}
