import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/health_connect_service.dart';

class _Health extends Health {
  bool? allowed = false;
  int writes = 0;
  int? failAt;
  List<HealthDataAccess>? checkedPermissions;

  @override
  Future<void> configure() async {}

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    expect(types, [
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    ]);
    checkedPermissions = permissions;
    return allowed;
  }

  @override
  Future<bool> writeBloodPressure({
    required int systolic,
    required int diastolic,
    required DateTime startTime,
    String? clientRecordId,
    double? clientRecordVersion,
    DateTime? endTime,
    RecordingMethod recordingMethod = RecordingMethod.automatic,
  }) async {
    writes++;
    return writes != failAt;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late _Health health;
  late HealthConnectService service;
  late DateTime first;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    health = _Health();
    service = HealthConnectService(db, health: health);
    // Five minutes into a 15-minute window, so the readings below fall into
    // the windows the tests expect whatever the clock says.
    const window = 15 * 60 * 1000;
    final twoHoursAgo = DateTime.now()
        .subtract(const Duration(hours: 2))
        .millisecondsSinceEpoch;
    first = DateTime.fromMillisecondsSinceEpoch(
      twoHoursAgo ~/ window * window + 5 * 60 * 1000,
    );
    await db.insertBpMeasurements(
      List.generate(
        3,
        // One reading per 15-minute window: Health gets one per window.
        (i) => BpMeasurementsCompanion.insert(
          measuredAt: first.add(Duration(minutes: 20 * i)),
          systolic: 120,
          diastolic: 80,
          heartRate: 60,
        ),
      ),
    );
  });
  tearDown(() => db.close());

  for (final permission in [false, null]) {
    test(
      'denied/unknown permission $permission skips BP without losing pending data',
      () async {
        health.allowed = permission;
        final result = await service.writeBack(true, false);
        expect(health.writes, 0);
        expect(health.checkedPermissions, [
          HealthDataAccess.WRITE,
          HealthDataAccess.WRITE,
        ]);
        expect(result.errors, hasLength(1));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('hc_wb_bp_ms') ?? 0, 0);
        health.allowed = true;
        final retry = await service.writeBack(true, false);
        expect(retry.bp, 3);
        expect((await service.writeBack(true, false)).bp, 0);
      },
    );
  }

  test('a stream of readings goes to Health as one per 15 minutes', () async {
    health.allowed = true;
    // Two more readings inside the first reading's window.
    await db.insertBpMeasurements([
      for (final m in [1, 2])
        BpMeasurementsCompanion.insert(
          measuredAt: first.add(Duration(minutes: m)),
          systolic: 121,
          diastolic: 81,
          heartRate: 60,
        ),
    ]);
    final result = await service.writeBack(true, false);
    expect(result.bp, 3);
    expect(health.writes, 3);
  });

  test(
    'failed write stops the batch and retries from last successful sample',
    () async {
      health.allowed = true;
      health.failAt = 2;
      final result = await service.writeBack(true, false);
      expect(result.bp, 1);
      expect(health.writes, 2);
      expect(result.errors, hasLength(1));
      final prefs = await SharedPreferences.getInstance();
      // Only the sample that was saved is remembered, so the retry resumes
      // after it instead of writing it twice.
      expect(prefs.getStringList('hc_wb_bp_sent_v1'), hasLength(1));
      health.failAt = null;
      expect((await service.writeBack(true, false)).bp, 2);
    },
  );
}
