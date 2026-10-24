import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/health_connect_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHealth implements Health {
  _FakeHealth({this.canWrite = true, this.inHealth = const []});

  final bool canWrite;

  /// Blood-pressure readings Health already holds (from any app).
  final List<({DateTime at, int sys, int dia})> inHealth;
  final written = <({DateTime at, int sys, int dia})>[];

  @override
  Future<void> configure() async {}

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async => canWrite;

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    required DateTime startTime,
    required DateTime endTime,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    HealthDataPoint point(HealthDataType type, DateTime at, int value) =>
        HealthDataPoint(
          uuid: '$type-${at.millisecondsSinceEpoch}',
          value: NumericHealthValue(numericValue: value),
          type: type,
          unit: HealthDataUnit.MILLIMETER_OF_MERCURY,
          dateFrom: at,
          dateTo: at,
          sourcePlatform: HealthPlatformType.appleHealth,
          sourceDeviceId: 'test',
          sourceId: 'com.hilo',
          sourceName: 'Hilo',
        );
    return [
      for (final r in inHealth) ...[
        point(HealthDataType.BLOOD_PRESSURE_SYSTOLIC, r.at, r.sys),
        point(HealthDataType.BLOOD_PRESSURE_DIASTOLIC, r.at, r.dia),
      ],
    ];
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
    written.add((at: startTime, sys: systolic, dia: diastolic));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  final recent = DateTime.now().subtract(const Duration(days: 1));
  BpMeasurement row(DateTime at, int sys, int dia) => BpMeasurement(
    id: 0,
    measuredAt: at,
    timezone: 'UTC',
    systolic: sys,
    diastolic: dia,
    heartRate: 60,
    measurementType: 'REPORT',
    dayNightTag: null,
    isBedTime: null,
    isWakeUpTime: null,
  );

  test('writes new readings and remembers them', () async {
    final health = _FakeHealth();
    final service = HealthConnectService(db, health: health);
    final rows = [row(recent, 130, 80)];

    final first = await service.exportBloodPressure(rows);
    expect(first.written, 1);
    expect(health.written, hasLength(1));

    final second = await service.exportBloodPressure(rows);
    expect(second.written, 0);
    expect(second.skipped, 1);
    expect(health.written, hasLength(1));
  });

  test('skips readings Health already holds, also within 2 mmHg', () async {
    final health = _FakeHealth(
      inHealth: [
        (at: recent, sys: 130, dia: 80),
        (at: recent.add(const Duration(minutes: 30)), sys: 121, dia: 71),
      ],
    );
    final service = HealthConnectService(db, health: health);
    final result = await service.exportBloodPressure([
      row(recent.add(const Duration(seconds: 20)), 130, 80),
      row(recent.add(const Duration(minutes: 30)), 120, 70),
      row(recent.add(const Duration(minutes: 60)), 125, 75),
    ]);
    expect(result.skipped, 2);
    expect(result.written, 1);
    expect(health.written.single.sys, 125);
  });

  test('a different value in the same minute is still written', () async {
    final health = _FakeHealth(inHealth: [(at: recent, sys: 110, dia: 60)]);
    final service = HealthConnectService(db, health: health);
    final result = await service.exportBloodPressure([row(recent, 140, 90)]);
    expect(result.written, 1);
  });

  test('writes nothing without write permission', () async {
    final health = _FakeHealth(canWrite: false);
    final service = HealthConnectService(db, health: health);
    final result = await service.exportBloodPressure([row(recent, 130, 80)]);
    expect(result.written, 0);
    expect(result.errors, isNotEmpty);
    expect(health.written, isEmpty);
  });
}
