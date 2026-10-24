import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'body_measurements_provider.dart';
import '../utils/decimal.dart';

final manualMeasurementActionsProvider = Provider<ManualMeasurementActions>(
  (ref) => ManualMeasurementActions(ref),
);

class ManualMeasurementActions {
  ManualMeasurementActions(this.ref);
  final Ref ref;
  Future<void> save(
    String? type,
    DateTime at,
    Map<String, String> fields,
  ) async {
    String text(String key) => fields[key] ?? '';
    double? read(String key) => parseDecimal(text(key));
    final db = ref.read(databaseProvider);
    switch (type) {
      case 'Blood Pressure':
        final sys = read('Systolic'),
            dia = read('Diastolic'),
            hr = read('Heart Rate');
        if (sys == null ||
            dia == null ||
            hr == null ||
            sys < 50 ||
            sys > 300 ||
            dia < 20 ||
            dia > 200 ||
            hr < 20 ||
            hr > 250) {
          throw StateError(
            'Enter valid systolic, diastolic and heart-rate readings.',
          );
        }
        await db.insertBpMeasurements([
          BpMeasurementsCompanion.insert(
            measuredAt: at,
            systolic: sys.round(),
            diastolic: dia.round(),
            heartRate: hr.round(),
            measurementType: const Value('MANUAL'),
          ),
        ]);
        break;
      case 'Weight Scale':
        final weight = read('Weight');
        if (weight == null || weight < 1 || weight > 500) {
          throw StateError('Enter weight in kg.');
        }
        await db.upsertRenphoMeasurements([
          RenphoRecordsCompanion.insert(
            measuredAt: at,
            weight: Value(weight),
            bodyFat: Value(read('Body Fat')),
            bmi: Value(read('BMI')),
            rawJson: '{}',
          ),
        ]);
        ref.invalidate(bodyMeasurementsProvider);
        break;
      case 'Sleep':
        final hours = read('Duration'), deep = read('Deep'), rem = read('REM');
        if (hours == null ||
            hours <= 0 ||
            hours > 24 ||
            (deep ?? 0) < 0 ||
            (rem ?? 0) < 0 ||
            (deep ?? 0) + (rem ?? 0) > hours) {
          throw StateError('Enter a valid sleep duration and stages in hours.');
        }
        final date = DateTime(at.year, at.month, at.day);
        await db.upsertSleep(
          SleepRecordsCompanion.insert(
            date: date,
            totalSleepSeconds: (hours * 3600).round(),
            deepSleepSeconds: ((deep ?? 0) * 3600).round(),
            remSleepSeconds: ((rem ?? 0) * 3600).round(),
            lightSleepSeconds: ((hours - (deep ?? 0) - (rem ?? 0)) * 3600)
                .round(),
            awakeSleepSeconds: 0,
            source: const Value('manual'),
          ),
        );
        break;
      case 'SpO₂ / Pulse Oximeter':
        final spo2 = read('SpO₂'), hr = read('Heart Rate');
        if (spo2 == null || spo2 < 50 || spo2 > 100) {
          throw StateError('Enter SpO₂ between 50 and 100%.');
        }
        await db.upsertHrv(
          HrvRecordsCompanion.insert(
            date: DateTime(at.year, at.month, at.day),
            spo2: Value(spo2),
            restingHeartRate: Value(hr?.round()),
            source: const Value('manual'),
          ),
        );
        break;
      case 'Manual Activity':
        final minutes = read('Duration'), km = read('Distance');
        if (minutes == null || minutes <= 0 || (km ?? 0) < 0) {
          throw StateError('Enter a valid duration.');
        }
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: const Uuid().v4(),
                name: text('Activity name').trim().isEmpty
                    ? 'Manual activity'
                    : text('Activity name').trim(),
                type: text('Sport').trim().isEmpty
                    ? 'running'
                    : text('Sport').trim(),
                startDate: at,
                durationSeconds: (minutes * 60).round(),
                distanceMeters: Value(km == null ? null : km * 1000),
                avgHeartRate: Value(read('Heart Rate')),
                source: const Value('manual'),
              ),
            );
        break;
      default:
        throw StateError('Choose a measurement.');
    }
    ref.read(syncStatusListenerProvider.notifier).state++;
  }
}
